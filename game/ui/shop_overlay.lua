-- File: ui/shop_overlay.lua (Formatted)
-- Defines the Shop overlay component for buying cards or spellbooks between rounds.

local Button -- Expected to be passed in config.ButtonClass

local ShopOverlay = {}
ShopOverlay.__index = ShopOverlay

--- Creates a new ShopOverlay instance.
-- @param config Table containing dependencies and settings.
function ShopOverlay:new(config)
    -- 1. Validate Configuration and Dependencies
    assert(config and config.name, "ShopOverlay:new requires config.name")
    assert(config.uiManager, "ShopOverlay:new requires config.uiManager")
    assert(config.gameState, "ShopOverlay:new requires config.gameState")
    assert(config.theme and config.theme.fonts and config.theme.colors and 
           config.theme.layout and config.theme.sizes and 
           config.theme.cornerRadius and config.theme.helpers, 
           "ShopOverlay:new requires a valid config.theme table")
    assert(config.theme.fonts.large and config.theme.fonts.ui and 
           config.theme.fonts.small and config.theme.fonts.default, 
           "ShopOverlay:new requires large, ui, small, and default fonts in config.theme.fonts")
    assert(config.theme.helpers.calculateOverlayPanelRect and 
           config.theme.helpers.drawOverlayBase and 
           config.theme.helpers.isPointInRect and 
           config.theme.helpers.drawCardIcon, -- drawPlaceholderIcon is optional helper
           "ShopOverlay:new requires core helper functions in config.theme.helpers")
    assert(config.ButtonClass, "ShopOverlay:new requires config.ButtonClass")
    assert(config.shopActions and type(config.shopActions.buy) == "function" and 
           type(config.shopActions.endPhase) == "function", 
           "ShopOverlay:new requires config.shopActions table with buy and endPhase functions")

    local instance = setmetatable({}, ShopOverlay)

    -- 2. Store Dependencies
    instance.name = config.name
    instance.uiManager = config.uiManager
    instance.gameState = config.gameState
    instance.theme = config.theme
    instance.shopActions = config.shopActions
    Button = config.ButtonClass -- Set module-level local for Button class

    -- 3. Initial UI Setup
    instance.panelRect = instance.theme.helpers.calculateOverlayPanelRect(instance.theme) 
                        or { x = 20, y = 20, width = 350, height = 450 } -- Fallback rect

    -- Cache theme values for button creation
    local theme = instance.theme
    local paddingSmall = theme.layout.paddingSmall or 5
    local defaultButtonRadius = theme.cornerRadius.default or 5
    
    local closeButtonSize = theme.sizes.overlayCloseButtonSize or 25
    local closeButtonRadius = theme.cornerRadius.closeButton or 3
    local closeButtonColor = theme.colors.buttonClose or {0.9, 0.5, 0.5, 1}
    
    local continueButtonWidth = theme.sizes.shopContinueButtonWidth or 200
    local continueButtonHeight = theme.sizes.shopContinueButtonHeight or 40

    local buttonDefaultSettings = {
        defaultFont = theme.fonts.default,
        defaultCornerRadius = defaultButtonRadius,
        defaultColors = theme.colors
    }

    -- Create Close Button
    instance.closeButton = Button:new({
        id = "shopClose", x = 0, y = 0, -- Positioned in draw()
        width = closeButtonSize, height = closeButtonSize,
        label = "X", 
        font = theme.fonts.ui, 
        cornerRadius = closeButtonRadius, 
        colors = { normal = closeButtonColor },
        onClick = function() instance.shopActions.endPhase() end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    -- Create Continue Button
    instance.continueButton = Button:new({
        id = "shopContinue", x = 0, y = 0, -- Positioned in draw()
        width = continueButtonWidth, height = continueButtonHeight,
        label = "Continue", 
        font = theme.fonts.ui,
        cornerRadius = defaultButtonRadius, -- Use default radius
        onClick = function() instance.shopActions.endPhase() end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    -- Item buttons are dynamically created/updated in onShow
    instance.itemButtons = {}

    return instance
end

--- Called when the overlay becomes visible. Creates/updates buttons for current shop items.
function ShopOverlay:onShow()
    print("Shop Overlay Shown")
    if not self.gameState or not self.gameState.currentShopItems then
        print("Error (ShopOverlay:onShow): Missing GameState.currentShopItems.")
        self.itemButtons = {}
        return
    end
    if not Button then 
        print("Error (ShopOverlay:onShow): Button component (ButtonClass) not available.")
        self.itemButtons = {}
        return
    end
    if not self.theme then 
        print("Error (ShopOverlay:onShow): Theme not available.")
        self.itemButtons = {}
        return
    end

    self.itemButtons = {} -- Clear existing item buttons

    local theme = self.theme
    local sizes = theme.sizes or {}
    local cornerRadius = theme.cornerRadius or {}
    local fonts = theme.fonts or {}
    local colors = theme.colors or {}

    local buyButtonWidth = sizes.shopBuyButtonWidth or 80
    local buyButtonHeight = sizes.shopBuyButtonHeight or 30
    local defaultBtnRadius = cornerRadius.default or 5

    local buttonCreationDefaults = {
        defaultFont = fonts.default,
        defaultCornerRadius = defaultBtnRadius,
        defaultColors = colors
    }
    
    local self_overlay = self -- Capture self for use in onClick closures

    for i, offer in ipairs(self.gameState.currentShopItems) do
        if offer and offer.itemDef then
            local itemIndex = i -- Capture the current index for the closure
            local newBuyButton = Button:new({
                id = "shopBuyItem" .. tostring(itemIndex),
                x = 0, y = 0, -- Positioned in draw()
                width = buyButtonWidth, height = buyButtonHeight,
                label = "Buy", -- Initial label, updated in draw() based on purchased status
                font = fonts.ui,
                cornerRadius = defaultBtnRadius,
                onClick = function()
                    self_overlay.shopActions.buy(itemIndex)
                end,
                defaultFont = buttonCreationDefaults.defaultFont,
                defaultCornerRadius = buttonCreationDefaults.defaultCornerRadius,
                defaultColors = buttonCreationDefaults.defaultColors
            })
            table.insert(self.itemButtons, newBuyButton)
        else
            table.insert(self.itemButtons, nil) -- Placeholder for invalid offer to maintain index alignment
            print(string.format("Warning (ShopOverlay:onShow): Invalid shop offer found at index %d.", i))
        end
    end
    print("Shop item buttons created/updated:", #self.itemButtons)
end

--- Updates the state of buttons within the shop overlay.
function ShopOverlay:update(dt, mx, my, isMouseButtonDown)
    if not self.closeButton or not self.continueButton or not self.itemButtons then
        print("Warning (ShopOverlay:update): Core buttons not initialized.")
        return
    end
    if not self.gameState or not self.gameState.currentShopItems then
        print("Warning (ShopOverlay:update): Missing GameState or currentShopItems.")
        return
    end

    -- Update standard overlay buttons
    self.closeButton:update(dt, mx, my, isMouseButtonDown)
    self.continueButton:update(dt, mx, my, isMouseButtonDown)

    -- Update dynamic item buy buttons (check affordability, purchased status)
    local playerWallet = self.gameState.wallet or 0
    for i, buyButtonInstance in ipairs(self.itemButtons) do
        if buyButtonInstance then -- Check button exists (might be nil if offer was invalid from onShow)
            local offer = self.gameState.currentShopItems[i]
            local canEnableButton = false
            if offer and offer.itemDef and not offer.isPurchased then
                local itemCost = offer.itemDef.cost or 9999 -- High cost if undefined
                if playerWallet >= itemCost then
                    canEnableButton = true
                end
            end
            buyButtonInstance:setEnabled(canEnableButton)
            buyButtonInstance:update(dt, mx, my, isMouseButtonDown) -- Update hover/pressed state
        end
    end
end

--- Draws the shop overlay UI.
function ShopOverlay:draw()
    if self.uiManager:getActiveOverlayName() ~= self.name then return end

    if not self.gameState or not self.theme or not self.closeButton or 
       not self.continueButton or not self.itemButtons then
        print("ERROR (ShopOverlay:draw): Missing critical dependencies or buttons.")
        return
    end
    if not self.gameState.currentShopItems then
        print("Error (ShopOverlay:draw): GameState.currentShopItems missing.")
        return
    end
    if not love or not love.graphics then
        print("Error (ShopOverlay:draw): LÖVE graphics module not available.")
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
    local itemRowSpacing = layout.shopItemSpacing or (layout.layoutGap or 15)
    local itemRowHeight = sizes.shopItemHeight or 60
    
    local titleTextColor = colors.textDark or {0.1,0.1,0.1,1}
    local costTextColor = colors.textScore or {0.8,0.7,0.1,1}
    local descriptionColor = colors.textDescription or {0.3,0.3,0.3,1}

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
        love.graphics.printf("Shop", self.panelRect.x, titleTextY, self.panelRect.width, "center")
    end
    local titleActualHeight = titleFontToUse and titleFontToUse:getHeight() or 20

    -- 3. Position and Draw Close Button
    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - paddingSmall
    self.closeButton.y = self.panelRect.y + paddingSmall
    self.closeButton:draw()

    -- 4. Draw Shop Items Area
    local currentY = self.panelRect.y + paddingMedium + titleActualHeight + paddingLarge
    local contentStartX = self.panelRect.x + paddingLarge
    local contentAvailableWidth = self.panelRect.width - (paddingLarge * 2)
    
    local itemNameFont = fonts.ui or fonts.default
    local itemDetailFont = fonts.small or fonts.default
    local itemCostFont = fonts.ui or fonts.default 

    if not itemNameFont or not itemDetailFont or not itemCostFont then
        print("Error (ShopOverlay:draw): Missing required fonts for shop items.")
        love.graphics.setFont(originalFont); love.graphics.setColor(r_orig,g_orig,b_orig,a_orig)
        return
    end

    -- Display Wallet Amount
    love.graphics.setFont(itemNameFont)
    love.graphics.setColor(costTextColor) 
    love.graphics.printf("Wallet: $" .. tostring(self.gameState.wallet or 0), contentStartX, currentY, contentAvailableWidth, "right")
    currentY = currentY + itemNameFont:getHeight() + paddingMedium

    -- Iterate through shop offers and draw them
    for i, offer in ipairs(self.gameState.currentShopItems) do
        if offer and offer.itemDef and offer.itemType then
            local itemDefinition = offer.itemDef
            local itemType = offer.itemType
            local buyButtonInstance = self.itemButtons[i] -- Get the corresponding button

            -- Item Icon
            local iconX = contentStartX + paddingMedium
            local iconY = currentY + paddingSmall
            local iconDisplaySize = itemRowHeight - (2 * paddingSmall) -- Make icon fit nicely in the row
            local iconAspectRatio = 0.6 -- For card/book like shape
            local iconDrawDisplayWidth = iconDisplaySize * iconAspectRatio

            if itemType == "card" and helpers.drawCardIcon then
                helpers.drawCardIcon(iconX, iconY, itemDefinition, {count=1}, iconDrawDisplayWidth, iconDisplaySize, theme)
            elseif itemType == "spellbook" then
                if helpers.drawPlaceholderIcon then
                    helpers.drawPlaceholderIcon("book", iconX, iconY, iconDrawDisplayWidth, iconDisplaySize, theme)
                else -- Inline fallback drawing for a book
                    local bookColor = theme.colors.iconBook or {0.6, 0.4, 0.2, 1}
                    local pageColor = theme.colors.iconPageLines or {1, 1, 1, 1}
                    love.graphics.setColor(bookColor)
                    love.graphics.rectangle("fill", iconX, iconY, iconDrawDisplayWidth, iconDisplaySize, theme.cornerRadius.default or 3)
                    love.graphics.setColor(pageColor); love.graphics.setLineWidth(1)
                    local lineX1, lineX2 = iconX + 4, iconX + iconDrawDisplayWidth - 4
                    for lineNum = 1, 3 do love.graphics.line(lineX1, iconY + 4 * lineNum, lineX2, iconY + 4 * lineNum) end
                end
            end

            -- Item Name & Description Text Area
            local textBlockX = iconX + iconDrawDisplayWidth + paddingMedium
            local buyButtonWidth = (buyButtonInstance and buyButtonInstance.width) or (sizes.shopBuyButtonWidth or 80)
            -- Calculate width available for name/description, accounting for icon and buy button
            local nameDescAvailableWidth = contentAvailableWidth - (iconDrawDisplayWidth + paddingMedium * 2) - buyButtonWidth - paddingMedium

            love.graphics.setColor(titleTextColor)
            love.graphics.setFont(itemNameFont)
            love.graphics.printf(tostring(itemDefinition.name or "???"), textBlockX, currentY + paddingSmall, nameDescAvailableWidth, "left")

            love.graphics.setFont(itemDetailFont)
            love.graphics.setColor(descriptionColor)
            love.graphics.printf(tostring(itemDefinition.description or ""), textBlockX, currentY + paddingSmall + itemNameFont:getHeight() + 2, nameDescAvailableWidth, "left")

            -- Item Cost Text (Positioned to the left of where the Buy button will be)
            local costString = "Cost: $" .. tostring(itemDefinition.cost or "N/A")
            love.graphics.setFont(itemCostFont)
            love.graphics.setColor(costTextColor)
            local costTextActualWidth = itemCostFont:getWidth(costString)
            local costTextX = contentStartX + contentAvailableWidth - buyButtonWidth - paddingMedium - costTextActualWidth
            local costTextY = currentY + (itemRowHeight / 2) - (itemCostFont:getHeight() / 2)
            love.graphics.print(costString, costTextX, costTextY)

            -- Position and Draw the Buy Button for this item
            if buyButtonInstance then
                buyButtonInstance.x = contentStartX + contentAvailableWidth - buyButtonWidth
                buyButtonInstance.y = currentY + (itemRowHeight - buyButtonInstance.height) / 2
                if offer.isPurchased then
                    buyButtonInstance:setLabel("Purchased")
                    buyButtonInstance:setEnabled(false) -- Ensure it's disabled if purchased
                else
                    buyButtonInstance:setLabel("Buy")
                    -- Enabled state based on affordability is handled in update()
                end
                buyButtonInstance:draw()
            end

            currentY = currentY + itemRowHeight + itemRowSpacing
        else
            -- Draw a placeholder for an invalid or missing offer
            love.graphics.setColor(descriptionColor)
            love.graphics.setFont(itemDetailFont)
            love.graphics.printf("Invalid item offer at index " .. i, contentStartX, currentY + itemRowHeight/2 - itemDetailFont:getHeight()/2, contentAvailableWidth, "center")
            currentY = currentY + itemRowHeight + itemRowSpacing
        end
    end

    -- 5. Position and Draw Continue Button (Bottom Center of panel)
    if self.continueButton then
        self.continueButton.x = self.panelRect.x + (self.panelRect.width - self.continueButton.width) / 2
        self.continueButton.y = self.panelRect.y + self.panelRect.height - self.continueButton.height - paddingMedium
        self.continueButton:draw()
    end

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
end

--- Handles clicks within the shop overlay.
function ShopOverlay:handleClick(x, y)
    -- Check overlay-specific static buttons first
    if self.closeButton and self.closeButton:handleClick(x, y) then return true end
    if self.continueButton and self.continueButton:handleClick(x, y) then return true end

    -- Check dynamic item buy buttons
    for i, buyButtonInstance in ipairs(self.itemButtons) do
        if buyButtonInstance and buyButtonInstance:handleClick(x, y) then
            -- The onClick callback for the buy button (set in onShow) handles calling shopActions.buy(i)
            return true
        end
    end

    -- Consume click if inside panel but not on any specific button
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    if isPointInRectFunc and self.panelRect and isPointInRectFunc(x, y, self.panelRect) then
        -- print("Click consumed by ShopOverlay panel background.") -- Optional debug
        return true
    end
    return false -- Click was not handled by this overlay
end


--- Called when the overlay is hidden.
function ShopOverlay:onHide()
    print("Shop Overlay Hidden")
    -- Optional: Clear itemButtons here if memory is a concern,
    -- though onShow already rebuilds them.
    -- self.itemButtons = {} 
end

return ShopOverlay