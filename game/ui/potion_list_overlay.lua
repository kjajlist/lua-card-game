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
                        or { x = 20, y = 20, width = 300, height = 400 } -- Fallback rect

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
    local itemVerticalSpacing = layout.overlayItemSpacing or paddingMedium
    
    local titleTextColor = colors.textDark or {0.1, 0.1, 0.1, 1}
    local potionNameColor = colors.textPotionName or {0.2, 0.2, 0.4, 1}
    local potionBonusColor = colors.textPotionBonus or {0.5, 0.2, 0.5, 1}
    local separatorLineColor = colors.separator or {0.8, 0.8, 0.8, 1}

    -- 1. Draw Panel Base
    self.panelRect = helpers.calculateOverlayPanelRect and helpers.calculateOverlayPanelRect(theme) or self.panelRect
    if helpers.drawOverlayBase then helpers.drawOverlayBase(self.panelRect, theme) end

    local originalFont = love.graphics.getFont()
    local r_orig, g_orig, b_orig, a_orig = love.graphics.getColor()

    -- 2. Draw Title
    local titleFontToUse = fonts.large or fonts.default
    local titleTextY = self.panelRect.y + paddingMedium
    if titleFontToUse then
        love.graphics.setColor(titleTextColor)
        love.graphics.setFont(titleFontToUse)
        love.graphics.printf("Potion Recipes", self.panelRect.x, titleTextY, self.panelRect.width, "center")
    end
    local titleActualHeight = titleFontToUse and titleFontToUse:getHeight() or 20

    -- 3. Update Close Button Position & Draw
    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - paddingSmall
    self.closeButton.y = self.panelRect.y + paddingSmall
    self.closeButton:draw()

    -- 4. Setup for Recipe List Content Area
    local contentAreaStartY = self.panelRect.y + paddingMedium + titleActualHeight + paddingMedium
    local contentAreaEndY = self.panelRect.y + self.panelRect.height - paddingLarge
    -- local contentVisibleHeight = contentAreaEndY - contentAreaStartY
    
    local listTextX = self.panelRect.x + paddingLarge
    local listTextAvailableWidth = self.panelRect.width - (paddingLarge * 2)

    -- Placeholder: Apply scissor for scrolling (if implemented)
    -- love.graphics.setScissor(self.panelRect.x, contentAreaStartY, self.panelRect.width, contentVisibleHeight)
    -- local scrollOffsetY = self.scrollTop or 0
    local currentY = contentAreaStartY -- - scrollOffsetY (adjust if scrolling)

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

    -- 5. Iterate through and Draw Recipes
    local recipesDrawn = 0
    for _, recipe in ipairs(recipes) do
        -- Filter out invalid recipes or default "Unknown Mixture"
        if type(recipe) == "table" and recipe.name and recipe.name ~= "Unknown Mixture" then
            recipesDrawn = recipesDrawn + 1
            
            -- Potion Name
            love.graphics.setColor(potionNameColor)
            love.graphics.setFont(recipeNameFont)
            love.graphics.printf(tostring(recipe.name), listTextX, currentY, listTextAvailableWidth, "left")
            currentY = currentY + recipeLineHeight

            -- Requirements Description
            love.graphics.setColor(titleTextColor) -- Using darker text for details
            love.graphics.setFont(recipeDetailFont)
            love.graphics.printf("Req: " .. tostring(recipe.requirementsDesc or "???"), listTextX + paddingMedium, currentY, listTextAvailableWidth - paddingMedium, "left")
            currentY = currentY + detailLineHeight

            -- Value (Sale or Base)
            local valueToShow = recipe.saleValue -- Prefer saleValue
            local valueLabel = "Sale Value"
            if valueToShow == nil then -- Fallback to baseMoney if saleValue isn't directly provided
                valueToShow = recipe.baseMoney 
                valueLabel = "Base Value"
            end
            if type(valueToShow) == "number" and valueToShow > 0 then
                love.graphics.setColor(titleTextColor) 
                love.graphics.setFont(recipeDetailFont)
                love.graphics.printf(string.format("%s: $%d", valueLabel, valueToShow), listTextX + paddingMedium, currentY, listTextAvailableWidth - paddingMedium, "left")
                currentY = currentY + detailLineHeight
            end

            -- Bonus Points Description
            if recipe.bonusPointsDesc and recipe.bonusPointsDesc ~= "" then
                love.graphics.setColor(potionBonusColor); love.graphics.setFont(recipeDetailFont)
                love.graphics.printf(tostring(recipe.bonusPointsDesc), listTextX + paddingMedium, currentY, listTextAvailableWidth - paddingMedium, "left")
                currentY = currentY + detailLineHeight
            end
            -- Bonus Money Description
            if recipe.bonusMoneyDesc and recipe.bonusMoneyDesc ~= "" then
                love.graphics.setColor(potionBonusColor); love.graphics.setFont(recipeDetailFont)
                love.graphics.printf(tostring(recipe.bonusMoneyDesc), listTextX + paddingMedium, currentY, listTextAvailableWidth - paddingMedium, "left")
                currentY = currentY + detailLineHeight
            end

            -- Example Icons
            local miniIconW = sizes.overlayMiniIconWidth or 12
            local miniIconH = sizes.overlayMiniIconHeight or 18
            local miniIconHorizontalSpacing = layout.overlayMiniIconSpacing or paddingSmall
            
            if recipe.exampleIcons and type(recipe.exampleIcons) == "table" and #recipe.exampleIcons > 0 and drawCardIconFunc then
                local currentIconX = listTextX + paddingMedium
                local iconsYPos = currentY
                for _, iconData in ipairs(recipe.exampleIcons) do
                    if type(iconData) == "table" then
                        -- Call helper, passing theme for potential internal use (though drawCardIcon takes Config, Dependencies)
                        drawCardIconFunc(currentIconX, iconsYPos, nil, iconData, miniIconW, miniIconH, theme) 
                        
                        local countText = "x".. tostring(iconData.count or 1)
                        local countTextRenderWidth = recipeDetailFont:getWidth(countText) + 2 -- Small buffer
                        currentIconX = currentIconX + miniIconW + countTextRenderWidth + miniIconHorizontalSpacing
                    end
                end
                currentY = currentY + miniIconH + paddingSmall -- Move Y down after drawing all icons in the row
            else
                currentY = currentY + paddingSmall -- If no icons, still add a small amount of vertical space
            end

            -- Separator Line & Spacing
            currentY = currentY + itemVerticalSpacing / 2 
            love.graphics.setColor(separatorLineColor)
            love.graphics.line(listTextX, currentY, self.panelRect.x + self.panelRect.width - paddingLarge, currentY)
            currentY = currentY + itemVerticalSpacing 

            -- Basic Clipping Check (stops drawing recipes if content exceeds visible area)
            if currentY > contentAreaEndY then 
                love.graphics.setColor(titleTextColor)
                love.graphics.setFont(recipeNameFont)
                love.graphics.printf("...", listTextX, contentAreaEndY - recipeLineHeight, listTextAvailableWidth, "center")
                break -- Stop drawing more recipes
            end
        end
    end
    
    if recipesDrawn == 0 then -- If no valid recipes were drawn
         love.graphics.setFont(recipeNameFont or fonts.default)
         love.graphics.setColor(titleTextColor)
         love.graphics.printf("No recipes to display.", listTextX, currentY + 20, listTextAvailableWidth, "center")
    end

    -- Placeholder: Store total content height for scrolling calculations
    -- self.contentHeight = currentY - contentAreaStartY -- + scrollOffsetY 

    -- Placeholder: Disable scissor if it was enabled for scrolling
    -- love.graphics.setScissor()

    -- Restore original graphics state
    love.graphics.setFont(originalFont)
    love.graphics.setColor(r_orig, g_orig, b_orig, a_orig)
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