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
    
    print("[DeckViewOverlay:new] Instance created with name: ", instance.name)
    
    -- Initialize deck view mode
    instance.gameState.deckViewMode = instance.gameState.deckViewMode or "remaining"
    
    -- Initialize sort mode for deck view (same as main game)
    instance.gameState.deckViewSortMode = instance.gameState.deckViewSortMode or "default"
    
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

    -- Create toggle buttons for deck view mode
    local toggleButtonWidth = 100
    local toggleButtonHeight = 30
    
    print("[DeckViewOverlay:new] Creating remaining button...")
    instance.remainingButton = Button:new({
        id = "deckViewRemaining", 
        x = 0, y = 0, -- Positioned in draw()
        width = toggleButtonWidth, height = toggleButtonHeight,
        label = "Remaining", 
        font = buttonFont,
        onClick = function() instance.gameState.deckViewMode = "remaining" end,
        defaultFont = buttonFont, 
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius or 5, 
        defaultColors = buttonDefaultSettings.defaultColors or {normal = {0.8, 0.8, 0.8, 1}}
    })
    
    print("[DeckViewOverlay:new] Creating full button...")
    instance.fullButton = Button:new({
        id = "deckViewFull", 
        x = 0, y = 0, -- Positioned in draw()
        width = toggleButtonWidth, height = toggleButtonHeight,
        label = "Full Deck", 
        font = buttonFont,
        onClick = function() instance.gameState.deckViewMode = "full" end,
        defaultFont = buttonFont, 
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius or 5, 
        defaultColors = buttonDefaultSettings.defaultColors or {normal = {0.8, 0.8, 0.8, 1}}
    })
    
    print("[DeckViewOverlay:new] All buttons created successfully!")
    print("[DeckViewOverlay:new] Returning instance...")
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
    print("=== DECK VIEW DRAW FUNCTION CALLED ===")
    print("=== FORCED ULTRA DEBUG - NEW CODE IS LOADED ===")
    print("[DeckViewOverlay:draw] Starting deck view draw...")
    print("[DeckViewOverlay:draw] Active overlay name: ", self.uiManager and self.uiManager.activeOverlayName or "unknown")
    print("[DeckViewOverlay:draw] Self name: ", self.name or "unknown")
    
    if self.uiManager:getActiveOverlayName() ~= self.name then 
        print("[DeckViewOverlay:draw] Not the active overlay, returning")
        return 
    end

    if not self.theme or not self.gameState or not self.cardDatabase or not self.closeButton then
        print("ERROR: DeckViewOverlay:draw - Missing critical dependencies.")
        return
    end
    if not self.theme.helpers.drawCardIcon then
        print("ERROR: DeckViewOverlay:draw - Missing drawCardIcon helper.")
        return
    end
    if not love or not love.graphics then
        print("Error: LÖVE graphics module not available in DeckViewOverlay:draw.")
        return
    end

    -- Create fonts early to avoid nil errors
    print("[DeckViewOverlay:draw] Creating fonts...")
    local cardNameFont = love.graphics.newFont(10) -- Smaller font for card names
    local cardCountFont = love.graphics.newFont(14) -- Larger font for card counts (increased from 12)
    local sortInfoFont = love.graphics.newFont(14) -- Font for sort info
    print("[DeckViewOverlay:draw] Fonts created successfully: ", cardNameFont and "yes" or "no")
    print("[DeckViewOverlay:draw] cardCountFont created: ", cardCountFont and "yes" or "no")
    print("[DeckViewOverlay:draw] cardCountFont size: ", cardCountFont and cardCountFont:getHeight() or "nil")

    local theme = self.theme
    local colors = theme.colors
    local layout = theme.layout
    local fonts = theme.fonts
    local sizes = theme.sizes
    local helpers = theme.helpers

    local paddingSmall = layout.paddingSmall or 8
    local paddingMedium = layout.paddingMedium or 15
    local paddingLarge = layout.paddingLarge or 25

    -- 1. Draw Panel Base
    self.panelRect = helpers.calculateOverlayPanelRect(theme)
    helpers.drawOverlayBase(self.panelRect, theme)

    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Header Section
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
        love.graphics.printf("Sort: " .. currentSortMode .. " (Press 'S' to change)", self.panelRect.x, sortTextY, self.panelRect.width, "center")
    end

    -- 3. Position and Draw Close Button (top right)
    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - paddingSmall
    self.closeButton.y = self.panelRect.y + paddingSmall
    self.closeButton:draw()

    -- 4. Position and Draw Toggle Buttons (below sort info)
    local toggleYPos = sortTextY + (sortInfoFont and sortInfoFont:getHeight() or 16) + paddingMedium
    local toggleButtonGap = paddingMedium
    local combinedToggleWidth = self.remainingButton.width + self.fullButton.width + toggleButtonGap
    local remainingBtnX = self.panelRect.x + (self.panelRect.width - combinedToggleWidth) / 2
    local fullBtnX = remainingBtnX + self.remainingButton.width + toggleButtonGap
    
    self.remainingButton.x, self.remainingButton.y = remainingBtnX, toggleYPos
    self.fullButton.x, self.fullButton.y = fullBtnX, toggleYPos
    self.remainingButton:draw()
    self.fullButton:draw()

    -- 5. Get Card Data for Display
    local cardCounts, totalCount = self:_getCardCounts()

    local sortedCardIds = {}
    for id, count in pairs(cardCounts) do
        if type(count) == "number" and count > 0 then
            table.insert(sortedCardIds, id)
        end
    end
    
    -- Sort cards based on current sort mode
    sortedCardIds = self:_sortCardIds(sortedCardIds, cardCounts, self.cardDatabase)
    print("[DeckViewOverlay:draw] Number of unique card IDs to display: ", #sortedCardIds)

    -- 6. Setup Grid parameters
    local gridStartY = toggleYPos + self.remainingButton.height + paddingLarge
    local gridX = self.panelRect.x + paddingLarge
    local gridW = self.panelRect.width - (paddingLarge * 2)
    local gridH = self.panelRect.height - gridStartY - paddingLarge

    -- FORCE THE UX CHANGES (even smaller cards with more spacing around them)
    local numColumns = 5 -- Increase to 5 columns for smaller cards
    local iconDrawHeight = 25 -- Even smaller height for more compact cards
    local iconDrawWidth = 20 -- Even smaller width for more compact cards
    local itemVisualPadding = 18 -- More padding for better spacing around cards
    local columnActualWidth = gridW / numColumns

    print("[DeckViewOverlay:draw] ULTRA DEBUG - BEFORE FORCE: numColumns: " .. (sizes.deckViewColumns or "nil") .. ", iconSize: " .. (sizes.deckViewMediumIconWidth or "nil") .. "x" .. (sizes.deckViewMediumIconHeight or "nil") .. ", itemPadding: " .. (layout.deckViewItemPadding or "nil"))
    print("[DeckViewOverlay:draw] ULTRA DEBUG - AFTER FORCE: numColumns: " .. numColumns .. ", iconSize: " .. iconDrawWidth .. "x" .. iconDrawHeight .. ", itemPadding: " .. itemVisualPadding .. ", columnWidth: " .. columnActualWidth)

    -- Calculate grid item height including space for card name above
    local gridItemHeightWithPadding = iconDrawHeight + itemVisualPadding + (cardNameFont and cardNameFont:getHeight() or 12) + 8 -- Add space for text below cards with more padding
    print("[DeckViewOverlay:draw] gridItemHeightWithPadding calculated: ", gridItemHeightWithPadding)

    -- 7. Draw Cards in Grid
    local currentColumn = 0
    local currentY = gridStartY

    for i, cardId in ipairs(sortedCardIds) do
        local countOfThisCard = cardCounts[cardId] or 0
        if countOfThisCard > 0 then
            -- Calculate position
            local itemX = gridX + (currentColumn * columnActualWidth) + (columnActualWidth - iconDrawWidth) / 2
            local itemY = currentY

            -- Get card definition
            print("[DeckViewOverlay:draw] Processing card ID: " .. cardId .. " (type: " .. type(cardId) .. ")")
            print("[DeckViewOverlay:draw] cardDatabase type: " .. type(self.cardDatabase))
            print("[DeckViewOverlay:draw] getDefinition type: " .. type(self.cardDatabase.getDefinition))
            print("[DeckViewOverlay:draw] cardDatabase value: " .. tostring(self.cardDatabase))
            print("[DeckViewOverlay:draw] self.cardDatabase is: " .. tostring(self.cardDatabase))
            print("[DeckViewOverlay:draw] self.cardDatabase.getDefinition is: " .. tostring(self.cardDatabase.getDefinition))
            print("[DeckViewOverlay:draw] About to call getDefinition with id: " .. cardId)
            print("[DeckViewOverlay:draw] self.cardDatabase is: " .. tostring(self.cardDatabase))
            print("[DeckViewOverlay:draw] self.cardDatabase.getDefinition is: " .. tostring(self.cardDatabase.getDefinition))
            print("[DeckViewOverlay:draw] Calling getDefinition with id: " .. cardId .. " (type: " .. type(cardId) .. ")")
            
            local cardDef = self.cardDatabase.getDefinition(self.cardDatabase, cardId)
            
            if cardDef then
                print("[DeckViewOverlay:draw] DRAWING CARD - Column: " .. currentColumn .. ", Position: (" .. itemX .. ", " .. itemY .. "), Size: " .. iconDrawWidth .. "x" .. iconDrawHeight .. ", Name: " .. (cardDef.name or "???"))

                -- Create a card instance for drawing the full card
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
                
                -- Draw the full card object (includes background color, border, name, value, and object color circle)
                print("[DeckViewOverlay:draw] DRAWING FULL CARD - Card: " .. (cardDef.name or "???") .. ", Position: (" .. itemX .. ", " .. itemY .. "), Size: " .. iconDrawWidth .. "x" .. iconDrawHeight)
                
                -- Use the drawCardObject function to draw the complete card
                local Draw = require("draw")
                Draw.drawCardObject(cardInstance, self.uiManager.sharedDependencies.config, self.uiManager.sharedDependencies, self.gameState)
                
                -- Draw card count as notification bubble in top-right corner of card
                local bubbleRadius = 8 -- Size of the notification bubble
                local bubbleX = itemX + iconDrawWidth - bubbleRadius - 2 -- 2px from right edge
                local bubbleY = itemY + bubbleRadius + 2 -- 2px from top edge
                
                print("[DeckViewOverlay:draw] DRAWING CARD COUNT BUBBLE - Card: " .. (cardDef.name or "???") .. ", Count: " .. countOfThisCard .. ", Position: (" .. bubbleX .. ", " .. bubbleY .. "), Font: " .. (cardCountFont and "valid" or "nil"))
                
                -- Draw bubble background (red circle)
                love.graphics.setColor(1, 0, 0, 1) -- Red background for notification bubble
                love.graphics.circle("fill", bubbleX, bubbleY, bubbleRadius)
                
                -- Draw bubble border (white)
                love.graphics.setColor(1, 1, 1, 1) -- White border
                love.graphics.circle("line", bubbleX, bubbleY, bubbleRadius)
                
                -- Draw count text inside bubble
                love.graphics.setFont(cardCountFont) -- Use larger font for card counts
                love.graphics.setColor(1, 1, 1, 1) -- White text for contrast
                local countText = tostring(countOfThisCard) -- Just the number, no "x"
                print("[DeckViewOverlay:draw] CARD COUNT BUBBLE TEXT - Text: '" .. countText .. "', Card: " .. (cardDef.name or "???"))
                
                -- Center the text in the bubble
                local textWidth = cardCountFont:getWidth(countText)
                local textHeight = cardCountFont:getHeight()
                local textX = bubbleX - textWidth / 2
                local textY = bubbleY - textHeight / 2
                
                love.graphics.print(countText, textX, textY)
                print("[DeckViewOverlay:draw] CARD COUNT BUBBLE DRAWN - Card: " .. (cardDef.name or "???") .. ", Count: " .. countOfThisCard)
            end

            -- Move to next column
            currentColumn = currentColumn + 1
            print("[DeckViewOverlay:draw] COLUMN UPDATE - New column: " .. currentColumn .. "/" .. numColumns)
            
            if currentColumn >= numColumns then
                currentColumn = 0
                currentY = currentY + gridItemHeightWithPadding
                print("[DeckViewOverlay:draw] ROW COMPLETE - Moving to next row at Y: " .. currentY)
                
                -- Check if we're about to go out of bounds
                local nextRowY = currentY + gridItemHeightWithPadding
                local maxAllowedY = self.panelRect.y + self.panelRect.height - paddingLarge
                print("[DeckViewOverlay:draw] ABOUT TO CHECK BOUNDS - currentY: " .. currentY .. ", gridItemHeightWithPadding: " .. gridItemHeightWithPadding)
                print("[DeckViewOverlay:draw] BOUNDS DEBUG - Checking bounds: nextRowY=" .. nextRowY .. ", maxAllowedY=" .. maxAllowedY .. ", panelRect.y=" .. self.panelRect.y .. ", panelRect.height=" .. self.panelRect.height .. ", paddingLarge=" .. paddingLarge)
                
                if nextRowY > maxAllowedY then
                    print("[DeckViewOverlay:draw] BOUNDS DEBUG - Content out of bounds! Would need: " .. nextRowY .. ", Available: " .. maxAllowedY)
                    print("[DeckViewOverlay:draw] BOUNDS DEBUG - Breaking card draw loop. Some cards will be cut off!")
                    
                    -- Draw ellipsis to indicate more content
                    love.graphics.setColor(titleTextColor)
                    love.graphics.setFont(fonts.default or originalFont)
                    love.graphics.printf("...", gridX, currentY, gridW, "center")
                    print("[DeckViewOverlay:draw] BOUNDS DEBUG - Drawing ellipsis to indicate more content")
                    break
                end
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
    local currentMode = self.gameState.deckViewMode or "remaining"
    
    -- Get the appropriate card source based on mode
    local cardSource = {}
    if currentMode == "remaining" then
        -- Count cards in deck
        if self.gameState.deck then
            for _, cardInstance in ipairs(self.gameState.deck) do
                if cardInstance and cardInstance.id then
                    local id = tonumber(cardInstance.id)
                    if id then
                        cardCounts[id] = (cardCounts[id] or 0) + 1
                        totalCount = totalCount + 1
                    end
                end
            end
        end
    else -- "full" mode
        -- Count all cards (deck + hand + discard)
        local allSources = {self.gameState.deck, self.gameState.hand, self.gameState.discardPile}
        for _, source in ipairs(allSources) do
            if source then
                for _, cardInstance in ipairs(source) do
                    if cardInstance and cardInstance.id then
                        local id = tonumber(cardInstance.id)
                        if id then
                            cardCounts[id] = (cardCounts[id] or 0) + 1
                            totalCount = totalCount + 1
                        end
                    end
                end
            end
        end
    end
    
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

-- Handle key presses for the deck view overlay
function DeckViewOverlay:handleKeyPress(key)
    if key == "s" then
        self:toggleSortMode()
        return true -- Key was handled
    end
    return false -- Key was not handled
end

return DeckViewOverlay