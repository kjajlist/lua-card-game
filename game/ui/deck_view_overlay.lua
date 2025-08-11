-- File: ui/deck_view_overlay.lua (Formatted)
-- Defines the Deck View overlay component with injected dependencies.

local Button -- Expected to be passed in config.ButtonClass

local DeckViewOverlay = {}
DeckViewOverlay.__index = DeckViewOverlay

function DeckViewOverlay:new(config)
    -- 1. Validate Configuration and Dependencies
    assert(config and config.name, "DeckViewOverlay:new requires config.name")
    assert(config.uiManager, "DeckViewOverlay:new requires config.uiManager")
    assert(config.gameState, "DeckViewOverlay:new requires config.gameState")
    assert(config.theme and config.theme.fonts and config.theme.colors and 
           config.theme.layout and config.theme.sizes and 
           config.theme.cornerRadius and config.theme.helpers, 
           "DeckViewOverlay:new requires a valid config.theme table")
    assert(config.theme.fonts.large and config.theme.fonts.ui and config.theme.fonts.default, 
           "DeckViewOverlay:new requires large, ui, and default fonts in config.theme.fonts")
    assert(config.theme.helpers.calculateOverlayPanelRect and 
           config.theme.helpers.drawOverlayBase and 
           config.theme.helpers.isPointInRect, 
           "DeckViewOverlay:new requires helper functions in config.theme.helpers")
    assert(config.cardDatabase and config.cardDatabase.getDefinition and config.cardDatabase.drawIcon, 
           "DeckViewOverlay:new requires a valid config.cardDatabase interface")
    assert(config.ButtonClass, "DeckViewOverlay:new requires config.ButtonClass")

    local instance = setmetatable({}, DeckViewOverlay)

    -- 2. Store Dependencies
    instance.name = config.name
    instance.uiManager = config.uiManager
    instance.gameState = config.gameState
    instance.theme = config.theme
    instance.cardDatabase = config.cardDatabase
    Button = config.ButtonClass -- Set module-level local for Button class

    -- 3. Initial UI Setup
    instance.panelRect = instance.theme.helpers.calculateOverlayPanelRect(instance.theme) 
                        or { x = 10, y = 10, width = 300, height = 400 } -- Fallback rect

    -- Cache theme values for button creation
    local paddingSmall = instance.theme.layout.paddingSmall or 5
    local closeButtonSize = instance.theme.sizes.overlayCloseButtonSize or 25
    local closeButtonRadius = instance.theme.cornerRadius.closeButton or 3
    local closeButtonColor = instance.theme.colors.buttonClose or {0.9, 0.5, 0.5, 1}
    
    local toggleButtonWidth = instance.theme.sizes.deckViewToggleButtonWidth or 100
    local toggleButtonHeight = instance.theme.sizes.deckViewToggleButtonHeight or 25
    local defaultButtonRadius = instance.theme.cornerRadius.default or 5

    local buttonDefaultSettings = {
        defaultFont = instance.theme.fonts.default,
        defaultCornerRadius = defaultButtonRadius,
        defaultColors = instance.theme.colors -- Pass the whole theme colors table for button defaults
    }

    -- Create Close Button
    instance.closeButton = Button:new({
        id = "deckViewClose", 
        x = 0, y = 0, -- Positioned in draw()
        width = closeButtonSize, height = closeButtonSize,
        label = "X", 
        font = instance.theme.fonts.ui, 
        cornerRadius = closeButtonRadius, 
        colors = { normal = closeButtonColor },
        onClick = function() instance.uiManager:hide() end,
        defaultFont = buttonDefaultSettings.defaultFont, 
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius, 
        defaultColors = buttonDefaultSettings.defaultColors
    })

    -- Create Toggle Buttons (Remaining / Full Deck)
    instance.remainingButton = Button:new({
        id = "deckViewRemaining", 
        x = 0, y = 0, -- Positioned in draw()
        width = toggleButtonWidth, height = toggleButtonHeight,
        label = "Remaining", 
        font = instance.theme.fonts.ui,
        onClick = function() instance.gameState.deckViewMode = "remaining" end,
        defaultFont = buttonDefaultSettings.defaultFont, 
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius, 
        defaultColors = buttonDefaultSettings.defaultColors
    })

    instance.fullButton = Button:new({
        id = "deckViewFull", 
        x = 0, y = 0, -- Positioned in draw()
        width = toggleButtonWidth, height = toggleButtonHeight,
        label = "Full Deck", 
        font = instance.theme.fonts.ui,
        onClick = function() instance.gameState.deckViewMode = "full" end,
        defaultFont = buttonDefaultSettings.defaultFont, 
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius, 
        defaultColors = buttonDefaultSettings.defaultColors
    })
    
    return instance
