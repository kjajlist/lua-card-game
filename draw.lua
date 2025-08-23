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
-- @param gameState (table, optional) The game state for spell casting highlights.
function Draw.drawCardObject(card, config, dependencies, gameState)
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

    -- Modern card colors with better contrast
    local baseColor = colors.surface or {1.0, 1.0, 1.0, 1}
    if card.family == "Plant" then 
        baseColor = colors.cardBasePlant or {0.95, 1.0, 0.95, 1}  -- Softer green
    elseif card.family == "Magic" then 
        baseColor = colors.cardBaseMagic or {0.05, 0.05, 0.1, 1}  -- Very dark blue-black
    end
    
    -- High contrast text colors
    local textColor = (card.family == "Magic") and (colors.textOnPrimary or {1.0, 1.0, 1.0, 1.0}) or (colors.textPrimary or {0.0, 0.0, 0.0, 0.87})
    
    -- Modern highlight system
    local borderColor = colors.textTertiary or {0.0, 0.0, 0.0, 0.12}  -- Subtle default border
    local borderWidth = layoutCfg.borderWidth or 1
    
    if card.isHighlighted then
        borderColor = colors.primary or {0.0, 0.48, 1.0, 1.0}  -- iOS Blue selection
        borderWidth = layoutCfg.focusBorderWidth or 2
    end
    
    -- Special highlight for spell casting mode - show purple outlines for selected cards
    if gameState and gameState.spellCastingMode and gameState.selectedCardIndices then
        for _, selectedIndex in ipairs(gameState.selectedCardIndices) do
            if gameState.hand and gameState.hand[selectedIndex] == card then
                -- This card is selected in spell casting mode - show purple highlight
                borderColor = colors.spellTarget or {0.8, 0.4, 1.0, 1} -- Purple highlight for spell targets
                break
            end
        end
    end

    -- Save current transform and style
    love.graphics.push()
    love.graphics.translate(x + width / 2, y + height / 2) -- Translate to center for rotation/scaling
    love.graphics.rotate(rotation)
    love.graphics.scale(scale)
    love.graphics.translate(-width / 2, -height / 2) -- Translate back to top-left for drawing
    
    -- Apply transformation glow effect if card is transforming
    local isTransforming = card.isTransforming and card.glowIntensity and card.glowIntensity > 0
    if isTransforming then
        local glowColor = card.objectColor or {1, 1, 1}
        love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], card.glowIntensity * 0.5)
        love.graphics.rectangle("fill", -5, -5, width + 10, height + 10, cornerRadius + 2, cornerRadius + 2)
    end

    -- Apply dissolve effect if card is transforming
    local cardAlpha = 1.0
    if card.dissolveIntensity and card.dissolveIntensity > 0 then
        cardAlpha = 1.0 - card.dissolveIntensity
        
        -- Create dissolve pattern using noise-like effect
        local dissolveThreshold = card.dissolveIntensity
        for dy = 0, height, 2 do
            for dx = 0, width, 2 do
                local noiseValue = (math.sin(dx * 0.1) + math.cos(dy * 0.1) + math.sin((dx + dy) * 0.05)) / 3
                noiseValue = (noiseValue + 1) * 0.5 -- Normalize to 0-1
                
                if noiseValue > dissolveThreshold then
                    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], cardAlpha)
                    love.graphics.rectangle("fill", dx, dy, 2, 2)
                end
            end
        end
    else
        -- Normal card background
        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], cardAlpha)
        love.graphics.rectangle("fill", 0, 0, width, height, cornerRadius, cornerRadius)
    end

    -- Draw modern border with subtle shadow
    -- Add subtle shadow for depth
    if not card.isHighlighted then
        local shadowOffset = layoutCfg.shadowOffset or 2
        love.graphics.setColor(0, 0, 0, 0.1 * cardAlpha)  -- Subtle shadow
        love.graphics.rectangle("fill", shadowOffset, shadowOffset, width, height, cornerRadius, cornerRadius)
    end
    
    -- Draw border
    love.graphics.setLineWidth(borderWidth)
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], cardAlpha)
    love.graphics.rectangle("line", 0, 0, width, height, cornerRadius, cornerRadius)
    love.graphics.setLineWidth(1) -- Reset line width

    -- Draw object color circle (element representation)
    if card.objectColor and type(card.objectColor) == "table" and #card.objectColor >= 3 then
        love.graphics.setColor(card.objectColor[1], card.objectColor[2], card.objectColor[3], (card.objectColor[4] or 1) * cardAlpha)
        local circleRadius = width * (layoutCfg.cardObjectCircleRadiusRatio or 0.25)
        local circleYPos = height / 2 - circleRadius + (height * (layoutCfg.cardObjectCircleYRatio or 0.15))
        love.graphics.circle("fill", width / 2, circleYPos, circleRadius)
    end

    -- Draw card name
    local cardNameFont = fonts.small or fonts.default
    if cardNameFont then
        love.graphics.setFont(cardNameFont)
        love.graphics.setColor(textColor[1], textColor[2], textColor[3], cardAlpha)
        local nameY = height * (layoutCfg.cardNameYRatio or 0.1)
        love.graphics.printf(card.name or "???", layoutCfg.cardTextPadding or 2, nameY, width - 2 * (layoutCfg.cardTextPadding or 2), "center")
    end

    -- Draw card value
    local cardValueFont = fonts.large or fonts.default
    if cardValueFont then
        love.graphics.setFont(cardValueFont)
        love.graphics.setColor(textColor[1], textColor[2], textColor[3], cardAlpha)
        local valueY = height * (layoutCfg.cardValueYRatio or 0.75) - cardValueFont:getHeight()/2
        love.graphics.printf(tostring(card.value or 0), 0, valueY, width, "center")
    end
    
    love.graphics.pop() -- Restore transform and style
    
    -- Draw magical particle trail (after popping transform so particles aren't affected by card rotation/scale)
    if card.magicalTrail and card.magicalTrail.particles then
        for _, particle in ipairs(card.magicalTrail.particles) do
            if particle.color and particle.color[4] > 0 then
                love.graphics.setColor(particle.color)
                love.graphics.circle("fill", particle.x, particle.y, particle.size)
                
                -- Add a subtle glow effect
                love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.color[4] * 0.3)
                love.graphics.circle("fill", particle.x, particle.y, particle.size * 1.5)
            end
        end
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
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

