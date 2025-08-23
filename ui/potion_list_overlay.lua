-- File: ui/potion_list_overlay.lua (Formatted)
-- Defines the Potion List overlay component for displaying recipes using injected dependencies.

local Button -- Expected to be passed in config.ButtonClass

local PotionListOverlay = {}
PotionListOverlay.__index = PotionListOverlay

--- Creates a new PotionListOverlay instance.
-- @param config Table containing dependencies and settings.
function PotionListOverlay:new(config)
    -- 1. Validate Configuration and Dependencies
    assert(config and config.name, "PotionListOverlay:new requires config.name")
    assert(config.uiManager, "PotionListOverlay:new requires config.uiManager")
    assert(config.theme and config.theme.fonts and config.theme.colors and 
           config.theme.layout and config.theme.sizes and 
           config.theme.cornerRadius and config.theme.helpers, 
           "PotionListOverlay:new requires a valid config.theme table")
    assert(config.theme.fonts.large and config.theme.fonts.ui and 
           config.theme.fonts.small and config.theme.fonts.default, 
           "PotionListOverlay:new requires large, ui, small, and default fonts in config.theme.fonts")
    assert(config.theme.helpers.calculateOverlayPanelRect and 
           config.theme.helpers.drawOverlayBase and 
           config.theme.helpers.isPointInRect and 
           config.theme.helpers.drawCardIcon, 
           "PotionListOverlay:new requires helper functions (calculateOverlayPanelRect, drawOverlayBase, isPointInRect, drawCardIcon) in config.theme.helpers")
    assert(config.ButtonClass, "PotionListOverlay:new requires config.ButtonClass")
    assert(config.recipeProvider and type(config.recipeProvider.getRecipes) == "function", 
           "PotionListOverlay:new requires config.recipeProvider with a getRecipes function")

    local instance = setmetatable({}, PotionListOverlay)

    -- 2. Store Dependencies
    instance.name = config.name
    instance.uiManager = config.uiManager
    instance.theme = config.theme
    instance.recipeProvider = config.recipeProvider
    Button = config.ButtonClass -- Set module-level local for Button class

    -- 3. Initial UI Setup
    instance.panelRect = instance.theme.helpers.calculateOverlayPanelRect(instance.theme) 
                        or { x = 20, y = 20, width = 400, height = 600 } -- Larger fallback rect for better readability

    -- Cache theme values for button creation
    local theme = instance.theme
    local closeButtonSize = theme.sizes.overlayCloseButtonSize or 25
    local closeButtonRadius = theme.cornerRadius.closeButton or 3
    local closeButtonColor = theme.colors.buttonClose or {0.9, 0.5, 0.5, 1}

    local buttonDefaultSettings = {
        defaultFont = theme.fonts.default,
        defaultCornerRadius = theme.cornerRadius.default or 5,
        defaultColors = theme.colors
    }

    -- Create Close Button
    instance.closeButton = Button:new({
        id = "potionListClose", 
        x = 0, y = 0, -- Positioned in draw()
        width = closeButtonSize, height = closeButtonSize,
        label = "X", 
        font = theme.fonts.ui,
        cornerRadius = closeButtonRadius,
        colors = { normal = closeButtonColor },
        onClick = function() instance.uiManager:hide() end,
        defaultFont = buttonDefaultSettings.defaultFont,
        defaultCornerRadius = buttonDefaultSettings.defaultCornerRadius,
        defaultColors = buttonDefaultSettings.defaultColors
    })

    -- Scroll state (for future implementation)
    -- instance.scrollTop = 0
    -- instance.contentHeight = 0 
    -- instance.scrollBarRect = {} -- etc.

    return instance
end

--- Updates the state of elements within the overlay.
function PotionListOverlay:update(dt, mx, my, isMouseButtonDown)
    if not self.closeButton then
        print("Warning (PotionListOverlay:update): Close button not initialized.")
        return
    end

    -- Update close button state (hover, pressed)
    self.closeButton:update(dt, mx, my, isMouseButtonDown)

    -- Placeholder for scroll logic update
    -- self:_updateScroll(dt, mx, my, isMouseButtonDown, love.mouse.isDown("wu"), love.mouse.isDown("wd"))