end

function DeckViewOverlay:update(dt, mx, my, isMouseDown)
    if not self.closeButton or not self.remainingButton or not self.fullButton then
        print("Warning (DeckViewOverlay:update): Buttons not initialized.")
        return
    end

    -- Update all buttons
    self.closeButton:update(dt, mx, my, isMouseDown)
    self.remainingButton:update(dt, mx, my, isMouseDown)
    self.fullButton:update(dt, mx, my, isMouseDown)

    -- Update toggle button appearance based on current deck view mode
    local activeColor = self.theme.colors.buttonToggleActive or {0.7, 0.9, 0.7, 1}
    local inactiveColor = self.theme.colors.buttonToggleInactive or {0.8, 0.8, 0.8, 1}
    local currentMode = self.gameState.deckViewMode or "remaining"

    self.remainingButton.colors.normal = (currentMode == "remaining") and activeColor or inactiveColor
    self.fullButton.colors.normal = (currentMode == "full") and activeColor or inactiveColor
end

function DeckViewOverlay:draw()
    if self.uiManager:getActiveOverlayName() ~= self.name then return end

    if not self.theme or not self.gameState or not self.cardDatabase or not self.closeButton then
        print("ERROR: DeckViewOverlay:draw - Missing critical dependencies.")
        return
    end
    if not love or not love.graphics then
        print("Error: LÖVE graphics module not available in DeckViewOverlay:draw.")
        return
    end

    local theme = self.theme
    local colors = theme.colors
    local layout = theme.layout
    local fonts = theme.fonts
    local sizes = theme.sizes
    local helpers = theme.helpers

    local paddingSmall = layout.paddingSmall or 5
    local paddingMedium = layout.paddingMedium or 10
    local paddingLarge = layout.paddingLarge or 20

    -- 1. Draw Panel Base
    self.panelRect = helpers.calculateOverlayPanelRect(theme)
    helpers.drawOverlayBase(self.panelRect, theme)

    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Title
    local titleTextColor = colors.textDark or {0.1, 0.1, 0.1, 1}
    local titleTextFont = fonts.large or fonts.default
    local titleTextY = self.panelRect.y + paddingMedium
    if titleTextFont then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(titleTextFont)
        love.graphics.printf("Deck View", self.panelRect.x, titleTextY, self.panelRect.width, "center")
    end
    local titleActualHeight = titleTextFont and titleTextFont:getHeight() or 20

    -- 3. Position and Draw Close Button
    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - paddingSmall
    self.closeButton.y = self.panelRect.y + paddingSmall
    self.closeButton:draw()

    -- 4. Position and Draw Toggle Buttons
    local toggleYPos = self.panelRect.y + paddingMedium + titleActualHeight + paddingMedium
    local toggleButtonGap = paddingMedium / 2
    local combinedToggleWidth = self.remainingButton.width + self.fullButton.width + toggleButtonGap
    local remainingBtnX = self.panelRect.x + (self.panelRect.width - combinedToggleWidth) / 2
    local fullBtnX = remainingBtnX + self.remainingButton.width + toggleButtonGap
    
    self.remainingButton.x, self.remainingButton.y = remainingBtnX, toggleYPos
    self.fullButton.x, self.fullButton.y = fullBtnX, toggleYPos
    self.remainingButton:draw()
    self.fullButton:draw()

    -- 5. Get Card Data for Display
    -- print("[DeckViewOverlay:draw] Aggregating card counts...") -- DEBUG
    local cardCounts, totalCount = self:_getCardCounts()
    -- print(string.format("[DeckViewOverlay:draw] Total cards to display: %d", totalCount)) -- DEBUG

    local sortedCardIds = {}
    for id, count in pairs(cardCounts) do
        if type(count) == "number" and count > 0 then
            table.insert(sortedCardIds, id)
        end
    end
    table.sort(sortedCardIds) -- Sort by ID for consistent display
    -- print(string.format("[DeckViewOverlay:draw] Number of unique card IDs to display: %d", #sortedCardIds)) -- DEBUG

    -- 6. Setup Grid parameters
    local gridStartY = toggleYPos + self.remainingButton.height + paddingMedium
    local currentY = gridStartY
    local gridX = self.panelRect.x + paddingLarge
    local gridW = self.panelRect.width - (2 * paddingLarge)
    
    local numColumns = sizes.deckViewColumns or 4
    if numColumns <= 0 then numColumns = 1 end
    local columnActualWidth = gridW / numColumns
    
    local iconDrawHeight = sizes.deckViewMediumIconHeight or 36
    local iconDrawWidth = sizes.deckViewMediumIconWidth or 24
    local itemVisualPadding = layout.deckViewItemPadding or paddingSmall
    local gridItemHeightWithPadding = iconDrawHeight + itemVisualPadding
    
    local currentColumn = 0
    local gridDisplayFont = fonts.ui or fonts.default
    if not gridDisplayFont then
        print("Error: DeckViewOverlay grid font (fonts.ui or fonts.default) is missing.")
        love.graphics.setFont(originalFont); love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
        return
    end

    -- Display "Total Cards" count
    love.graphics.setFont(gridDisplayFont)
    love.graphics.setColor(titleTextColor)
    love.graphics.print("Total Cards: " .. tostring(totalCount), gridX, currentY)
    currentY = currentY + gridDisplayFont:getHeight() + paddingSmall

    -- Handle empty states
    if #sortedCardIds == 0 then
        if totalCount > 0 then
            print("[DeckViewOverlay:draw] No sortedCardIds but totalCount > 0. Issue in aggregation/sorting?") -- DEBUG
        else
            -- print("[DeckViewOverlay:draw] No cards to display in this view.") -- DEBUG
        end
        love.graphics.printf("No cards in this view.", gridX, currentY + 20, gridW, "center")
    end

    -- 7. Draw the Grid of Cards
    for _, id in ipairs(sortedCardIds) do
        local cardDef = self.cardDatabase:getDefinition(id)
        local countOfThisCard = cardCounts[id] or 0
        
        -- print(string.format("[DeckViewOverlay:draw] Processing card ID: %s, Count: %d, Name: %s", tostring(id), countOfThisCard, (cardDef and cardDef.name or "???"))) -- DEBUG
        
        if cardDef and countOfThisCard > 0 then
            local itemX = gridX + currentColumn * columnActualWidth
            local itemY = currentY
            
            -- print(string.format("  Drawing icon for '%s' at (%.1f, %.1f) size (%.1f, %.1f)", cardDef.name or "???", itemX, itemY, iconDrawWidth, iconDrawHeight)) -- DEBUG
            self.cardDatabase:drawIcon(itemX, itemY, cardDef, {count = countOfThisCard}, iconDrawWidth, iconDrawHeight, theme)

            love.graphics.setColor(titleTextColor) -- Ensure color is set for text
            love.graphics.setFont(gridDisplayFont)
            
            local textStartXPos = itemX + iconDrawWidth + itemVisualPadding
            -- Calculate available width for text next to icon carefully
            local textAvailableRenderWidth = columnActualWidth - (iconDrawWidth + itemVisualPadding * 2) 
            if textAvailableRenderWidth < 0 then textAvailableRenderWidth = 0 end

            local textRenderY = itemY + math.floor((iconDrawHeight - gridDisplayFont:getHeight()) / 2) -- Vertically center text with icon
            
            -- print(string.format("  Drawing text '%s (x%d)' at (%.1f, %.1f) width %.1f", tostring(cardDef.name or "???"), countOfThisCard, textStartXPos, textRenderY, textAvailableRenderWidth)) -- DEBUG
            love.graphics.printf(
                string.format("%s (x%d)", tostring(cardDef.name or "???"), countOfThisCard), 
                textStartXPos, 
                textRenderY, 
                textAvailableRenderWidth, 
                "left"
            )

            currentColumn = currentColumn + 1
            if currentColumn >= numColumns then
                currentColumn = 0
                currentY = currentY + gridItemHeightWithPadding
            end

            -- Basic clipping: Stop drawing if next row would be out of panel bounds
            if currentY + gridItemHeightWithPadding > self.panelRect.y + self.panelRect.height - paddingLarge then
                print("[DeckViewOverlay:draw] Content out of bounds, breaking card draw loop.") -- DEBUG
                if currentColumn == 0 then -- Only draw ellipsis if we are at the start of a new line that would be out of bounds
                     love.graphics.printf("...", gridX, currentY + gridItemHeightWithPadding / 2, columnActualWidth, "left")
                end
                break 
            end
        end
    end

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
end

function DeckViewOverlay:_getCardCounts()
    local cardCounts = {}
    local totalCount = 0
    local sourcesToCount = {}
    local currentMode = self.gameState.deckViewMode or "remaining"
    local gs = self.gameState
    local inspectFunc = self.theme.helpers.inspect -- Cache for potential use

    -- print(string.format("[DeckViewOverlay:_getCardCounts] Mode: %s", currentMode)) -- DEBUG

    if currentMode == "remaining" then
        if type(gs.deck) == "table" then
            -- print(string.format("  Counting 'remaining' from gs.deck (size: %d)", #(gs.deck))) -- DEBUG
            sourcesToCount = { gs.deck }
        else
            print("  gs.deck is not a table for 'remaining' mode.") -- DEBUG
        end
    else -- "full" mode
        -- print("  Counting 'full' deck sources:") -- DEBUG
        sourcesToCount = {}
        if type(gs.deck) == "table" then 
            -- print(string.format("    Adding gs.deck (size: %d)", #(gs.deck))) -- DEBUG
            table.insert(sourcesToCount, gs.deck) 
        else 
            -- print("    gs.deck is not a table.") -- DEBUG
        end
        if type(gs.discardPile) == "table" then 
            -- print(string.format("    Adding gs.discardPile (size: %d)", #(gs.discardPile))) -- DEBUG
            table.insert(sourcesToCount, gs.discardPile) 
        else 
            -- print("    gs.discardPile is not a table.") -- DEBUG
        end
        if type(gs.hand) == "table" then 
            -- print(string.format("    Adding gs.hand (size: %d)", #(gs.hand))) -- DEBUG
            table.insert(sourcesToCount, gs.hand) 
        else 
            -- print("    gs.hand is not a table.") -- DEBUG
        end
    end

    for i_source, sourceTable in ipairs(sourcesToCount) do
        -- print(string.format("  Processing source #%d (size: %d)", i_source, #sourceTable)) -- DEBUG
        for i_card, cardInstance in ipairs(sourceTable) do
            if cardInstance and type(cardInstance) == "table" and cardInstance.id then
                cardCounts[cardInstance.id] = (cardCounts[cardInstance.id] or 0) + 1
                totalCount = totalCount + 1
            else
                -- print(string.format("    Warning: Invalid item at index %d in source #%d.", i_card, i_source)) -- DEBUG (can be noisy)
            end
        end
    end

    -- if inspectFunc then -- DEBUG
    --    print(string.format("[DeckViewOverlay:_getCardCounts] Final cardCounts: %s, totalCount: %d", inspectFunc(cardCounts), totalCount))
    -- else -- DEBUG
    --    print(string.format("[DeckViewOverlay:_getCardCounts] Final totalCount: %d (inspect unavailable for cardCounts)", totalCount))
    -- end
    return cardCounts, totalCount
end

function DeckViewOverlay:handleClick(x, y)
    if self.closeButton and self.closeButton:handleClick(x, y) then return true end
    if self.remainingButton and self.remainingButton:handleClick(x, y) then return true end
    if self.fullButton and self.fullButton:handleClick(x, y) then return true end
    
    -- Consume click if inside panel but not on specific buttons (prevents click-through)
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    if isPointInRectFunc and self.panelRect and isPointInRectFunc(x, y, self.panelRect) then
        return true 
    end
    return false
end

function DeckViewOverlay:onShow()
    local currentMode = self.gameState.deckViewMode or "remaining"
    print("Deck View Overlay Shown. Mode:", currentMode)
    -- Potentially reset scroll or other states here if implementing scrolling
end

function DeckViewOverlay:onHide()
    print("Deck View Overlay Hidden")
end

return DeckViewOverlay