--- Draws different bottle shapes based on bottle type
-- @param bottleType (string) The type of bottle to draw
-- @param W (number) Width of the bottle
-- @param H (number) Height of the bottle
function Draw.drawBottleShape(bottleType, W, H)
    local halfW = W / 2
    local halfH = H / 2
    
    if bottleType == "cauldron" then
        -- Draw a wide, round cauldron
        local radius = halfW * 0.8
        love.graphics.circle("line", 0, halfH * 0.3, radius)
        -- Add cauldron legs
        for i = 1, 3 do
            local angle = (i - 1) * (math.pi * 2 / 3) + math.pi / 2
            local legX = math.cos(angle) * radius * 0.7
            local legY = halfH * 0.3 + math.sin(angle) * radius * 0.7
            love.graphics.line(legX, legY, legX, legY + halfH * 0.4)
        end
        -- Add handles
        love.graphics.arc("line", -radius * 1.1, halfH * 0.3, radius * 0.3, -math.pi/3, math.pi/3)
        love.graphics.arc("line", radius * 1.1, halfH * 0.3, radius * 0.3, math.pi*2/3, math.pi*4/3)
        
    elseif bottleType == "teapot" then
        -- Draw teapot body (ellipse)
        love.graphics.ellipse("line", 0, halfH * 0.2, halfW * 0.8, halfH * 0.6)
        -- Draw spout
        love.graphics.arc("line", halfW * 0.8, halfH * 0.1, halfW * 0.3, 0, math.pi/2)
        -- Draw handle
        love.graphics.arc("line", -halfW * 0.8, halfH * 0.2, halfW * 0.4, -math.pi/2, math.pi/2)
        -- Draw lid
        love.graphics.ellipse("line", 0, -halfH * 0.4, halfW * 0.6, halfH * 0.2)
        -- Draw knob
        love.graphics.circle("line", 0, -halfH * 0.5, halfW * 0.1)
        
    elseif bottleType == "skull" then
        -- Draw skull shape
        love.graphics.circle("line", 0, -halfH * 0.2, halfW * 0.7) -- Main skull
        love.graphics.rectangle("line", -halfW * 0.3, halfH * 0.1, halfW * 0.6, halfH * 0.4) -- Jaw
        -- Eye sockets
        love.graphics.circle("line", -halfW * 0.25, -halfH * 0.3, halfW * 0.15)
        love.graphics.circle("line", halfW * 0.25, -halfH * 0.3, halfW * 0.15)
        -- Nasal cavity
        love.graphics.polygon("line", 0, -halfH * 0.1, -halfW * 0.1, halfH * 0.05, halfW * 0.1, halfH * 0.05)
        
    elseif bottleType == "star" then
        -- Draw 5-pointed star bottle
        local points = {}
        local outerRadius = halfW * 0.8
        local innerRadius = halfW * 0.4
        for i = 0, 9 do
            local angle = i * math.pi / 5
            local radius = (i % 2 == 0) and outerRadius or innerRadius
            table.insert(points, math.cos(angle) * radius)
            table.insert(points, math.sin(angle) * radius)
        end
        love.graphics.polygon("line", points)
        
    elseif bottleType == "heart" then
        -- Draw heart shape
        local scale = halfW * 0.6
        love.graphics.circle("line", -scale * 0.5, -halfH * 0.2, scale * 0.5)
        love.graphics.circle("line", scale * 0.5, -halfH * 0.2, scale * 0.5)
        love.graphics.polygon("line", 
            -scale, halfH * 0.1, 
            0, halfH * 0.7, 
            scale, halfH * 0.1,
            scale * 0.5, -halfH * 0.2 + scale * 0.5,
            -scale * 0.5, -halfH * 0.2 + scale * 0.5
        )
        
    elseif bottleType == "diamond" then
        -- Draw diamond/gem shape
        love.graphics.polygon("line",
            0, -halfH * 0.8,           -- Top point
            -halfW * 0.4, -halfH * 0.3, -- Upper left
            -halfW * 0.6, halfH * 0.2,  -- Lower left
            0, halfH * 0.8,             -- Bottom point
            halfW * 0.6, halfH * 0.2,   -- Lower right
            halfW * 0.4, -halfH * 0.3   -- Upper right
        )
        -- Add facet lines
        love.graphics.line(0, -halfH * 0.8, 0, -halfH * 0.3)
        love.graphics.line(-halfW * 0.4, -halfH * 0.3, halfW * 0.4, -halfH * 0.3)
        
    elseif bottleType == "crystal_orb" then
        -- Draw crystal orb with facets
        love.graphics.circle("line", 0, 0, halfW * 0.7)
        -- Add crystal facet lines
        for i = 1, 6 do
            local angle = i * math.pi / 3
            local x1 = math.cos(angle) * halfW * 0.4
            local y1 = math.sin(angle) * halfW * 0.4
            local x2 = math.cos(angle) * halfW * 0.7
            local y2 = math.sin(angle) * halfW * 0.7
            love.graphics.line(x1, y1, x2, y2)
        end
        
    elseif bottleType == "nature_vial" then
        -- Draw nature vial with leaf decorations
        love.graphics.rectangle("line", -halfW * 0.3, -halfH * 0.7, halfW * 0.6, halfH * 1.2, halfW * 0.1)
        -- Cork/stopper
        love.graphics.rectangle("line", -halfW * 0.2, -halfH * 0.8, halfW * 0.4, halfH * 0.2)
        -- Leaf decorations
        for i = 1, 3 do
            local y = -halfH * 0.4 + (i - 1) * halfH * 0.3
            love.graphics.ellipse("line", halfW * 0.4, y, halfW * 0.2, halfH * 0.1)
            love.graphics.ellipse("line", -halfW * 0.4, y, halfW * 0.2, halfH * 0.1)
        end
        
    elseif bottleType == "grand_flask" then
        -- Draw grand flask with wide base and narrow neck
        love.graphics.circle("line", 0, halfH * 0.3, halfW * 0.8) -- Base
        love.graphics.rectangle("line", -halfW * 0.2, -halfH * 0.7, halfW * 0.4, halfH * 1.0) -- Neck
        love.graphics.rectangle("line", -halfW * 0.25, -halfH * 0.8, halfW * 0.5, halfH * 0.15) -- Lip
        
    elseif bottleType == "mystical_vial" then
        -- Draw mystical vial with swirling patterns
        love.graphics.rectangle("line", -halfW * 0.25, -halfH * 0.6, halfW * 0.5, halfH * 1.0, halfW * 0.05)
        -- Cork
        love.graphics.rectangle("line", -halfW * 0.2, -halfH * 0.7, halfW * 0.4, halfH * 0.15)
        -- Mystical swirls
        for i = 1, 2 do
            local offsetY = (i - 1) * halfH * 0.4 - halfH * 0.2
            love.graphics.arc("line", 0, offsetY, halfW * 0.15, 0, math.pi)
            love.graphics.arc("line", 0, offsetY + halfH * 0.2, halfW * 0.15, math.pi, math.pi * 2)
        end
        
    elseif bottleType == "elegant_bottle" then
        -- Draw elegant wine bottle shape
        love.graphics.circle("line", 0, halfH * 0.2, halfW * 0.6) -- Base
        love.graphics.rectangle("line", -halfW * 0.15, -halfH * 0.7, halfW * 0.3, halfH * 0.9) -- Neck
        love.graphics.circle("line", 0, -halfH * 0.7, halfW * 0.2) -- Top
        
    elseif bottleType == "herbal_jar" then
        -- Draw wide herbal jar
        love.graphics.rectangle("line", -halfW * 0.6, -halfH * 0.4, halfW * 1.2, halfH * 0.8, halfW * 0.1)
        -- Lid
        love.graphics.rectangle("line", -halfW * 0.7, -halfH * 0.5, halfW * 1.4, halfH * 0.15)
        -- Handle
        love.graphics.arc("line", halfW * 0.8, 0, halfW * 0.3, -math.pi/2, math.pi/2)
        
    elseif bottleType == "round_flask" then
        -- Draw round flask
        love.graphics.circle("line", 0, halfH * 0.1, halfW * 0.6)
        love.graphics.rectangle("line", -halfW * 0.1, -halfH * 0.6, halfW * 0.2, halfH * 0.7)
        love.graphics.circle("line", 0, -halfH * 0.6, halfW * 0.15)
        
    else -- default, standard, energy, or any unknown type
        -- Draw standard bottle shape
        love.graphics.rectangle("line", -halfW * 0.3, -halfH * 0.5, halfW * 0.6, halfH * 0.9, halfW * 0.05)
        -- Cork/cap
        love.graphics.rectangle("line", -halfW * 0.25, -halfH * 0.6, halfW * 0.5, halfH * 0.15)
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

    -- 4. Draw Bubbles (if any exist in gameState)
    if gameState.potionDisplay and gameState.potionDisplay.bubbles then
        for _, bubble in ipairs(gameState.potionDisplay.bubbles) do
            if bubble.x and bubble.y and bubble.size and bubble.color then
                love.graphics.setColor(bubble.color)
                love.graphics.circle("fill", bubble.x, bubble.y, bubble.size)
                
                -- Add a subtle glow effect
                love.graphics.setColor(bubble.color[1], bubble.color[2], bubble.color[3], bubble.color[4] * 0.3)
                love.graphics.circle("fill", bubble.x, bubble.y, bubble.size * 1.5)
            end
        end
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    -- 5. Draw Bottle Outline based on bottle type
    love.graphics.setColor(outlineColor)
    love.graphics.setLineWidth(2)
    
    Draw.drawBottleShape(currentBottleType, W, H)
    
    love.graphics.pop()
    love.graphics.setLineWidth(1)
