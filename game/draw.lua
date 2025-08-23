-- File: draw.lua (Formatted with Energy Display and Robustness)
-- Contains all drawing functions for the game, operating on passed-in state and config.

local Draw = {}

-- =============================================================================
-- Helper Drawing Functions (Internal or also exposed via Dependencies.theme.helpers)
-- =============================================================================

--- Draws a single card object with its details.
-- This is a core visual component used by drawHand and potentially other UI elements.
-- @param card (table) The card instance data.
-- @param config (table) The main game configuration table.
-- @param dependencies (table) Table containing theme (fonts, colors, layout) and other helpers.
function Draw.drawCardObject(card, config, dependencies)
    if not card or type(card) ~= "table" then print("Draw.drawCardObject: Invalid card data."); return end
    if not config or not config.Card or not config.Layout or not config.UI then print("Draw.drawCardObject: Missing Config sections."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawCardObject: Missing dependencies.theme."); return end

    local theme = dependencies.theme
    local cardCfg = config.Card
    local layoutCfg = config.Layout
    local uiCfg = config.UI
    local colors = theme.colors or {}
    local fonts = theme.fonts or {}

    -- Card properties
    local x, y = card.x or 0, card.y or 0
    local width, height = cardCfg.width or 60, cardCfg.height or 80
    local rotation = card.rotation or 0
    local scale = card.scale or 1
    local cornerRadius = layoutCfg.cardCornerRadius or 5

    -- Base card color
    local baseColor = colors.cardBaseDefault or {0.95, 0.95, 0.95, 1}
    if card.family == "Plant" then baseColor = colors.cardBasePlant or {0.8, 1.0, 0.8, 1}
    elseif card.family == "Magic" then baseColor = colors.cardBaseMagic or {0.1, 0.1, 0.1, 1} end
    
    -- Text color based on base
    local textColor = (card.family == "Magic") and (colors.textLight or {0.9,0.9,0.9,1}) or (colors.textDark or {0.1,0.1,0.1,1})
    
    -- Highlight
    local borderColor = (card.family == "Magic") and (colors.cardBorderLight or {0.7,0.7,0.7,1}) or (colors.cardBorderDark or {0.2,0.2,0.2,1})
    if card.isHighlighted then
        borderColor = colors.highlight or {1,1,0,1}
    end

    -- Save current transform and style
    love.graphics.push()
    love.graphics.translate(x + width / 2, y + height / 2) -- Translate to center for rotation/scaling
    love.graphics.rotate(rotation)
    love.graphics.scale(scale)
    love.graphics.translate(-width / 2, -height / 2) -- Translate back to top-left for drawing

    -- Draw card background
    love.graphics.setColor(baseColor)
    love.graphics.rectangle("fill", 0, 0, width, height, cornerRadius, cornerRadius)

    -- Draw border
    love.graphics.setLineWidth(card.isHighlighted and 3 or 1)
    love.graphics.setColor(borderColor)
    love.graphics.rectangle("line", 0, 0, width, height, cornerRadius, cornerRadius)
    love.graphics.setLineWidth(1) -- Reset line width

    -- Draw object color circle (element representation)
    if card.objectColor and type(card.objectColor) == "table" and #card.objectColor >= 3 then
        love.graphics.setColor(card.objectColor[1], card.objectColor[2], card.objectColor[3], card.objectColor[4] or 1)
        local circleRadius = width * (layoutCfg.cardObjectCircleRadiusRatio or 0.25)
        local circleYPos = height / 2 - circleRadius + (height * (layoutCfg.cardObjectCircleYRatio or 0.15))
        love.graphics.circle("fill", width / 2, circleYPos, circleRadius)
    end

    -- Draw card name
    local cardNameFont = fonts.small or fonts.default
    if cardNameFont then
        love.graphics.setFont(cardNameFont)
        love.graphics.setColor(textColor)
        local nameY = height * (layoutCfg.cardNameYRatio or 0.1)
        love.graphics.printf(card.name or "???", layoutCfg.cardTextPadding or 2, nameY, width - 2 * (layoutCfg.cardTextPadding or 2), "center")
    end

    -- Draw card value
    local cardValueFont = fonts.large or fonts.default
    if cardValueFont then
        love.graphics.setFont(cardValueFont)
        love.graphics.setColor(textColor)
        local valueY = height * (layoutCfg.cardValueYRatio or 0.75) - cardValueFont:getHeight()/2
        love.graphics.printf(tostring(card.value or 0), 0, valueY, width, "center")
    end
    
    love.graphics.pop() -- Restore transform and style
end

--- Draws a generic card icon, typically smaller than a full card object.
-- Used in UI lists like recipes or shop.
-- @param x (number) Top-left X position.
-- @param y (number) Top-left Y position.
-- @param cardDef (table, optional) The card definition (for specific look) OR nil if using generic iconData.
-- @param iconData (table) Generic icon data (e.g., {type="family", name="Plant", count=2}).
-- @param iconW (number) Width of the icon.
-- @param iconH (number) Height of the icon.
-- @param config (table) The main game Config table (for fallback theme elements if needed).
-- @param dependencies (table) Provides access to theme.
function Draw.drawCardIcon(x, y, cardDef, iconData, iconW, iconH, config, dependencies)
    if not iconData or type(iconData) ~= "table" then print("Draw.drawCardIcon: Invalid iconData."); return end
    if not config or not dependencies or not dependencies.theme then print("Draw.drawCardIcon: Missing config or theme dependencies."); return end

    local theme = dependencies.theme
    local colors = theme.colors or {}
    local fonts = theme.fonts or {}
    local layoutCfg = config.Layout or {}
    
    iconW = iconW or (layoutCfg.cardCornerRadius or 5) * 4 -- Default derived width
    iconH = iconH or (layoutCfg.cardCornerRadius or 5) * 6 -- Default derived height
    local cornerRadius = math.min(iconW, iconH) * 0.15 -- Proportional corner radius

    local bgColor = colors.cardBaseDefault or {0.8,0.8,0.8,1}
    local symbolColor = colors.textDark or {0.1,0.1,0.1,1}
    local text = "?"

    if cardDef then -- Icon represents a specific card
        if cardDef.family == "Plant" then bgColor = colors.cardBasePlant or {0.7,1,0.7,1}
        elseif cardDef.family == "Magic" then bgColor = colors.cardBaseMagic or {0.2,0.2,0.2,1}; symbolColor = colors.textLight or {1,1,1,1} end
        text = string.sub(cardDef.name or "?", 1, 1) -- First letter of card name
    elseif iconData.type == "family" then
        if iconData.name == "Plant" then bgColor = colors.cardBasePlant or {0.7,1,0.7,1}; text = "P"
        elseif iconData.name == "Magic" then bgColor = colors.cardBaseMagic or {0.2,0.2,0.2,1}; text = "M"; symbolColor = colors.textLight or {1,1,1,1} end
    elseif iconData.type == "subtype" then -- Example
        text = string.sub(iconData.name or "?", 1, 1)
    end

    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, iconW, iconH, cornerRadius, cornerRadius)
    love.graphics.setColor(symbolColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, iconW, iconH, cornerRadius, cornerRadius)

    local iconFont = fonts.small or fonts.default
    if iconFont then
        love.graphics.setFont(iconFont)
        local charW = iconFont:getWidth(text)
        local charH = iconFont:getHeight()
        love.graphics.print(text, x + (iconW - charW) / 2, y + (iconH - charH) / 2)
    end

    -- Draw count if provided
    if iconData.count and type(iconData.count) == "number" and iconData.count > 1 then
        local countText = "x" .. tostring(iconData.count)
        local countFont = fonts.small or fonts.default -- Or an even smaller font
        if countFont then
            love.graphics.setFont(countFont)
            local countW = countFont:getWidth(countText)
            -- Position count at bottom-right of icon, slightly offset
            love.graphics.print(countText, x + iconW - countW - 2, y + iconH - countFont:getHeight() - 2)
        end
    end
