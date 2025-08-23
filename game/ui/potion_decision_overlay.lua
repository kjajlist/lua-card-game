-- File: ui/potion_decision_overlay.lua (Formatted)
-- Defines the overlay shown after crafting a potion, allowing the player to choose Drink or Sell.
-- Uses injected dependencies.

local Button -- Expected to be passed in config.ButtonClass

local PotionDecisionOverlay = {}
PotionDecisionOverlay.__index = PotionDecisionOverlay

--- Creates a new PotionDecisionOverlay instance.
-- @param config Table containing dependencies and settings.
function PotionDecisionOverlay:new(config)
    -- 1. Validate Configuration and Dependencies
    assert(config and config.name, "PotionDecisionOverlay:new requires config.name")
    assert(config.uiManager, "PotionDecisionOverlay:new requires config.uiManager")
    assert(config.gameState, "PotionDecisionOverlay:new requires config.gameState")
    assert(config.theme and config.theme.fonts and config.theme.colors and 
           config.theme.layout and config.theme.sizes and 
           config.theme.cornerRadius and config.theme.helpers, 
           "PotionDecisionOverlay:new requires a valid config.theme table")
    assert(config.theme.fonts.large and config.theme.fonts.ui and config.theme.fonts.default, 
           "PotionDecisionOverlay:new requires large, ui, and default fonts in config.theme.fonts")
    assert(config.theme.helpers.calculateOverlayPanelRect and 
           config.theme.helpers.drawOverlayBase and 
           config.theme.helpers.isPointInRect and 
           config.theme.helpers.drawPotionBottle, 
           "PotionDecisionOverlay:new requires helper functions (calculateOverlayPanelRect, drawOverlayBase, isPointInRect, drawPotionBottle) in config.theme.helpers")
    assert(config.ButtonClass, "PotionDecisionOverlay:new requires config.ButtonClass")
    assert(config.potionActions and type(config.potionActions.drink) == "function" and 
           type(config.potionActions.sell) == "function", 
           "PotionDecisionOverlay:new requires config.potionActions table with drink and sell functions")

    local instance = setmetatable({}, PotionDecisionOverlay)

    -- 2. Store Dependencies
    instance.name = config.name
    instance.uiManager = config.uiManager
    instance.gameState = config.gameState
    instance.theme = config.theme
    instance.potionActions = config.potionActions
    Button = config.ButtonClass -- Set module-level local for Button class

    -- 3. Initial UI Setup
    instance.panelRect = instance.theme.helpers.calculateOverlayPanelRect(instance.theme) 
                        or { x = 20, y = 20, width = 350, height = 450 } -- Fallback rect

    -- Cache theme values for button creation
    local theme = instance.theme
    local defaultButtonRadius = theme.cornerRadius.default or 5
    local choiceButtonWidth = theme.sizes.decisionButtonWidth or 120
    local choiceButtonHeight = theme.sizes.decisionButtonHeight or 40
    local drinkButtonColor = theme.colors.buttonDrink or {0.6, 0.9, 0.6, 1}
    local sellButtonColor = theme.colors.buttonSell or {0.9, 0.8, 0.6, 1}

    local buttonDefaultSettings = {
        defaultFont = theme.fonts.default,
        defaultCornerRadius = defaultButtonRadius,
        defaultColors = theme.colors -- Pass the whole theme colors table for button defaults
    }

    -- Create Drink Button
    instance.drinkButton = Button:new({
        id = "potionDrink", 
        x = 0, y = 0, -- Positioned in draw()
        width = choiceButtonWidth, height = choiceButtonHeight,
        label = "Drink", 
        font = theme.fonts.ui,
        cornerRadius = defaultButtonRadius,
        colors = { normal = drinkButtonColor }, -- Override normal color for this specific button
        onClick = function() instance.potionActions.drink() end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    -- Create Sell Button
    instance.sellButton = Button:new({
        id = "potionSell", 
        x = 0, y = 0, -- Positioned in draw()
        width = choiceButtonWidth, height = choiceButtonHeight,
        label = "Sell", 
        font = theme.fonts.ui,
        cornerRadius = defaultButtonRadius,
        colors = { normal = sellButtonColor }, -- Override normal color
        onClick = function() instance.potionActions.sell() end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    return instance
end

--- Updates the state of buttons within the decision overlay.
function PotionDecisionOverlay:update(dt, mx, my, isMouseButtonDown)
    if not self.drinkButton or not self.sellButton then
        print("Warning (PotionDecisionOverlay:update): Buttons not initialized.")
        return
    end

    -- Update buttons, passing required input state
    self.drinkButton:update(dt, mx, my, isMouseButtonDown)
    self.sellButton:update(dt, mx, my, isMouseButtonDown)

    -- Ensure buttons are enabled; this overlay being active generally means they should be.
    -- Future: Consider edge cases where one might be disabled (e.g., cannot drink if at max effect).
    self.drinkButton:setEnabled(true)
    self.sellButton:setEnabled(true)
end

--- Draws the potion decision overlay UI.
-- File: ui/potion_decision_overlay.lua (Modified draw function snippet)

--- Draws the potion decision overlay UI.
-- File: ui/potion_decision_overlay.lua

function PotionDecisionOverlay:draw()
    -- Only draw if this overlay is active
    if self.uiManager:getActiveOverlayName() ~= self.name then
        return
    end

    -- Check for critical missing dependencies for the overlay itself
    if not self.gameState or not self.theme or not self.drinkButton or not self.sellButton then
        print("ERROR (PotionDecisionOverlay:draw): Missing critical dependencies or buttons for the overlay.")
        return
    end
    local pendingPotion = self.gameState.pendingPotionChoice
    if not pendingPotion or type(pendingPotion) ~= "table" then
        print("Error (PotionDecisionOverlay:draw): GameState.pendingPotionChoice missing or invalid.")
        return
    end
    if not love or not love.graphics then
        print("Error (PotionDecisionOverlay:draw): LÖVE graphics module not available.")
        return
    end

    -- Cache theme elements for readability
    local theme = self.theme
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    local fonts = theme.fonts or {}
    local sizes = theme.sizes or {}
    local helpers = theme.helpers or {}

    local paddingSmall = layout.paddingSmall or 5
    local paddingMedium = layout.paddingMedium or 10
    local paddingLarge = layout.paddingLarge or 20
    
    local titleTextColor = colors.textDark or {0.1, 0.1, 0.1, 1}
    local effectTextColor = colors.textPotionBonus or {0.5, 0.2, 0.5, 1}
    local valueTextColor = colors.textScore or {0.8, 0.7, 0.1, 1}

    -- 1. Recalculate Panel and Draw Base
    self.panelRect = (helpers.calculateOverlayPanelRect and helpers.calculateOverlayPanelRect(theme)) or self.panelRect
    if helpers.drawOverlayBase then helpers.drawOverlayBase(self.panelRect, theme) end

    -- Store current graphics state to restore later
    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Title
    local titleFontToUse = fonts.large or fonts.default
    local titleTextY = self.panelRect.y + paddingMedium
    if titleFontToUse then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(titleFontToUse)
        love.graphics.printf("Potion Crafted!", self.panelRect.x, titleTextY, self.panelRect.width, "center")
    end
    local titleActualHeight = titleFontToUse and titleFontToUse:getHeight() or 20

    -- 3. Draw Potion Details
    local currentY = self.panelRect.y + paddingMedium + titleActualHeight + paddingLarge
    local contentStartX = self.panelRect.x + paddingLarge
    local contentAvailableWidth = self.panelRect.width - (paddingLarge * 2)
    local detailFont = fonts.ui or fonts.default

    if not detailFont then 
        print("Warning (PotionDecisionOverlay:draw): Detail font (fonts.ui or fonts.default) is missing.")
        love.graphics.setFont(originalFont); love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
        return
    end
    love.graphics.setFont(detailFont)

    -- Potion Name
    love.graphics.setColor(titleTextColor)
    love.graphics.printf(pendingPotion.name or "Unknown Potion", contentStartX, currentY, contentAvailableWidth, "center")
    currentY = currentY + detailFont:getHeight() + paddingLarge

    -- Draw Potion Bottle Visual
    local bottleDisplayData = pendingPotion.display or {}
    local bottleVisualHeight = sizes.bottleHeight or 90
    local bottleVisualX = self.panelRect.x + self.panelRect.width / 2
    local bottleVisualY = currentY + bottleVisualHeight / 2 
    
    if helpers.drawPotionBottle then
        print(string.format("PotionDecisionOverlay: Calling helpers.drawPotionBottle for '%s'", pendingPotion.name or "Unknown"))
        -- The 'theme' argument passed here is self.theme (which is Dependencies.theme from main.lua)
        -- The wrapper in main.lua's Dependencies.theme.helpers is responsible for calling Draw.drawPotionBottle with GameState, Config, Dependencies
        helpers.drawPotionBottle(bottleVisualX, bottleVisualY, 
                                 bottleDisplayData.bottle, bottleDisplayData.color, 
                                 1.0, theme) 
    else
        print("Warning (PotionDecisionOverlay:draw): drawPotionBottle helper missing from theme.")
        love.graphics.setColor(0.7,0.7,0.7,1); love.graphics.rectangle("fill", bottleVisualX - 20, currentY, 40, bottleVisualHeight);
    end
    currentY = currentY + bottleVisualHeight + paddingLarge

    -- Draw Effect Description
    love.graphics.setColor(effectTextColor)
    local effectDescText = (pendingPotion.drinkEffect and pendingPotion.drinkEffect.description) or "No special effect."
    local numberOfEffectLines = 1 
    if detailFont:getWidth("Drink Effect: " .. effectDescText) > contentAvailableWidth then
        local _, linesTable = detailFont:getWrap("Drink Effect: " .. effectDescText, contentAvailableWidth)
        if linesTable then numberOfEffectLines = #linesTable end
    end
    love.graphics.printf("Drink Effect: " .. effectDescText, contentStartX, currentY, contentAvailableWidth, "center")
    currentY = currentY + (detailFont:getHeight() * numberOfEffectLines) + paddingSmall

    -- Draw Sale Value
    love.graphics.setColor(valueTextColor)
    local saleValueText = "Sell Value: $" .. tostring(pendingPotion.saleValue or 0)
    love.graphics.printf(saleValueText, contentStartX, currentY, contentAvailableWidth, "center")
    currentY = currentY + detailFont:getHeight() + paddingLarge * 1.5

    -- 4. Position and Draw Buttons
    local buttonsYPos = currentY
    if self.drinkButton and self.sellButton then
        local totalButtonsWidth = self.drinkButton.width + self.sellButton.width + paddingMedium
        local startButtonsX = self.panelRect.x + (self.panelRect.width - totalButtonsWidth) / 2

        self.drinkButton.x = startButtonsX
        self.drinkButton.y = buttonsYPos
        self.drinkButton:draw()

        self.sellButton.x = startButtonsX + self.drinkButton.width + paddingMedium
        self.sellButton.y = buttonsYPos
        self.sellButton:draw()
    end

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
end
--- Handles clicks within the potion decision overlay.
function PotionDecisionOverlay:handleClick(x, y)
    -- Check buttons first (Button:handleClick handles isEnabled and calls injected onClick)
    if self.drinkButton and self.drinkButton:handleClick(x, y) then return true end
    if self.sellButton and self.sellButton:handleClick(x, y) then return true end

    -- Consume click if inside panel but not on specific buttons (prevents click-through)
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    if isPointInRectFunc and self.panelRect and isPointInRectFunc(x, y, self.panelRect) then
        -- print("Click consumed by PotionDecisionOverlay panel background.") -- Optional debug
        return true
    end
    return false -- Click was not handled by this overlay
end

--- Called when the overlay becomes visible.
function PotionDecisionOverlay:onShow()
    print("Potion Decision Overlay Shown")
    -- Example of dynamic update:
    -- local potionChoice = self.gameState and self.gameState.pendingPotionChoice
    -- if self.sellButton and potionChoice then
    --     self.sellButton:setLabel("Sell for $" .. tostring(potionChoice.saleValue or 0))
    -- else
    --     self.sellButton:setLabel("Sell") -- Fallback
    -- end
end

--- Called when the overlay is hidden.
function PotionDecisionOverlay:onHide()
    print("Potion Decision Overlay Hidden")
    -- State cleanup (like clearing GameState.pendingPotionChoice or GameState.gamePhase)
    -- is handled by the potionActions.drink/sell functions in CoreGame, not here.
end

return PotionDecisionOverlay