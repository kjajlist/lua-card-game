-- File: handlers.lua (Formatted with Energy Checks)
-- Contains top-level input handling functions called by LÖVE callbacks.
-- Dispatches input events based on provided state and dependencies.

local Handlers = {}

-- =============================================================================
-- Input Helper Functions (Specific to Handler Logic)
-- =============================================================================

--- Checks if a point (x,y) is within a card's bounds, considering its transformation.
-- @param x (number) Mouse X coordinate.
-- @param y (number) Mouse Y coordinate.
-- @param card (table) The card object (must have x, y, rotation).
-- @param config (table) The main configuration table (for Card.width, Card.height).
-- @return boolean True if the point is in the card, false otherwise.
local function isPointInCard(x, y, card, config)
    if not card or type(x) ~= "number" or type(y) ~= "number" or
       type(card.x) ~= "number" or type(card.y) ~= "number" or
       type(card.rotation) ~= "number" then
        -- print("Warning (isPointInCard): Invalid card or coordinate data.")
        return false
    end

    local cardConfig = config and config.Card
    if not cardConfig or type(cardConfig.width) ~= "number" or type(cardConfig.height) ~= "number" then
        print("Warning (isPointInCard): Config.Card.width/height missing.")
        return false -- Cannot determine card dimensions
    end

    if not love or not love.math then
        print("Error (isPointInCard): love.math module not available.")
        return false
    end

    local cardWidth = cardConfig.width
    local cardHeight = cardConfig.height
    
    -- Create a transform for the card's current state
    local transform = love.math.newTransform()
    transform:translate(card.x + cardWidth / 2, card.y + cardHeight / 2) -- Move origin to card center
    transform:rotate(card.rotation)
    -- No need to scale here if hit detection is on unscaled card dimensions

    -- Get the inverse transform to convert screen coordinates to card's local coordinates
    local inverseTransform, errorMessage = transform:inverse()
    if not inverseTransform then
        print(string.format("Error (isPointInCard): Failed to create inverse transform for card '%s'. Error: %s", 
              tostring(card.name), tostring(errorMessage or "unknown error")))
        return false
    end

    -- Transform the click coordinates into the card's local space
    local localX, localY = inverseTransform:transformPoint(x, y)

    -- Check if the local coordinates are within the card's unrotated, unscaled bounding box (centered at 0,0)
    return math.abs(localX) <= cardWidth / 2 and math.abs(localY) <= cardHeight / 2
end

--- Determines if a main UI button should be enabled based on game state and energy.
-- @param buttonName (string) The identifier of the button (e.g., "discard", "makePotion").
-- @param gameState (table) The current game state.
-- @param dependencies (table) Provides access to config (for costs).
-- @return boolean True if the button should be enabled, false otherwise.
function Handlers.isButtonEnabled(buttonName, gameState, dependencies)
    if not gameState then
        print("Warning (isButtonEnabled): GameState missing.")
        return false
    end
    
    local config = dependencies and dependencies.config
    local gameConfig = config and config.Game -- For energy costs
    if not gameConfig then
        print("Warning (isButtonEnabled): Config.Game section (for energy costs) missing via dependencies.")
        -- If costs can't be determined, actions requiring energy should probably be disabled.
    end

    local isEnabled = false 
    local canPerformGeneralActions = (gameState.gamePhase == "playing" and not gameState.isWaitingForDiscard)

    if buttonName == "discard" then
        isEnabled = canPerformGeneralActions and
                      (gameState.canDiscard == true) and
                      gameState.selectedCardIndices and
                      #gameState.selectedCardIndices > 0

    elseif buttonName == "makePotion" then
        local makePotionEnergyCost = (gameConfig and gameConfig.makePotionEnergyCost) or 15 -- Fallback
        isEnabled = canPerformGeneralActions and
                      gameState.selectedCardIndices and
                      #gameState.selectedCardIndices > 0 and
                      gameState.potentialPotionResult and
                      gameState.potentialPotionResult.name and
                      gameState.potentialPotionResult.name ~= "Nothing" and
                      gameState.potentialPotionResult.name ~= "None" and
                      gameState.potentialPotionResult.name ~= "Unknown Mixture" and
                      (type(gameState.currentEnergy) == "number" and gameState.currentEnergy >= makePotionEnergyCost)

    elseif buttonName == "castSpell" then
        local hasAffordableSpellWithUses = false
        if gameState.knownSpells and type(gameState.currentEnergy) == "number" then
            for spellId, spellData in pairs(gameState.knownSpells) do
                if spellData then
                    local hasUses = not spellData.uses or spellData.uses < 0 or 
                                  (spellData.currentUses and spellData.currentUses > 0)
                    local energyCost = spellData.energyCost or 0 
                    local canAfford = gameState.currentEnergy >= energyCost
                    if hasUses and canAfford then
                        hasAffordableSpellWithUses = true
                        break 
                    end
                end
            end
        end
        isEnabled = canPerformGeneralActions and hasAffordableSpellWithUses

    elseif buttonName == "sortToggle" then
        isEnabled = (gameState.gamePhase == "playing")

    elseif buttonName == "potionList" or buttonName == "deckView" then
        isEnabled = true -- These are generally always accessible

    else
        print(string.format("Warning (isButtonEnabled): Unknown button name '%s'", tostring(buttonName)))
        isEnabled = false
    end
    
    -- Verbose debug print, can be enabled if needed
    -- local energyInfo = ""
    -- if buttonName == "makePotion" then energyInfo = string.format(", Cost: %d", (gameConfig and gameConfig.makePotionEnergyCost) or 0) end
    -- if buttonName == "castSpell" and isEnabled then energyInfo = " (Spell affordable)" elseif buttonName == "castSpell" then energyInfo = " (No spell affordable/usable)" end
    -- print(string.format("Handlers.isButtonEnabled for '%s': %s (Phase: %s, GenActions: %s, Energy: %s%s)",
    --    buttonName, tostring(isEnabled), gameState.gamePhase, tostring(canPerformGeneralActions), tostring(gameState.currentEnergy), energyInfo))
        
    return isEnabled