end
-- =============================================================================
-- Main UI Drawing Functions (Called from main.lua's love.draw)
-- =============================================================================

--- Draws the current round goal and progress with improved formatting.
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
    local accentColor = colors.textEnergy or {0.4,0.7,1.0,1}
    local goalDescFont = fonts.ui or fonts.default
    local progressFont = fonts.small or fonts.default

    -- Draw panel background with subtle border
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, layoutCfg.cardCornerRadius or 5)
    love.graphics.setColor(colors.panelBorder or {0.3,0.3,0.4,0.8})
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, layoutCfg.cardCornerRadius or 5)

    -- Draw Round Number with accent color
    if goalDescFont then
        love.graphics.setFont(goalDescFont)
        love.graphics.setColor(accentColor)
        local roundText = "Round " .. tostring(gameState.currentRoundNumber or 0)
        local roundTextY = panelY + padding + (goalCfg.roundTextYOffset or 0)
        love.graphics.printf(roundText, panelX + padding, roundTextY, panelW - 2 * padding, "left")
    end
    
    -- Draw Goal Description with better formatting
    if goalDescFont then
        local goalDesc = gameState.currentRoundData.description or "No goal set."
        local goalDescY = panelY + padding + (goalCfg.goalTextYOffset or 18)
        love.graphics.setColor(textColor)
        love.graphics.printf(goalDesc, panelX + padding, goalDescY, panelW - 2 * padding, "left")
    end

    -- Draw Goal Progress with visual indicator
    if progressFont and dependencies.getGoalProgressString then
        love.graphics.setFont(progressFont)
        local progressText = dependencies.getGoalProgressString(gameState.currentRoundData, gameState)
        local progressTextY = panelY + padding + (goalCfg.progressTextYOffset or 38)
        
        -- Check if goal is met and use appropriate color
        local progressColor = textColor
        if gameState.roundCompletionPending then
            progressColor = colors.highlight or {1,1,0,1} -- Yellow for completed
        end
        
        love.graphics.setColor(progressColor)
        love.graphics.printf(progressText, panelX + padding, progressTextY, panelW - 2 * padding, "left")
    end