end

--- Draws the potion list overlay UI.
function PotionListOverlay:draw()
    -- Only draw if this overlay is active
    if self.uiManager:getActiveOverlayName() ~= self.name then return end

    -- Check for critical dependencies
    if not self.theme or not self.recipeProvider or not self.closeButton then
        print("ERROR (PotionListOverlay:draw): Missing critical dependencies (theme, recipeProvider, or closeButton).")
        return
    end
    if not love or not love.graphics then
        print("Error (PotionListOverlay:draw): LÖVE graphics module not available.")
        return
    end

    -- Get recipes from the provider; handle potential failure gracefully
    local recipes = self.recipeProvider:getRecipes()
    if not recipes or type(recipes) ~= "table" then
        print("Warning (PotionListOverlay:draw): recipeProvider:getRecipes() did not return a valid table. Displaying empty list.")
        recipes = {} -- Default to empty list to avoid further errors
    end

    -- Cache theme elements
    local theme = self.theme
    local colors = theme.colors or {}
    local layout = theme.layout or {}
    local fonts = theme.fonts or {}
    local sizes = theme.sizes or {}
    local helpers = theme.helpers or {}

    local paddingSmall = layout.paddingSmall or 5
    local paddingMedium = layout.paddingMedium or 10
    local paddingLarge = layout.paddingLarge or 20
    local itemVerticalSpacing = layout.overlayItemSpacing or 30 -- Increased spacing between recipes
    
    -- Enhanced color scheme for better readability
    local titleTextColor = colors.textDark or {0.1, 0.1, 0.1, 1}
    local potionNameColor = colors.textPotionName or {0.2, 0.2, 0.6, 1} -- Darker blue for better contrast
    local potionBonusColor = colors.textPotionBonus or {0.6, 0.3, 0.8, 1} -- Purple for effects
    local separatorLineColor = colors.separator or {0.8, 0.8, 0.8, 1}
    local sectionHeaderColor = {0.4, 0.4, 0.6, 1} -- New color for section headers
    local valueColor = {0.2, 0.6, 0.2, 1} -- Green for values
    local requirementColor = {0.5, 0.5, 0.5, 1} -- Gray for requirements

    -- 1. Draw Panel Base
    self.panelRect = helpers.calculateOverlayPanelRect and helpers.calculateOverlayPanelRect(theme) or self.panelRect
    if helpers.drawOverlayBase then helpers.drawOverlayBase(self.panelRect, theme) end

    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Title with better styling
    local titleFontToUse = fonts.large or fonts.default
    local titleTextY = self.panelRect.y + paddingMedium
    if titleFontToUse then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(titleFontToUse)
        love.graphics.printf("📖 POTION RECIPES", self.panelRect.x, titleTextY, self.panelRect.width, "center")
    end
    local titleActualHeight = titleFontToUse and titleFontToUse:getHeight() or 20

    -- 3. Update Close Button Position & Draw
    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - paddingSmall
    self.closeButton.y = self.panelRect.y + paddingSmall
    self.closeButton:draw()

    -- 4. Setup for Recipe List Content Area
    local contentAreaStartY = self.panelRect.y + paddingMedium + titleActualHeight + paddingMedium
    local contentAreaEndY = self.panelRect.y + self.panelRect.height - paddingLarge
    
    local listTextX = self.panelRect.x + paddingLarge
    local listTextAvailableWidth = self.panelRect.width - (paddingLarge * 2)

    local currentY = contentAreaStartY

    local recipeNameFont = fonts.ui or fonts.default
    local recipeDetailFont = fonts.small or fonts.default
    if not recipeNameFont or not recipeDetailFont then
        print("Error (PotionListOverlay:draw): Missing recipeNameFont or recipeDetailFont.")
        love.graphics.setFont(originalFont); love.graphics.setColor(r_orig,g_orig,b_orig,a_orig)
        return
    end
    
    local recipeLineHeight = recipeNameFont:getHeight()
    local detailLineHeight = recipeDetailFont:getHeight()
    local drawCardIconFunc = helpers.drawCardIcon -- Alias the helper for drawing icons

    -- 5. Draw Introduction Text
    love.graphics.setColor(requirementColor)
    love.graphics.setFont(recipeDetailFont)
    love.graphics.printf("Combine cards to create powerful potions. Match by name or value for best results!", 
                        listTextX, currentY, listTextAvailableWidth, "left")
    currentY = currentY + detailLineHeight + paddingMedium

    -- Draw separator after intro
    love.graphics.setColor(separatorLineColor)
    love.graphics.line(listTextX, currentY, self.panelRect.x + self.panelRect.width - paddingLarge, currentY)
    currentY = currentY + paddingMedium

    -- 6. Categorize and Draw Recipes
    local recipesDrawn = 0
    local typeMatchRecipes = {}
    local valueMatchRecipes = {}
    local flushRecipes = {}
    
    -- Categorize recipes
    for _, recipe in ipairs(recipes) do
        if type(recipe) == "table" and recipe.name and recipe.name ~= "Unknown Mixture" then
            if recipe.name:find("Type") then
                table.insert(typeMatchRecipes, recipe)
            elseif recipe.name:find("Value") then
                table.insert(valueMatchRecipes, recipe)
            elseif recipe.name:find("Concoction") or recipe.name:find("Essence") then
                table.insert(flushRecipes, recipe)
            else
                table.insert(typeMatchRecipes, recipe) -- Default category
            end
        end
    end

    -- Draw Type Match Recipes Section
    if #typeMatchRecipes > 0 then
        currentY = self:drawRecipeSection(currentY, "🃏 MATCH BY CARD NAME", typeMatchRecipes, 
                                         listTextX, listTextAvailableWidth, contentAreaEndY,
                                         recipeNameFont, recipeDetailFont, detailLineHeight,
                                         potionNameColor, valueColor, requirementColor, potionBonusColor,
                                         separatorLineColor, paddingSmall, paddingMedium, paddingLarge,
                                         sizes, drawCardIconFunc, helpers)
        recipesDrawn = recipesDrawn + #typeMatchRecipes
    end

    -- Draw Value Match Recipes Section
    if #valueMatchRecipes > 0 then
        currentY = self:drawRecipeSection(currentY, "🎯 MATCH BY CARD VALUE", valueMatchRecipes, 
                                         listTextX, listTextAvailableWidth, contentAreaEndY,
                                         recipeNameFont, recipeDetailFont, detailLineHeight,
                                         potionNameColor, valueColor, requirementColor, potionBonusColor,
                                         separatorLineColor, paddingSmall, paddingMedium, paddingLarge,
                                         sizes, drawCardIconFunc, helpers)
        recipesDrawn = recipesDrawn + #valueMatchRecipes
    end

    -- Draw Flush Recipes Section
    if #flushRecipes > 0 then
        currentY = self:drawRecipeSection(currentY, "✨ SPECIAL FLUSH BONUSES", flushRecipes, 
                                         listTextX, listTextAvailableWidth, contentAreaEndY,
                                         recipeNameFont, recipeDetailFont, detailLineHeight,
                                         potionNameColor, valueColor, requirementColor, potionBonusColor,
                                         separatorLineColor, paddingSmall, paddingMedium, paddingLarge,
                                         sizes, drawCardIconFunc, helpers)
        recipesDrawn = recipesDrawn + #flushRecipes
    end
    
    if recipesDrawn == 0 then -- If no valid recipes were drawn
         love.graphics.setFont(recipeNameFont or fonts.default)
         love.graphics.setColor(titleTextColor)
         love.graphics.printf("No recipes to display.", listTextX, currentY + 20, listTextAvailableWidth, "center")
    end

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
end

