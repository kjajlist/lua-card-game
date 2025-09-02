-- File: main.lua (Fully Refactored, Formatted, with Energy & Endless Mode Logic)
-- Main application file for the LÖVE game.
-- Handles initialization, the main game loop (update/draw), and input routing using dependencies.

-- =============================================================================
-- Global Helper Functions (Defined at top or passed via Dependencies)
-- =============================================================================

--- Helper function to safely get nested config values.
-- This function is defined here and will be added to the Dependencies table.
local function getConfigValue(configTable, path, defaultValue)
    local current = configTable
    if not current or type(current) ~= "table" then
        -- Optional: print(string.format("getConfigValue: Root configTable is not a table or nil for path %s. Returning default.", table.concat(path, ".")))
        return defaultValue
    end
    for i, key in ipairs(path) do
        if current and type(current) == "table" and current[key] ~= nil then
            current = current[key]
        else
            -- Optional: print(string.format("getConfigValue: Path broken at key '%s' in path %s. Returning default.", tostring(key), table.concat(path, ".")))
            return defaultValue
        end
    end
    return current
end

--- Helper Function: Calculates the overlay panel rectangle based on Config ratios.
-- Relies on global Config (available after conf.lua is processed).
function calculateOverlayPanelRect()
    if not Config or not Config.Screen or not Config.UI then
        print("Error (calculateOverlayPanelRect): Config, Config.Screen, or Config.UI not accessible globally.")
        return { x = 50, y = 50, width = 300, height = 500 } -- Fallback rectangle
    end
    local screenW = Config.Screen.width or 400
    local screenH = Config.Screen.height or 600
    
    local panelXRatio = Config.UI.overlayPanelXRatio or 0.05
    local panelYRatio = Config.UI.overlayPanelYRatio or 0.1
    local panelWidthRatio = Config.UI.overlayPanelWidthRatio or 0.9
    local panelHeightRatio = Config.UI.overlayPanelHeightRatio or 0.8

    local panelX = screenW * panelXRatio
    local panelY = screenH * panelYRatio
    local panelW = screenW * panelWidthRatio
    local panelH = screenH * panelHeightRatio
    
    return { x = panelX, y = panelY, width = panelW, height = panelH }
end

--- Helper Function: Draws the standard overlay background (dimmer) and panel.
-- Relies on global Config.
function drawOverlayBase(panelRect)
    if not love or not love.graphics or not Config or not Config.Screen or not Config.UI or not Config.UI.Colors then
        print("Error (drawOverlayBase): Missing dependencies (love.graphics, Config tables).")
        return
    end
    if not panelRect or type(panelRect.x) ~= "number" then -- Basic validation for panelRect
        print("Error (drawOverlayBase): Invalid panelRect passed.")
        panelRect = { x = 50, y = 50, width = 300, height = 500 } -- Sensible fallback
    end

    local screenW = Config.Screen.width or 800
    local screenH = Config.Screen.height or 600
    local overlayBgColor = Config.UI.Colors.overlayBackground or {0.2, 0.2, 0.2, 0.9}
    local panelBgColor = Config.UI.Colors.overlayPanel or {0.95, 0.95, 1.0, 1}
    local panelCornerRadius = Config.UI.panelCornerRadius or 10

    -- Draw dimming layer
    love.graphics.setColor(overlayBgColor)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Draw overlay panel
    love.graphics.setColor(panelBgColor)
    love.graphics.rectangle("fill", panelRect.x, panelRect.y, panelRect.width, panelRect.height, panelCornerRadius)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

