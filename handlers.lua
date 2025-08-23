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
        local hasAffordableSpell = false
        local hasAnySpells = false
        if gameState.knownSpells and type(gameState.currentEnergy) == "number" then
            for spellId, spellData in pairs(gameState.knownSpells) do
                if spellData then
                    hasAnySpells = true
                    local energyCost = spellData.energyCost or 0 
                    local canAfford = gameState.currentEnergy >= energyCost
                    if canAfford then
                        hasAffordableSpell = true
                        break 
                    end
                end
            end
        end
        isEnabled = canPerformGeneralActions and hasAnySpells and hasAffordableSpell

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

    -- 2. Check if Player is in Spell Casting Mode
    if gameState.spellCastingMode and gameState.selectedSpellId then
        print(string.format("    Handlers: Spell Casting Mode for Spell ID: %s", tostring(gameState.selectedSpellId)))
        local spellDefinition = gameState.knownSpells and gameState.knownSpells[gameState.selectedSpellId]
        
        if spellDefinition then
            -- Check if click is on the spell casting UI
            local screenW = config.Screen.width or 400
            local screenH = config.Screen.height or 600
            local layoutCfg = config.Layout or {}
            local handBaseY = layoutCfg.handBaseY or (screenH * 0.85)
            local uiY = handBaseY - 80
            local panelW = 300
            local panelH = 70
            local panelX = (screenW - panelW) / 2
            
            -- Check if click is within the spell casting UI panel
            if x >= panelX and x <= panelX + panelW and y >= uiY and y <= uiY + panelH then
                -- Check if click is on cast button
                local buttonW = 80
                local buttonH = 25
                local buttonX = panelX + (panelW - buttonW) / 2
                local buttonY = uiY + panelH - buttonH - 5
                
                if x >= buttonX and x <= buttonX + buttonW and y >= buttonY and y <= buttonY + buttonH then
                    -- Cast button clicked
                    if gameState.selectedCardIndices and #gameState.selectedCardIndices > 0 then
                        local selectedCardIndex = gameState.selectedCardIndices[1]
                        print(string.format("        -> Casting spell '%s' on card at index %d", spellDefinition.name, selectedCardIndex))
                        applySpellEffectFunc(gameState, dependencies, gameState.selectedSpellId, {handIndex = selectedCardIndex})
                        gameState.spellCastingMode = false
                        gameState.selectedSpellId = nil
                        gameState.selectedCardIndices = {}
                        clickWasHandled = true
                    end
                else
                    -- Check if click is on cancel button
                    local cancelW = 60
                    local cancelH = 20
                    local cancelX = panelX + panelW - cancelW - 5
                    local cancelY = uiY + 5
                    
                    if x >= cancelX and x <= cancelX + cancelW and y >= cancelY and y <= cancelY + cancelH then
                        -- Cancel button clicked
                        print("        -> Exiting spell casting mode")
                        gameState.spellCastingMode = false
                        gameState.selectedSpellId = nil
                        gameState.selectedCardIndices = {}
                        clickWasHandled = true
                    end
                end
            end
            
            if clickWasHandled then return clickedCardHandIndex end -- Return if UI handled it
        else
            print(string.format("Error (handleMouseClick): Could not find definition for selectedSpellId: %s during spell casting.", tostring(gameState.selectedSpellId)))
            gameState.selectedSpellId = nil; gameState.spellCastingMode = false -- Reset invalid state
        end
    end

    -- 3. Check if Player is Selecting a Spell Target (legacy system for non-hand_card targets)
    if gameState.selectingSpellTarget and gameState.selectedSpellId then
        print(string.format("    Handlers: Legacy Spell Targeting for Spell ID: %s", tostring(gameState.selectedSpellId)))
        local spellDefinition = gameState.knownSpells and gameState.knownSpells[gameState.selectedSpellId]
        
        if spellDefinition then
            -- Only handle non-hand_card targets with legacy system
            if spellDefinition.target ~= "hand_card" then
                print(string.format("        -> Spell '%s' target type is '%s' - applying immediately.", spellDefinition.name, tostring(spellDefinition.target)))
                applySpellEffectFunc(gameState, dependencies, gameState.selectedSpellId) 
            else
                print("        -> hand_card target spells now use card selection system")
            end
            clickWasHandled = true -- Consume the click attempt
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

                if gameState.spellCastingMode then
                    -- In spell casting mode, replace selection with single card
                    if selectionListIndex > 0 then
                        print(string.format("    Handlers: Deselecting card at hand index: %d", i))
                        deselectCardFunc(gameState, dependencies, selectionListIndex)
                    else
                        print(string.format("    Handlers: Selecting card at hand index: %d for spell casting", i))
                        -- Clear existing selections and select only this card
                        if deselectAllCardsFunc then deselectAllCardsFunc(gameState, dependencies) end
                        selectCardFunc(gameState, dependencies, i)
                    end
                else
                    -- Normal selection mode
                    if selectionListIndex > 0 then
                        print(string.format("    Handlers: Deselecting card at hand index: %d", i))
                        deselectCardFunc(gameState, dependencies, selectionListIndex)
                    else
                        print(string.format("    Handlers: Selecting card at hand index: %d", i))
                        selectCardFunc(gameState, dependencies, i)
                    end
                end
                clickWasHandled = true; clickedCardHandIndex = i; 
                break -- Only interact with one card per click
            end
        end
        if clickWasHandled then return clickedCardHandIndex end -- Card click handled
    end

    -- 5. Background Click (if in playing phase and no other UI element handled it)
    if not clickWasHandled and gameState.gamePhase == "playing" then
        if gameState.spellCastingMode then
            -- In spell casting mode, don't deselect cards on background click
            print("    Handlers: Background Click in Spell Casting Mode - No action.")
            clickWasHandled = true
        else
            print("    Handlers: Background Click - Deselecting All Cards.")
            deselectAllCardsFunc(gameState, dependencies)
            clickWasHandled = true 
        end
        -- No specific return value needed for background click unless it implies something
    end

    if not clickWasHandled then
        print(string.format("    Handlers: Click at (%.1f, %.1f) was not handled by any system.", x, y))
    end
    
    return nil -- Default return if no card was the primary target of the click for dragging.
end

print("handlers.lua (formatted with energy checks) loaded.")
return Handlers