end

--- Draws the Energy Display with improved formatting.
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
    local energyColor = colors.textLight or {0.9, 0.9, 0.9, 1} -- Use light text for better readability
    local bgColor = colors.panelBackground or {0.2,0.2,0.25,0.9}
    
    local energyText = string.format("Day Energy: %d/%d", gameState.currentEnergy, gameCfg.energyPerRound or 100)
    
    -- Position (Top right corner, stacked above money)
    local textX, textY
    if uiCfg.goalDisplay and type(uiCfg.goalDisplay.y) == "number" and energyFont then
        -- Position at the far right of the screen, top of the stack
        local textW = energyFont:getWidth(energyText)
        local panelW = textW + 20 -- Add padding for background
        local panelH = 30 -- Fixed height for stacked panels
        textX = (config.Screen.width or 400) - panelW - (layout.paddingMedium or 10)
        textY = uiCfg.goalDisplay.y + 5 -- Top of the stack
        
        -- Draw background panel
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", textX - 10, textY - 4, panelW, panelH, layout.cornerRadius or 5)
        love.graphics.setColor(colors.panelBorder or {0.3,0.3,0.4,0.8})
        love.graphics.rectangle("line", textX - 10, textY - 4, panelW, panelH, layout.cornerRadius or 5)
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

--- Draws a visual energy progress bar below the energy text display.
function Draw.drawEnergyProgressBar(gameState, config, dependencies)
    if not gameState or type(gameState.currentEnergy) ~= "number" then print("Draw.drawEnergyProgressBar: Missing gameState.currentEnergy."); return end
    if not config or not config.Game or not config.UI then print("Draw.drawEnergyProgressBar: Missing Config.Game or Config.UI."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawEnergyProgressBar: Missing dependencies.theme."); return end

    local theme = dependencies.theme
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    local uiCfg = config.UI
    local gameCfg = config.Game

    local maxEnergy = gameCfg.energyPerRound or 100
    local currentEnergy = gameState.currentEnergy
    local energyRatio = math.max(0, math.min(1, currentEnergy / maxEnergy))
    
    -- Progress bar colors
    local barBgColor = colors.progressBarBackground or {0.1, 0.1, 0.15, 0.8}
    local barFillColor = colors.progressBarFill or {0.3, 0.7, 1.0, 1.0} -- Blue energy color
    local barBorderColor = colors.progressBarBorder or {0.3, 0.3, 0.4, 0.8}
    
    -- Change color based on energy level for visual feedback
    if energyRatio <= 0.25 then
        -- Low energy - red/orange warning
        barFillColor = {1.0, 0.4, 0.2, 1.0}
    elseif energyRatio <= 0.5 then
        -- Medium energy - yellow/orange
        barFillColor = {1.0, 0.7, 0.2, 1.0}
    end
    
    -- Progress bar dimensions and position
    local barHeight = 12
    local barX, barY
    
    -- Calculate bar width to match energy text panel width
    local energyText = string.format("Day Energy: %d/%d", currentEnergy, maxEnergy)
    local energyFont = theme.fonts and (theme.fonts.ui or theme.fonts.default)
    local textW = energyFont and energyFont:getWidth(energyText) or 150
    local panelW = textW + 20 -- Same padding as energy text panel
    local barWidth = panelW - 20 -- Slightly smaller than panel for visual balance
    
    -- Position below the energy text display
    if uiCfg.goalDisplay and type(uiCfg.goalDisplay.y) == "number" then
        -- Calculate the same X position as the energy text panel
        local energyText = string.format("Day Energy: %d/%d", currentEnergy, maxEnergy)
        local energyFont = theme.fonts and (theme.fonts.ui or theme.fonts.default)
        local textW = energyFont and energyFont:getWidth(energyText) or 150
        local panelW = textW + 20 -- Same padding as energy text panel
        local panelX = (config.Screen.width or 400) - panelW - (layout.paddingMedium or 10)
        barX = panelX + (panelW - barWidth) / 2 -- Center the bar within the panel
        barY = uiCfg.goalDisplay.y + 40 -- Below energy text panel (5 + 30 + 5 gap)
    else -- Fallback positioning
        barX = (config.Screen.width or 400) - barWidth - (layout.paddingMedium or 10)
        barY = (layout.paddingSmall or 5) + 40
    end
    
    local cornerRadius = math.min(barHeight / 2, 6)
    
    -- Draw background bar
    love.graphics.setColor(barBgColor)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, cornerRadius, cornerRadius)
    
    -- Draw border
    love.graphics.setColor(barBorderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, cornerRadius, cornerRadius)
    
    -- Draw fill bar
    if energyRatio > 0 then
        local fillWidth = barWidth * energyRatio
        love.graphics.setColor(barFillColor)
        love.graphics.rectangle("fill", barX, barY, fillWidth, barHeight, cornerRadius, cornerRadius)
        
        -- Add a subtle highlight/glow effect for the fill
        local highlightColor = {barFillColor[1] + 0.2, barFillColor[2] + 0.2, barFillColor[3] + 0.2, 0.6}
        love.graphics.setColor(highlightColor)
        love.graphics.rectangle("fill", barX, barY, fillWidth, barHeight / 3, cornerRadius, cornerRadius)
        
        -- Add a subtle glow effect when energy is high (above 75%)
        if energyRatio > 0.75 then
            local glowColor = {barFillColor[1], barFillColor[2], barFillColor[3], 0.3}
            love.graphics.setColor(glowColor)
            love.graphics.rectangle("fill", barX - 2, barY - 2, fillWidth + 4, barHeight + 4, cornerRadius + 2, cornerRadius + 2)
        end
    end
    
    -- Draw energy percentage text on the bar
    local percentageFont = theme.fonts and theme.fonts.small or theme.fonts and theme.fonts.default
    if percentageFont then
        local percentageText = string.format("%d%%", math.floor(energyRatio * 100))
        local textColor = colors.textLight or {0.9, 0.9, 0.9, 1}
        
        love.graphics.setFont(percentageFont)
        love.graphics.setColor(textColor)
        
        local textWidth = percentageFont:getWidth(percentageText)
        local textHeight = percentageFont:getHeight()
        local textX = barX + (barWidth - textWidth) / 2
        local textY = barY + (barHeight - textHeight) / 2
        
        love.graphics.print(percentageText, textX, textY)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draws the Money Display with improved formatting.