--- Helper function to draw a recipe section
function PotionListOverlay:drawRecipeSection(currentY, sectionTitle, recipes, listTextX, listTextAvailableWidth, 
                                            contentAreaEndY, recipeNameFont, recipeDetailFont, detailLineHeight,
                                            potionNameColor, valueColor, requirementColor, potionBonusColor,
                                            separatorLineColor, paddingSmall, paddingMedium, paddingLarge,
                                            sizes, drawCardIconFunc, helpers)
    
    local theme = self.theme
    local fonts = theme.fonts or {}
    local sectionHeaderFont = fonts.ui or fonts.default
    
    -- Draw section header
    love.graphics.setColor({0.4, 0.4, 0.6, 1})
    love.graphics.setFont(sectionHeaderFont)
    love.graphics.printf(sectionTitle, listTextX, currentY, listTextAvailableWidth, "left")
    currentY = currentY + sectionHeaderFont:getHeight() + paddingSmall

    -- Draw recipes in this section
    for _, recipe in ipairs(recipes) do
        -- Check if we have room to draw this recipe
        if currentY > contentAreaEndY - 100 then -- Leave some space for "..." indicator
            love.graphics.setColor({0.1, 0.1, 0.1, 1})
            love.graphics.setFont(recipeNameFont)
            love.graphics.printf("...", listTextX, contentAreaEndY - recipeNameFont:getHeight(), listTextAvailableWidth, "center")
            break
        end

        -- Recipe card background (subtle)
        local cardBgColor = {0.98, 0.98, 1.0, 0.3}
        local cardBorderColor = {0.8, 0.8, 0.9, 0.5}
        local cardPadding = paddingMedium
        local cardWidth = listTextAvailableWidth
        local cardHeight = 0 -- Will be calculated
        
        -- Calculate card height first
        local tempY = currentY + cardPadding
        tempY = tempY + recipeNameFont:getHeight() + paddingSmall -- Recipe name
        tempY = tempY + detailLineHeight + paddingSmall -- Requirements
        tempY = tempY + detailLineHeight + paddingSmall -- Values
        if recipe.drinkEffect and recipe.drinkEffect.description then
            tempY = tempY + detailLineHeight + paddingSmall -- Effect
        end
        tempY = tempY + (sizes.overlayMiniIconHeight or 18) + paddingSmall -- Icons
        tempY = tempY + cardPadding -- Bottom padding
        cardHeight = tempY - currentY

        -- Draw card background
        love.graphics.setColor(cardBgColor)
        love.graphics.rectangle("fill", listTextX, currentY, cardWidth, cardHeight, 8, 8)
        love.graphics.setColor(cardBorderColor)
        love.graphics.rectangle("line", listTextX, currentY, cardWidth, cardHeight, 8, 8)

        -- Recipe content starts after card padding
        local contentY = currentY + cardPadding

        -- Potion Name (larger, more prominent)
        love.graphics.setColor(potionNameColor)
        love.graphics.setFont(recipeNameFont)
        love.graphics.printf("🧪 " .. tostring(recipe.name), listTextX + paddingSmall, contentY, listTextAvailableWidth - paddingSmall * 2, "left")
        contentY = contentY + recipeNameFont:getHeight() + paddingSmall

        -- Requirements Description (simplified and clearer)
        love.graphics.setColor(requirementColor)
        love.graphics.setFont(recipeDetailFont)
        local reqText = tostring(recipe.requirementsDesc or "???")
        -- Clean up the requirements text
        reqText = reqText:gsub("%(Bonus: .*%)", "") -- Remove bonus text from requirements
        reqText = reqText:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
        love.graphics.printf("📋 " .. reqText, listTextX + paddingSmall, contentY, listTextAvailableWidth - paddingSmall * 2, "left")
        contentY = contentY + detailLineHeight + paddingSmall

        -- Recipe Values (better formatted)
        local drinkPoints = recipe.drinkPoints or 0
        local saleMoney = recipe.saleMoney or 0
        if drinkPoints > 0 or saleMoney > 0 then
            love.graphics.setColor(valueColor) 
            love.graphics.setFont(recipeDetailFont)
            local valueText = ""
            if drinkPoints > 0 and saleMoney > 0 then
                valueText = string.format("💚 Drink: %d Points  |  💰 Sell: $%d", drinkPoints, saleMoney)
            elseif drinkPoints > 0 then
                valueText = string.format("💚 Drink: %d Points", drinkPoints)
            elseif saleMoney > 0 then
                valueText = string.format("💰 Sell: $%d", saleMoney)
            end
            love.graphics.printf(valueText, listTextX + paddingSmall, contentY, listTextAvailableWidth - paddingSmall * 2, "left")
            contentY = contentY + detailLineHeight + paddingSmall
        end

        -- Drink Effect Description (if present)
        if recipe.drinkEffect and recipe.drinkEffect.description then
            love.graphics.setColor(potionBonusColor)
            love.graphics.setFont(recipeDetailFont)
            local effectText = tostring(recipe.drinkEffect.description)
            love.graphics.printf("✨ " .. effectText, listTextX + paddingSmall, contentY, listTextAvailableWidth - paddingSmall * 2, "left")
            contentY = contentY + detailLineHeight + paddingSmall
        end

        -- Example Icons (if present)
        local miniIconW = sizes.overlayMiniIconWidth or 12
        local miniIconH = sizes.overlayMiniIconHeight or 18
        local miniIconHorizontalSpacing = (self.theme and self.theme.layout and self.theme.layout.overlayMiniIconSpacing) or paddingSmall
        
        if recipe.exampleIcons and type(recipe.exampleIcons) == "table" and #recipe.exampleIcons > 0 and drawCardIconFunc then
            local currentIconX = listTextX + paddingSmall
            local iconsYPos = contentY
            for _, iconData in ipairs(recipe.exampleIcons) do
                if type(iconData) == "table" then
                    drawCardIconFunc(currentIconX, iconsYPos, nil, iconData, miniIconW, miniIconH, theme) 
                    
                    local countText = "x".. tostring(iconData.count or 1)
                    local countTextRenderWidth = recipeDetailFont:getWidth(countText) + 2
                    currentIconX = currentIconX + miniIconW + countTextRenderWidth + miniIconHorizontalSpacing
                end
            end
            contentY = contentY + miniIconH + paddingSmall
        else
            contentY = contentY + paddingSmall
        end

        -- Move to next recipe position
        currentY = contentY + paddingMedium
    end

    -- Add section separator
    love.graphics.setColor(separatorLineColor)
    love.graphics.line(listTextX, currentY, self.panelRect.x + self.panelRect.width - paddingLarge, currentY)
    currentY = currentY + paddingMedium

    return currentY
end

--- Handles clicks within the potion list overlay.
function PotionListOverlay:handleClick(x, y)
    -- Check close button first
    if self.closeButton and self.closeButton:handleClick(x, y) then return true end

    -- Placeholder: Check for clicks on recipes or scrollbar if implemented
    -- if self.scrollBarRect and isPointInRect(x,y, self.scrollBarRect) then ... return true end

    -- Consume click if inside panel but not handled otherwise (prevents click-through)
    local helpers = self.theme and self.theme.helpers
    local isPointInRectFunc = helpers and helpers.isPointInRect
    if isPointInRectFunc and self.panelRect and isPointInRectFunc(x, y, self.panelRect) then
        -- print("Click consumed by PotionListOverlay panel background.") -- Optional debug
        return true
    end
    return false -- Click wasn't handled by this overlay
end

--- Called when the overlay becomes visible.
function PotionListOverlay:onShow()
    print("Potion List Overlay Shown")
    -- Placeholder: Reset scroll position if implemented
    -- self.scrollTop = 0
end

--- Called when the overlay is hidden.
function PotionListOverlay:onHide()
    print("Potion List Overlay Hidden")
    -- Any specific cleanup for this overlay when hidden
end

return PotionListOverlay