-- File: ui/overlay_manager.lua (Formatted)
-- Manages showing, hiding, and interacting with UI overlays using injected dependencies.

local OverlayManager = {
    overlays = {},            -- Stores INSTANCES of each overlay (e.g., overlays["potionList"])
    overlayClasses = {},      -- Stores the CLASSES/modules passed in at init
    sharedDependencies = {},  -- Stores dependencies like gameState, theme, etc., passed to overlays
    activeOverlayName = nil,  -- String key of the currently active overlay
    isInitialized = false     -- Flag to prevent re-initialization
}
OverlayManager.__index = OverlayManager -- For method calls on the table itself if used as an object (though it's mostly a static manager)

--- Initializes the OverlayManager. Must be called once (e.g., in love.load).
-- @param config Table containing necessary setup info:
-- {
--   overlayClasses = { -- Map of overlay names to their required class tables
--     potionList = PotionListOverlayClass,
--     -- ... other overlay classes ...
--   },
--   sharedDependencies = { -- ALL Dependencies needed by the manager AND passed to overlays
--     gameState = GameState, theme = Theme, cardDatabase = CardDatabase,
--     ButtonClass = ButtonClass, uiManager = OverlayManager, -- uiManager will be this instance
--     potionActions = {...}, shopActions = {...}, spellActions = {...}, recipeProvider = {...},
--     -- ... other shared dependencies ...
--   }
-- }
function OverlayManager:init(config)
    if self.isInitialized then
        print("WARNING: OverlayManager:init called more than once. Skipping re-initialization.")
        return
    end
    print("Initializing OverlayManager...")

    -- Validate config structure
    assert(config and type(config) == "table", "OverlayManager:init requires a config table.")
    assert(config.overlayClasses and type(config.overlayClasses) == "table", "OverlayManager:init requires config.overlayClasses table.")
    assert(config.sharedDependencies and type(config.sharedDependencies) == "table", "OverlayManager:init requires config.sharedDependencies table.")
    
    -- Validate critical shared dependencies
    assert(config.sharedDependencies.gameState, "OverlayManager:init requires config.sharedDependencies.gameState.")
    assert(config.sharedDependencies.theme and config.sharedDependencies.theme.helpers, "OverlayManager:init requires config.sharedDependencies.theme with a helpers sub-table.")
    assert(config.sharedDependencies.ButtonClass, "OverlayManager:init requires config.sharedDependencies.ButtonClass.")

    -- Store dependencies and classes
    self.overlayClasses = config.overlayClasses
    self.sharedDependencies = config.sharedDependencies
    
    -- Ensure the uiManager reference within sharedDependencies points to this OverlayManager instance.
    -- This allows overlays to call back to the manager (e.g., self.uiManager:hide()).
    self.sharedDependencies.uiManager = self

    -- Reset internal state for overlays
    self.overlays = {}
    self.activeOverlayName = nil
    local instantiatedOverlayCount = 0

    print("Instantiating overlays...")
    for name, OverlayClass in pairs(self.overlayClasses) do
        if OverlayClass and type(OverlayClass) == "table" and type(OverlayClass.new) == "function" then
            -- Each overlay's :new() function expects a single config table.
            -- We pass a shallow copy of sharedDependencies and add the overlay's name to it.
            -- This avoids modifying the main sharedDependencies table if an overlay :new() adds/changes its config.
            local overlaySpecificConfig = {}
            for k, v in pairs(self.sharedDependencies) do -- Create a shallow copy
                overlaySpecificConfig[k] = v
            end
            overlaySpecificConfig.name = name -- Add the overlay's unique name to its config

            -- Use pcall for safety in case an overlay's :new() method errors out.
            local success, instanceOrError = pcall(OverlayClass.new, OverlayClass, overlaySpecificConfig)

            if success and instanceOrError and type(instanceOrError) == "table" then
                self.overlays[name] = instanceOrError
                print(string.format("    -> Initialized '%s' overlay instance.", name))
                instantiatedOverlayCount = instantiatedOverlayCount + 1
            else
                print(string.format("ERROR: Failed to instantiate overlay '%s'. Error: %s", name, tostring(instanceOrError)))
                -- Depending on game design, you might want to halt here or handle missing critical overlays.
            end
        else
            print(string.format("WARNING: Invalid or missing overlay class provided for name: '%s'. Skipping.", name))
        end
    end

    self.isInitialized = true
    print("OverlayManager initialization complete. Instantiated overlay count:", instantiatedOverlayCount)
end

--- Shows a specific overlay by its registered name.
-- Hides any currently active overlay before showing the new one.
-- @param overlayName (string) The key used when initializing the overlay.
function OverlayManager:show(overlayName)
    if not self.isInitialized then
        print("ERROR: OverlayManager:show called before init.")
        return
    end

    local overlayToShow = self.overlays[overlayName]
    if not overlayToShow then
        print("Error (OverlayManager:show): Cannot show unknown or uninitialized overlay: '" .. tostring(overlayName) .. "'")
        return
    end

    if self.activeOverlayName == overlayName then
        -- print("Info (OverlayManager:show): Overlay '" .. overlayName .. "' is already active.") -- Optional debug
        return -- Already active, do nothing
    end

    -- Hide the previously active overlay first (this will call its onHide method)
    if self.activeOverlayName then
        self:hide() -- This clears self.activeOverlayName and updates GameState
    end

    print("Showing overlay:", overlayName)
    self.activeOverlayName = overlayName
    
    -- Keep GameState in sync (useful for external systems checking active UI state)
    if self.sharedDependencies.gameState then
        self.sharedDependencies.gameState.activeOverlay = overlayName
    end

    -- Call the overlay's onShow method, if it exists, using pcall for safety
    if overlayToShow.onShow and type(overlayToShow.onShow) == "function" then
        local success, err = pcall(overlayToShow.onShow, overlayToShow)
        if not success then
            print(string.format("ERROR: During %s:onShow() - %s", overlayName, tostring(err)))
        end
    end
end

--- Hides the currently active overlay.
function OverlayManager:hide()
    if not self.isInitialized then
        print("ERROR: OverlayManager:hide called before init.")
        return
    end
    if not self.activeOverlayName then
        return -- No overlay is currently active to hide
    end

    local closingOverlayName = self.activeOverlayName
    local overlayToHide = self.overlays[closingOverlayName]
    print("Hiding overlay:", closingOverlayName)

    -- Clear active overlay state *before* calling onHide,
    -- in case onHide itself triggers showing another overlay immediately.
    self.activeOverlayName = nil
    if self.sharedDependencies.gameState then
        self.sharedDependencies.gameState.activeOverlay = nil
    end

    -- Call the overlay's onHide method, if it exists, using pcall for safety
    if overlayToHide and overlayToHide.onHide and type(overlayToHide.onHide) == "function" then
        local success, err = pcall(overlayToHide.onHide, overlayToHide)
        if not success then
            print(string.format("ERROR: During %s:onHide() - %s", closingOverlayName, tostring(err)))
        end
    end
end

--- Updates the active overlay, passing necessary input state.
function OverlayManager:update(dt, mx, my, isMouseButtonDown)
    if not self.isInitialized or not self.activeOverlayName then return end

    local activeOverlayInstance = self.overlays[self.activeOverlayName]
    if activeOverlayInstance and activeOverlayInstance.update and type(activeOverlayInstance.update) == "function" then
        local success, err = pcall(activeOverlayInstance.update, activeOverlayInstance, dt, mx, my, isMouseButtonDown)
        if not success then
            print(string.format("ERROR: During %s:update() - %s", self.activeOverlayName, tostring(err)))
        end
    end
end

--- Draws the active overlay.
function OverlayManager:draw()
    if not self.isInitialized or not self.activeOverlayName then return end

    local activeOverlayInstance = self.overlays[self.activeOverlayName]
    if activeOverlayInstance and activeOverlayInstance.draw and type(activeOverlayInstance.draw) == "function" then
        local success, err = pcall(activeOverlayInstance.draw, activeOverlayInstance)
        if not success then
            print(string.format("ERROR: During %s:draw() - %s", self.activeOverlayName, tostring(err)))
            self:_drawFallbackError("Overlay '" .. self.activeOverlayName .. "' failed to draw. Error: " .. tostring(err))
        end
    elseif activeOverlayInstance == nil then
        print(string.format("ERROR: Active overlay instance for '%s' is missing.", self.activeOverlayName))
        self:_drawFallbackError("Error: Overlay '" .. self.activeOverlayName .. "' instance missing.")
    -- else: Overlay instance exists but has no draw method (less common for visible overlays)
    end
end

--- Internal helper to draw a fallback error message if an overlay fails to draw.
function OverlayManager:_drawFallbackError(message)
    -- Ensure critical drawing dependencies are available
    if not love or not love.graphics or 
       not self.sharedDependencies or not self.sharedDependencies.theme or 
       not self.sharedDependencies.theme.helpers then
        print("CRITICAL ERROR (_drawFallbackError): Cannot draw fallback message - missing essential dependencies (love.graphics or theme helpers).")
        return
    end

    local theme = self.sharedDependencies.theme
    local helpers = theme.helpers
    local calculatePanelRectFunc = helpers.calculateOverlayPanelRect
    local drawBaseFunc = helpers.drawOverlayBase

    if calculatePanelRectFunc and drawBaseFunc then
        local panelRect = calculatePanelRectFunc(theme) -- Calculate a standard panel rect
        drawBaseFunc(panelRect, theme) -- Draw the base panel visuals

        local originalFont = love.graphics.getFont()
        local r, g, b, a = love.graphics.getColor()

        love.graphics.setColor(1, 0, 0, 1) -- Bright red for error text
        local errorFont = (theme.fonts and theme.fonts.default) or originalFont -- Use default theme font or current LÖVE font
        if errorFont then love.graphics.setFont(errorFont) end

        local textHeight = errorFont and errorFont:getHeight() or 12
        local textYPos = panelRect.y + panelRect.height / 2 - textHeight / 2
        
        love.graphics.printf(message or "Unknown Overlay Drawing Error",
                             panelRect.x + 10, 
                             textYPos, 
                             panelRect.width - 20, 
                             "center")

        if errorFont then love.graphics.setFont(originalFont) end -- Restore font
        love.graphics.setColor(r, g, b, a) -- Restore color
    else
        print("ERROR (_drawFallbackError): Cannot draw fallback message - missing calculateOverlayPanelRect or drawOverlayBase helper.")
    end
end

--- Passes click events to the active overlay.
-- @return true if the click was handled by the overlay system, false otherwise.
function OverlayManager:handleClick(x, y)
    if not self.isInitialized or not self.activeOverlayName then return false end

    local activeOverlayInstance = self.overlays[self.activeOverlayName]
    local handledByOverlay = false

    if activeOverlayInstance and activeOverlayInstance.handleClick and type(activeOverlayInstance.handleClick) == "function" then
        local success, result = pcall(activeOverlayInstance.handleClick, activeOverlayInstance, x, y)
        if success and result == true then
            handledByOverlay = true
        elseif not success then
            print(string.format("ERROR: During %s:handleClick() - %s", self.activeOverlayName, tostring(result)))
            handledByOverlay = true -- Assume click is consumed on error to prevent further issues
        end
    end

    -- If the overlay's handleClick didn't explicitly handle it (returned false or nil),
    -- but the click was within the general overlay panel area, still consume the click.
    if not handledByOverlay then
        local helpers = self.sharedDependencies.theme and self.sharedDependencies.theme.helpers
        local calculatePanelRectFunc = helpers and helpers.calculateOverlayPanelRect
        local isPointInRectFunc = helpers and helpers.isPointInRect
        
        if activeOverlayInstance and calculatePanelRectFunc and isPointInRectFunc then
            -- Recalculate panelRect here as it might be dynamic or not stored if overlay doesn't manage it itself
            local panelRect = calculatePanelRectFunc(self.sharedDependencies.theme) 
            if panelRect and isPointInRectFunc(x, y, panelRect) then
                handledByOverlay = true -- Click was inside the general overlay area, consume it.
                -- print(string.format("Info: Click on overlay '%s' panel area consumed.", self.activeOverlayName)) -- Optional debug
            end
        end
    end
    return handledByOverlay
end

--- Passes key press events to the active overlay and handles global Escape key for closing overlays.
-- @param key (string) The key that was pressed.
-- @return true if the key press was handled, false otherwise.
function OverlayManager:handleKeyPress(key)
    if not self.isInitialized then return false end

    local gameState = self.sharedDependencies.gameState
    local handled = false

    -- Global Escape key handler for overlays (unless it's a modal that shouldn't be escaped, like potionDecision)
    local canEscapeCloseActiveOverlay = self.activeOverlayName and 
                                       self.activeOverlayName ~= "potionDecision" -- Example of non-escapable overlay

    if key == "escape" and canEscapeCloseActiveOverlay then
        print("Escape key pressed, hiding overlay:", self.activeOverlayName)
        
        -- Specific logic for cancelling spell selection via Escape
        if gameState and (self.activeOverlayName == "spellSelection" or gameState.selectingSpellTarget) then
            gameState.selectedSpellId = nil
            gameState.selectingSpellTarget = false
            print("    -> Spell selection cancelled by Escape.")
        end
        
        self:hide() -- Hide the current overlay
        handled = true
    end

    -- If not handled by global Escape, pass to the active overlay's specific handler
    if not handled and self.activeOverlayName then
        local activeOverlayInstance = self.overlays[self.activeOverlayName]
        if activeOverlayInstance and activeOverlayInstance.handleKeyPress and type(activeOverlayInstance.handleKeyPress) == "function" then
            local success, result = pcall(activeOverlayInstance.handleKeyPress, activeOverlayInstance, key)
            if success and result == true then
                handled = true
            elseif not success then
                print(string.format("ERROR: During %s:handleKeyPress() - %s", self.activeOverlayName, tostring(result)))
                -- Optionally, consider 'handled = true' on error to prevent key passing through.
            end
        end
    end
    return handled
end

--- Returns the instance of the currently active overlay, or nil.
function OverlayManager:getActive()
    if self.activeOverlayName then
        return self.overlays[self.activeOverlayName]
    end
    return nil
end

--- Returns the name (string key) of the currently active overlay, or nil.
function OverlayManager:getActiveOverlayName()
    return self.activeOverlayName
end

-- Return the OverlayManager table itself so it acts like a singleton module
return OverlayManager