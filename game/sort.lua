-- File: sort.lua (Formatted)
-- Contains functions for sorting the player's hand and calculating card layout.
-- Operates on state and configuration passed as arguments.

local Sort = {}

-- =============================================================================
-- Layout Calculation Function
-- =============================================================================

--- Calculates target screen positions for cards in hand, arranging them in an arc.
-- Updates targetX, targetY, targetRotation, targetScale on each card object.
-- Snaps non-animating/non-dragging cards to their target positions.
-- @param gameState (table) The main game state table (must contain 'hand' and 'drag' state).
-- @param config (table) The main configuration table (for Layout, Card, Screen settings).
function Sort.calculateHandLayout(gameState, config)
    -- 1. Validate Inputs
    if not gameState or not gameState.hand then
        print("Error (calculateHandLayout): Missing gameState.hand.")
        return
    end
    if not config or not config.Layout or not config.Card or not config.Screen then
        print("Error (calculateHandLayout): Missing required Config sections (Layout, Card, Screen).")
        return
    end

    local hand = gameState.hand
    local handSize = #hand

    if handSize == 0 then return end -- No cards to position

    -- 2. Get Layout Parameters from Config (with fallbacks)
    local layoutConfig = config.Layout
    local cardConfig = config.Card
    local screenConfig = config.Screen

    local cardWidth = cardConfig.width or 60
    local cardHorizontalSpacing = cardConfig.width + (layoutConfig.handSpacing or -25) -- Spacing between card centers
    local totalHandDisplayWidth = (handSize - 1) * cardHorizontalSpacing + cardWidth
    
    local handStartX = (screenConfig.width - totalHandDisplayWidth) / 2
    local handBaseY = layoutConfig.handBaseY or (screenConfig.height * 0.85) -- Default to lower part of screen
    local handArcCurvature = layoutConfig.handArcDepth or 15
    local maxCardRotationDegrees = layoutConfig.handMaxRotation or 10
    local highlightedCardOffsetY = layoutConfig.handHighlightOffsetY or 10

    -- 3. Calculate and Apply Target Transform for Each Card
    for i = 1, handSize do
        local card = hand[i]
        if card and type(card) == "table" then
            local targetXPosition = handStartX + (i - 1) * cardHorizontalSpacing
            local normalizedPositionInHand = 0 -- For center card, -1 for leftmost, +1 for rightmost

            if handSize > 1 then
                normalizedPositionInHand = (i - (handSize + 1) / 2) / (handSize / 2)
                normalizedPositionInHand = math.max(-1, math.min(1, normalizedPositionInHand)) -- Clamp to [-1, 1]
            end

            -- Calculate Y offset for arc (parabolic curve: y = depth * (1 - x^2))
            local arcOffsetY = handArcCurvature * (1 - normalizedPositionInHand * normalizedPositionInHand)
            local targetYPosition = handBaseY - arcOffsetY -- Y is from top, so subtract offset

            -- Adjust Y if card is highlighted (selected)
            if card.isHighlighted then
                targetYPosition = targetYPosition - highlightedCardOffsetY
            end

            local targetRotationAngle = math.rad(-maxCardRotationDegrees * normalizedPositionInHand)

            -- Store calculated target values in the card object
            card.targetX = targetXPosition
            card.targetY = targetYPosition
            card.targetRotation = targetRotationAngle
            card.targetScale = 1 -- Default scale

            -- Snap card to target if not animating and not being dragged by the player
            local isThisCardBeingDragged = gameState.drag and gameState.drag.isDragging and gameState.drag.cardIndex == i
            if not card.isAnimating and not isThisCardBeingDragged then
                card.x = targetXPosition
                card.y = targetYPosition
                card.rotation = targetRotationAngle
                card.scale = card.targetScale
            end
        else
            print(string.format("Warning (calculateHandLayout): Nil card found in hand at index %d.", i))
        end
    end
end

-- =============================================================================
-- Sorting Helper Function for Color Sorting
-- =============================================================================

--- Approximates hue for color sorting.
-- @param card (table) The card object with an 'objectColor' field.
-- @return number A numeric key for sorting by color (hue, with special values for grayscale).
local function getColorSortKeyHueApprox(card)
    if not card or not card.objectColor or type(card.objectColor) ~= "table" or #card.objectColor < 3 then
        return 999 -- Push colors that can't be determined to the end
    end

    local r, g, b = card.objectColor[1], card.objectColor[2], card.objectColor[3]
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

