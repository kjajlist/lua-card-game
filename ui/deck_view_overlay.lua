-- File: ui/deck_view_overlay.lua (Formatted)
-- Defines the Deck View overlay component with injected dependencies.

local Button = require("ui.button")

local DeckViewOverlay = {}
DeckViewOverlay.__index = DeckViewOverlay

function DeckViewOverlay:new(config)
    print("=== DECK VIEW OVERLAY NEW FUNCTION CALLED ===")
    print("[DeckViewOverlay:new] Starting overlay creation...")
    print("[DeckViewOverlay:new] config.theme type: ", type(config.theme))
    print("[DeckViewOverlay:new] config.gameState type: ", type(config.gameState))
    print("[DeckViewOverlay:new] config.uiManager type: ", type(config.uiManager))
    print("[DeckViewOverlay:new] config.cardDatabase type: ", type(config.cardDatabase))
    
    local instance = setmetatable({}, DeckViewOverlay)
    
    instance.name = "deckView"
    instance.theme = config.theme
    instance.gameState = config.gameState
    instance.uiManager = config.uiManager
    instance.cardDatabase = config.cardDatabase
    instance.config = config -- Store the full config for scrolling settings
    
    print("[DeckViewOverlay:new] Instance created with name: ", instance.name)
    
    -- Initialize sort mode for deck view (same as main game)
    instance.gameState.deckViewSortMode = instance.gameState.deckViewSortMode or "default"
    
    -- Initialize scroll state
    instance.scrollY = 0
    instance.maxScrollY = 0
    
    print("[DeckViewOverlay:new] About to create buttons...")
    print("[DeckViewOverlay:new] instance.theme type: ", type(instance.theme))
    print("[DeckViewOverlay:new] instance.theme.buttonDefaults type: ", type(instance.theme.buttonDefaults))
    print("[DeckViewOverlay:new] instance.theme.fonts type: ", type(instance.theme.fonts))
    print("[DeckViewOverlay:new] instance.theme.fonts.ui type: ", type(instance.theme.fonts and instance.theme.fonts.ui))
    
    -- Create close button
    local buttonDefaultSettings = instance.theme.buttonDefaults or {}
    local closeButtonSize = 25
    
    print("[DeckViewOverlay:new] buttonDefaultSettings.defaultFont: ", buttonDefaultSettings.defaultFont)
    print("[DeckViewOverlay:new] instance.theme.fonts.ui: ", instance.theme.fonts and instance.theme.fonts.ui)
    
    -- Ensure we have a valid font - use fallback if needed
    local buttonFont = buttonDefaultSettings.defaultFont or (instance.theme.fonts and instance.theme.fonts.ui)
    if not buttonFont then
        print("[DeckViewOverlay:new] ERROR: No valid font found for buttons!")
        print("[DeckViewOverlay:new] Using fallback font...")
        buttonFont = love.graphics.newFont(12) -- Fallback font
    end
    
    print("[DeckViewOverlay:new] Creating close button with font: ", buttonFont)
    
    instance.closeButton = Button:new({
        id = "deckViewClose", 
        x = 0, y = 0, -- Positioned in draw()
        width = closeButtonSize, height = closeButtonSize,
        label = "X", 
        font = buttonFont,
        onClick = function() instance.uiManager:hide() end,
        defaultFont = buttonFont, 
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius or 5, 
        defaultColors = buttonDefaultSettings.defaultColors or {normal = {0.8, 0.8, 0.8, 1}}
    })
    
    print("[DeckViewOverlay:new] Close button created successfully")
    print("[DeckViewOverlay:new] All buttons created successfully!")
    
    return instance
end