--- Updates card animations (dealing, discarding).
-- Relies on global GameState, Config, and functions within the Dependencies table.
function updateCardAnimations(dt)
    if not GameState or not GameState.hand or not GameState.discardPile then return end
    if not Config or not Config.Animation then print("Warning (updateCardAnimations): Missing Config.Animation."); return end
    if not Dependencies then print("Warning (updateCardAnimations): Global Dependencies table missing."); return end

    local calculateHandLayout = Dependencies.sort and Dependencies.sort.calculateHandLayout
    local lerp = Dependencies.lerp
    local updatePotentialPotion = Dependencies.coreGame and Dependencies.coreGame.updatePotentialPotion
    local drawCardsFromCore = Dependencies.coreGame and Dependencies.coreGame.drawCards

    if not calculateHandLayout then print("Warning (updateCardAnimations): Missing calculateHandLayout in Dependencies.sort"); calculateHandLayout = function() end end
    if not lerp then print("Warning (updateCardAnimations): Missing lerp in Dependencies"); lerp = function(a,b,t) return a+(b-a)*t end end
    if not updatePotentialPotion then print("Warning (updateCardAnimations): Missing updatePotentialPotion in Dependencies.coreGame"); updatePotentialPotion = function() end end
    
    local dealAnimDuration = Config.Animation.dealDuration or 0.3
    local discardAnimDuration = Config.Animation.discardDuration or 0.4
    if type(dealAnimDuration) ~= "number" or dealAnimDuration <= 0 then dealAnimDuration = 0.01 end
    if type(discardAnimDuration) ~= "number" or discardAnimDuration <= 0 then discardAnimDuration = 0.01 end

    local indicesOfCardsToRemove = {}
    local cardsToPotionFinished = 0
    
    for i, card in ipairs(GameState.hand) do
        if type(card) == "table" and card.isAnimating then
            local currentDuration
            if card.isAnimatingToPotion then
                currentDuration = card.animDuration or 0.8 -- Default for potion animation
            elseif card.isDiscarding then
                currentDuration = discardAnimDuration
            else
                currentDuration = dealAnimDuration -- Normal dealing animation
            end
            card.animProgress = math.min(1, (tonumber(card.animProgress) or 0) + dt / currentDuration)
            
            -- Debug output for card animation issues
            if card.animProgress == 0 and not card.isAnimatingToPotion and not card.isDiscarding then
                print("DEBUG: Card starting deal animation:", card.name or "Unknown", "Duration:", currentDuration)
            end
            
            local t = card.animProgress
            
            -- Different easing for different animation types
            if card.isAnimatingToPotion then
                -- Smooth ease-in-out for card-to-potion animation
                t = t * t * (3 - 2 * t)
                
                -- Update magical trail particles
                if card.magicalTrail then
                    card.magicalTrail.lastSpawnTime = card.magicalTrail.lastSpawnTime + dt
                    if card.magicalTrail.lastSpawnTime >= card.magicalTrail.spawnRate then
                        card.magicalTrail.lastSpawnTime = 0
                        
                        -- Add sparkle particle at current card position
                        local particle = {
                            x = card.x + math.random(-10, 10),
                            y = card.y + math.random(-10, 10),
                            vx = math.random(-30, 30),
                            vy = math.random(-50, -10),
                            life = 0.5,
                            maxLife = 0.5,
                            size = math.random(2, 5),
                            color = {
                                card.magicalTrail.color[1] or 1,
                                card.magicalTrail.color[2] or 1,
                                card.magicalTrail.color[3] or 1,
                                1
                            }
                        }
                        table.insert(card.magicalTrail.particles, particle)
                    end
                    
                    -- Update existing particles
                    for j = #card.magicalTrail.particles, 1, -1 do
                        local particle = card.magicalTrail.particles[j]
                        particle.life = particle.life - dt
                        particle.x = particle.x + particle.vx * dt
                        particle.y = particle.y + particle.vy * dt
                        particle.color[4] = particle.life / particle.maxLife -- Fade out
                        
                        if particle.life <= 0 then
                            table.remove(card.magicalTrail.particles, j)
                        end
                    end
                end
            elseif card.isDiscarding then
                t = t * t -- Ease-in for discard
            else
                t = t * (2 - t) -- Ease-out for deal
            end

            card.x = lerp(card.startX or card.x, card.targetX or card.x, t)
            card.y = lerp(card.startY or card.y, card.targetY or card.y, t)
            card.rotation = lerp(card.startRotation or 0, card.targetRotation or 0, t)
            card.scale = lerp(card.startScale or 1, card.targetScale or 1, t)

            -- Update transformation effects during the last part of the animation
            if card.isAnimatingToPotion and card.animProgress > 0.7 then
                local transformProgress = (card.animProgress - 0.7) / 0.3 -- Transform during last 30% of animation
                card.dissolveIntensity = transformProgress
                card.glowIntensity = 1 - transformProgress
            end

            if card.animProgress >= 1 then
                card.isAnimating = false
                card.animProgress = 0
                card.x, card.y, card.rotation, card.scale = card.targetX, card.targetY, card.targetRotation, card.targetScale
                card.startX, card.startY, card.startRotation, card.startScale = nil, nil, nil, nil

                if card.isDiscarding then
                    table.insert(indicesOfCardsToRemove, i)
                elseif card.isAnimatingToPotion then
                    -- Card has reached the potion bottle
                    card.isAnimatingToPotion = false
                    card.magicalTrail = nil -- Clean up trail data
                    card.dissolveIntensity = nil -- Clean up transformation data
                    card.glowIntensity = nil
                    table.insert(indicesOfCardsToRemove, i) -- Remove from hand
                    cardsToPotionFinished = cardsToPotionFinished + 1
                end
            end
        end
        
        -- Update spell sparkle effects
        if card.spellSparkleEffect then
            card.spellSparkleEffect.timer = card.spellSparkleEffect.timer + dt
            
            -- Calculate sparkle intensity (fade out over time)
            local progress = card.spellSparkleEffect.timer / card.spellSparkleEffect.duration
            card.spellSparkleEffect.intensity = math.max(0, 1 - progress)
            
            -- Remove effect when finished
            if progress >= 1 then
                card.spellSparkleEffect = nil
            end
        end
    end

    if #indicesOfCardsToRemove > 0 then
        local numActuallyRemovedFromHand = #indicesOfCardsToRemove
        table.sort(indicesOfCardsToRemove, function(a,b) return a > b end) -- Sort high to low for safe removal

        for _, indexToRemove in ipairs(indicesOfCardsToRemove) do
            if indexToRemove >= 1 and indexToRemove <= #GameState.hand then
                local removedCard = table.remove(GameState.hand, indexToRemove)
                if removedCard and type(removedCard) == "table" then
                    removedCard.isHighlighted, removedCard.isAnimating, removedCard.isDiscarding = false, false, false
                    removedCard.isAnimatingToPotion = false
                    removedCard.animProgress, removedCard.scale = 0, 1
                    removedCard.targetX, removedCard.targetY, removedCard.targetRotation, removedCard.targetScale = 0,0,0,1
                    removedCard.x, removedCard.y, removedCard.rotation = 0,0,0
                    
                    -- Clean up transformation properties
                    removedCard.dissolveIntensity = nil
                    removedCard.glowIntensity = nil
                    removedCard.magicalTrail = nil
                    
                    table.insert(GameState.discardPile, removedCard)
                end
            end
        end
        
        calculateHandLayout(GameState, Config)
        updatePotentialPotion(GameState, Dependencies)

        if GameState.isWaitingForDiscard then
            GameState.discardAnimCounter = math.max(0, (tonumber(GameState.discardAnimCounter) or 0) - numActuallyRemovedFromHand)
            if GameState.discardAnimCounter <= 0 then
                local numReplacements = GameState.numReplacementsToDraw or 0
                GameState.isWaitingForDiscard = false
                GameState.numReplacementsToDraw = 0
                GameState.discardAnimCounter = 0
                
                -- Set game phase back to "playing" after discard animation completes
                if GameState.gamePhase ~= "game_over" and GameState.gamePhase ~= "shop" then
                    GameState.gamePhase = "playing"
                    print("Discard animation completed, game phase set to 'playing'")
                end
                
                if numReplacements > 0 then
                    print("DEBUG: Drawing replacement cards to reach target hand size")
                    if Dependencies.coreGame and Dependencies.coreGame.drawReplacements then
                        -- Use drawReplacements which automatically calculates how many cards are needed
                        Dependencies.coreGame.drawReplacements(GameState, Config, Dependencies)
                        print("DEBUG: Replacement cards drawn. New hand size:", #GameState.hand)
                    else
                        print("Error (updateCardAnimations): CoreGame.drawReplacements missing from Dependencies! Cannot draw replacements.")
                    end
                end
            end
        end
    end
    
    -- Handle card-to-potion animation completion
    if GameState.potionAnimationState and GameState.potionAnimationState.isAnimatingCardsToPotionBottle then
        GameState.potionAnimationState.cardsAnimatingCount = GameState.potionAnimationState.cardsAnimatingCount - cardsToPotionFinished
        
        if cardsToPotionFinished > 0 then
            print("DEBUG: Cards finished animating to potion:", cardsToPotionFinished, "Remaining:", GameState.potionAnimationState.cardsAnimatingCount)
        end
        
        if GameState.potionAnimationState.cardsAnimatingCount <= 0 then
            print("All cards have reached the potion bottle! Starting potion fill animation...")
            
            -- Clear selected card indices and update game state
            GameState.selectedCardIndices = {}
            Dependencies.coreGame.recalculateCurrentScore(GameState)
            Dependencies.coreGame.updatePotentialPotion(GameState, Dependencies)
            
            -- Start potion fill animation
            local potionResult = GameState.potionAnimationState.potionResult
            local deps = GameState.potionAnimationState.dependencies
            
            print("DEBUG: potionResult =", potionResult and potionResult.name or "nil")
            print("DEBUG: GameState.pendingPotionChoice =", GameState.pendingPotionChoice and GameState.pendingPotionChoice.name or "nil")
            
            if Dependencies.coreGame.animatePotionFill then
                Dependencies.coreGame.animatePotionFill(GameState, Config, potionResult, deps)
            end
            
            -- Transition to potion decision phase
            GameState.gamePhase = "potion_decision"
            print("Phase: potion_decision")
            print("DEBUG: About to show potionDecision overlay")
            if Dependencies.overlayManager then
                Dependencies.overlayManager:show("potionDecision")
                print("DEBUG: Called overlayManager:show('potionDecision')")
            else
                print("ERROR: Dependencies.overlayManager is nil!")
            end
            
            -- Clean up animation state
            GameState.potionAnimationState = nil
        end
    end
end

function getAnchoredPosition(parentX, parentY, parentW, parentH, elementW, elementH, anchorX, anchorY, offsetX, offsetY)
    parentX = tonumber(parentX) or 0; parentY = tonumber(parentY) or 0
    parentW = tonumber(parentW) or 0; parentH = tonumber(parentH) or 0
    elementW = tonumber(elementW) or 0; elementH = tonumber(elementH) or 0
    anchorX = tonumber(anchorX) or 0; anchorY = tonumber(anchorY) or 0
    offsetX = tonumber(offsetX) or 0; offsetY = tonumber(offsetY) or 0

    local anchorPointX = parentX + parentW * anchorX
    local anchorPointY = parentY + parentH * anchorY
    
    local finalElementX = anchorPointX - (elementW * anchorX) + offsetX
    local finalElementY = anchorPointY - (elementH * anchorY) + offsetY
    
    return finalElementX, finalElementY
end

function isPointInRect(x, y, rect)
    if not rect or type(x) ~= "number" or type(y) ~= "number" or 
       type(rect.x) ~= "number" or type(rect.y) ~= "number" or 
       type(rect.width) ~= "number" or type(rect.height) ~= "number" then
        return false
    end
    return x >= rect.x and x <= rect.x + rect.width and 
           y >= rect.y and y <= rect.y + rect.height
end

function shallowcopy(original)
    if type(original) ~= 'table' then return original end
    local copy = {}
    for key, value in pairs(original) do copy[key] = value end
    return copy
end

local uniqueIDCounter = 1 
function generateUniqueID() 
    local id = uniqueIDCounter
    uniqueIDCounter = uniqueIDCounter + 1
    return "GeneratedID_" .. id 
end

function updateScale()
    if not love or not love.graphics or not Config or not Config.Screen or not RenderState then return end
    
    local actualW, actualH = love.graphics.getDimensions()
    local virtualW = Config.Screen.width
    local virtualH = Config.Screen.height

    if type(virtualW) ~= "number" or type(virtualH) ~= "number" or virtualW <= 0 or virtualH <= 0 then
        print("Error (updateScale): Invalid virtual screen dimensions in Config.")
        RenderState.scale, RenderState.offsetX, RenderState.offsetY = 1, 0, 0
        return
    end

    local scaleX = actualW / virtualW
    local scaleY = actualH / virtualH
    RenderState.scale = math.min(scaleX, scaleY)
    if RenderState.scale <= 0 then RenderState.scale = 1 end

    local scaledCanvasW = virtualW * RenderState.scale
    local scaledCanvasH = virtualH * RenderState.scale
    RenderState.offsetX = (actualW - scaledCanvasW) / 2
    RenderState.offsetY = (actualH - scaledCanvasH) / 2
end

function translateMouseCoords(screenX, screenY)
    if not RenderState or type(RenderState.scale) ~= "number" or RenderState.scale == 0 then
        return screenX, screenY 
    end
    local virtualX = (screenX - RenderState.offsetX) / RenderState.scale
    local virtualY = (screenY - RenderState.offsetY) / RenderState.scale
    return virtualX, virtualY
end

function lerp(a, b, t) 
    return a + (b - a) * t 
end

-- =============================================================================
-- Require Modules & Components
-- =============================================================================
print("Loading modules...")
local CoreGameData          = require("core_game")
local CoreGame              = CoreGameData -- This table holds functions AND data definitions
local Draw                  = require("draw")
local Handlers              = require("handlers")
local Sort                  = require("sort")
local BubbleManager         = require("bubbles")
local inspect               = require("inspect") -- Utility for pretty printing tables

-- UI Components
local Button                = require("ui.button")
local OverlayManager        = require("ui.overlay_manager")
local PotionListOverlay     = require("ui.potion_list_overlay")
local DeckViewOverlay       = require("ui.deck_view_overlay")
local ShopOverlay           = require("ui.shop_overlay")
local PotionDecisionOverlay = require("ui.potion_decision_overlay")
 local SpellSelectionOverlay = require("ui.spell_selection_overlay")
 local GameOverOverlay    = require("ui.game_over_overlay")
print("Modules loaded.")

Dependencies = {} -- Global Dependencies Table, populated in love.load

-- =============================================================================
-- LÖVE Callbacks
-- =============================================================================
function love.load()
    print("--- Checking LÖVE Version ---")
    print("LÖVE Version:", love.getVersion())
    print("-----------------------------")
    print("love.load executing...")

    -- Initialize globals from conf.lua if not already done (they should be)
    if not Config then error("CRITICAL ERROR: Config table not loaded from conf.lua!") end
    love.graphics.setBackgroundColor(Config.UI.Colors.background or {0.85,0.95,1})
    math.randomseed(os.time())
    if not GameState then GameState = {} end 
    GameState.gamePhase = "loading"
    if not RenderState then RenderState = {} end

    -- Populate Dependencies Table
    print("Populating dependencies table...")
    Dependencies.config = Config
    Dependencies.gameState = GameState
    Dependencies.renderState = RenderState
    Dependencies.coreGame = CoreGame             -- Provides CoreGame functions
    Dependencies.draw = Draw
    Dependencies.handlers = Handlers
    Dependencies.sort = Sort
    Dependencies.bubbleManager = BubbleManager
    Dependencies.overlayManager = OverlayManager -- The module/singleton itself
    Dependencies.ButtonClass = Button            -- The Button class/constructor
    Dependencies.inspect = inspect               -- The inspect function
    Dependencies.shallowcopy = shallowcopy       -- Global helper
    Dependencies.lerp = lerp                     -- Global helper
    Dependencies.getAnchoredPosition = getAnchoredPosition -- Global helper
    Dependencies.isPointInRect = isPointInRect             -- Global helper
    Dependencies.translateMouseCoords = translateMouseCoords -- Global helper
    Dependencies.updateScale = updateScale                   -- Global helper
    Dependencies.calculateOverlayPanelRect = calculateOverlayPanelRect -- Global helper
    Dependencies.drawOverlayBase = drawOverlayBase             -- Global helper
    Dependencies.uiState = UIState               -- Global table for main screen UI elements
    Dependencies.getConfigValue = getConfigValue -- Global helper

    -- Populate data definitions into Dependencies from CoreGameData
    Dependencies.cardDefinitions = CoreGameData.cardDefinitions or {}
    Dependencies.potionRecipes = CoreGameData.PotionRecipes or {}
    Dependencies.roundsData = CoreGameData.RoundsData or {} -- Base 10 rounds
    Dependencies.spellDefinitions = CoreGameData.SpellDefinitions or {}
    Dependencies.spellbookDefinitions = CoreGameData.SpellbookDefinitions or {}
    Dependencies.energyElixirDefinitions = CoreGameData.EnergyElixirDefinitions or {}

    Dependencies.cardDefLookup = {}
    if Dependencies.cardDefinitions then
        for _, defEntry in ipairs(Dependencies.cardDefinitions) do
            if defEntry and defEntry.data and defEntry.data.id then
                -- Create a complete card definition that includes objectColor
                local completeDef = {}
                for k, v in pairs(defEntry.data) do
                    completeDef[k] = v
                end
                -- Ensure objectColor is preserved
                if defEntry.data.objectColor then
                    completeDef.objectColor = defEntry.data.objectColor
                end
                Dependencies.cardDefLookup[defEntry.data.id] = completeDef
            end
        end
    end
    do 
        local count = 0; if Dependencies.cardDefLookup then for _ in pairs(Dependencies.cardDefLookup) do count = count + 1 end end
        print("CardDefLookup populated. Count:", count)
    end

    Dependencies.getCardDefinitionById = CoreGame.getCardDefinitionById
    Dependencies.createCard = CoreGame.createCardInstance      
    Dependencies.getGoalProgressString = CoreGame.getGoalProgressString
    Dependencies.consumeEnergyElixir = CoreGame.consumeEnergyElixir

    -- Setup Theme table for UI components
 Dependencies.theme = {
        fonts = {}, 
        colors = Config.UI.Colors or {},
        layout = Config.Layout or {},
        sizes = Config.UI or {}, 
        cornerRadius = Config.UI or {}, 
        bubbleConfigData = Config.Bubble or {},
        scrollConfig = Config.UI.Scrolling or {}, -- Add scrolling configuration to theme
        helpers = {
            calculateOverlayPanelRect = calculateOverlayPanelRect,
            drawOverlayBase = drawOverlayBase,
            isPointInRect = isPointInRect,
            drawCardIcon = function(x, y, cardDef, options, iconW, iconH, themeArg_unused)
                -- The themeArg_unused is self.theme from the overlay.
                -- Draw.drawCardIcon expects config and dependencies directly.
                Draw.drawCardIcon(x, y, cardDef, options, iconW, iconH, Config, Dependencies)
            end,
            drawPlaceholderIcon = nil, 
            drawPotionBottle = function(x, y, bottleType, fillColor, fillLevel, theme_arg_from_overlay)
                -- theme_arg_from_overlay is effectively self.theme of the calling overlay, which IS Dependencies.theme.
                -- The actual Draw.drawPotionBottle function now expects gameState, config, dependencies.
                -- The GameState, Config, and Dependencies should be directly accessible globally here
                -- or better yet, ensure Dependencies are fully formed when this closure is made.
                -- Since this is in love.load, GameState, Config, Dependencies globals are set.
                Draw.drawPotionBottle(x, y, bottleType, fillColor, fillLevel, GameState, Config, Dependencies)
            end,
            inspect = Dependencies.inspect 
        }
    }
    print("Theme table created. Inspect helper included:", type(Dependencies.theme.helpers.inspect) == "function")
    -- Load Fonts
    print("Loading fonts...")
    local defaultSystemFont = love.graphics.getFont()
    if not defaultSystemFont then error("CRITICAL: Failed to get default system font!") end
    Dependencies.theme.fonts.default = defaultSystemFont
    local fontSuccess
    fontSuccess, Dependencies.theme.fonts.large = pcall(love.graphics.newFont, 24); if not fontSuccess then Dependencies.theme.fonts.large = defaultSystemFont end
    fontSuccess, Dependencies.theme.fonts.ui = pcall(love.graphics.newFont, 16);   if not fontSuccess then Dependencies.theme.fonts.ui = defaultSystemFont end
    fontSuccess, Dependencies.theme.fonts.small = pcall(love.graphics.newFont, 14); if not fontSuccess then Dependencies.theme.fonts.small = defaultSystemFont end
    print("Fonts loaded.")
    
    -- Print game controls
    print("=== GAME CONTROLS ===")
    print("Keyboard Controls:")
    print("Escape - Exit spell casting mode")
    print("R - Reset game (debug)")
    print("")
    print("Touch Controls:")
    print("Main action buttons available in UI")
    print("=====================")

    -- Setup Action Dispatch Tables for UI elements
    Dependencies.potionActions = {
        drink = function() CoreGame.drinkPotion(GameState, Config, Dependencies) end,
        sell  = function() CoreGame.sellPotion(GameState, Config, Dependencies) end
    }
    Dependencies.shopActions = {
        buy      = function(itemIndex) CoreGame.buyShopItem(GameState, Dependencies, itemIndex) end,
        refresh  = function() CoreGame.refreshShop(GameState, Dependencies) end,
        endPhase = function() CoreGame.endShoppingPhase(GameState, Dependencies) end
    }
    Dependencies.spellActions = {
        select = function(spellId, spellData, targetData)
            if spellData.target and spellData.target ~= "none" then
                if targetData and targetData.handIndex then
                    -- Direct target provided (from card selection), apply spell immediately
                    
                    -- Add sparkle effect to the targeted card before casting
                    if GameState.hand and GameState.hand[targetData.handIndex] then
                        local targetCard = GameState.hand[targetData.handIndex]
                        targetCard.spellSparkleEffect = {
                            duration = 3.0, -- 3 second sparkle effect (increased for more prominence)
                            timer = 0,
                            intensity = 1.0
                        }
                        -- Deselect the card visually (remove highlight and move back to row)
                        targetCard.isHighlighted = false
                    end
                    
                    CoreGame.applySpellEffect(GameState, Dependencies, spellId, targetData)
                    GameState.spellCastingMode = false
                    GameState.selectedSpellId = nil
                    GameState.selectedCardIndices = {}
                    
                    -- Recalculate hand layout to move cards back to normal positions
                    if Dependencies.sort and Dependencies.sort.calculateHandLayout then
                        Dependencies.sort.calculateHandLayout(GameState, Dependencies.config)
                    end
                else
                    -- Fall back to old targeting system for non-hand_card targets
                    GameState.selectedSpellId = spellId
                    GameState.selectingSpellTarget = true
                    if OverlayManager then OverlayManager:hide() end -- Hide selection UI to allow targeting
                end
            else
                CoreGame.applySpellEffect(GameState, Dependencies, spellId) -- No target needed
                GameState.spellCastingMode = false
                GameState.selectedSpellId = nil
                if OverlayManager then OverlayManager:hide() end
            end
        end,
        cancel = function()
            GameState.selectedSpellId = nil
            GameState.selectingSpellTarget = false
            GameState.spellCastingMode = false
            GameState.selectedCardIndices = {}
            if OverlayManager then OverlayManager:hide() end
        end
    }
    Dependencies.recipeProvider = {
        getRecipes = function()
            -- Derive recipe list from PotionCombinationEffects and card families/subtypes
            local recipes = {}
            local PCE = CoreGame.PotionCombinationEffects or {}
            
            -- Type matches (by card ID) - Primary recipes
            if PCE.typeMatches then
                for k,v in pairs(PCE.typeMatches) do
                    local setSize = tonumber(k) or 2
                    local setDesc = ""
                    if setSize == 2 then setDesc = "Two cards with same name"
                    elseif setSize == 3 then setDesc = "Three cards with same name"
                    elseif setSize == 4 then setDesc = "Four cards with same name"
                    elseif setSize == 5 then setDesc = "Five cards with same name"
                    elseif setSize == 6 then setDesc = "Six cards with same name"
                    elseif setSize == 7 then setDesc = "Seven cards with same name"
                    else setDesc = string.format("%d cards with same name", setSize)
                    end
                    
                    table.insert(recipes, { 
                        name = v.name, 
                        requirementsDesc = setDesc .. " (Bonus: +5 if all same type, +10 if all same subtype)", 
                        drinkPoints = v.baseScore,
                        saleMoney = v.baseMoney,
                        drinkEffect = v.drinkEffect,
                        exampleIcons = {
                            { type = "set", name = "Rose", count = setSize }
                        }
                    })
                end
            end
            
            -- Value matches (by card value) - Primary recipes
            if PCE.valueMatches then
                for k,v in pairs(PCE.valueMatches) do
                    local setSize = tonumber(k) or 2
                    local setDesc = ""
                    if setSize == 2 then setDesc = "Two cards with same value"
                    elseif setSize == 3 then setDesc = "Three cards with same value"
                    elseif setSize == 4 then setDesc = "Four cards with same value"
                    elseif setSize == 5 then setDesc = "Five cards with same value"
                    elseif setSize == 6 then setDesc = "Six cards with same value"
                    elseif setSize == 7 then setDesc = "Seven cards with same value"
                    else setDesc = string.format("%d cards with same value", setSize)
                    end
                    
                    table.insert(recipes, { 
                        name = v.name, 
                        requirementsDesc = setDesc .. " (Bonus: +5 if all same type, +10 if all same subtype)", 
                        drinkPoints = v.baseScore,
                        saleMoney = v.baseMoney,
                        drinkEffect = v.drinkEffect,
                        exampleIcons = {
                            { type = "value", name = "3", count = setSize }
                        }
                    })
                end
            end
            
            -- Compute saleValue when possible
            for _,r in ipairs(recipes) do
                local sM = tonumber(r.saleMoney) or 0
                r.saleValue = sM
            end
            return recipes
        end
    }
    Dependencies.cardDatabase = {
        getDefinition = function(self, id)
            print(string.format("[CardDatabase:getDefinition] Called with id: %s (type: %s)", tostring(id), type(id))) -- DEBUG
            local def = CoreGame.getCardDefinitionById(id, Dependencies)
            if not def then
                print(string.format("[CardDatabase:getDefinition] No definition found for ID: %s", tostring(id)))
            elseif not def.name then
                local inspectPrint = Dependencies.inspect and Dependencies.inspect(def) or "Inspect unavailable"
                print(string.format("[CardDatabase:getDefinition] Definition for ID %s MISSING NAME. Def: %s", tostring(id), inspectPrint))
            end
            return def
        end,
        drawIcon = function(x, y, cardDefData, options, iconW, iconH, themeArg_unused) 
            Draw.drawCardIcon(x, y, cardDefData, options, iconW, iconH, Config, Dependencies) 
        end
    }
    print("Action/Provider dependencies created.")

    -- Initialize OverlayManager
    print("Initializing OverlayManager...")
    local overlayClassesToRegister = {
        potionList       = PotionListOverlay,
        deckView         = DeckViewOverlay,
        shop             = ShopOverlay,
        potionDecision   = PotionDecisionOverlay,
        spellSelection   = SpellSelectionOverlay,
        gameOver         = GameOverOverlay
    }
    -- Debug: Check what's in Dependencies.cardDatabase before passing to overlay manager
    print(string.format("[main.lua] Dependencies.cardDatabase type: %s", type(Dependencies.cardDatabase)))
    print(string.format("[main.lua] Dependencies.cardDatabase value: %s", tostring(Dependencies.cardDatabase)))
    print(string.format("[main.lua] Dependencies.cardDatabase.getDefinition type: %s", type(Dependencies.cardDatabase and Dependencies.cardDatabase.getDefinition)))
    
    local overlayManagerInitConfig = {
        overlayClasses = overlayClassesToRegister,
        sharedDependencies = Dependencies 
    }
    Dependencies.uiManager = OverlayManager -- Ensure uiManager is available before init if OverlayManager needs it.
                                         -- OverlayManager:init will set sharedDependencies.uiManager = self (the manager instance).
    if OverlayManager and OverlayManager.init then
        OverlayManager:init(overlayManagerInitConfig)
    else
        error("CRITICAL: OverlayManager module or its :init() function is nil.")
    end
    do
        local instantiatedCount = 0
        if OverlayManager.overlays then for _ in pairs(OverlayManager.overlays) do instantiatedCount = instantiatedCount + 1 end end
        print("OverlayManager initialization complete. Instantiated overlay count:", instantiatedCount)
    end
    
    -- Calculate UI Regions and Main Screen Button Positions with modern spacing
    if not UIState then UIState = { Regions = {}, Buttons = {} } end
    UIState.Regions = {}
    UIState.Buttons = {}

    print("Calculating UI Regions...")
    local sW, sH = Config.Screen.width, Config.Screen.height
    -- Use new spacing system
    local spacingS, spacingM, spacingL = Config.Layout.spacingS or 8, Config.Layout.spacingM or 16, Config.Layout.spacingL or 24
    local uiFnt = Dependencies.theme.fonts.ui or Dependencies.theme.fonts.default
    local uiLineH = uiFnt:getHeight()
    local currentY = 0

    local goalConf = Config.UI.goalDisplay or {}
    UIState.Regions.Goal = { x=spacingM, y=spacingS, width=sW-2*spacingM, height=goalConf.height or 80 }; currentY = UIState.Regions.Goal.y+UIState.Regions.Goal.height+spacingM
    UIState.Regions.TopBar={x=0,y=currentY+20,width=sW,height=(Config.UI.sortButton.height or 36)}; currentY=UIState.Regions.TopBar.y+UIState.Regions.TopBar.height+spacingM
    UIState.Regions.InfoArea={x=0,y=currentY,width=sW,height=(uiLineH*2)+spacingM}; currentY=UIState.Regions.InfoArea.y+UIState.Regions.InfoArea.height+spacingM
    local pAreaCfg=Config.UI.potionDisplayArea or {}; local pAreaW=sW*0.8; local pAreaX=(sW-pAreaW)/2
    UIState.Regions.PotionArea={x=pAreaX,y=currentY,width=pAreaW,height=pAreaCfg.height or 140}; currentY=UIState.Regions.PotionArea.y+UIState.Regions.PotionArea.height+spacingM
    local potPCfg=Config.UI.potentialPotionDisplay or {}; local potPW=potPCfg.width or 300; local potPH=potPCfg.height or 75; local potPX=(sW-potPW)/2
    -- Move potential potion display higher up with extra spacing from hand area
    UIState.Regions.PotentialPotionArea={x=potPX,y=currentY-140,width=potPW,height=potPH}; currentY=UIState.Regions.PotentialPotionArea.y+UIState.Regions.PotentialPotionArea.height+spacingM*2
    local btmBtnH=(Config.UI.discardButton.height or 48); local btmBtnPY=(Config.UI.discardButton.padding or spacingM)
    UIState.Regions.BottomBar={x=0,y=sH-btmBtnH-btmBtnPY,width=sW,height=btmBtnH}
    Config.Layout.handBaseY=currentY+20; UIState.Regions.HandArea={x=0,y=Config.Layout.handBaseY-(Config.Layout.handArcDepth or 0),width=sW,height=(UIState.Regions.BottomBar.y-spacingM)-(Config.Layout.handBaseY-(Config.Layout.handArcDepth or 0))}
    
    -- Update Config with absolute positions if any drawing functions rely on these directly (should ideally use regions from UIState)
    Config.UI.goalDisplay.x = UIState.Regions.Goal.x; Config.UI.goalDisplay.y = UIState.Regions.Goal.y; Config.UI.goalDisplay.width = UIState.Regions.Goal.width
    Config.UI.potionDisplayArea.x = UIState.Regions.PotionArea.x; Config.UI.potionDisplayArea.y = UIState.Regions.PotionArea.y;
    Config.UI.potentialPotionDisplay.x = UIState.Regions.PotentialPotionArea.x; Config.UI.potentialPotionDisplay.y = UIState.Regions.PotentialPotionArea.y
    print("UI Regions Calculated.")

    print("Calculating initial button and UI element positions...")
    local topBarR, btmBarR, infoAreaR = UIState.Regions.TopBar, UIState.Regions.BottomBar, UIState.Regions.InfoArea
    local bLC, bSC, bDC = Config.UI.potionListButton, Config.UI.sortButton, Config.UI.deckViewButton
    local bDiC, bPC, bSpC = Config.UI.discardButton, Config.UI.makePotionButton, Config.UI.castSpellButton
    local bListX,bListY=getAnchoredPosition(topBarR.x,topBarR.y,topBarR.width,topBarR.height,bLC.width,bLC.height,0,0.5,spacingM,0)
    local bSortX,bSortY=getAnchoredPosition(topBarR.x,topBarR.y,topBarR.width,topBarR.height,bSC.width,bSC.height,0.5,0.5,0,0)
    local bDeckX,bDeckY=getAnchoredPosition(topBarR.x,topBarR.y,topBarR.width,topBarR.height,bDC.width,bDC.height,1,0.5,-spacingM,0)
    _,Config.UI.CountInfoY=getAnchoredPosition(infoAreaR.x,infoAreaR.y,infoAreaR.width,infoAreaR.height,0,uiLineH,0,0,0,spacingS)
    Config.UI.ScoreInfoY=Config.UI.CountInfoY+uiLineH+spacingS
    Config.Animation.deckDrawX,Config.Animation.deckDrawY=getAnchoredPosition(0,0,sW,sH,Config.Card.width,Config.Card.height,1,0,-spacingM,spacingM)
    local totalBtmW=bPC.width+bSpC.width+bDiC.width+(2*spacingM); local startBtmX=(sW-totalBtmW)/2
    local bPotX,bPotY=startBtmX, btmBarR.y+(btmBarR.height-bPC.height)/2
    local bSpX,bSpY=bPotX+bPC.width+spacingM, btmBarR.y+(btmBarR.height-bSpC.height)/2
    local bDiX,bDiY=bSpX+bSpC.width+spacingM, btmBarR.y+(btmBarR.height-bDiC.height)/2
    print("Initial button and UI element positions calculated.")

    print("Creating main UI buttons...")
    local sortModeName=(GameState.sortModes and GameState.sortModes[GameState.currentSortModeIndex or 1])or"default"; local capSortMode="Default"
    if type(sortModeName)=="string" and #sortModeName>0 then capSortMode=sortModeName:sub(1,1):upper()..sortModeName:sub(2) end
    local btnDefs={defaultFont=Dependencies.theme.fonts.ui,defaultCornerRadius=Dependencies.getConfigValue(Config,{"UI","cornerRadius"},5),defaultColors=Dependencies.theme.colors}
    
    UIState.Buttons={
        discard=Button:new({id="discard",x=bDiX,y=bDiY,width=bDiC.width,height=bDiC.height,label=bDiC.label,colors={normal=btnDefs.defaultColors.buttonDiscardActive},onClick=function()CoreGame.discardSelectedCards(GameState,Config,Dependencies)end,defaultFont=btnDefs.defaultFont,defaultCornerRadius=btnDefs.defaultCornerRadius,defaultColors=btnDefs.defaultColors}),
        makePotion=Button:new({id="makePotion",x=bPotX,y=bPotY,width=bPC.width,height=bPC.height,label=bPC.label,colors={normal=btnDefs.defaultColors.buttonPotionActive},onClick=function()CoreGame.tryMakePotion(GameState,Config,Dependencies)end,defaultFont=btnDefs.defaultFont,defaultCornerRadius=btnDefs.defaultCornerRadius,defaultColors=btnDefs.defaultColors}),
        castSpell=Button:new({id="castSpell",x=bSpX,y=bSpY,width=bSpC.width,height=bSpC.height,label=bSpC.label,colors={normal=btnDefs.defaultColors.buttonSpellActive},onClick=function()OverlayManager:show("spellSelection")end,defaultFont=btnDefs.defaultFont,defaultCornerRadius=btnDefs.defaultCornerRadius,defaultColors=btnDefs.defaultColors}),
        sortToggle=Button:new({id="sortToggle",x=bSortX,y=bSortY,width=bSC.width,height=bSC.height,label=(bSC.label or "Sort: ")..capSortMode,colors={normal=btnDefs.defaultColors.buttonSortActive},onClick=function()Sort.toggleSortMode(GameState,Config,Dependencies)end,defaultFont=btnDefs.defaultFont,defaultCornerRadius=btnDefs.defaultCornerRadius,defaultColors=btnDefs.defaultColors}),
        potionList=Button:new({id="potionList",x=bListX,y=bListY,width=bLC.width,height=bLC.height,label=bLC.label,colors={normal=btnDefs.defaultColors.buttonRecipeActive},onClick=function()OverlayManager:show("potionList")end,defaultFont=btnDefs.defaultFont,defaultCornerRadius=btnDefs.defaultCornerRadius,defaultColors=btnDefs.defaultColors}),
        deckView=Button:new({id="deckView",x=bDeckX,y=bDeckY,width=bDC.width,height=bDC.height,label=bDC.label,colors={normal=btnDefs.defaultColors.buttonDeckViewActive},onClick=function()OverlayManager:show("deckView")end,defaultFont=btnDefs.defaultFont,defaultCornerRadius=btnDefs.defaultCornerRadius,defaultColors=btnDefs.defaultColors}),
    }
    print("Main UI buttons created.")

    print("Creating game canvas...")
    GameCanvas = love.graphics.newCanvas(Config.Screen.width, Config.Screen.height)
    if not GameCanvas then error("CRITICAL: Failed to create GameCanvas!") end
    GameCanvas:setFilter("linear", "linear")
    print("Game canvas created: " .. Config.Screen.width .. "x" .. Config.Screen.height)
    
    updateScale() 
    print("Initial rendering scale calculated.")

    print("Setting up initial game board...")
    CoreGame.resetGame(GameState, Config, Dependencies) 
    print("Initial game board set up (resetGame calls startNextRound, which draws initial hand).")
    
    -- Further state updates after initial hand draw by resetGame/startNextRound
    if Dependencies.sort.calculateHandLayout then Dependencies.sort.calculateHandLayout(GameState,Config) end
    if CoreGame.recalculateCurrentScore then CoreGame.recalculateCurrentScore(GameState) end -- Score from selected cards
    if CoreGame.updatePotentialPotion then CoreGame.updatePotentialPotion(GameState,Dependencies) end
    if BubbleManager.setup then BubbleManager.setup(GameState.potionDisplay) end
    
    -- GameState.gamePhase should be 'playing' after resetGame -> startNextRound
    print("LÖVE load complete. Final game phase: " .. GameState.gamePhase)
end

function love.resize(w, h)
    print("Window resized to:", w, "x", h)
    if Dependencies and Dependencies.updateScale then
        Dependencies.updateScale()
    else
        updateScale() -- Fallback if Dependencies not fully populated yet (less likely for resize)
    end
end

function love.update(dt)
    -- Guard clause for critical missing dependencies
    if not GameState or not Config or not UIState or not OverlayManager or not RenderState or not Dependencies then
        return
    end

    -- Update virtual mouse coordinates
    local screenMouseX, screenMouseY = love.mouse.getPosition()
    GameState.mouse.x, GameState.mouse.y = Dependencies.translateMouseCoords(screenMouseX, screenMouseY)

    -- Update potion fill animation with magical effects
    if GameState.potionDisplay and GameState.potionDisplay.isAnimatingFill then
        local fillDuration = Config.Animation.potionFillDuration or 0.8
        if fillDuration <= 0 then fillDuration = 0.01 end 

        GameState.potionDisplay.animProgress = math.min(1, (GameState.potionDisplay.animProgress or 0) + dt / fillDuration)
        local t = GameState.potionDisplay.animProgress; t = t * (2 - t) -- Ease-out
        local targetFill = GameState.potionDisplay.targetFillLevel or 1
        GameState.potionDisplay.fillLevel = Dependencies.lerp(0, targetFill, t)

        -- Update magical effects during fill animation
        if GameState.potionDisplay.magicalEffects then
            local effects = GameState.potionDisplay.magicalEffects
            
            -- Update glow pulse
            effects.glowPulse = effects.glowPulse + dt * 4
            effects.colorShift = effects.colorShift + dt * 2
            
            -- Update swirls
            for i = #effects.swirls, 1, -1 do
                local swirl = effects.swirls[i]
                swirl.angle = swirl.angle + swirl.speed * swirl.direction * dt
                swirl.life = swirl.life - dt * 0.5
                swirl.color[4] = swirl.life / swirl.maxLife * 0.7
                
                if swirl.life <= 0 then
                    table.remove(effects.swirls, i)
                end
            end
            
            -- Spawn new swirls periodically
            effects.lastSwirlTime = effects.lastSwirlTime + dt
            if effects.lastSwirlTime >= 0.3 and #effects.swirls < 5 then
                effects.lastSwirlTime = 0
                local newSwirl = {
                    angle = math.random() * math.pi * 2,
                    radius = 8 + math.random() * 12,
                    speed = 1.5 + math.random() * 2.5,
                    life = 0.8 + math.random() * 0.4,
                    maxLife = 0.8 + math.random() * 0.4,
                    direction = (math.random() > 0.5) and 1 or -1,
                    color = {
                        GameState.potionDisplay.fillColor[1] or 0.5,
                        GameState.potionDisplay.fillColor[2] or 0.5,
                        GameState.potionDisplay.fillColor[3] or 0.5,
                        0.7
                    }
                }
                table.insert(effects.swirls, newSwirl)
            end
            
            -- Update sparkles
            for i = #effects.sparkles, 1, -1 do
                local sparkle = effects.sparkles[i]
                sparkle.x = sparkle.x + sparkle.vx * dt
                sparkle.y = sparkle.y + sparkle.vy * dt
                sparkle.life = sparkle.life - dt
                sparkle.color[4] = sparkle.life / sparkle.maxLife
                
                if sparkle.life <= 0 then
                    table.remove(effects.sparkles, i)
                end
            end
            
            -- Spawn new sparkles
            effects.lastSparkleTime = effects.lastSparkleTime + dt
            if effects.lastSparkleTime >= 0.1 then
                effects.lastSparkleTime = 0
                local sparkle = {
                    x = math.random(-25, 25),
                    y = math.random(-30, 10),
                    vx = math.random(-20, 20),
                    vy = math.random(-40, -10),
                    life = 0.5 + math.random() * 0.3,
                    maxLife = 0.5 + math.random() * 0.3,
                    size = 1 + math.random() * 3,
                    color = {1, 1, 0.8, 1} -- Golden sparkles
                }
                table.insert(effects.sparkles, sparkle)
            end
        end

        if GameState.potionDisplay.animProgress >= 1 then
            GameState.potionDisplay.isAnimatingFill = false
            GameState.potionDisplay.fillLevel = GameState.potionDisplay.targetFillLevel 
            -- Keep magical effects for a bit longer after fill completes
            if GameState.potionDisplay.magicalEffects then
                GameState.potionDisplay.magicalEffects.fadeOut = true
                GameState.potionDisplay.magicalEffects.fadeTimer = 0
            end
            
            -- Show potion decision overlay if we're in potion_decision phase but no overlay is active
            if GameState.gamePhase == "potion_decision" and not OverlayManager:getActiveOverlayName() then
                print("Potion fill animation completed, showing potion decision overlay")
                OverlayManager:show("potionDecision")
            end
        end
    end
    
    -- Fade out magical effects after potion fill completes
    if GameState.potionDisplay and GameState.potionDisplay.magicalEffects and GameState.potionDisplay.magicalEffects.fadeOut then
        local effects = GameState.potionDisplay.magicalEffects
        effects.fadeTimer = effects.fadeTimer + dt
        
        if effects.fadeTimer >= 1.0 then
            GameState.potionDisplay.magicalEffects = nil
        else
            -- Fade out all effects
            local fadeAlpha = 1 - effects.fadeTimer
            for _, swirl in ipairs(effects.swirls) do
                swirl.color[4] = swirl.color[4] * fadeAlpha
            end
            for _, sparkle in ipairs(effects.sparkles) do
                sparkle.color[4] = sparkle.color[4] * fadeAlpha
            end
        end
    end

    OverlayManager:update(dt, GameState.mouse.x, GameState.mouse.y, love.mouse.isDown(1))

    if not OverlayManager:getActiveOverlayName() and GameState.gamePhase ~= "game_over" then
        updateCardAnimations(dt) -- Handles dealing, discarding animations

        if GameState.gamePhase == "playing" and GameState.drag and GameState.drag.isDragging and GameState.drag.cardIndex then
            local draggedCard = GameState.hand and GameState.hand[GameState.drag.cardIndex]
            if draggedCard then
                draggedCard.x = GameState.mouse.x - GameState.drag.offsetX
                draggedCard.y = GameState.mouse.y - GameState.drag.offsetY
            end
        end

        if UIState.Buttons then
            for buttonId, buttonInstance in pairs(UIState.Buttons) do
                if buttonInstance and buttonInstance.update and buttonInstance.setEnabled then
                    buttonInstance:update(dt, GameState.mouse.x, GameState.mouse.y, love.mouse.isDown(1))
                    
                    -- Handle different button types
                    if Dependencies.handlers.isButtonEnabled then
                        -- Main action buttons (discard, makePotion, castSpell, sortToggle, potionList, deckView)
                        if buttonId == "discard" or buttonId == "makePotion" or buttonId == "castSpell" or buttonId == "sortToggle" or buttonId == "potionList" or buttonId == "deckView" then
                            local isEnabled = Dependencies.handlers.isButtonEnabled(buttonId, GameState, Dependencies)
                            buttonInstance:setEnabled(isEnabled)
                        end
                    end
                    
                    -- Touch action buttons - enable based on game state
                    if buttonId == "sortHand" then
                        buttonInstance:setEnabled(GameState.gamePhase == "playing")
                    elseif buttonId == "discardSelected" then
                        local canDiscard = Dependencies.handlers and Dependencies.handlers.isButtonEnabled and Dependencies.handlers.isButtonEnabled("discard", GameState, Dependencies)
                        buttonInstance:setEnabled(canDiscard)
                    elseif buttonId == "makePotionAction" then
                        local canMakePotion = Dependencies.handlers and Dependencies.handlers.isButtonEnabled and Dependencies.handlers.isButtonEnabled("makePotion", GameState, Dependencies)
                        buttonInstance:setEnabled(canMakePotion)
                    elseif buttonId == "castSpellAction" then
                        local canCastSpell = Dependencies.handlers and Dependencies.handlers.isButtonEnabled and Dependencies.handlers.isButtonEnabled("castSpell", GameState, Dependencies)
                        buttonInstance:setEnabled(canCastSpell)
                    elseif buttonId == "consumeElixir" then
                        buttonInstance:setEnabled(GameState.energyElixirs and #GameState.energyElixirs > 0)
                    elseif buttonId == "resetGame" then
                        buttonInstance:setEnabled(true) -- Always enabled for debug
                    elseif buttonId == "exitSpellMode" then
                        buttonInstance:setEnabled(GameState.spellCastingMode)
                    end
                end
            end
        end

        -- Comprehensive energy check for all phases
        if Dependencies.coreGame.checkRoundGoalCompletion then
            local goalMet = Dependencies.coreGame.checkRoundGoalCompletion(GameState)
            local makePotionCost = (Config.Game and Config.Game.makePotionEnergyCost) or 15
            
            -- Check if player can't make potions and hasn't met the goal
            if GameState.currentEnergy < makePotionCost and not goalMet then
                -- Only end game if we're in playing phase (not during potion decision)
                if GameState.gamePhase == "playing" then
                    print(string.format("Out of energy! Cannot make potions. Energy: %d, Cost: %d", GameState.currentEnergy, makePotionCost))
                    GameState.gamePhase = "game_over"
                    GameState.gameOverReason = "out_of_energy"
                    if OverlayManager then OverlayManager:show("gameOver") end 
                end
            end
        end
        
        -- Stalemate check (for other conditions like no cards, no actions possible)
        if GameState.gamePhase == "playing" and not GameState.roundCompletionPending and Dependencies.coreGame.checkStalemate then
            local stalemateResult = Dependencies.coreGame.checkStalemate(GameState, Dependencies)
            if stalemateResult then
                GameState.gamePhase = "game_over"
                GameState.gameOverReason = stalemateResult
                if OverlayManager then OverlayManager:show("gameOver") end 
            end
        end
    end
    
    if GameState.roundCompletionPending then
        local isPotionAnimating = GameState.potionDisplay and GameState.potionDisplay.isAnimatingFill
        local isBubblingActive = GameState.potionDisplay and GameState.potionDisplay.isBubbling
        local isWaitingForDiscard = GameState.isWaitingForDiscard
        local isInPotionDecision = (GameState.gamePhase == "potion_decision")
        local hasPendingPotionChoice = (GameState.pendingPotionChoice ~= nil)

        -- If we're in potion decision phase, wait for the player to make their choice
        if isInPotionDecision then
            print("love.update: Round completion pending, but currently in potion_decision phase. Shop deferred.")
        -- If we have a pending potion choice but not in potion decision phase, show the overlay
        elseif hasPendingPotionChoice and not isInPotionDecision then
            print("love.update: Pending potion choice detected, showing potion decision overlay.")
            GameState.gamePhase = "potion_decision"
            if Dependencies.overlayManager then
                Dependencies.overlayManager:show("potionDecision")
            end
        -- If all animations are done and no pending choices, enter shop phase
        elseif not isPotionAnimating and not isBubblingActive and not isWaitingForDiscard and not isInPotionDecision and not hasPendingPotionChoice then
            print("love.update: Conditions met to enter shop phase (animations done, potion decision completed).")
            GameState.roundCompletionPending = false
            Dependencies.coreGame.enterShopPhase(GameState, Config, Dependencies)
        end
    end

    if Dependencies.bubbleManager and Dependencies.bubbleManager.update then
        Dependencies.bubbleManager.update(dt, GameState.potionDisplay, Config.Bubble, Config.UI)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    print(string.format("love.mousepressed: Screen(%d,%d), Button: %d, Presses: %d", x, y, button, presses))

    if not GameState or not Config or not Dependencies then print("love.mousepressed: Critical dependencies missing, returning."); return end

    if button == 1 then -- Primary mouse button
        local virtualX, virtualY = Dependencies.translateMouseCoords(x, y)
        GameState.mouse.x = virtualX; GameState.mouse.y = virtualY
        print(string.format("    MousePressed: Screen(%d,%d) -> Virtual(%.1f,%.1f)", x, y, virtualX, virtualY))

        local clickedCardHandIdx = Dependencies.handlers.handleMouseClick(virtualX, virtualY, GameState, Config, Dependencies)
        
        if clickedCardHandIdx and GameState.hand and GameState.drag and GameState.gamePhase == "playing" then
            local card = GameState.hand[clickedCardHandIdx]
            -- Start drag only if the card clicked is currently selected (highlighted)
            if card and card.isHighlighted then 
                if not GameState.drag.isDragging then
                    GameState.drag.isDragging = true
                    GameState.drag.cardIndex = clickedCardHandIdx
                    GameState.drag.offsetX = virtualX - card.x
                    GameState.drag.offsetY = virtualY - card.y
                    print("    Drag started on card index:", clickedCardHandIdx)
                end
            end
        end

        -- Only reset game if we're in game_over phase AND no overlay handled the click
        if GameState.gamePhase == "game_over" and not clickWasHandled then
            print("Click detected in game_over phase. Resetting game...")
            if Dependencies.coreGame and Dependencies.coreGame.resetGame then
                Dependencies.coreGame.resetGame(GameState, Config, Dependencies)
                -- Initial hand draw is handled by resetGame -> startNextRound
                if Dependencies.overlayManager then Dependencies.overlayManager:hide() end -- Hide gameOver overlay
            else
                print("Error: Cannot reset game, CoreGame.resetGame is missing from Dependencies.")
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if not GameState or not GameState.drag or not GameState.hand or not Dependencies then return end

    if button == 1 then -- Primary mouse button released
        if GameState.drag.isDragging then
            print("    Drag ended for card index:", GameState.drag.cardIndex)
            GameState.drag.isDragging = false
            GameState.drag.cardIndex = nil
            GameState.drag.offsetX = 0
            GameState.drag.offsetY = 0
            -- Recalculate hand layout to snap card back or to new position if dropping on a target
            if Dependencies.sort and Dependencies.sort.calculateHandLayout then
                Dependencies.sort.calculateHandLayout(GameState, Config)
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- Not actively used for core logic, but mouse position is updated in love.update
    -- GameState.mouse.x, GameState.mouse.y are updated in love.update using translated coordinates
end

function love.keypressed(key, scancode, isrepeat)
    if not GameState or not Config or not Dependencies then return end

    local ovManager = Dependencies.overlayManager
    local gameHandlers = Dependencies.handlers
    local coreGameAPI = Dependencies.coreGame
    local sortAPI = Dependencies.sort

    -- 1. Give active overlay priority for key presses
    if ovManager and ovManager.handleKeyPress then
        if ovManager:handleKeyPress(key) then
            return -- Key was handled by the overlay
        end
    end

    -- 2. Global key presses (if no overlay handled it and in 'playing' phase)
    if not (ovManager and ovManager:getActiveOverlayName()) and GameState.gamePhase == "playing" then
        if key == "escape" then -- Exit spell casting mode
            if GameState.spellCastingMode then
                print("Exiting spell casting mode via Escape key.")
                GameState.spellCastingMode = false
                GameState.selectedSpellId = nil
                GameState.selectedCardIndices = {}
            end
        elseif key == "r" then -- Quick Reset (for debugging)
            if coreGameAPI and coreGameAPI.resetGame then
                print("DEBUG: Quick reset via 'r' key.")
                coreGameAPI.resetGame(GameState, Config, Dependencies)
            end
        end
    end
end

function love.wheelmoved(x, y)
    if not GameState or not Config or not UIState or not OverlayManager or not Dependencies then
        return
    end
    
    -- Convert screen coordinates to virtual coordinates
    local virtualX = (x - RenderState.offsetX) / RenderState.scale
    local virtualY = (y - RenderState.offsetY) / RenderState.scale
    
    -- Handle wheel events for active overlay
    if OverlayManager:getActiveOverlayName() then
        local activeOverlay = OverlayManager:getActiveOverlay()
        if activeOverlay and activeOverlay.handleWheel then
            if activeOverlay:handleWheel(virtualX, virtualY, 0, y) then
                return -- Event was handled by overlay
            end
        end
    end
end

-- Add comprehensive touch event handlers for touch screen support
function love.touchpressed(id, x, y, dx, dy, pressure)
    if not GameState or not Config or not UIState or not OverlayManager or not Dependencies then
        return
    end
    
    -- Convert screen coordinates to virtual coordinates
    local virtualX = (x - RenderState.offsetX) / RenderState.scale
    local virtualY = (y - RenderState.offsetY) / RenderState.scale
    
    -- Store touch state for tracking
    if not GameState.touchState then
        GameState.touchState = {}
    end
    
    GameState.touchState[id] = {
        x = virtualX,
        y = virtualY,
        startX = virtualX,
        startY = virtualY,
        startTime = love.timer.getTime(),
        isActive = true
    }
    
    -- Handle touch events for active overlay
    if OverlayManager:getActiveOverlayName() then
        local activeOverlay = OverlayManager:getActiveOverlay()
        if activeOverlay and activeOverlay.handleTouchPressed then
            if activeOverlay:handleTouchPressed(id, virtualX, virtualY, pressure) then
                return -- Event was handled by overlay
            end
        end
    end
    
    -- Fallback to mouse press handling for single touch
    if id == 1 then -- Primary touch
        love.mousepressed(x, y, 1, true, 1)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if not GameState or not GameState.touchState or not GameState.touchState[id] then
        return
    end
    
    -- Convert screen coordinates to virtual coordinates
    local virtualX = (x - RenderState.offsetX) / RenderState.scale
    local virtualY = (y - RenderState.offsetY) / RenderState.scale
    
    local touchData = GameState.touchState[id]
    touchData.isActive = false
    touchData.endX = virtualX
    touchData.endY = virtualY
    touchData.endTime = love.timer.getTime()
    
    -- Handle touch events for active overlay
    if OverlayManager:getActiveOverlayName() then
        local activeOverlay = OverlayManager:getActiveOverlay()
        if activeOverlay and activeOverlay.handleTouchReleased then
            if activeOverlay:handleTouchReleased(id, virtualX, virtualY, pressure) then
                return -- Event was handled by overlay
            end
        end
    end
    
    -- Fallback to mouse release handling for single touch
    if id == 1 then -- Primary touch
        love.mousereleased(x, y, 1, true, 1)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if not GameState or not GameState.touchState or not GameState.touchState[id] then
        return
    end
    
    -- Convert screen coordinates to virtual coordinates
    local virtualX = (x - RenderState.offsetX) / RenderState.scale
    local virtualY = (y - RenderState.offsetY) / RenderState.scale
    
    local touchData = GameState.touchState[id]
    local prevX, prevY = touchData.x, touchData.y
    touchData.x = virtualX
    touchData.y = virtualY
    touchData.dx = virtualX - prevX
    touchData.dy = virtualY - prevY
    
    -- Handle touch events for active overlay
    if OverlayManager:getActiveOverlayName() then
        local activeOverlay = OverlayManager:getActiveOverlay()
        if activeOverlay and activeOverlay.handleTouchMoved then
            if activeOverlay:handleTouchMoved(id, virtualX, virtualY, touchData.dx, touchData.dy, pressure) then
                return -- Event was handled by overlay
            end
        end
    end
    
    -- Fallback to mouse move handling for single touch
    if id == 1 then -- Primary touch
        love.mousemoved(x, y, touchData.dx, touchData.dy, true)
    end
end

function love.draw()
    if not GameState or not Config or not UIState or not OverlayManager or 
       not GameCanvas or not RenderState or not Dependencies then
        if love and love.graphics then love.graphics.print("CRITICAL DRAW ERROR: Missing components.", 10, 10, 0, 2, 2) end
        return
    end

    local drawAPI = Dependencies.draw 
    if not drawAPI then print("Error: Draw module (Dependencies.draw) is missing."); return end
    if not love or not love.graphics then print("Error: love.graphics module not available."); return end

    -- 1. Draw all game elements to the GameCanvas
    love.graphics.setCanvas(GameCanvas)
    love.graphics.push() 
    local bgColor = Config.UI.Colors.background or {0.1,0.1,0.1} 
    love.graphics.clear(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)

    drawAPI.drawModernTopBar(GameState, Config, Dependencies) -- Draw modern top bar
    drawAPI.drawEnergyElixirDisplay(GameState, Config, Dependencies) -- Draw energy elixir count
    -- drawAPI.drawPotionDisplay(GameState, Config, Dependencies) -- Removed potion drawing
    drawAPI.drawPotentialPotionDisplay(GameState, Config, Dependencies)
    -- drawAPI.drawDeckAndDiscardPiles(GameState, Config, Dependencies) -- Removed deck/discard pile cards
    drawAPI.drawHand(GameState, Config, Dependencies)
    
    -- Draw spell casting mode UI if active
    if GameState.spellCastingMode then
        drawAPI.drawSpellCastingModeUI(GameState, Config, Dependencies)
    end

    -- Draw main UI buttons if no overlay is active
    if not OverlayManager:getActiveOverlayName() and UIState.Buttons then
        for buttonId, buttonInst in pairs(UIState.Buttons) do
            if buttonInst and buttonInst.draw then 
                -- Only draw main action buttons (not touch equivalents) in normal mode
                if buttonId ~= "sortHand" and buttonId ~= "discardSelected" and buttonId ~= "makePotionAction" and 
                   buttonId ~= "castSpellAction" and buttonId ~= "consumeElixir" and buttonId ~= "resetGame" and 
                   buttonId ~= "exitSpellMode" then
                    buttonInst:draw()
                end
            end
        end
        
        -- Draw touch action buttons (always visible for touch screens)
        local touchButtons = {"sortHand", "discardSelected", "makePotionAction", "castSpellAction", "consumeElixir", "resetGame", "exitSpellMode"}
        for _, buttonId in ipairs(touchButtons) do
            local buttonInst = UIState.Buttons[buttonId]
            if buttonInst and buttonInst.draw then
                buttonInst:draw()
            end
        end
    end

    OverlayManager:draw() -- Draw active overlay on top of game elements but under specific UI like drag/target

    -- Draw dragged card on top if being dragged (drawHand already does this if card is part of its list)
    -- This re-draw ensures it's visually on top of other hand cards if not handled by z-ordering.
    -- However, drawHand iterates 1 to #hand, so higher index cards are drawn last (on top).
    -- If dragging reorders or needs specific highlight, this block might be adjusted.
    if GameState.drag and GameState.drag.isDragging and GameState.drag.cardIndex then
        local draggedCard = GameState.hand and GameState.hand[GameState.drag.cardIndex]
        if draggedCard then
            -- Re-draw the dragged card slightly emphasized or using Draw.drawCardObject directly
            -- For simplicity, we assume drawHand handles the visual aspect of the dragged card correctly.
            -- This block could be used for an additional highlight or effect if needed.
            -- love.graphics.push()
            -- love.graphics.setColor(1,1,0,0.2); 
            -- love.graphics.rectangle("fill", draggedCard.x-2, draggedCard.y-2, Config.Card.width+4, Config.Card.height+4, 5,5)
            -- love.graphics.pop()
        end
    end

    -- Draw spell targeting UI if active
    if GameState.selectingSpellTarget and GameState.selectedSpellId then
        drawAPI.drawSpellTargetingUI(GameState, Config, Dependencies)
    end

    love.graphics.pop()
    love.graphics.setCanvas()

    -- 2. Draw the GameCanvas to the screen, scaled and centered
    love.graphics.setColor(1, 1, 1, 1) 
    love.graphics.draw(
        GameCanvas,
        RenderState.offsetX, RenderState.offsetY,
        0, -- rotation
        RenderState.scale, RenderState.scale
    )
end

print("main.lua (fully refactored with energy, endless rounds, and formatting) processed.")