-- =============================================================================
-- Specific Sorting Logic Functions (Local Helpers, sorting `hand` in-place)
-- =============================================================================

local function sortById(hand)
    table.sort(hand, function(a, b)
        if not a or not a.id then return false end -- Sort nils to one end
        if not b or not b.id then return true end
        return a.id < b.id
    end)
end

local function sortByValue(hand)
    table.sort(hand, function(a, b)
        if not a or type(a.value) ~= "number" or not a.id then return false end
        if not b or type(b.value) ~= "number" or not b.id then return true end
        if a.value ~= b.value then return a.value > b.value end -- Primary: Value descending
        return a.id < b.id -- Secondary: ID ascending
    end)
end

local function sortByColor(hand)
    table.sort(hand, function(a, b)
        if not a or type(a.value) ~= "number" or not a.id then return false end
        if not b or type(b.value) ~= "number" or not b.id then return true end
        local hueA = getColorSortKeyHueApprox(a)
        local hueB = getColorSortKeyHueApprox(b)
        if hueA ~= hueB then return hueA < hueB end         -- Primary: Hue ascending
        if a.value ~= b.value then return a.value > b.value end -- Secondary: Value descending
        return a.id < b.id -- Tertiary: ID ascending
    end)
end

local function sortByFamily(hand)
    table.sort(hand, function(a, b)
        if not a or not a.family or type(a.value) ~= "number" or not a.id then return false end
        if not b or not b.family or type(b.value) ~= "number" or not b.id then return true end
        local familyA = a.family or ""
        local familyB = b.family or ""
        if familyA ~= familyB then return familyA < familyB end -- Primary: Family ascending
        if a.value ~= b.value then return a.value > b.value end   -- Secondary: Value descending
        return a.id < b.id -- Tertiary: ID ascending
    end)
end

local function sortBySubType(hand)
    table.sort(hand, function(a, b)
        if not a or not a.family or type(a.value) ~= "number" or not a.id then return false end
        if not b or not b.family or type(b.value) ~= "number" or not b.id then return true end
        
        local subTypeA, subTypeB = a.subType, b.subType
        -- Handle nil subtypes consistently (e.g., sort them to the end or beginning)
        if subTypeA == nil and subTypeB ~= nil then return false end -- Sort nils after non-nils
        if subTypeA ~= nil and subTypeB == nil then return true end
        if subTypeA == nil and subTypeB == nil then -- Both nil, proceed to next criterion
            -- This 'elseif' was incomplete, fixed:
        elseif subTypeA ~= subTypeB then 
            return tostring(subTypeA) < tostring(subTypeB) -- Primary: SubType ascending
        end

        local familyA = a.family or ""
        local familyB = b.family or ""
        if familyA ~= familyB then return familyA < familyB end -- Secondary: Family ascending
        if a.value ~= b.value then return a.value > b.value end   -- Tertiary: Value descending
        return a.id < b.id -- Quaternary: ID ascending
    end)
end

-- =============================================================================
-- Main Sorting Application Functions (Exposed by the module)
-- =============================================================================