-- Helper function to get color sort key (similar to sort.lua)
local function getColorSortKeyHueApprox(cardDef)
    if not cardDef or not cardDef.objectColor or type(cardDef.objectColor) ~= "table" or #cardDef.objectColor < 3 then
        return 999 -- Push colors that can't be determined to the end
    end

    local r, g, b = cardDef.objectColor[1], cardDef.objectColor[2], cardDef.objectColor[3]
    if type(r) ~= 'number' or type(g) ~= 'number' or type(b) ~= 'number' then
        return 998 -- Invalid color components
    end

    local maxC = math.max(r, g, b)
    local minC = math.min(r, g, b)
    local delta = maxC - minC
    local hue = 0

    if delta < 0.01 then -- Grayscale (or very close to it)
        if maxC > 0.9 then return 361 -- White/Light gray (after colors)
        elseif maxC < 0.1 then return -2 -- Black/Dark gray (before colors)
        else return -1 end -- Mid-gray (before colors, after black)
    elseif maxC == r then hue = 60 * (((g - b) / delta) % 6)
    elseif maxC == g then hue = 60 * (((b - r) / delta) + 2)
    elseif maxC == b then hue = 60 * (((r - g) / delta) + 4) end
    
    if hue ~= hue then return 997 end -- NaN check, push to end
    if hue < 0 then hue = hue + 360 end -- Normalize hue to 0-360 range
    
    return hue
end

-- Helper function to sort cards based on sort mode
function DeckViewOverlay:_sortCardIds(cardIds, cardCounts, cardDatabase)
    local currentSortMode = self.gameState.deckViewSortMode or "default"
    
    -- Create a table of card data for sorting
    local cardData = {}
    for _, id in ipairs(cardIds) do
        local cardDef = cardDatabase.getDefinition(cardDatabase, id)
        if cardDef then
            table.insert(cardData, {
                id = id,
                count = cardCounts[id] or 0,
                cardDef = cardDef
            })
        end
    end
    
    -- Sort based on current sort mode
    if currentSortMode == "value" then
        table.sort(cardData, function(a, b)
            if not a.cardDef or type(a.cardDef.value) ~= "number" then return false end
            if not b.cardDef or type(b.cardDef.value) ~= "number" then return true end
            if a.cardDef.value ~= b.cardDef.value then return a.cardDef.value > b.cardDef.value end -- Primary: Value descending
            return a.id < b.id -- Secondary: ID ascending
        end)
    elseif currentSortMode == "color" then
        table.sort(cardData, function(a, b)
            if not a.cardDef or type(a.cardDef.value) ~= "number" then return false end
            if not b.cardDef or type(b.cardDef.value) ~= "number" then return true end
            local hueA = getColorSortKeyHueApprox(a.cardDef)
            local hueB = getColorSortKeyHueApprox(b.cardDef)
            if hueA ~= hueB then return hueA < hueB end         -- Primary: Hue ascending
            if a.cardDef.value ~= b.cardDef.value then return a.cardDef.value > b.cardDef.value end -- Secondary: Value descending
            return a.id < b.id -- Tertiary: ID ascending
        end)
    elseif currentSortMode == "family" then
        table.sort(cardData, function(a, b)
            if not a.cardDef or not a.cardDef.family or type(a.cardDef.value) ~= "number" then return false end
            if not b.cardDef or not b.cardDef.family or type(b.cardDef.value) ~= "number" then return true end
            local familyA = a.cardDef.family or ""
            local familyB = b.cardDef.family or ""
            if familyA ~= familyB then return familyA < familyB end -- Primary: Family ascending
            if a.cardDef.value ~= b.cardDef.value then return a.cardDef.value > b.cardDef.value end   -- Secondary: Value descending
            return a.id < b.id -- Tertiary: ID ascending
        end)
    elseif currentSortMode == "subtype" then
        table.sort(cardData, function(a, b)
            if not a.cardDef or not a.cardDef.family or type(a.cardDef.value) ~= "number" then return false end
            if not b.cardDef or not b.cardDef.family or type(b.cardDef.value) ~= "number" then return true end
            
            local subTypeA, subTypeB = a.cardDef.subType, b.cardDef.subType
            -- Handle nil subtypes consistently
            if subTypeA == nil and subTypeB ~= nil then return false end -- Sort nils after non-nils
            if subTypeA ~= nil and subTypeB == nil then return true end
            if subTypeA ~= nil and subTypeB ~= nil and subTypeA ~= subTypeB then 
                return tostring(subTypeA) < tostring(subTypeB) -- Primary: SubType ascending
            end

            local familyA = a.cardDef.family or ""
            local familyB = b.cardDef.family or ""
            if familyA ~= familyB then return familyA < familyB end -- Secondary: Family ascending
            if a.cardDef.value ~= b.cardDef.value then return a.cardDef.value > b.cardDef.value end   -- Tertiary: Value descending
            return a.id < b.id -- Quaternary: ID ascending
        end)
    else
        -- Default sort by ID
        table.sort(cardData, function(a, b)
            return a.id < b.id
        end)
    end
    
    -- Extract sorted IDs
    local sortedIds = {}
    for _, data in ipairs(cardData) do
        table.insert(sortedIds, data.id)
    end
    
    return sortedIds