end

-- =============================================================================
-- Main Input Dispatch Function
-- =============================================================================
--- Handles mouse click events and dispatches them to relevant game systems.
-- @param x (number) Virtual mouse X coordinate.
-- @param y (number) Virtual mouse Y coordinate.
-- @param gameState (table) The current game state.
-- @param config (table) The main game configuration.
-- @param dependencies (table) Provides access to other modules and helpers.
-- @return clickedCardIndex (number or nil) if a hand card was clicked, nil otherwise.
function Handlers.handleMouseClick(x, y, gameState, config, dependencies)
    print(string.format("Handlers.handleMouseClick: Virtual Coords (%.1f, %.1f)", x, y))

    if not gameState or not config or not dependencies then print("Error (handleMouseClick): Missing critical arguments."); return nil end
    
    local overlayManager = dependencies.overlayManager
    local uiStateButtons = dependencies.uiState and dependencies.uiState.Buttons -- Main screen buttons
    local coreGameFuncs = dependencies.coreGame
    local applySpellEffectFunc = coreGameFuncs and coreGameFuncs.applySpellEffect
    local selectCardFunc = coreGameFuncs and coreGameFuncs.selectCard
    local deselectCardFunc = coreGameFuncs and coreGameFuncs.deselectCard
    local deselectAllCardsFunc = coreGameFuncs and coreGameFuncs.deselectAllCards

    if not overlayManager then print("Error (handleMouseClick): Missing dependencies.overlayManager"); return nil end
    if not (selectCardFunc and deselectCardFunc and deselectAllCardsFunc) then print("Error (handleMouseClick): Missing card selection functions from coreGame dependencies"); return nil end
    if not applySpellEffectFunc then print("Error (handleMouseClick): Missing applySpellEffect from coreGame dependencies"); return nil end

    local clickWasHandled = false
    local clickedCardHandIndex = nil

    -- 1. Check Active Overlay First
    if overlayManager:getActiveOverlayName() then
        print(string.format("    Handlers: Checking Active Overlay: '%s'", overlayManager:getActiveOverlayName()))
        clickWasHandled = overlayManager:handleClick(x, y)
        if clickWasHandled then
            print("    Handlers: Click handled by OverlayManager.")
            return nil -- Overlay consumed the click
        end
    end

    -- 2. Check if Player is Selecting a Spell Target (only if no overlay handled click)
    if gameState.selectingSpellTarget and gameState.selectedSpellId then
        print(string.format("    Handlers: Selecting Spell Target for Spell ID: %s", tostring(gameState.selectedSpellId)))
        local spellDefinition = gameState.knownSpells and gameState.knownSpells[gameState.selectedSpellId]
        
        if spellDefinition then
            if spellDefinition.target == "hand_card" then
                local targetCardFound = false
                for i = #gameState.hand, 1, -1 do -- Iterate backwards for correct selection from overlapping cards
                    local cardInHand = gameState.hand[i]
                    if cardInHand and not cardInHand.isDiscarding and isPointInCard(x, y, cardInHand, config) then
                        print("        -> Found target hand card at index:", i)
                        applySpellEffectFunc(gameState, dependencies, gameState.selectedSpellId, {handIndex = i})
                        clickedCardHandIndex = i; targetCardFound = true; 
                        break
                    end
                end
                if not targetCardFound then print("        -> No valid hand card target found at click location.") end
            else -- Spell targets something else or is self-targeted
                print(string.format("        -> Spell '%s' target type is '%s' or no specific target needed.", spellDefinition.name, tostring(spellDefinition.target)))
                applySpellEffectFunc(gameState, dependencies, gameState.selectedSpellId) 
            end
            clickWasHandled = true -- Consume the click attempt, whether successful target or not
        else
            print(string.format("Error (handleMouseClick): Could not find definition for selectedSpellId: %s during targeting.", tostring(gameState.selectedSpellId)))
            gameState.selectedSpellId = nil; gameState.selectingSpellTarget = false -- Reset invalid state
        end
        
        if clickWasHandled then return clickedCardHandIndex end -- Return if targeting logic handled it
    end

    -- 3. Check Main UI Buttons (e.g., Discard, Make Potion on main game screen)
    -- Ensure uiStateButtons is a table before trying to iterate
    if uiStateButtons and type(uiStateButtons) == "table" then
        -- print("    Handlers: Checking Main UI Buttons...") -- Can be noisy
        for buttonId, buttonInstance in pairs(uiStateButtons) do
            if buttonInstance and buttonInstance.handleClick and type(buttonInstance.handleClick) == "function" then
                -- print(string.format("        Attempting handleClick for button ID: %s", tostring(buttonId))) -- Can be noisy
                if buttonInstance:handleClick(x, y) then
                    clickWasHandled = true
                    print(string.format("    Handlers: Main UI Button '%s' handled click.", tostring(buttonId)))
                    break 
                end
            end
        end
        if clickWasHandled then return nil end -- Main UI button consumed the click
    end

    -- 4. Check Card Clicks in Hand (Toggle Selection)
    if gameState.hand and gameState.gamePhase == "playing" then
        -- print("    Handlers: Checking Card Clicks in hand...") -- Can be noisy
        for i = #gameState.hand, 1, -1 do -- Iterate backwards for top-most card
            local cardInHand = gameState.hand[i]
            if cardInHand and not cardInHand.isDiscarding and isPointInCard(x, y, cardInHand, config) then
                local selectionListIndex = -1
                if gameState.selectedCardIndices then
                    for j, selectedHandIdx in ipairs(gameState.selectedCardIndices) do
                        if selectedHandIdx == i then selectionListIndex = j; break end
                    end
                end

                if selectionListIndex > 0 then
                    print(string.format("    Handlers: Deselecting card at hand index: %d", i))
                    deselectCardFunc(gameState, dependencies, selectionListIndex)
                else
                    print(string.format("    Handlers: Selecting card at hand index: %d", i))
                    selectCardFunc(gameState, dependencies, i)
                end
                clickWasHandled = true; clickedCardHandIndex = i; 
                break -- Only interact with one card per click
            end
        end
        if clickWasHandled then return clickedCardHandIndex end -- Card click handled
    end

    -- 5. Background Click (if in playing phase and no other UI element handled it)
    if not clickWasHandled and gameState.gamePhase == "playing" then
        print("    Handlers: Background Click - Deselecting All Cards.")
        deselectAllCardsFunc(gameState, dependencies)
        clickWasHandled = true 
        -- No specific return value needed for background click unless it implies something
    end

    if not clickWasHandled then
        print(string.format("    Handlers: Click at (%.1f, %.1f) was not handled by any system.", x, y))
    end
    
    return nil -- Default return if no card was the primary target of the click for dragging.
end

print("handlers.lua (formatted with energy checks) loaded.")
return Handlers