--- Sorts the player's hand based on the current sort mode, preserving selection.
function Sort.sortHand(gameState, config, dependencies)
    if not gameState or not gameState.hand or not gameState.sortModes or 
       type(gameState.currentSortModeIndex) ~= "number" then
        print("Error (sortHand): Missing required GameState fields (hand, sortModes, currentSortModeIndex).")
        return
    end
    if not dependencies or not dependencies.coreGame or 
       not dependencies.coreGame.recalculateCurrentScore or 
       not dependencies.coreGame.updatePotentialPotion then
        print("Error (sortHand): Missing required coreGame helper functions in dependencies.")
        return
    end

    -- Preserve current selection by card IDs
    local selectedOriginalIDs = {}
    if gameState.selectedCardIndices and #gameState.selectedCardIndices > 0 then
        print("Preserving selection during sort...")
        for _, handIdx in ipairs(gameState.selectedCardIndices) do
            local card = gameState.hand[handIdx]
            if card and card.id then
                selectedOriginalIDs[card.id] = true -- Mark ID as selected
                -- print("    -> Storing selected ID:", card.id) -- Debug
            end
        end
        -- Clear current selection indices and visual highlight before sort
        gameState.selectedCardIndices = {} 
        for _, cardInstance in ipairs(gameState.hand) do
            if cardInstance then cardInstance.isHighlighted = false end
        end
    end

    local currentSortMode = gameState.sortModes[gameState.currentSortModeIndex]
    if not currentSortMode then
        print(string.format("Warning (sortHand): Invalid sort mode index %d. Defaulting to 'id' sort.", gameState.currentSortModeIndex))
        currentSortMode = "default" -- Fallback to default/ID sort
    end
    print("Sorting hand by:", currentSortMode)

    -- Apply the chosen sort function
    if currentSortMode == "value" then sortByValue(gameState.hand)
    elseif currentSortMode == "color" then sortByColor(gameState.hand)
    elseif currentSortMode == "family" then sortByFamily(gameState.hand)
    elseif currentSortMode == "subtype" then sortBySubType(gameState.hand)
    else sortById(gameState.hand) end -- Default sort is by ID

    -- Restore selection based on IDs
    if next(selectedOriginalIDs) ~= nil then -- Check if selectedOriginalIDs table is not empty
        print("Restoring selection after sort...")
        local newSelectedIndices = {}
        for newHandIndex, cardInstance in ipairs(gameState.hand) do
            if cardInstance and cardInstance.id and selectedOriginalIDs[cardInstance.id] then
                table.insert(newSelectedIndices, newHandIndex)
                cardInstance.isHighlighted = true
                -- print(string.format("    -> Restored ID: %s at new hand index: %d", cardInstance.id, newHandIndex)) -- Debug
            end
        end
        gameState.selectedCardIndices = newSelectedIndices
        print("Selection restored. New selected count:", #gameState.selectedCardIndices)
    end

    -- Update game state and UI after sorting
    dependencies.coreGame.recalculateCurrentScore(gameState)
    dependencies.coreGame.updatePotentialPotion(gameState, dependencies)
    Sort.calculateHandLayout(gameState, config) -- Recalculate visual layout
    print("Hand sorted and layout updated.")
end

--- Toggles to the next sort mode and applies it.
function Sort.toggleSortMode(gameState, config, dependencies)
    if not gameState or not gameState.sortModes or type(gameState.currentSortModeIndex) ~= "number" then
        print("Error (toggleSortMode): Missing GameState.sortModes or currentSortModeIndex.")
        return
    end
    if not dependencies or not dependencies.uiState or not dependencies.uiState.Buttons or 
       not dependencies.uiState.Buttons.sortToggle then
        print("Error (toggleSortMode): Missing sortToggle button instance in dependencies.uiState.")
        return
    end
    local getConfigValueFunc = dependencies.getConfigValue -- Get from Dependencies
    if not getConfigValueFunc then
        print("Error (toggleSortMode): getConfigValue function missing from dependencies.")
        return
    end

    print("Toggling sort mode...")
    gameState.currentSortModeIndex = gameState.currentSortModeIndex + 1
    if gameState.currentSortModeIndex > #gameState.sortModes then
        gameState.currentSortModeIndex = 1 -- Cycle back to the first mode
    end
    
    local newModeName = gameState.sortModes[gameState.currentSortModeIndex]
    print("Sort mode changed to:", newModeName or "Unknown")

    -- Update the sort button's label
    local sortButtonInstance = dependencies.uiState.Buttons.sortToggle
    local sortButtonBaseLabel = getConfigValueFunc(config, {"UI", "sortButton", "label"}, "Sort: ")
    
    local capitalizedModeName = "Default" -- Fallback
    if type(newModeName) == "string" and #newModeName > 0 then
        capitalizedModeName = newModeName:sub(1,1):upper() .. newModeName:sub(2)
    end
    
    if sortButtonInstance.setLabel then
        sortButtonInstance:setLabel(sortButtonBaseLabel .. capitalizedModeName)
        print("Updated sort button label to:", sortButtonBaseLabel .. capitalizedModeName)
    else
        print("Warning (toggleSortMode): sortToggle button instance is missing setLabel method.")
    end

    Sort.sortHand(gameState, config, dependencies) -- Apply the new sort order
end

print("sort.lua (formatted with energy and getConfigValue fix) loaded.")
return Sort