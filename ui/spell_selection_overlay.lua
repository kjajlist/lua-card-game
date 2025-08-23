-- File: ui/spell_selection_overlay.lua (Formatted)
-- Defines the overlay for selecting a spell to cast, using injected dependencies.

local Button -- Expected to be passed in config.ButtonClass

local SpellSelectionOverlay = {}
SpellSelectionOverlay.__index = SpellSelectionOverlay

--- Creates a new SpellSelectionOverlay instance.
-- @param config Table containing dependencies and settings.
function SpellSelectionOverlay:new(config)
    -- 1. Validate Configuration and Dependencies
    assert(config and config.name, "SpellSelectionOverlay:new requires config.name")
    assert(config.uiManager, "SpellSelectionOverlay:new requires config.uiManager")
    assert(config.gameState, "SpellSelectionOverlay:new requires config.gameState")
    assert(config.theme and config.theme.fonts and config.theme.colors and 
           config.theme.layout and config.theme.sizes and 
           config.theme.cornerRadius and config.theme.helpers, 
           "SpellSelectionOverlay:new requires a valid config.theme table")
    assert(config.theme.fonts.large and config.theme.fonts.ui and 
           config.theme.fonts.small and config.theme.fonts.default, 
           "SpellSelectionOverlay:new requires large, ui, small, and default fonts in config.theme.fonts")
    assert(config.theme.helpers.calculateOverlayPanelRect and 
           config.theme.helpers.drawOverlayBase and 
           config.theme.helpers.isPointInRect, 
           "SpellSelectionOverlay:new requires core helper functions in config.theme.helpers")
    assert(config.ButtonClass, "SpellSelectionOverlay:new requires config.ButtonClass")
    assert(config.spellActions and type(config.spellActions.select) == "function", 
           "SpellSelectionOverlay:new requires config.spellActions table with at least a select function")

    local instance = setmetatable({}, SpellSelectionOverlay)

    -- 2. Store Dependencies
    instance.name = config.name
    instance.uiManager = config.uiManager
    instance.gameState = config.gameState
    instance.theme = config.theme
    instance.spellActions = config.spellActions
    Button = config.ButtonClass -- Set module-level local for Button class

    -- 3. Initial UI Setup
    instance.panelRect = instance.theme.helpers.calculateOverlayPanelRect(instance.theme) 
                        or { x = 20, y = 20, width = 350, height = 450 } -- Fallback rect

    -- Cache theme values for button creation
    local theme = instance.theme
    local closeButtonSize = theme.sizes.overlayCloseButtonSize or 25
    local closeButtonRadius = theme.cornerRadius.closeButton or 3
    local closeButtonColor = theme.colors.buttonClose or {0.9, 0.5, 0.5, 1}

    local buttonDefaultSettings = {
        defaultFont = theme.fonts.default,
        defaultCornerRadius = theme.cornerRadius.default or 5,
        defaultColors = theme.colors
    }

    -- Create Close/Cancel Button
    instance.closeButton = Button:new({
        id = "spellSelectClose", 
        x = 0, y = 0, -- Positioned in draw()
        width = closeButtonSize, height = closeButtonSize,
        label = "X", 
        font = theme.fonts.ui,
        cornerRadius = closeButtonRadius,
        colors = { normal = closeButtonColor },
        onClick = function()
            if instance.spellActions.cancel and type(instance.spellActions.cancel) == "function" then
                instance.spellActions.cancel()
            else
                instance.uiManager:hide() -- Default hide if no specific cancel action
            end
        end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    -- Spell "Cast" buttons are dynamically created/updated in onShow
    instance.spellButtons = {} -- Store as a map: { [spellId] = buttonInstance }

    return instance
end

--- Called when the overlay becomes visible. Creates/updates buttons for known spells.
function SpellSelectionOverlay:onShow()
    print("Spell Selection Overlay Shown")

    if not self.gameState or not self.gameState.knownSpells then 
        print("Error (SpellSelectionOverlay:onShow): Missing GameState.knownSpells.")
        self.spellButtons = {}
        return 
    end
    if not Button then 
        print("Error (SpellSelectionOverlay:onShow): Button component (ButtonClass) not available.")
        self.spellButtons = {}
        return 
    end
    if not self.theme then 
        print("Error (SpellSelectionOverlay:onShow): Theme not available.")
        self.spellButtons = {}
        return 
    end

    self.spellButtons = {} -- Clear existing spell buttons to refresh

    local theme = self.theme
    local sizes = theme.sizes or {}
    local cornerRadius = theme.cornerRadius or {}
    local fonts = theme.fonts or {}
    local colors = theme.colors or {}

    local castButtonWidth = sizes.spellSelectButtonWidth or 80
    local castButtonHeight = sizes.spellSelectButtonHeight or 25
    local defaultBtnRadius = cornerRadius.default or 5
    local spellActionButtonColor = colors.buttonSpellActive or {0.8, 0.6, 0.9, 1}

    local buttonCreationDefaults = {
        defaultFont = fonts.default,
        defaultCornerRadius = defaultBtnRadius,
        defaultColors = colors
    }
    
    local self_overlay = self -- Capture 'self' for use in button onClick closures

    for spellId, spellData in pairs(self.gameState.knownSpells) do
        if spellData then
            local currentSpellId_closure = spellId       -- Capture for closure
            local currentSpellData_closure = spellData -- Capture for closure

            local newCastButton = Button:new({
                id = "castSpell_" .. tostring(currentSpellId_closure),
                x = 0, y = 0, -- Positioned in draw()
                width = castButtonWidth, height = castButtonHeight,
                label = "Select",
                font = fonts.ui,
                cornerRadius = defaultBtnRadius,
                colors = { normal = spellActionButtonColor },
                onClick = function()
                    print("Select spell button clicked for spell:", currentSpellId_closure)
                    -- Enter spell casting mode with this spell
                    self_overlay.gameState.selectedSpellId = currentSpellId_closure
                    self_overlay.gameState.spellCastingMode = true
                    self_overlay.gameState.selectedCardIndices = {} -- Clear any existing selections
                    if self_overlay.uiManager then self_overlay.uiManager:hide() end
                end,
                defaultFont = buttonCreationDefaults.defaultFont,
                defaultCornerRadius = buttonCreationDefaults.defaultCornerRadius,
                defaultColors = buttonCreationDefaults.defaultColors
            })
            self.spellButtons[currentSpellId_closure] = newCastButton
        end
    end

    local createdButtonCount = 0
    for _ in pairs(self.spellButtons) do createdButtonCount = createdButtonCount + 1 end
    print("Spell buttons created/updated:", createdButtonCount)
end


--- Updates the state of buttons within the spell selection overlay.
function SpellSelectionOverlay:update(dt, mx, my, isMouseButtonDown)
    if not self.closeButton or not self.spellButtons then
        print("Warning (SpellSelectionOverlay:update): Core buttons not initialized.")
        return
    end
    if not self.gameState or not self.gameState.knownSpells then 
        print("Warning (SpellSelectionOverlay:update): Missing GameState or knownSpells.")
        return 
    end
    if type(self.gameState.currentEnergy) ~= "number" then
         print("Warning (SpellSelectionOverlay:update): self.gameState.currentEnergy is not a number.")
         -- Spells requiring energy might be incorrectly disabled if currentEnergy is nil
    end

    self.closeButton:update(dt, mx, my, isMouseButtonDown)

    for spellId, buttonInstance in pairs(self.spellButtons) do
        if buttonInstance then 
            local spellData = self.gameState.knownSpells[spellId]
            local canBeEnabled = false

            if spellData then
                local energyCost = spellData.energyCost or 0 
                local canAfford = (self.gameState.currentEnergy or 0) >= energyCost
                
                if canAfford then
                    canBeEnabled = true
                end
            else
                -- print(string.format("Warning (SpellSelectionOverlay:update): No spellData for spellId '%s'", tostring(spellId))) -- Can be noisy
            end
            
            buttonInstance:setEnabled(canBeEnabled)
            buttonInstance:update(dt, mx, my, isMouseButtonDown)
        end
    end
end

--- Draws the spell selection overlay UI.
function SpellSelectionOverlay:draw()
    if self.uiManager:getActiveOverlayName() ~= self.name then return end

    if not self.gameState or not self.theme or not self.closeButton or not self.spellButtons then
        print("ERROR (SpellSelectionOverlay:draw): Missing critical dependencies or buttons.")
        return
    end
    if not self.gameState.knownSpells then
        print("Error (SpellSelectionOverlay:draw): GameState.knownSpells missing.")
        return
    end
    if not love or not love.graphics then
        print("Error (SpellSelectionOverlay:draw): LÖVE graphics module not available.")
        return
    end

    local theme = self.theme
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    local fonts = theme.fonts or {}
    local sizes = theme.sizes or {}
    local helpers = theme.helpers or {}

    local paddingSmall = layout.paddingSmall or 5
    local paddingMedium = layout.paddingMedium or 10
    local paddingLarge = layout.paddingLarge or 20
    local itemVerticalSpacing = layout.overlayItemSpacing or paddingMedium
    
    local titleTextColor = colors.textDark or {0.1,0.1,0.1,1}
    local descriptionTextColor = colors.textDescription or {0.3,0.3,0.3,1}
    local energyTextColor = colors.textEnergy or {0.1,0.4,0.1,1}

    -- 1. Draw Panel Base
    self.panelRect = helpers.calculateOverlayPanelRect and helpers.calculateOverlayPanelRect(theme) or self.panelRect
    if helpers.drawOverlayBase then helpers.drawOverlayBase(self.panelRect, theme) end

    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Title
    local titleFontToUse = fonts.large or fonts.default
    local titleTextY = self.panelRect.y + paddingMedium
    if titleFontToUse then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(titleFontToUse)
        love.graphics.printf("Select Spell", self.panelRect.x, titleTextY, self.panelRect.width, "center")
    end
    local titleActualHeight = titleFontToUse and titleFontToUse:getHeight() or 20

    -- Draw help text for new spell casting system
    local helpFont = fonts.small or fonts.default
    if helpFont then
        love.graphics.setFont(helpFont)
        love.graphics.setColor(descriptionTextColor)
        local helpText = "Tip: Select a spell to enter casting mode, then choose a target card"
        local helpY = titleTextY + titleActualHeight + 5
        love.graphics.printf(helpText, self.panelRect.x, helpY, self.panelRect.width, "center")
        titleActualHeight = titleActualHeight + helpFont:getHeight() + 5
    end

    -- 3. Position and Draw Close Button
    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - paddingSmall
    self.closeButton.y = self.panelRect.y + paddingSmall
    self.closeButton:draw()

    -- 4. Draw Spell List Content
    local currentY = self.panelRect.y + paddingMedium + titleActualHeight + paddingLarge
    local contentStartX = self.panelRect.x + paddingLarge
    local contentAvailableWidth = self.panelRect.width - (paddingLarge * 2)
    
    local spellNameFont = fonts.ui or fonts.default
    local spellDetailFont = fonts.small or fonts.default
    local castButtonWidth = sizes.spellSelectButtonWidth or 80
    local spellItemRowHeight = sizes.spellSelectItemHeight or 50

    if not spellNameFont or not spellDetailFont then
        print("Error (SpellSelectionOverlay:draw): Missing required fonts for spell list.")
        love.graphics.setFont(originalFont); love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
        return
    end

    local spellCountDrawn = 0
    -- Iterate through known spells (keys are spell IDs, so use pairs)
    -- For consistent order, one might collect keys and sort them first if needed.
    for spellId, spellData in pairs(self.gameState.knownSpells) do
        if spellData then
            spellCountDrawn = spellCountDrawn + 1
            local castButtonInstance = self.spellButtons[spellId]

            -- Spell Name
            love.graphics.setFont(spellNameFont)
            love.graphics.setColor(titleTextColor) -- Darker color for the name
            local nameTextY = currentY + paddingSmall
            
            -- Calculate available width for name, considering button and energy cost text
            local energyDisplayString = string.format(" (E:%d)", spellData.energyCost or 0)

            local infoTextWidth = 0
            if energyDisplayString ~= "" then
                 love.graphics.setFont(spellDetailFont) -- Use detail font for info string width calculation
                 infoTextWidth = spellDetailFont:getWidth(energyDisplayString)
                 love.graphics.setFont(spellNameFont) -- Switch back for name
            end

            local nameAvailableWidth = contentAvailableWidth - castButtonWidth - paddingMedium * 2 - infoTextWidth
            love.graphics.printf(tostring(spellData.name or "Unknown Spell"), contentStartX, nameTextY, nameAvailableWidth, "left")

            -- Energy Cost
            if energyDisplayString ~= "" then
                love.graphics.setFont(spellDetailFont)
                love.graphics.setColor(energyTextColor)
                local infoTextX = contentStartX + nameAvailableWidth + paddingMedium
                love.graphics.printf(energyDisplayString, infoTextX, nameTextY, infoTextWidth, "left")
            end

            -- Spell Description
            love.graphics.setFont(spellDetailFont)
            love.graphics.setColor(descriptionTextColor)
            local descriptionY = nameTextY + spellNameFont:getHeight() + 2 
            local descriptionAvailableWidth = contentAvailableWidth - castButtonWidth - paddingMedium 
            love.graphics.printf(tostring(spellData.description or ""), contentStartX, descriptionY, descriptionAvailableWidth, "left")



            -- Position and Draw Cast Button
            if castButtonInstance then
                castButtonInstance.x = contentStartX + contentAvailableWidth - castButtonWidth
                castButtonInstance.y = currentY + (spellItemRowHeight - castButtonInstance.height) / 2 -- Vertically center button in the row
                castButtonInstance:draw()
            end

            currentY = currentY + spellItemRowHeight + itemVerticalSpacing

            -- Basic check for panel overflow
            local panelBottomEdge = self.panelRect.y + self.panelRect.height - paddingLarge
            if currentY > panelBottomEdge then
                love.graphics.setColor(titleTextColor)
                love.graphics.setFont(spellNameFont)
                love.graphics.printf("...", contentStartX, panelBottomEdge - spellNameFont:getHeight(), contentAvailableWidth, "center")
                break -- Stop drawing more spells
            end
        end
    end

    if spellCountDrawn == 0 then
        love.graphics.setFont(fonts.ui or fonts.default)
        love.graphics.setColor(titleTextColor)
        love.graphics.printf("No spells known or available.", contentStartX, currentY, contentAvailableWidth, "center")
    end

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
end

--- Handles clicks within the spell selection overlay.
function SpellSelectionOverlay:handleClick(x, y)
    if self.closeButton and self.closeButton:handleClick(x, y) then return true end

    if self.spellButtons then
        for spellId, buttonInstance in pairs(self.spellButtons) do
            if buttonInstance and buttonInstance:handleClick(x, y) then
                -- The onClick callback (set in onShow) will handle calling spellActions.select
                return true
            end
        end
    end

    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    if isPointInRectFunc and self.panelRect and isPointInRectFunc(x, y, self.panelRect) then
        return true -- Consume click if inside panel but not on a specific button
    end
    return false
end

--- Called when the overlay is hidden.
function SpellSelectionOverlay:onHide()
    print("Spell Selection Overlay Hidden")
    -- GameState.selectedSpellId and GameState.selectingSpellTarget are reset
    -- by the spellActions.cancel or spellActions.select logic, or by CoreGame.applySpellEffect.
end

return SpellSelectionOverlay