function Draw.drawMoneyDisplay(gameState, config, dependencies)
    if not gameState or type(gameState.wallet) ~= "number" then print("Draw.drawMoneyDisplay: Missing gameState.wallet."); return end
    if not config or not config.UI then print("Draw.drawMoneyDisplay: Missing Config.UI."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawMoneyDisplay: Missing dependencies.theme."); return end

    local theme = dependencies.theme
    local fonts = theme.fonts or {}
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    local uiCfg = config.UI

    local moneyFont = fonts.ui or fonts.default
    local moneyColor = colors.textLight or {0.9, 0.9, 0.9, 1} -- Use light text for better readability
    local bgColor = colors.panelBackground or {0.2,0.2,0.25,0.9}
    
    local moneyText = string.format("Money: $%d", gameState.wallet or 0)
    
    -- Position (Top right corner, stacked below energy)
    local textX, textY
    if uiCfg.goalDisplay and type(uiCfg.goalDisplay.y) == "number" and moneyFont then
        -- Position below energy panel in the stack
        local textW = moneyFont:getWidth(moneyText)
        local panelW = textW + 20 -- Add padding for background
        local panelH = 30 -- Fixed height for stacked panels
        
        -- Use same X position as energy (right-aligned)
        textX = (config.Screen.width or 400) - panelW - (layout.paddingMedium or 10)
        textY = uiCfg.goalDisplay.y + 40 -- Below energy panel (5 + 30 + 5 gap)
        
        -- Draw background panel
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", textX - 10, textY - 4, panelW, panelH, layout.cornerRadius or 5)
        love.graphics.setColor(colors.panelBorder or {0.3,0.3,0.4,0.8})
        love.graphics.rectangle("line", textX - 10, textY - 4, panelW, panelH, layout.cornerRadius or 5)
    else -- Fallback positioning
        textX = (config.Screen.width or 400) / 2 - (moneyFont and moneyFont:getWidth(moneyText) or 100) / 2
        textY = (layout.paddingSmall or 5)
    end

    if moneyFont then
        local originalFont = love.graphics.getFont()
        love.graphics.setFont(moneyFont)
        love.graphics.setColor(moneyColor)
        love.graphics.print(moneyText, textX, textY)
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
    Draw.drawPotionBottle(areaX, areaY, pdState.bottleType, pdState.fillColor, pdState.fillLevel, gameState, config, dependencies)

    -- Draw Bubbles
    if pdState.isBubbling and pdState.bubbles and #pdState.bubbles > 0 then
        love.graphics.push()
        love.graphics.translate(areaX, areaY) -- Translate to bottle center for bubble relative positions
        
        local bubbleBaseColor = pdState.fillColor or {0.5,0.8,1} -- Bubbles match liquid or a highlight
        
        for _, bubble in ipairs(pdState.bubbles) do
            if type(bubble) == "table" and type(bubble.x) == "number" then
                local alpha = bubble.alpha or 1.0
                local radius = bubble.radius or 5
                local bubbleType = bubble.bubbleType or "normal"
                
                -- Draw different bubble types with special effects
                if bubbleType == "magical" then
                    -- Magical bubbles have a shimmering rainbow effect
                    local shimmerOffset = (bubble.shimmer or 0) * 0.1
                    local magicalColor = {
                        0.5 + 0.3 * math.sin(bubble.shimmer or 0),
                        0.5 + 0.3 * math.sin((bubble.shimmer or 0) + 2),
                        0.8 + 0.2 * math.sin((bubble.shimmer or 0) + 4)
                    }
                    
                    -- Pulsing size
                    local pulseSize = radius * (1 + 0.1 * math.sin(bubble.pulsePhase or 0))
                    
                    love.graphics.setColor(magicalColor[1], magicalColor[2], magicalColor[3], alpha * 0.8)
                    love.graphics.circle("fill", bubble.x, bubble.y, pulseSize)
                    
                    -- Magical aura
                    love.graphics.setColor(magicalColor[1], magicalColor[2], magicalColor[3], alpha * 0.3)
                    love.graphics.circle("line", bubble.x, bubble.y, pulseSize * 1.3)
                    
                elseif bubbleType == "sparkly" then
                    -- Sparkly bubbles are bright with sparkle particles
                    love.graphics.setColor(1, 1, 0.8, alpha * 0.9) -- Bright golden
                    love.graphics.circle("fill", bubble.x, bubble.y, radius)
                    
                    -- Draw sparkles
                    if bubble.sparkles then
                        for _, sparkle in ipairs(bubble.sparkles) do
                            local sparkleAlpha = (sparkle.life / sparkle.maxLife) * alpha
                            love.graphics.setColor(1, 1, 1, sparkleAlpha)
                            love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
                        end
                    end
                    
                elseif bubbleType == "glowing" then
                    -- Glowing bubbles have a warm pulsing glow
                    local glowIntensity = bubble.glowIntensity or 0.5
                    local glowColor = bubble.glowColor or {1, 1, 0.8}
                    
                    -- Main bubble
                    love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], alpha * 0.8)
                    love.graphics.circle("fill", bubble.x, bubble.y, radius)
                    
                    -- Glow effect
                    love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], alpha * glowIntensity * 0.4)
                    love.graphics.circle("fill", bubble.x, bubble.y, radius * 1.5)
                    love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], alpha * glowIntensity * 0.2)
                    love.graphics.circle("fill", bubble.x, bubble.y, radius * 2)
                    
                else
                    -- Normal bubbles (original behavior)
                    love.graphics.setColor(bubbleBaseColor[1], bubbleBaseColor[2], bubbleBaseColor[3], alpha * 0.7)
                    love.graphics.circle("fill", bubble.x, bubble.y, radius)
                end
                
                -- Standard highlight for all bubble types
                love.graphics.setColor(1, 1, 1, alpha * 0.5)
                love.graphics.circle("fill", bubble.x - radius * 0.3, bubble.y - radius * 0.3, radius * 0.3)
            end
        end
        love.graphics.pop()
    end
    
    -- Draw Magical Effects (swirls and sparkles)
    if pdState.magicalEffects then
        love.graphics.push()
        love.graphics.translate(areaX, areaY) -- Translate to bottle center for effect relative positions
        
        local effects = pdState.magicalEffects
        
        -- Draw swirls
        for _, swirl in ipairs(effects.swirls) do
            if swirl.color and swirl.color[4] > 0 then
                love.graphics.setColor(swirl.color)
                
                -- Calculate swirl position
                local swirlX = math.cos(swirl.angle) * swirl.radius
                local swirlY = math.sin(swirl.angle) * swirl.radius * 0.5 -- Flatten for bottle shape
                
                -- Draw swirl as a small circle with trailing effect
                love.graphics.circle("fill", swirlX, swirlY, 3)
                
                -- Draw trailing swirl segments
                for i = 1, 3 do
                    local trailAngle = swirl.angle - (i * 0.3 * swirl.direction)
                    local trailX = math.cos(trailAngle) * swirl.radius
                    local trailY = math.sin(trailAngle) * swirl.radius * 0.5
                    local trailAlpha = swirl.color[4] * (1 - i * 0.3)
                    
                    love.graphics.setColor(swirl.color[1], swirl.color[2], swirl.color[3], trailAlpha)
                    love.graphics.circle("fill", trailX, trailY, 3 - i * 0.5)
                end
            end
        end
        
        -- Draw sparkles
        for _, sparkle in ipairs(effects.sparkles) do
            if sparkle.color and sparkle.color[4] > 0 then
                love.graphics.setColor(sparkle.color)
                love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
                
                -- Add sparkle cross effect
                love.graphics.setColor(sparkle.color[1], sparkle.color[2], sparkle.color[3], sparkle.color[4] * 0.8)
                love.graphics.rectangle("fill", sparkle.x - sparkle.size * 1.5, sparkle.y - 0.5, sparkle.size * 3, 1)
                love.graphics.rectangle("fill", sparkle.x - 0.5, sparkle.y - sparkle.size * 1.5, 1, sparkle.size * 3)
            end
        end
        
        -- Draw glow effect around the bottle during magical moments
        if effects.glowPulse then
            local glowIntensity = (math.sin(effects.glowPulse) + 1) * 0.5 * 0.3 -- Pulse between 0 and 0.3
            local glowColor = pdState.fillColor or {0.5, 0.5, 0.5}
            
            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], glowIntensity)
            love.graphics.circle("line", 0, 0, (bottleW + bottleH) * 0.4)
            love.graphics.circle("line", 0, 0, (bottleW + bottleH) * 0.45)
        end
        
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
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
                Draw.drawCardObject(card, config, dependencies, gameState)
            end
        end
    end

    -- If a card is being dragged, re-draw it on top of everything else in the hand
    if gameState.drag and gameState.drag.isDragging and gameState.drag.cardIndex then
        local draggedCardInstance = hand[gameState.drag.cardIndex]
        if draggedCardInstance and type(draggedCardInstance) == "table" and not draggedCardInstance.isDiscarding then
            Draw.drawCardObject(draggedCardInstance, config, dependencies, gameState)
        end
    end