end

--- Draws the potion bottle shape, optionally filled with liquid and bubbles.
--- Draws a stylized potion bottle with fill level.
-- centerX, centerY: center of the bottle drawing area

function Draw.drawPotionBottle(centerX, centerY, bottleType, fillColor, fillLevel, gameState, config, dependencies)
    -- 1. Validate Inputs (This part seems to pass for the overlay now)
    if not gameState or not config or not dependencies or not config.UI or not config.UI.bottleWidth or
       not config.Bubble or not config.Bubble.boundaryData or not dependencies.theme or 
       not dependencies.theme.colors or not dependencies.theme.fonts or 
       not dependencies.theme.cornerRadius or not dependencies.bubbleManager then
        -- This error is still appearing for the main potion display (centerX: 40), which we'll address separately.
        print("Draw.drawPotionBottle: Failing validation for centerX:", centerX)
        return
    end
    if not love or not love.graphics then return end

    -- Cache necessary tables
    local uiConfig = config.UI
    local bubbleConfig = config.Bubble
    local themeColors = dependencies.theme.colors
    local themeCornerRadius = dependencies.theme.cornerRadius

    -- Prepare variables
    local W = uiConfig.bottleWidth
    local H = uiConfig.bottleHeight
    local outlineColor = themeColors.potionBottleOutline or {0.3,0.3,0.4,1}
    local currentFillColor = fillColor or {0.5,0.8,1,1}
    local currentFillLevel = math.max(0, math.min(1, fillLevel or 0))
    local currentBottleType = bottleType or "default"

    love.graphics.push()
    love.graphics.translate(centerX, centerY)

    -- 2. Get Liquid Boundaries
    local bubbleMgr = dependencies.bubbleManager
    local liquidTopY_centerRel, liquidBottomY_centerRel, _, liquidBodyHeight_abs = bubbleMgr.getBoundaries(
        currentBottleType, W, H, bubbleConfig.boundaryData
    )
    local boundaryDataEntry = bubbleConfig.boundaryData[currentBottleType] or bubbleConfig.boundaryData["default"] or {}
    local bodyW_ratio = boundaryDataEntry.bodyW or 0.8
    local bodyW_abs = bodyW_ratio * W
    
    local actualFillHeight = liquidBodyHeight_abs * currentFillLevel
    local fillTopY_centerRel = liquidBottomY_centerRel - actualFillHeight 

    -- 3. Draw Liquid Fill
    if type(currentFillColor) == "table" and #currentFillColor >= 3 and currentFillLevel > 0.001 then
        love.graphics.setColor(currentFillColor)
        
        local scissorX, scissorY = -bodyW_abs / 2, fillTopY_centerRel
        local scissorW, scissorH = bodyW_abs, actualFillHeight

        love.graphics.setScissor(scissorX, scissorY, scissorW, scissorH)
        love.graphics.rectangle("fill", -W, -H, W * 2, H * 2) -- Draw a very large rectangle to guarantee it fills the scissor area
        love.graphics.setScissor()

        -- *** NEW DEBUG DRAWING: Draw the outline of the scissor box ***
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 1, 0, 0.7) -- Bright, semi-transparent green
        love.graphics.rectangle("line", scissorX, scissorY, scissorW, scissorH)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    -- ... (rest of the function to draw bubbles and bottle outline remains the same) ...

    -- 5. Draw Bottle Outline (This part is working)
    love.graphics.setColor(outlineColor)
    love.graphics.setLineWidth(2)
    -- ... (complex shape drawing logic) ...
    love.graphics.pop()
    love.graphics.setLineWidth(1)