end

-- Function to toggle sort mode (like main game)
function DeckViewOverlay:toggleSortMode()
    print("=== DECK VIEW SORT TOGGLE CALLED ===")
    local sortModes = {"default", "value", "color", "family", "subtype"}
    local currentIndex = 1
    
    -- Find current sort mode index
    for i, mode in ipairs(sortModes) do
        if mode == self.gameState.deckViewSortMode then
            currentIndex = i
            break
        end
    end
    
    -- Move to next sort mode
    currentIndex = currentIndex + 1
    if currentIndex > #sortModes then
        currentIndex = 1
    end
    
    self.gameState.deckViewSortMode = sortModes[currentIndex]
    print("Deck view sort mode changed to:", self.gameState.deckViewSortMode)
end

function DeckViewOverlay:update(dt, mx, my, isMouseDown)
    if not self.closeButton then
        print("Warning (DeckViewOverlay:update): Buttons not initialized.")
        return
    end

    -- Update close button
    self.closeButton:update(dt, mx, my, isMouseDown)
    
    -- Update touch-like scroll logic
    self:_updateTouchScroll(dt, mx, my, isMouseDown)
    
    -- Apply momentum scrolling when not dragging
    if not self.isDragging and math.abs(self.scrollVelocity) > 0.1 then
        self.scrollY = self.scrollY + self.scrollVelocity * dt
        
        -- Calculate maxScrollY dynamically
        local maxScrollY = self:_calculateMaxScrollY()
        
        -- Apply bounds and bounce
        if self.scrollY < 0 then
            self.scrollY = 0
            self.scrollVelocity = 0
        elseif self.scrollY > maxScrollY then
            self.scrollY = maxScrollY
            self.scrollVelocity = 0
        end
        
        -- Apply deceleration
        self.scrollVelocity = self.scrollVelocity * 0.85 -- Deceleration factor
    end
end