end

--- Draws UI elements for spell targeting (legacy system for non-hand_card targets).
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

    -- Only show targeting UI for non-hand_card targets (legacy system)
    if spell.target == "hand_card" then
        return -- hand_card targets now use card selection system
    end

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

--- Draws the spell casting mode UI with cast button and spell info.
function Draw.drawSpellCastingModeUI(gameState, config, dependencies)
    if not gameState or not gameState.spellCastingMode or not gameState.selectedSpellId then return end
    if not gameState.knownSpells or not gameState.knownSpells[gameState.selectedSpellId] then return end
    if not config or not config.Screen then print("Draw.drawSpellCastingModeUI: Missing Config.Screen."); return end
    if not dependencies or not dependencies.theme then print("Draw.drawSpellCastingModeUI: Missing dependencies.theme."); return end

    local spell = gameState.knownSpells[gameState.selectedSpellId]
    local theme = dependencies.theme
    local fonts = theme.fonts or {}
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    
    local uiFont = fonts.ui or fonts.default
    local smallFont = fonts.small or fonts.default
    local textColor = colors.textDark or {0.1,0.1,0.1,1}
    local buttonColor = colors.buttonSpellActive or {0.8, 0.6, 0.9, 1}
    local cancelColor = colors.buttonClose or {0.9, 0.5, 0.5, 1}
    
    local screenW = config.Screen.width or 400
    local screenH = config.Screen.height or 600
    local padding = layout.paddingMedium or 10
    
    -- Calculate position above the hand (assuming hand is at bottom)
    local handBaseY = layout.handBaseY or (screenH * 0.85)
    local uiY = handBaseY - 80 -- Position above the hand
    
    -- Draw background panel
    local panelW = 300
    local panelH = 70
    local panelX = (screenW - panelW) / 2
    
    love.graphics.setColor(colors.panelBackground or {0.2, 0.2, 0.25, 0.9})
    love.graphics.rectangle("fill", panelX, uiY, panelW, panelH, layout.cornerRadius or 5)
    love.graphics.setColor(colors.panelBorder or {0.3, 0.3, 0.4, 1})
    love.graphics.rectangle("line", panelX, uiY, panelW, panelH, layout.cornerRadius or 5)
    
    -- Draw spell name and description
    if uiFont then
        love.graphics.setFont(uiFont)
        love.graphics.setColor(textColor)
        local spellName = spell.name or "Unknown Spell"
        local energyCost = spell.energyCost or 0
        local nameText = string.format("Casting: %s (E: %d)", spellName, energyCost)
        love.graphics.printf(nameText, panelX + padding, uiY + 5, panelW - 2 * padding, "center")
    end
    
    if smallFont then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(textColor)
        local description = spell.description or ""
        love.graphics.printf(description, panelX + padding, uiY + 25, panelW - 2 * padding, "center")
    end
    
    -- Draw cast button (if card is selected)
    local hasSelectedCard = gameState.selectedCardIndices and #gameState.selectedCardIndices > 0
    local buttonW = 80
    local buttonH = 25
    local buttonX = panelX + (panelW - buttonW) / 2
    local buttonY = uiY + panelH - buttonH - 5
    
    if hasSelectedCard then
        love.graphics.setColor(buttonColor)
        love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, layout.cornerRadius or 3)
        love.graphics.setColor(textColor)
        love.graphics.rectangle("line", buttonX, buttonY, buttonW, buttonH, layout.cornerRadius or 3)
        
        if uiFont then
            love.graphics.setFont(uiFont)
            love.graphics.setColor(textColor)
            love.graphics.printf("Cast", buttonX, buttonY + 2, buttonW, "center")
        end
    else
        -- Show "Select a card" message
        if smallFont then
            love.graphics.setFont(smallFont)
            love.graphics.setColor({0.6, 0.6, 0.6, 1})
            love.graphics.printf("Select a card to cast on", buttonX, buttonY + 5, buttonW, "center")
        end
    end
    
    -- Draw cancel button
    local cancelW = 60
    local cancelH = 20
    local cancelX = panelX + panelW - cancelW - 5
    local cancelY = uiY + 5
    
    love.graphics.setColor(cancelColor)
    love.graphics.rectangle("fill", cancelX, cancelY, cancelW, cancelH, layout.cornerRadius or 3)
    love.graphics.setColor(textColor)
    love.graphics.rectangle("line", cancelX, cancelY, cancelW, cancelH, layout.cornerRadius or 3)
    
    if smallFont then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(textColor)
        love.graphics.printf("Exit", cancelX, cancelY + 2, cancelW, "center")
    end
