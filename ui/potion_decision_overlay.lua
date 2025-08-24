-- File: ui/potion_decision_overlay.lua (Formatted)
-- Defines the overlay shown after crafting a potion, allowing the player to choose Drink or Sell.
-- Uses injected dependencies.

local Button -- Expected to be passed in config.ButtonClass

local PotionDecisionOverlay = {}
PotionDecisionOverlay.__index = PotionDecisionOverlay

--- Creates a new PotionDecisionOverlay instance.
-- @param config Table containing dependencies and settings.
function PotionDecisionOverlay:new(config)
    -- 1. Validate Configuration and Dependencies
    assert(config and config.name, "PotionDecisionOverlay:new requires config.name")
    assert(config.uiManager, "PotionDecisionOverlay:new requires config.uiManager")
    assert(config.gameState, "PotionDecisionOverlay:new requires config.gameState")
    assert(config.theme and config.theme.fonts and config.theme.colors and 
           config.theme.layout and config.theme.sizes and 
           config.theme.cornerRadius and config.theme.helpers, 
           "PotionDecisionOverlay:new requires a valid config.theme table")
    assert(config.theme.fonts.large and config.theme.fonts.ui and config.theme.fonts.default, 
           "PotionDecisionOverlay:new requires large, ui, and default fonts in config.theme.fonts")
    assert(config.theme.helpers.calculateOverlayPanelRect and 
           config.theme.helpers.drawOverlayBase and 
           config.theme.helpers.isPointInRect and 
           config.theme.helpers.drawPotionBottle, 
           "PotionDecisionOverlay:new requires helper functions (calculateOverlayPanelRect, drawOverlayBase, isPointInRect, drawPotionBottle) in config.theme.helpers")
    assert(config.ButtonClass, "PotionDecisionOverlay:new requires config.ButtonClass")
    assert(config.potionActions and type(config.potionActions.drink) == "function" and 
           type(config.potionActions.sell) == "function", 
           "PotionDecisionOverlay:new requires config.potionActions table with drink and sell functions")

    local instance = setmetatable({}, PotionDecisionOverlay)

    -- 2. Store Dependencies
    instance.name = config.name
    instance.uiManager = config.uiManager
    instance.gameState = config.gameState
    instance.theme = config.theme
    instance.potionActions = config.potionActions
    Button = config.ButtonClass -- Set module-level local for Button class

    -- 3. Initial UI Setup
    instance.panelRect = instance.theme.helpers.calculateOverlayPanelRect(instance.theme) 
                        or { x = 20, y = 20, width = 350, height = 450 } -- Fallback rect
    
    -- Initialize animation state for point breakdown
    instance.pointAnimation = {
        isAnimating = false,
        animProgress = 0,
        animDuration = 2.0, -- 2 seconds for full animation
        currentStep = 0,
        totalSteps = 0,
        stepDelay = 0.4, -- Delay between each line appearing
        stepTimer = 0,
        visibleLines = {},
        fadeInDuration = 0.2, -- How long each line takes to fade in
        lineTimers = {}, -- Individual timers for each line's fade-in
        scrollOffset = 0 -- For scrolling if content is too long
    }

    -- Cache theme values for button creation
    local theme = instance.theme
    local defaultButtonRadius = theme.cornerRadius.default or 5
    local choiceButtonWidth = theme.sizes.decisionButtonWidth or 120
    local choiceButtonHeight = theme.sizes.decisionButtonHeight or 40
    local drinkButtonColor = theme.colors.buttonDrink or {0.6, 0.9, 0.6, 1}
    local sellButtonColor = theme.colors.buttonSell or {0.9, 0.8, 0.6, 1}

    local buttonDefaultSettings = {
        defaultFont = theme.fonts.default,
        defaultCornerRadius = defaultButtonRadius,
        defaultColors = theme.colors -- Pass the whole theme colors table for button defaults
    }

    -- Create Drink Button
    instance.drinkButton = Button:new({
        id = "potionDrink", 
        x = 0, y = 0, -- Positioned in draw()
        width = choiceButtonWidth, height = choiceButtonHeight,
        label = "Drink", 
        font = theme.fonts.ui,
        cornerRadius = defaultButtonRadius,
        colors = { normal = drinkButtonColor }, -- Override normal color for this specific button
        onClick = function() instance.potionActions.drink() end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    -- Create Sell Button
    instance.sellButton = Button:new({
        id = "potionSell", 
        x = 0, y = 0, -- Positioned in draw()
        width = choiceButtonWidth, height = choiceButtonHeight,
        label = "Sell", 
        font = theme.fonts.ui,
        cornerRadius = defaultButtonRadius,
        colors = { normal = sellButtonColor }, -- Override normal color
        onClick = function() instance.potionActions.sell() end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    return instance
end

--- Updates the state of buttons within the decision overlay.
function PotionDecisionOverlay:update(dt, mx, my, isMouseButtonDown)
    if not self.drinkButton or not self.sellButton then
        print("Warning (PotionDecisionOverlay:update): Buttons not initialized.")
        return
    end

    -- Update point animation
    if self.pointAnimation.isAnimating then
        self.pointAnimation.stepTimer = self.pointAnimation.stepTimer + dt
        
        if self.pointAnimation.stepTimer >= self.pointAnimation.stepDelay then
            self.pointAnimation.stepTimer = 0
            self.pointAnimation.currentStep = self.pointAnimation.currentStep + 1
            
            -- Initialize timer for the new line
            self.pointAnimation.lineTimers[self.pointAnimation.currentStep] = 0
            
            if self.pointAnimation.currentStep >= self.pointAnimation.totalSteps then
                self.pointAnimation.isAnimating = false
            end
        end
        
        -- Update individual line timers for fade-in effect
        for step, timer in pairs(self.pointAnimation.lineTimers) do
            if step <= self.pointAnimation.currentStep then
                self.pointAnimation.lineTimers[step] = timer + dt
            end
        end
        
        -- Auto-scroll if content is too long
        if self.gameState and self.gameState.pendingPotionChoice and self.gameState.pendingPotionChoice.pointBreakdown then
            local breakdown = self.gameState.pendingPotionChoice.pointBreakdown
            local totalLines = #breakdown.typeMatches + #breakdown.valueMatches
            if breakdown.flushBonus > 0 then totalLines = totalLines + 1 end
            if breakdown.cardValueBonus > 0 then totalLines = totalLines + 1 end
            totalLines = totalLines + 1 -- For total line
            
            local lineHeight = (self.theme.fonts.ui or self.theme.fonts.default):getHeight() + (self.theme.layout.paddingSmall or 5)
            local contentHeight = totalLines * lineHeight
            local availableHeight = self.panelRect.height - (self.panelRect.y + (self.theme.layout.paddingLarge or 20) + (self.theme.sizes.bottleHeight or 90) + (self.theme.layout.paddingLarge or 20) + (self.theme.fonts.ui or self.theme.fonts.default):getHeight() + (self.theme.layout.paddingSmall or 5)) - ((self.theme.layout.paddingLarge or 20) + (self.drinkButton and self.drinkButton.height or 40))
            
            if contentHeight > availableHeight then
                local maxScroll = contentHeight - availableHeight
                local scrollProgress = self.pointAnimation.currentStep / self.pointAnimation.totalSteps
                self.pointAnimation.scrollOffset = maxScroll * scrollProgress
            end
        end
    end

    -- Update buttons, passing required input state
    self.drinkButton:update(dt, mx, my, isMouseButtonDown)
    self.sellButton:update(dt, mx, my, isMouseButtonDown)

    -- Ensure buttons are enabled; this overlay being active generally means they should be.
    -- Future: Consider edge cases where one might be disabled (e.g., cannot drink if at max effect).
    self.drinkButton:setEnabled(true)
    self.sellButton:setEnabled(true)
end

--- Draws the potion decision overlay UI.
-- File: ui/potion_decision_overlay.lua (Modified draw function snippet)

--- Draws the potion decision overlay UI.
-- File: ui/potion_decision_overlay.lua

function PotionDecisionOverlay:draw()
    -- Only draw if this overlay is active
    if self.uiManager:getActiveOverlayName() ~= self.name then
        return
    end

    -- Check for critical missing dependencies for the overlay itself
    if not self.gameState or not self.theme or not self.drinkButton or not self.sellButton then
        print("ERROR (PotionDecisionOverlay:draw): Missing critical dependencies or buttons for the overlay.")
        return
    end
    local pendingPotion = self.gameState.pendingPotionChoice
    if not pendingPotion or type(pendingPotion) ~= "table" then
        print("Error (PotionDecisionOverlay:draw): GameState.pendingPotionChoice missing or invalid.")
        return
    end
    if not love or not love.graphics then
        print("Error (PotionDecisionOverlay:draw): LÖVE graphics module not available.")
        return
    end

    -- Cache theme elements for readability
    local theme = self.theme
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    local fonts = theme.fonts or {}
    local sizes = theme.sizes or {}
    local helpers = theme.helpers or {}

    local paddingSmall = layout.paddingSmall or 5
    local paddingMedium = layout.paddingMedium or 10
    local paddingLarge = layout.paddingLarge or 20
    
    local titleTextColor = colors.textDark or {0.1, 0.1, 0.1, 1}
    local effectTextColor = colors.textPotionBonus or {0.5, 0.2, 0.5, 1}
    local valueTextColor = colors.textScore or {0.8, 0.7, 0.1, 1}

    -- 1. Recalculate Panel and Draw Base
    self.panelRect = (helpers.calculateOverlayPanelRect and helpers.calculateOverlayPanelRect(theme)) or self.panelRect
    if helpers.drawOverlayBase then helpers.drawOverlayBase(self.panelRect, theme) end

    -- Store current graphics state to restore later
    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Title
    local titleFontToUse = fonts.large or fonts.default
    local titleTextY = self.panelRect.y + paddingMedium
    if titleFontToUse then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(titleFontToUse)
        love.graphics.printf("Potion Crafted!", self.panelRect.x, titleTextY, self.panelRect.width, "center")
    end
    local titleActualHeight = titleFontToUse and titleFontToUse:getHeight() or 20

    -- 3. Draw Potion Details
    local currentY = self.panelRect.y + paddingMedium + titleActualHeight + paddingLarge
    local contentStartX = self.panelRect.x + paddingLarge
    local contentAvailableWidth = self.panelRect.width - (paddingLarge * 2)
    local detailFont = fonts.ui or fonts.default

    if not detailFont then 
        print("Warning (PotionDecisionOverlay:draw): Detail font (fonts.ui or fonts.default) is missing.")
        love.graphics.setFont(originalFont); love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
        return
    end
    love.graphics.setFont(detailFont)

    -- Potion Name
    love.graphics.setColor(titleTextColor)
    love.graphics.printf(pendingPotion.name or "Unknown Potion", contentStartX, currentY, contentAvailableWidth, "center")
    currentY = currentY + detailFont:getHeight() + paddingLarge

    -- Draw Potion Bottle Visual
    local bottleDisplayData = pendingPotion.display or {}
    local bottleVisualHeight = sizes.bottleHeight or 90
    local bottleVisualX = self.panelRect.x + self.panelRect.width / 2
    local bottleVisualY = currentY + bottleVisualHeight / 2 
    
    if helpers.drawPotionBottle then
        -- The 'theme' argument passed here is self.theme (which is Dependencies.theme from main.lua)
        -- The wrapper in main.lua's Dependencies.theme.helpers is responsible for calling Draw.drawPotionBottle with GameState, Config, Dependencies
        helpers.drawPotionBottle(bottleVisualX, bottleVisualY, 
                                 bottleDisplayData.bottle, bottleDisplayData.color, 
                                 1.0, theme) 
        
        -- Add special visual effects based on bottle type
        local bottleType = bottleDisplayData.bottle or "default"
        local potionColor = bottleDisplayData.color or {0.5, 0.5, 0.5}
        local time = love.timer.getTime()
        
        if bottleType == "skull" then
            -- Skull bottle gets dark magical aura with floating spirits
            local pulse = (math.sin(time * 2) + 1) * 0.5
            love.graphics.setColor(0.5, 0.1, 0.8, pulse * 0.4)
            love.graphics.circle("fill", bottleVisualX, bottleVisualY, bottleVisualHeight * 0.9)
            -- Floating spirits
            for i = 1, 3 do
                local spiritAngle = time * 0.5 + i * math.pi * 2 / 3
                local spiritX = bottleVisualX + math.cos(spiritAngle) * bottleVisualHeight * 0.6
                local spiritY = bottleVisualY + math.sin(spiritAngle) * bottleVisualHeight * 0.4
                love.graphics.setColor(0.8, 0.8, 1, 0.6)
                love.graphics.circle("fill", spiritX, spiritY, 3)
            end
            
        elseif bottleType == "crystal_orb" then
            -- Magical crystal orb gets shimmering aura
            local shimmer = (math.sin(time * 3) + 1) * 0.5
            love.graphics.setColor(0.8, 0.6, 1, shimmer * 0.3)
            love.graphics.circle("line", bottleVisualX, bottleVisualY, bottleVisualHeight * 0.6)
            love.graphics.circle("line", bottleVisualX, bottleVisualY, bottleVisualHeight * 0.7)
            
        elseif bottleType == "cauldron" then
            -- Cauldron gets bubbling steam effect
            for i = 1, 8 do
                local bubbleTime = time * 2 + i * 0.3
                local bubbleY = bottleVisualY - bottleVisualHeight * 0.3 - (bubbleTime % 2) * bottleVisualHeight * 0.4
                local bubbleX = bottleVisualX + math.sin(bubbleTime) * 10
                local bubbleAlpha = 1 - (bubbleTime % 2) / 2
                love.graphics.setColor(0.9, 0.9, 0.9, bubbleAlpha * 0.6)
                love.graphics.circle("fill", bubbleX, bubbleY, 2 + math.sin(bubbleTime * 3))
            end
            
        elseif bottleType == "teapot" then
            -- Teapot gets steam from spout
            for i = 1, 5 do
                local steamTime = time * 1.5 + i * 0.2
                local steamY = bottleVisualY - bottleVisualHeight * 0.2 - (steamTime % 1.5) * bottleVisualHeight * 0.3
                local steamX = bottleVisualX + bottleVisualHeight * 0.4 + math.sin(steamTime * 4) * 8
                local steamAlpha = 1 - (steamTime % 1.5) / 1.5
                love.graphics.setColor(1, 1, 1, steamAlpha * 0.7)
                love.graphics.circle("fill", steamX, steamY, 3)
            end
            
        elseif bottleType == "star" then
            -- Star bottle gets twinkling stars around it
            for i = 1, 12 do
                local twinkleAngle = (i / 12) * math.pi * 2
                local twinkleRadius = bottleVisualHeight * (0.6 + math.sin(time * 3 + i) * 0.1)
                local twinkleX = bottleVisualX + math.cos(twinkleAngle) * twinkleRadius
                local twinkleY = bottleVisualY + math.sin(twinkleAngle) * twinkleRadius
                local twinkleAlpha = (math.sin(time * 4 + i) + 1) * 0.5
                love.graphics.setColor(1, 1, 0.6, twinkleAlpha * 0.8)
                love.graphics.circle("fill", twinkleX, twinkleY, 2)
            end
            
        elseif bottleType == "heart" then
            -- Heart bottle gets floating hearts
            for i = 1, 4 do
                local heartTime = time * 1.2 + i * 0.5
                local heartY = bottleVisualY - (heartTime % 2) * bottleVisualHeight * 0.5
                local heartX = bottleVisualX + math.sin(heartTime * 2) * 20
                local heartAlpha = 1 - (heartTime % 2) / 2
                love.graphics.setColor(1, 0.4, 0.6, heartAlpha * 0.7)
                -- Simple heart shape
                love.graphics.circle("fill", heartX - 3, heartY - 2, 3)
                love.graphics.circle("fill", heartX + 3, heartY - 2, 3)
                love.graphics.polygon("fill", heartX - 6, heartY, heartX, heartY + 8, heartX + 6, heartY)
            end
            
        elseif bottleType == "diamond" then
            -- Diamond bottle gets prismatic light rays
            for i = 1, 8 do
                local rayAngle = (i / 8) * math.pi * 2 + time * 0.5
                local rayLength = bottleVisualHeight * 0.8
                local rayX1 = bottleVisualX + math.cos(rayAngle) * bottleVisualHeight * 0.3
                local rayY1 = bottleVisualY + math.sin(rayAngle) * bottleVisualHeight * 0.3
                local rayX2 = bottleVisualX + math.cos(rayAngle) * rayLength
                local rayY2 = bottleVisualY + math.sin(rayAngle) * rayLength
                local hue = (i / 8 + time * 0.2) % 1
                local r = math.abs(math.sin(hue * math.pi * 2))
                local g = math.abs(math.sin((hue + 0.33) * math.pi * 2))
                local b = math.abs(math.sin((hue + 0.66) * math.pi * 2))
                love.graphics.setColor(r, g, b, 0.6)
                love.graphics.line(rayX1, rayY1, rayX2, rayY2)
            end
            
        elseif bottleType == "nature_vial" then
            -- Nature vial gets green sparkles
            for i = 1, 6 do
                local angle = (i / 6) * math.pi * 2 + time
                local radius = bottleVisualHeight * 0.5
                local sparkleX = bottleVisualX + math.cos(angle) * radius
                local sparkleY = bottleVisualY + math.sin(angle) * radius * 0.7
                love.graphics.setColor(0.4, 0.9, 0.4, 0.8)
                love.graphics.circle("fill", sparkleX, sparkleY, 2)
            end
            
        elseif bottleType == "grand_flask" then
            -- Grand flask gets golden glow
            love.graphics.setColor(1, 0.8, 0.2, 0.4)
            love.graphics.circle("fill", bottleVisualX, bottleVisualY, bottleVisualHeight * 0.8)
            love.graphics.setColor(1, 0.9, 0.4, 0.6)
            love.graphics.circle("line", bottleVisualX, bottleVisualY, bottleVisualHeight * 0.6)
            
        elseif bottleType == "mystical_vial" then
            -- Mystical vial gets purple energy
            for i = 1, 4 do
                local offset = i * math.pi * 0.5 + time * 2
                local waveX = bottleVisualX + math.sin(offset) * 15
                local waveY = bottleVisualY + math.cos(offset) * 10
                love.graphics.setColor(0.6, 0.2, 0.8, 0.5)
                love.graphics.circle("fill", waveX, waveY, 3)
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    else
        print("Warning (PotionDecisionOverlay:draw): drawPotionBottle helper missing from theme.")
        love.graphics.setColor(0.7,0.7,0.7,1); love.graphics.rectangle("fill", bottleVisualX - 20, currentY, 40, bottleVisualHeight);
    end
    currentY = currentY + bottleVisualHeight + paddingLarge

    -- Draw Animated Point Breakdown
    if pendingPotion.pointBreakdown then
        local breakdown = pendingPotion.pointBreakdown
        local lineHeight = detailFont:getHeight() + paddingSmall
        local breakdownY = currentY
        
        -- Calculate available space for breakdown (leave room for buttons)
        local buttonAreaHeight = paddingLarge + (self.drinkButton and self.drinkButton.height or 40)
        local maxBreakdownHeight = self.panelRect.height - (breakdownY - self.panelRect.y) - buttonAreaHeight - paddingLarge
        
        -- Start animation if not already started
        if not self.pointAnimation.isAnimating and self.pointAnimation.currentStep == 0 then
            self.pointAnimation.isAnimating = true
            self.pointAnimation.currentStep = 0
            self.pointAnimation.stepTimer = 0
            self.pointAnimation.totalSteps = 0
            
            -- Count total steps needed
            if #breakdown.typeMatches > 0 then
                self.pointAnimation.totalSteps = self.pointAnimation.totalSteps + #breakdown.typeMatches
            end
            if #breakdown.valueMatches > 0 then
                self.pointAnimation.totalSteps = self.pointAnimation.totalSteps + #breakdown.valueMatches
            end
            if breakdown.flushBonus > 0 then
                self.pointAnimation.totalSteps = self.pointAnimation.totalSteps + 1
            end
            if breakdown.cardValueBonus > 0 then
                self.pointAnimation.totalSteps = self.pointAnimation.totalSteps + 1
            end
            self.pointAnimation.totalSteps = self.pointAnimation.totalSteps + 1 -- For total
        end
        
        local currentStep = 0
        
        -- Draw Type Matches
        for i, match in ipairs(breakdown.typeMatches) do
            currentStep = currentStep + 1
            if currentStep <= self.pointAnimation.currentStep then
                local timer = self.pointAnimation.lineTimers[currentStep] or 0
                local alpha = math.min(1.0, timer / self.pointAnimation.fadeInDuration)
                local r, g, b = unpack(valueTextColor)
                love.graphics.setColor(r, g, b, alpha)
                
                -- Add subtle bounce effect
                local bounceOffset = 0
                if timer < self.pointAnimation.fadeInDuration then
                    bounceOffset = 5 * (1 - timer / self.pointAnimation.fadeInDuration)
                end
                
                local matchText = string.format("+%d Points (%s)", match.points, match.description)
                local drawY = breakdownY + bounceOffset - self.pointAnimation.scrollOffset
                
                -- Only draw if within visible area
                if drawY + lineHeight > self.panelRect.y and drawY < self.panelRect.y + self.panelRect.height - buttonAreaHeight then
                    love.graphics.printf(matchText, contentStartX, drawY, contentAvailableWidth, "center")
                end
                breakdownY = breakdownY + lineHeight
            end
        end
        
        -- Draw Value Matches
        for i, match in ipairs(breakdown.valueMatches) do
            currentStep = currentStep + 1
            if currentStep <= self.pointAnimation.currentStep then
                local timer = self.pointAnimation.lineTimers[currentStep] or 0
                local alpha = math.min(1.0, timer / self.pointAnimation.fadeInDuration)
                local r, g, b = unpack(valueTextColor)
                love.graphics.setColor(r, g, b, alpha)
                
                -- Add subtle bounce effect
                local bounceOffset = 0
                if timer < self.pointAnimation.fadeInDuration then
                    bounceOffset = 5 * (1 - timer / self.pointAnimation.fadeInDuration)
                end
                
                local matchText = string.format("+%d Points (%s)", match.points, match.description)
                local drawY = breakdownY + bounceOffset - self.pointAnimation.scrollOffset
                
                -- Only draw if within visible area
                if drawY + lineHeight > self.panelRect.y and drawY < self.panelRect.y + self.panelRect.height - buttonAreaHeight then
                    love.graphics.printf(matchText, contentStartX, drawY, contentAvailableWidth, "center")
                end
                breakdownY = breakdownY + lineHeight
            end
        end
        
        -- Draw Flush Bonus
        if breakdown.flushBonus > 0 then
            currentStep = currentStep + 1
            if currentStep <= self.pointAnimation.currentStep then
                local timer = self.pointAnimation.lineTimers[currentStep] or 0
                local alpha = math.min(1.0, timer / self.pointAnimation.fadeInDuration)
                local r, g, b = unpack(effectTextColor)
                love.graphics.setColor(r, g, b, alpha)
                
                -- Add subtle bounce effect
                local bounceOffset = 0
                if timer < self.pointAnimation.fadeInDuration then
                    bounceOffset = 5 * (1 - timer / self.pointAnimation.fadeInDuration)
                end
                
                local flushText = string.format("+%d Points (Flush Bonus)", breakdown.flushBonus)
                local drawY = breakdownY + bounceOffset - self.pointAnimation.scrollOffset
                
                -- Only draw if within visible area
                if drawY + lineHeight > self.panelRect.y and drawY < self.panelRect.y + self.panelRect.height - buttonAreaHeight then
                    love.graphics.printf(flushText, contentStartX, drawY, contentAvailableWidth, "center")
                end
                breakdownY = breakdownY + lineHeight
            end
        end
        
        -- Draw Card Value Bonus
        if breakdown.cardValueBonus > 0 then
            currentStep = currentStep + 1
            if currentStep <= self.pointAnimation.currentStep then
                local timer = self.pointAnimation.lineTimers[currentStep] or 0
                local alpha = math.min(1.0, timer / self.pointAnimation.fadeInDuration)
                local r, g, b = unpack(valueTextColor)
                love.graphics.setColor(r, g, b, alpha)
                
                -- Add subtle bounce effect
                local bounceOffset = 0
                if timer < self.pointAnimation.fadeInDuration then
                    bounceOffset = 5 * (1 - timer / self.pointAnimation.fadeInDuration)
                end
                
                local cardValueText = string.format("+%d Points (Card Values)", breakdown.cardValueBonus)
                local drawY = breakdownY + bounceOffset - self.pointAnimation.scrollOffset
                
                -- Only draw if within visible area
                if drawY + lineHeight > self.panelRect.y and drawY < self.panelRect.y + self.panelRect.height - buttonAreaHeight then
                    love.graphics.printf(cardValueText, contentStartX, drawY, contentAvailableWidth, "center")
                end
                breakdownY = breakdownY + lineHeight
            end
        end
        
        -- Draw Total
        currentStep = currentStep + 1
        if currentStep <= self.pointAnimation.currentStep then
            local timer = self.pointAnimation.lineTimers[currentStep] or 0
            local alpha = math.min(1.0, timer / self.pointAnimation.fadeInDuration)
            local r, g, b = unpack(titleTextColor)
            love.graphics.setColor(r, g, b, alpha)
            
            -- Add subtle bounce effect
            local bounceOffset = 0
            if timer < self.pointAnimation.fadeInDuration then
                bounceOffset = 5 * (1 - timer / self.pointAnimation.fadeInDuration)
            end
            
            local totalText = string.format("Total: %d Points", breakdown.total)
            local drawY = breakdownY + bounceOffset - self.pointAnimation.scrollOffset
            
            -- Only draw if within visible area
            if drawY + lineHeight > self.panelRect.y and drawY < self.panelRect.y + self.panelRect.height - buttonAreaHeight then
                love.graphics.printf(totalText, contentStartX, drawY, contentAvailableWidth, "center")
            end
            breakdownY = breakdownY + lineHeight
        end
        
        currentY = breakdownY + paddingMedium
    else
        -- Fallback to old display if no breakdown available
        local drinkPoints = pendingPotion.drinkPoints or 0
        if drinkPoints > 0 then
            love.graphics.setColor(valueTextColor)
            local drinkText = string.format("Drink for: %d Points", drinkPoints)
            love.graphics.printf(drinkText, contentStartX, currentY, contentAvailableWidth, "center")
            currentY = currentY + detailFont:getHeight() + paddingSmall
        end
    end

    -- Draw Effect Description and Sale Value (moved above buttons)
    love.graphics.setColor(effectTextColor)
    local effectDescText = (pendingPotion.drinkEffect and pendingPotion.drinkEffect.description) or "No special effect."
    local numberOfEffectLines = 1 
    if detailFont:getWidth("Drink Effect: " .. effectDescText) > contentAvailableWidth then
        local _, linesTable = detailFont:getWrap("Drink Effect: " .. effectDescText, contentAvailableWidth)
        if linesTable then numberOfEffectLines = #linesTable end
    end
    love.graphics.printf("Drink Effect: " .. effectDescText, contentStartX, currentY, contentAvailableWidth, "center")
    currentY = currentY + (detailFont:getHeight() * numberOfEffectLines) + paddingSmall

    -- Draw Sale Value
    love.graphics.setColor(valueTextColor)
    local saleMoney = pendingPotion.saleMoney or 0
    local saleValueText = string.format("Sell for: $%d", saleMoney)
    love.graphics.printf(saleValueText, contentStartX, currentY, contentAvailableWidth, "center")
    currentY = currentY + detailFont:getHeight() + paddingLarge * 1.5

    -- 4. Position and Draw Buttons (Fixed at bottom)
    local buttonsYPos = self.panelRect.y + self.panelRect.height - paddingLarge - (self.drinkButton and self.drinkButton.height or 40)
    if self.drinkButton and self.sellButton then
        local totalButtonsWidth = self.drinkButton.width + self.sellButton.width + paddingMedium
        local startButtonsX = self.panelRect.x + (self.panelRect.width - totalButtonsWidth) / 2

        self.drinkButton.x = startButtonsX
        self.drinkButton.y = buttonsYPos
        self.drinkButton:draw()

        self.sellButton.x = startButtonsX + self.drinkButton.width + paddingMedium
        self.sellButton.y = buttonsYPos
        self.sellButton:draw()
    end

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
end
--- Handles clicks within the potion decision overlay.
function PotionDecisionOverlay:handleClick(x, y)
    -- Check buttons first (Button:handleClick handles isEnabled and calls injected onClick)
    if self.drinkButton and self.drinkButton:handleClick(x, y) then return true end
    if self.sellButton and self.sellButton:handleClick(x, y) then return true end

    -- Consume click if inside panel but not on specific buttons (prevents click-through)
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    if isPointInRectFunc and self.panelRect and isPointInRectFunc(x, y, self.panelRect) then
        -- print("Click consumed by PotionDecisionOverlay panel background.") -- Optional debug
        return true
    end
    return false -- Click was not handled by this overlay
end

--- Called when the overlay becomes visible.
function PotionDecisionOverlay:onShow()
    print("Potion Decision Overlay Shown")
    
    -- Reset animation state
    if self.pointAnimation then
        self.pointAnimation.isAnimating = false
        self.pointAnimation.currentStep = 0
        self.pointAnimation.stepTimer = 0
        self.pointAnimation.totalSteps = 0
        self.pointAnimation.lineTimers = {}
        self.pointAnimation.scrollOffset = 0
    end
    
    -- Example of dynamic update:
    -- local potionChoice = self.gameState and self.gameState.pendingPotionChoice
    -- if self.sellButton and potionChoice then
    --     self.sellButton:setLabel("Sell for $" .. tostring(potionChoice.saleValue or 0))
    -- else
    --     self.sellButton:setLabel("Sell") -- Fallback
    -- end
end

--- Called when the overlay is hidden.
function PotionDecisionOverlay:onHide()
    print("Potion Decision Overlay Hidden")
    -- State cleanup (like clearing GameState.pendingPotionChoice or GameState.gamePhase)
    -- is handled by the potionActions.drink/sell functions in CoreGame, not here.
end

return PotionDecisionOverlay