function DeckViewOverlay:draw()
    print("=== DECK VIEW DRAW FUNCTION CALLED ===")
    print("[DeckViewOverlay:draw] Starting deck view draw...")
    
    if self.uiManager:getActiveOverlayName() ~= self.name then 
        print("[DeckViewOverlay:draw] Not the active overlay, returning")
        return 
    end

    if not self.theme or not self.gameState or not self.cardDatabase or not self.closeButton then
        print("ERROR: DeckViewOverlay:draw - Missing critical dependencies.")
        return
    end
    if not love or not love.graphics then
        print("Error: LÖVE graphics module not available in DeckViewOverlay:draw.")
        return
    end

    -- Create fonts
    local cardNameFont = love.graphics.newFont(11) -- Slightly smaller font for card names
    local availabilityFont = love.graphics.newFont(9) -- Smaller font for availability text
    local sortInfoFont = love.graphics.newFont(14) -- Font for sort info

    local theme = self.theme
    local colors = theme.colors
    local layout = theme.layout
    local fonts = theme.fonts
    local helpers = theme.helpers

    local paddingSmall = layout.paddingSmall or 8
    local paddingMedium = layout.paddingMedium or 15
    local paddingLarge = layout.paddingLarge or 25

    -- 1. Draw Panel Base
    self.panelRect = helpers.calculateOverlayPanelRect(theme)
    helpers.drawOverlayBase(self.panelRect, theme)

    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Header Section (fixed position, not affected by scroll)
    local headerY = self.panelRect.y + paddingMedium
    local titleTextColor = colors.textDark or {0.1, 0.1, 0.1, 1}
    local titleTextFont = fonts.large or fonts.default
    
    -- Draw title
    if titleTextFont then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(titleTextFont)
        love.graphics.printf("Deck View", self.panelRect.x, headerY, self.panelRect.width, "center")
    end
    
    -- Draw sort mode indicator below title
    local currentSortMode = self.gameState.deckViewSortMode or "default"
    local sortTextY = headerY + (titleTextFont and titleTextFont:getHeight() or 20) + 8
    if sortInfoFont then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(sortInfoFont)
        love.graphics.printf("Sort: " .. currentSortMode .. " (Press 'S' to change) | Scroll: Mouse Wheel", self.panelRect.x, sortTextY, self.panelRect.width, "center")
    end

    -- 3. Position and Draw Close Button (top right, fixed position)
    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - paddingSmall
    self.closeButton.y = self.panelRect.y + paddingSmall
    self.closeButton:draw()

    -- 4. Get Card Data for Display
    local cardData = self:_getAllCardData()
    local sortedCardIds = self:_sortCardIds(cardData.cardIds, cardData.counts, self.cardDatabase)
    
    print("DeckViewOverlay: Card data - total cards:", #sortedCardIds)

    -- 5. Setup Grid parameters with scroll
    local gridStartY = sortTextY + (sortInfoFont and sortInfoFont:getHeight() or 16) + paddingLarge
    local gridX = self.panelRect.x + paddingLarge
    local gridW = self.panelRect.width - (paddingLarge * 2)
    local gridH = self.panelRect.height - gridStartY - paddingLarge

    local numColumns = 4 -- 4 columns for better readability
    local iconDrawHeight = 28 -- Slightly smaller card height
    local iconDrawWidth = 22 -- Slightly smaller card width
    local itemVisualPadding = 25 -- More padding around cards to prevent overlap
    local columnActualWidth = gridW / numColumns

    -- Calculate grid item height with better spacing
    local cardNameHeight = cardNameFont and cardNameFont:getHeight() or 12
    local availabilityHeight = availabilityFont and availabilityFont:getHeight() or 10
    local gridItemHeightWithPadding = iconDrawHeight + itemVisualPadding + cardNameHeight + availabilityHeight + 12

    -- 6. Calculate total content height and update scroll limits
    local totalRows = math.ceil(#sortedCardIds / numColumns)
    local totalContentHeight = totalRows * gridItemHeightWithPadding
    self.maxScrollY = math.max(0, totalContentHeight - gridH)
    
    -- Clamp scroll position
    self.scrollY = math.max(0, math.min(self.scrollY, self.maxScrollY))

    -- 7. Set up scissor for scrollable area
    love.graphics.setScissor(gridX, gridStartY, gridW, gridH)

    -- 8. Draw Cards in Grid with scroll offset
    local currentColumn = 0
    local currentY = gridStartY - self.scrollY

    for i, cardId in ipairs(sortedCardIds) do
        local cardInfo = cardData.counts[cardId]
        if cardInfo then
            -- Calculate position
            local itemX = gridX + (currentColumn * columnActualWidth) + (columnActualWidth - iconDrawWidth) / 2
            local itemY = currentY

            -- Only draw if card is visible in the scissor area
            if itemY + gridItemHeightWithPadding > gridStartY and itemY < gridStartY + gridH then
                -- Get card definition
                local cardDef = self.cardDatabase.getDefinition(self.cardDatabase, cardId)
                
                if cardDef then
                    -- Determine if card is available (in deck) or unavailable (played/discarded)
                    local isAvailable = cardInfo.inDeck > 0
                    local totalCount = cardInfo.inDeck + cardInfo.inHand + cardInfo.inDiscard
                    
                    -- Create a card instance for drawing
                    local cardInstance = {
                        x = itemX,
                        y = itemY,
                        width = iconDrawWidth,
                        height = iconDrawHeight,
                        name = cardDef.name,
                        value = cardDef.value,
                        family = cardDef.family,
                        objectColor = cardDef.objectColor,
                        isHighlighted = false
                    }
                    
                    -- Apply grey effect if card is unavailable
                    if not isAvailable then
                        love.graphics.setColor(0.6, 0.6, 0.6, 1) -- Grey overlay
                    end
                    
                    -- Draw the card object
                    local Draw = require("draw")
                    Draw.drawCardObject(cardInstance, self.uiManager.sharedDependencies.config, self.uiManager.sharedDependencies, self.gameState)
                    
                    -- Reset color if we applied grey effect
                    if not isAvailable then
                        love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
                    end
                    
                    -- Draw card name below card with better spacing
                    local nameY = itemY + iconDrawHeight + 6
                    if cardNameFont then
                        love.graphics.setFont(cardNameFont)
                        love.graphics.setColor(titleTextColor)
                        local nameText = cardDef.name or "???"
                        -- Truncate long names to prevent overlap
                        if cardNameFont:getWidth(nameText) > iconDrawWidth + 10 then
                            nameText = nameText:sub(1, 8) .. "..."
                        end
                        local nameWidth = cardNameFont:getWidth(nameText)
                        local nameX = itemX + (iconDrawWidth - nameWidth) / 2
                        love.graphics.print(nameText, nameX, nameY)
                    end
                    
                    -- Draw availability text below name with better spacing
                    local availabilityY = nameY + cardNameHeight + 4
                    if availabilityFont then
                        love.graphics.setFont(availabilityFont)
                        if isAvailable then
                            love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green for available
                        else
                            love.graphics.setColor(0.8, 0.2, 0.2, 1) -- Red for unavailable
                        end
                        
                        local availabilityText = string.format("%d/%d", cardInfo.inDeck, totalCount)
                        local availWidth = availabilityFont:getWidth(availabilityText)
                        local availX = itemX + (iconDrawWidth - availWidth) / 2
                        love.graphics.print(availabilityText, availX, availabilityY)
                    end
                end
            end

            -- Move to next column
            currentColumn = currentColumn + 1
            
            if currentColumn >= numColumns then
                currentColumn = 0
                currentY = currentY + gridItemHeightWithPadding
            end
        end
    end

    -- 9. Reset scissor
    love.graphics.setScissor()

    -- 10. Draw scroll indicator if needed
    if self.maxScrollY > 0 then
        -- Get scroll configuration - access from theme or config
        local scrollConfig = self.theme and self.theme.scrollConfig or 
                            (self.config and self.config.UI and self.config.UI.Scrolling) or
                            { scrollBarWidth = 12, scrollBarMinHeight = 30, scrollBarCornerRadius = 6 }
        local colors = self.theme and self.theme.colors or {}
        
        -- Use configured values or defaults
        local scrollBarWidth = scrollConfig.scrollBarWidth or 12
        local minHeight = scrollConfig.scrollBarMinHeight or 30
        local cornerRadius = scrollConfig.scrollBarCornerRadius or 6
        
        local scrollBarHeight = math.max(minHeight, (gridH / totalContentHeight) * gridH)
        local scrollBarX = self.panelRect.x + self.panelRect.width - paddingSmall - scrollBarWidth
        local scrollBarY = gridStartY + (self.scrollY / self.maxScrollY) * (gridH - scrollBarHeight)
        
        -- Draw scroll bar background (more visible)
        local bgColor = colors.scrollBarBackground or {0.8, 0.8, 0.8, 0.9}
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", scrollBarX, gridStartY, scrollBarWidth, gridH, cornerRadius, cornerRadius)
        
        -- Draw scroll bar thumb
        local thumbColor = colors.scrollBarThumb or {0.6, 0.6, 0.6, 1.0}
        love.graphics.setColor(thumbColor)
        love.graphics.rectangle("fill", scrollBarX, scrollBarY, scrollBarWidth, scrollBarHeight, cornerRadius, cornerRadius)
        
        -- Draw scroll bar border
        local borderColor = colors.scrollBarBorder or {0.4, 0.4, 0.4, 1.0}
        love.graphics.setColor(borderColor)
        love.graphics.rectangle("line", scrollBarX, scrollBarY, scrollBarWidth, scrollBarHeight, cornerRadius, cornerRadius)
    end

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
end

function DeckViewOverlay:_getAllCardData()
    local cardCounts = {}
    local cardIds = {}
    
    -- Count cards in all sources (deck, hand, discard)
    local allSources = {
        {source = self.gameState.deck, key = "inDeck"},
        {source = self.gameState.hand, key = "inHand"},
        {source = self.gameState.discardPile, key = "inDiscard"}
    }
    
    for _, sourceInfo in ipairs(allSources) do
        local source = sourceInfo.source
        local key = sourceInfo.key
        
        if source then
            for _, cardInstance in ipairs(source) do
                if cardInstance and cardInstance.id then
                    local id = tonumber(cardInstance.id)
                    if id then
                        if not cardCounts[id] then
                            cardCounts[id] = {inDeck = 0, inHand = 0, inDiscard = 0}
                            table.insert(cardIds, id)
                        end
                        cardCounts[id][key] = cardCounts[id][key] + 1
                    end
                end
            end
        end
    end
    
    return {counts = cardCounts, cardIds = cardIds}
end

function DeckViewOverlay:handleClick(x, y)
    if self.closeButton and self.closeButton:handleClick(x, y) then return true end
    
    -- Consume click if inside panel but not on specific buttons (prevents click-through)
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    if isPointInRectFunc and self.panelRect and isPointInRectFunc(x, y, self.panelRect) then
        return true 
    end
    return false
end

function DeckViewOverlay:handleWheel(x, y, dx, dy)
    print("DeckViewOverlay:handleWheel called with dy:", dy)
    
    -- Check if scrolling is enabled - access from theme or config
    local scrollConfig = self.theme and self.theme.scrollConfig or 
                        (self.config and self.config.UI and self.config.UI.Scrolling) or
                        { enabled = true, mouseWheelEnabled = true, scrollSpeed = 30 }
    
    if not scrollConfig.enabled or not scrollConfig.mouseWheelEnabled then
        print("DeckViewOverlay: Scrolling disabled or not configured")
        return false
    end
    
    -- Calculate maxScrollY dynamically (like potion list overlay)
    local maxScrollY = self:_calculateMaxScrollY()
    print("DeckViewOverlay: Calculated maxScrollY:", maxScrollY)
    
    -- Handle mouse wheel scrolling
    if maxScrollY > 0 then
        local scrollSpeed = scrollConfig.scrollSpeed or 30 -- Pixels per wheel tick
        local oldScrollY = self.scrollY
        self.scrollY = self.scrollY - (dy * scrollSpeed)
        self.scrollY = math.max(0, math.min(self.scrollY, maxScrollY))
        print("DeckViewOverlay: Scrolled from", oldScrollY, "to", self.scrollY, "maxScrollY:", maxScrollY)
        return true -- Consume the wheel event
    else
        print("DeckViewOverlay: maxScrollY is 0, no scrolling needed")
    end
    return false
end

-- Add touch event handlers for better touch screen support
function DeckViewOverlay:handleTouchPressed(id, x, y, pressure)
    if not self.panelRect then return false end
    
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    
    -- Check if touch is in the panel
    if not isPointInRectFunc or not isPointInRectFunc(x, y, self.panelRect) then
        return false
    end
    
    -- Handle close button touch
    if self.closeButton and self.closeButton:handleClick(x, y) then
        return true
    end
    
    -- Handle content area touch for scrolling
    local contentArea = self:_getContentArea()
    if isPointInRectFunc(x, y, contentArea) then
        -- Start touch scrolling
        self.isDragging = true
        self.dragStartY = y
        self.dragStartScrollY = self.scrollY
        self.scrollVelocity = 0
        return true
    end
    
    return false
end

function DeckViewOverlay:handleTouchReleased(id, x, y, pressure)
    if not self.panelRect then return false end
    
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    
    -- Check if touch was in the panel
    if not isPointInRectFunc or not isPointInRectFunc(x, y, self.panelRect) then
        return false
    end
    
    -- Stop touch dragging
    if self.isDragging then
        self.isDragging = false
        return true
    end
    
    return false
end

function DeckViewOverlay:handleTouchMoved(id, x, y, dx, dy, pressure)
    if not self.panelRect then return false end
    
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    
    -- Check if touch is in the panel
    if not isPointInRectFunc or not isPointInRectFunc(x, y, self.panelRect) then
        return false
    end
    
    -- Handle content area touch scrolling
    local contentArea = self:_getContentArea()
    if isPointInRectFunc(x, y, contentArea) and self.isDragging then
        local deltaY = self.dragStartY - y -- Inverted for natural feel
        local newScrollY = self.dragStartScrollY + deltaY
        
        -- Calculate maxScrollY dynamically
        local maxScrollY = self:_calculateMaxScrollY()
        
        -- Apply bounds
        self.scrollY = math.max(0, math.min(maxScrollY, newScrollY))
        
        -- Calculate velocity for momentum
        local dt = love.timer.getDelta()
        if dt > 0 then
            local velocityDelta = dy / dt
            self.scrollVelocity = velocityDelta * 0.92 -- Friction factor
        end
        
        return true
    end
    
    return false
end

-- Add touch scrolling state variables
function DeckViewOverlay:onShow()
    print("Deck View Overlay Shown")
    -- Debug configuration access
    print("DeckViewOverlay: theme.scrollConfig exists:", self.theme and self.theme.scrollConfig ~= nil)
    print("DeckViewOverlay: config.UI.Scrolling exists:", self.config and self.config.UI and self.config.UI.Scrolling ~= nil)
    if self.theme and self.theme.scrollConfig then
        print("DeckViewOverlay: scrollConfig.enabled:", self.theme.scrollConfig.enabled)
        print("DeckViewOverlay: scrollConfig.touchEnabled:", self.theme.scrollConfig.touchEnabled)
        print("DeckViewOverlay: scrollConfig.mouseWheelEnabled:", self.theme.scrollConfig.mouseWheelEnabled)
    end
    -- Reset scroll position when overlay is shown
    self.scrollY = 0
    self.maxScrollY = 0
    
    -- Initialize touch scrolling state
    self.isDragging = false
    self.dragStartY = 0
    self.dragStartScrollY = 0
    self.scrollVelocity = 0
end

--- Updates touch-like scroll state and handles scroll interactions
function DeckViewOverlay:_updateTouchScroll(dt, mx, my, isMouseButtonDown)
    if not self.panelRect then 
        print("DeckViewOverlay:_updateTouchScroll: No panelRect")
        return 
    end
    
    -- Check if scrolling is enabled - access from theme or config
    local scrollConfig = self.theme and self.theme.scrollConfig or 
                        (self.config and self.config.UI and self.config.UI.Scrolling) or
                        { enabled = true, touchEnabled = true, momentumEnabled = true }
    
    if not scrollConfig.enabled then 
        print("DeckViewOverlay:_updateTouchScroll: Scrolling disabled")
        return 
    end
    
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    
    -- Check if mouse is in the content area
    local contentArea = self:_getContentArea()
    local mouseInContent = isPointInRectFunc and isPointInRectFunc(mx, my, contentArea)
    
    -- Handle touch-like dragging
    if mouseInContent and isMouseButtonDown and scrollConfig and scrollConfig.touchEnabled then
        if not self.isDragging then
            -- Start dragging
            self.isDragging = true
            self.dragStartY = my
            self.dragStartScrollY = self.scrollY
            self.scrollVelocity = 0
        else
            -- Continue dragging
            local deltaY = self.dragStartY - my -- Inverted for natural feel
            local newScrollY = self.dragStartScrollY + deltaY
            
            -- Calculate maxScrollY dynamically
            local maxScrollY = self:_calculateMaxScrollY()
            
            -- Apply bounds
            self.scrollY = math.max(0, math.min(maxScrollY, newScrollY))
            
            -- Calculate velocity for momentum
            if dt > 0 and scrollConfig.momentumEnabled then
                local velocityDelta = (my - (self.lastMouseY or my)) / dt
                local friction = scrollConfig.momentumFriction or 0.92
                self.scrollVelocity = velocityDelta * friction
            end
        end
    else
        if self.isDragging then
            -- Stop dragging, start momentum
            self.isDragging = false
        end
    end
    
    -- Update last frame data
    self.lastMouseY = my
end

-- Helper function to calculate max scroll Y dynamically
function DeckViewOverlay:_calculateMaxScrollY()
    if not self.panelRect then return 0 end
    
    -- Get card data
    local cardData = self:_getAllCardData()
    local sortedCardIds = self:_sortCardIds(cardData.cardIds, cardData.counts, self.cardDatabase)
    
    -- Calculate grid parameters (same as in draw function)
    local layout = self.theme and self.theme.layout or {}
    local paddingLarge = layout.paddingLarge or 25
    local paddingMedium = layout.paddingMedium or 15
    
    local fonts = self.theme and self.theme.fonts or {}
    local titleTextFont = fonts.large or fonts.default
    local sortInfoFont = love.graphics.newFont(14)
    
    local headerY = self.panelRect.y + paddingMedium
    local sortTextY = headerY + (titleTextFont and titleTextFont:getHeight() or 20) + 8
    local gridStartY = sortTextY + (sortInfoFont and sortInfoFont:getHeight() or 16) + paddingLarge
    local gridH = self.panelRect.height - gridStartY - paddingLarge
    
    local numColumns = 4
    local iconDrawHeight = 28
    local itemVisualPadding = 25
    local cardNameFont = love.graphics.newFont(11)
    local availabilityFont = love.graphics.newFont(9)
    
    local cardNameHeight = cardNameFont and cardNameFont:getHeight() or 12
    local availabilityHeight = availabilityFont and availabilityFont:getHeight() or 10
    local gridItemHeightWithPadding = iconDrawHeight + itemVisualPadding + cardNameHeight + availabilityHeight + 12
    
    local totalRows = math.ceil(#sortedCardIds / numColumns)
    local totalContentHeight = totalRows * gridItemHeightWithPadding
    
    return math.max(0, totalContentHeight - gridH)
end

-- Helper function to get content area for touch scrolling
function DeckViewOverlay:_getContentArea()
    if not self.panelRect then return { x = 0, y = 0, width = 0, height = 0 } end
    
    local paddingSmall = 8
    local titleHeight = 30
    local sortButtonHeight = 25
    local sortButtonSpacing = 10
    
    return {
        x = self.panelRect.x + paddingSmall,
        y = self.panelRect.y + titleHeight + sortButtonHeight + sortButtonSpacing + paddingSmall,
        width = self.panelRect.width - (paddingSmall * 2),
        height = self.panelRect.height - titleHeight - sortButtonHeight - sortButtonSpacing - (paddingSmall * 3)
    }
end

function DeckViewOverlay:onHide()
    print("Deck View Overlay Hidden")
end

-- Handle key presses for the deck view overlay
function DeckViewOverlay:handleKeyPress(key)
    if key == "s" then
        self:toggleSortMode()
        return true -- Key was handled
    end
    return false -- Key was not handled
end

return DeckViewOverlay