end

--- Draws the energy elixir count display.
function Draw.drawEnergyElixirDisplay(gameState, config, dependencies)
    if not gameState then return end
    if not config or not config.UI then return end
    if not dependencies or not dependencies.theme then return end

    local theme = dependencies.theme
    local colors = theme.colors or {}
    local fonts = theme.fonts or {}
    local layout = theme.layout or {}
    
    local elixirCount = gameState.energyElixirs and #gameState.energyElixirs or 0
    if elixirCount == 0 then return end -- Don't draw if no elixirs
    
    local uiFont = fonts.ui or fonts.default
    local smallFont = fonts.small or fonts.default
    local textColor = colors.textLight or {0.9, 0.9, 0.9, 1}
    local elixirColor = colors.textEnergy or {0.3, 0.7, 1.0, 1}
    
    local screenW = config.Screen.width or 400
    local screenH = config.Screen.height or 600
    local padding = layout.paddingSmall or 5
    
    -- Position in top-right corner, below energy display
    local textX = screenW - 150
    local textY = 60 -- Below energy display
    
    if uiFont then
        local originalFont = love.graphics.getFont()
        love.graphics.setFont(uiFont)
        love.graphics.setColor(elixirColor)
        
        local elixirText = string.format("Elixirs: %d", elixirCount)
        love.graphics.print(elixirText, textX, textY)
        
        -- Draw small elixir icon
        local iconSize = 12
        local iconX = textX + uiFont:getWidth(elixirText) + 5
        local iconY = textY + 2
        
        -- Draw bottle outline
        love.graphics.setColor({0.8, 0.8, 0.8, 1})
        love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize * 1.5, 2)
        
        -- Draw elixir liquid
        love.graphics.setColor(elixirColor)
        love.graphics.rectangle("fill", iconX + 1, iconY + 1, iconSize - 2, (iconSize * 1.5) - 2, 1)
        
        -- Draw bottle neck
        love.graphics.setColor({0.8, 0.8, 0.8, 1})
        local neckWidth = iconSize * 0.3
        local neckHeight = iconSize * 0.2
        local neckX = iconX + (iconSize - neckWidth) / 2
        local neckY = iconY - neckHeight
        love.graphics.rectangle("fill", neckX, neckY, neckWidth, neckHeight, 1)
        
        love.graphics.setFont(originalFont)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
end

return Draw