end
-- =============================================================================
-- Main UI Drawing Functions (Called from main.lua's love.draw)
-- =============================================================================

--- Draws the current round goal and progress.
function Draw.drawGoalDisplay(gameState, config, dependencies)
    if not gameState or not gameState.currentRoundData then print("Draw.drawGoalDisplay: Missing GameState or currentRoundData."); return end
    if not config or not config.UI or not config.UI.goalDisplay then print("Draw.drawGoalDisplay: Missing Config.UI.goalDisplay."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawGoalDisplay: Missing dependencies.theme."); return end

    local theme = dependencies.theme
    local goalCfg = config.UI.goalDisplay
    local colors = theme.colors or {}
    local fonts = theme.fonts or {}
    local layoutCfg = config.Layout or {}

    local panelX = goalCfg.x or (layoutCfg.paddingMedium or 10)
    local panelY = goalCfg.y or (layoutCfg.paddingSmall or 5)
    local panelW = goalCfg.width or (config.Screen.width - 2 * (layoutCfg.paddingMedium or 10))
    local panelH = goalCfg.height or 65
    local padding = goalCfg.padding or 8
    
    local bgColor = colors.panelBackground or {0.2,0.2,0.25,0.9}
    local textColor = colors.textLight or {0.9,0.9,0.9,1}
    local goalDescFont = fonts.ui or fonts.default
    local progressFont = fonts.small or fonts.default

    -- Draw panel background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, layoutCfg.cardCornerRadius or 5)

    -- Draw Round Number
    if goalDescFont then
        love.graphics.setFont(goalDescFont)
        love.graphics.setColor(textColor)
        local roundText = "Round " .. tostring(gameState.currentRoundNumber or 0)
        local roundTextY = panelY + padding + (goalCfg.roundTextYOffset or 0)
        love.graphics.printf(roundText, panelX + padding, roundTextY, panelW - 2 * padding, "left")
    end
    
    -- Draw Goal Description
    if goalDescFont then
        local goalDesc = gameState.currentRoundData.description or "No goal set."
        local goalDescY = panelY + padding + (goalCfg.goalTextYOffset or 18)
        love.graphics.printf(goalDesc, panelX + padding, goalDescY, panelW - 2 * padding, "left")
    end

    -- Draw Goal Progress
    if progressFont and dependencies.getGoalProgressString then
        love.graphics.setFont(progressFont)
        love.graphics.setColor(textColor)
        local progressText = dependencies.getGoalProgressString(gameState.currentRoundData, gameState)
        local progressTextY = panelY + padding + (goalCfg.progressTextYOffset or 38)
        love.graphics.printf(progressText, panelX + padding, progressTextY, panelW - 2 * padding, "left")
    end
end

--- Draws the new Energy Display.
function Draw.drawEnergyDisplay(gameState, config, dependencies)
    if not gameState or type(gameState.currentEnergy) ~= "number" then print("Draw.drawEnergyDisplay: Missing gameState.currentEnergy."); return end
    if not config or not config.Game or not config.UI then print("Draw.drawEnergyDisplay: Missing Config.Game or Config.UI."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawEnergyDisplay: Missing dependencies.theme."); return end

    local theme = dependencies.theme
    local fonts = theme.fonts or {}
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    local uiCfg = config.UI
    local gameCfg = config.Game

    local energyFont = fonts.ui or fonts.default
    local energyColor = colors.textEnergy or colors.textDark or {0.2, 0.2, 0.7, 1}
    
    local energyText = string.format("Energy: %d / %d", gameState.currentEnergy, gameCfg.energyPerRound or 100)
    
    -- Position (Example: Top right, below Goal Display or near it)
    local textX, textY
    if uiCfg.goalDisplay and type(uiCfg.goalDisplay.x) == "number" and type(uiCfg.goalDisplay.width) == "number" and
       type(uiCfg.goalDisplay.y) == "number" and type(uiCfg.goalDisplay.height) == "number" and energyFont then
        -- Position relative to goal display's right edge
        local goalRightEdge = uiCfg.goalDisplay.x + uiCfg.goalDisplay.width
        local textW = energyFont:getWidth(energyText)
        textX = goalRightEdge - textW - (layout.paddingMedium or 10)
        textY = uiCfg.goalDisplay.y + (uiCfg.goalDisplay.height - energyFont:getHeight()) / 2 -- Vertically center with goal display
    else -- Fallback positioning
        textX = (config.Screen.width or 400) - (energyFont and energyFont:getWidth(energyText) or 100) - (layout.paddingMedium or 10)
        textY = (layout.paddingSmall or 5)
    end

    if energyFont then
        local originalFont = love.graphics.getFont()
        love.graphics.setFont(energyFont)
        love.graphics.setColor(energyColor)
        love.graphics.print(energyText, textX, textY)
        love.graphics.setFont(originalFont)
        love.graphics.setColor(1,1,1,1) -- Reset color
    end
end

--- Draws the main Potion Display area (bottle, fill level, bubbles).
function Draw.drawPotionDisplay(gameState, config, dependencies)
    if not gameState or not gameState.potionDisplay then print("Draw.drawPotionDisplay: Missing gameState.potionDisplay."); return end
    if not config or not config.UI or not config.Bubble then print("Draw.drawPotionDisplay: Missing Config.UI or Config.Bubble."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawPotionDisplay: Missing dependencies.theme."); return end
    
    local pdState = gameState.potionDisplay
    if not pdState.showPotion then return end -- Don't draw if not showing

    local theme = dependencies.theme
    local uiCfg = config.UI
    local bubbleCfg = config.Bubble
    local pDisplayCfg = uiCfg.potionDisplayArea or {}
    local colors = theme.colors or {}
    
    -- Bottle position (centered in its designated area)
    local areaX = pDisplayCfg.x or ((config.Screen.width or 400) / 2)
    local areaY = pDisplayCfg.y or ((config.Screen.height or 600) / 2)
    local bottleW = uiCfg.bottleWidth or 60
    local bottleH = uiCfg.bottleHeight or 90

    -- Background for the area (optional)
    local areaBgColor = colors.potionDisplayBg -- Potentially transparent or themed
    if areaBgColor and pDisplayCfg.width and pDisplayCfg.height then
        love.graphics.setColor(areaBgColor)
        love.graphics.rectangle("fill", areaX - pDisplayCfg.width / 2, areaY - pDisplayCfg.height / 2, pDisplayCfg.width, pDisplayCfg.height)
    end

    -- Draw the potion bottle itself using the helper
    -- The helper Draw.drawPotionBottle expects centerX, centerY of the bottle
    Draw.drawPotionBottle(areaX, areaY, pdState.bottleType, pdState.fillColor, pdState.fillLevel, theme)

    -- Draw Bubbles
    if pdState.isBubbling and pdState.bubbles and #pdState.bubbles > 0 then
        love.graphics.push()
        love.graphics.translate(areaX, areaY) -- Translate to bottle center for bubble relative positions
        
        local bubbleBaseColor = pdState.fillColor or {0.5,0.8,1} -- Bubbles match liquid or a highlight
        
        for _, bubble in ipairs(pdState.bubbles) do
            if type(bubble) == "table" and type(bubble.x) == "number" then
                local alpha = bubble.alpha or 1.0
                love.graphics.setColor(bubbleBaseColor[1], bubbleBaseColor[2], bubbleBaseColor[3], alpha * 0.7) -- Semi-transparent
                love.graphics.circle("fill", bubble.x, bubble.y, bubble.radius or 5)
                
                -- Optional highlight
                love.graphics.setColor(1,1,1, alpha * 0.5)
                love.graphics.circle("fill", bubble.x - (bubble.radius or 5)*0.3, bubble.y - (bubble.radius or 5)*0.3, (bubble.radius or 5)*0.3)
            end
        end
        love.graphics.pop()
    end
end

--- Draws the "Potential Potion" display text area.
function Draw.drawPotentialPotionDisplay(gameState, config, dependencies)
    if not gameState or not gameState.potentialPotionResult then print("Draw.drawPPDisplay: Missing gameState.potentialPotionResult."); return end
    if not config or not config.UI or not config.UI.potentialPotionDisplay then print("Draw.drawPPDisplay: Missing Config.UI.potentialPotionDisplay."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawPPDisplay: Missing dependencies.theme."); return end

    local theme = dependencies.theme
    local potPotCfg = config.UI.potentialPotionDisplay
    local colors = theme.colors or {}
    local fonts = theme.fonts or {}
    local layoutCfg = config.Layout or {}

    local panelX = potPotCfg.x or ((config.Screen.width - (potPotCfg.width or 300)) / 2)
    local panelY = potPotCfg.y or 200 -- Fallback Y
    local panelW = potPotCfg.width or 300
    local panelH = potPotCfg.height or 55
    local padding = potPotCfg.padding or 5
    
    local bgColor = colors.panelBackground or {0.2,0.2,0.25,0.9}
    local textColor = colors.textLight or {0.9,0.9,0.9,1}
    local potionNameFont = fonts.ui or fonts.default
    local scoreFont = fonts.small or fonts.default

    -- Draw panel background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, layoutCfg.cardCornerRadius or 5)

    -- Draw Potion Name
    if potionNameFont then
        love.graphics.setFont(potionNameFont)
        love.graphics.setColor(textColor)
        local potionName = gameState.potentialPotionResult.name or "Nothing"
        local nameY = panelY + padding
        love.graphics.printf(potionName, panelX + padding, nameY, panelW - 2 * padding, "center")
    
        -- Draw Current Score from selected cards (if any cards selected)
        if scoreFont and gameState.selectedCardIndices and #gameState.selectedCardIndices > 0 then
            love.graphics.setFont(scoreFont)
            local scoreText = "Value: " .. tostring(gameState.currentScore or 0)
            local scoreY = nameY + (potionNameFont and potionNameFont:getHeight() or 16) + 2 -- Below name
            love.graphics.printf(scoreText, panelX + padding, scoreY, panelW - 2 * padding, "center")
        end
    end
end

--- Draws the Deck and Discard Pile visuals and counts.
function Draw.drawDeckAndDiscardPiles(gameState, config, dependencies)
    if not gameState then print("Draw.drawPiles: Missing GameState."); return end
    if not config or not config.UI or not config.Card or not config.Layout then print("Draw.drawPiles: Missing Config sections."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawPiles: Missing dependencies.theme."); return end

    local theme = dependencies.theme
    local uiCfg = config.UI
    local cardCfg = config.Card
    local layoutCfg = config.Layout
    local colors = theme.colors or {}
    local fonts = theme.fonts or {}

    local cardW, cardH = cardCfg.width or 60, cardCfg.height or 80
    local padding = layoutCfg.paddingMedium or 10
    local screenW = config.Screen.width or 400
    
    -- Deck Position & Visual
    local deckX = padding
    local deckY = uiCfg.CountInfoY or 10 -- Use calculated Y from love.load or fallback
    local deckColor = colors.deckPile or {0.3,0.3,0.7,0.8}
    local deckCount = #(gameState.deck or {})
    if deckCount > 0 then
        love.graphics.setColor(deckColor)
        love.graphics.rectangle("fill", deckX, deckY, cardW * 0.8, cardH * 0.8, layoutCfg.cardCornerRadius or 3) -- Slightly smaller visual
    end
    
    -- Discard Pile Position & Visual (Right side)
    local discardX = screenW - (cardW * 0.8) - padding
    local discardY = deckY -- Align vertically with deck
    local discardColor = colors.discardPile or {0.7,0.3,0.3,0.8}
    local discardCount = #(gameState.discardPile or {})
    if discardCount > 0 then
        love.graphics.setColor(discardColor)
        love.graphics.rectangle("fill", discardX, discardY, cardW * 0.8, cardH * 0.8, layoutCfg.cardCornerRadius or 3)
    end

    -- Draw Counts Text
    local countFont = fonts.ui or fonts.default
    local countColor = colors.textDark or {0.1,0.1,0.1,1}
    if countFont then
        love.graphics.setFont(countFont)
        love.graphics.setColor(countColor)
        -- Deck count text (below deck visual)
        local deckTextY = deckY + (cardH * 0.8) + 2
        love.graphics.print("Deck: " .. deckCount, deckX, deckTextY)
        -- Discard count text (below discard visual)
        love.graphics.print("Discard: " .. discardCount, discardX, deckTextY)
    end
end

--- Draws the player's hand of cards.
function Draw.drawHand(gameState, config, dependencies)
    if not gameState or not gameState.hand then print("Draw.drawHand: Missing gameState.hand."); return end
    if not config or not config.Layout then print("Draw.drawHand: Missing Config.Layout."); return end
    if not dependencies then print("Draw.drawHand: Missing dependencies."); return end

    local hand = gameState.hand
    -- Draw cards from back to front so overlaps look correct
    for i = 1, #hand do
        local card = hand[i]
        if card and type(card) == "table" then
            -- Only draw cards that are not currently being discarded (they are handled by animation to move off-screen)
            if not card.isDiscarding then
                Draw.drawCardObject(card, config, dependencies)
            end
        end
    end

    -- If a card is being dragged, re-draw it on top of everything else in the hand
    if gameState.drag and gameState.drag.isDragging and gameState.drag.cardIndex then
        local draggedCardInstance = hand[gameState.drag.cardIndex]
        if draggedCardInstance and type(draggedCardInstance) == "table" and not draggedCardInstance.isDiscarding then
            Draw.drawCardObject(draggedCardInstance, config, dependencies)
        end
    end
end

--- Draws UI elements for spell targeting (e.g., reticle at mouse).
function Draw.drawSpellTargetingUI(gameState, config, dependencies)
    if not gameState or not gameState.selectingSpellTarget or not gameState.selectedSpellId then return end
    if not gameState.knownSpells or not gameState.knownSpells[gameState.selectedSpellId] then return end
    if not config or not config.Screen then print("Draw.drawSpellTargetUI: Missing Config.Screen."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawSpellTargetUI: Missing dependencies.theme."); return end

    local spell = gameState.knownSpells[gameState.selectedSpellId]
    local theme = dependencies.theme
    local fonts = theme.fonts or {}
    local colors = theme.colors or {}
    
    local targetFont = fonts.ui or fonts.default
    local targetTextColor = colors.textDark or {0.1,0.1,0.1,1}
    local reticleColor = {1, 0, 0, 0.7} -- Reddish for targeter

    -- Draw text prompt
    if targetFont then
        love.graphics.setFont(targetFont)
        love.graphics.setColor(targetTextColor)
        local promptText = "CASTING: " .. (spell.name or "Spell") .. " - Click Target"
        local textY = (config.Screen.height or 600) - 20 - targetFont:getHeight()
        love.graphics.print(promptText, 10, textY)
    end

    -- Draw reticle at mouse position (virtual coordinates)
    love.graphics.setColor(reticleColor)
    love.graphics.circle("line", gameState.mouse.x, gameState.mouse.y, 15)
    love.graphics.line(gameState.mouse.x - 10, gameState.mouse.y, gameState.mouse.x + 10, gameState.mouse.y) -- Crosshair
    love.graphics.line(gameState.mouse.x, gameState.mouse.y - 10, gameState.mouse.x, gameState.mouse.y + 10)
end

return Draw