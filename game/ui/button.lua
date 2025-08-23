-- File: ui/button.lua (Refactored - with Debug Prints)
-- Defines a reusable Button component with reduced global dependencies.

local Button = {}
Button.__index = Button

-- Assumed helper function (could be passed in or required from a utils module)
local function isPointInRect(px, py, rect)
  -- Simple Axis-Aligned Bounding Box check
  return px >= rect.x and px < rect.x + rect.width and
         py >= rect.y and py < rect.y + rect.height
end

--- Creates a new Button instance.
-- @param config Table containing button properties:
-- { x, y, width, height, label, id (optional),
--   colors = { normal, hover, pressed, disabled, textNormal, textDisabled },
--   font (optional), defaultFont (required fallback),
--   cornerRadius (optional), defaultCornerRadius (optional fallback),
--   defaultColors (optional table for fallback colors),
--   onClick (function) }
function Button:new(config)
    local instance = setmetatable({}, Button)

    -- Validate required config elements for clarity
    assert(config.defaultFont, "Button:new requires config.defaultFont")

    -- Required positional/size properties
    instance.x = config.x or 0
    instance.y = config.y or 0
    instance.width = config.width or 100
    instance.height = config.height or 30
    instance.label = config.label or "Button"
    instance.onClick = config.onClick -- Callback function

    -- Optional properties
    instance.id = config.id or instance.label -- Use label as default ID
    instance.font = config.font or config.defaultFont -- Use provided defaultFont
    instance.cornerRadius = config.cornerRadius or config.defaultCornerRadius or 5 -- Use provided defaultCornerRadius

    -- Colors: Merge provided colors with provided defaults
    local defaultColors = config.defaultColors or {}
    local providedColors = config.colors or {}
    instance.colors = {
        normal       = providedColors.normal or defaultColors.button or {0.3, 0.3, 0.4, 1},
        hover        = providedColors.hover or defaultColors.buttonHover or {0.4, 0.4, 0.5, 1},
        pressed      = providedColors.pressed or defaultColors.buttonPressed or {0.2, 0.2, 0.3, 1},
        disabled     = providedColors.disabled or defaultColors.buttonDisabled or {0.6, 0.6, 0.6, 1},
        textNormal   = providedColors.textNormal or defaultColors.text or {0.9, 0.9, 0.9, 1},
        textDisabled = providedColors.textDisabled or defaultColors.textDisabled or {0.5, 0.5, 0.5, 1},
    }

    -- Internal state
    instance.isHovered = false
    instance.isPressed = false
    instance.isEnabled = true -- Buttons are enabled by default

    return instance
end

--- Updates the button's hover and pressed states based on mouse input.
-- @param dt Delta time (not currently used)
-- @param mx Mouse X coordinate (virtual coordinates)
-- @param my Mouse Y coordinate (virtual coordinates)
-- @param isMouseDown Boolean indicating if the primary mouse button is currently down.
function Button:update(dt, mx, my, isMouseDown)
    if not self.isEnabled then return end
    if mx == nil or my == nil then return end

    local wasHovered = self.isHovered
    self.isHovered = isPointInRect(mx, my, self)

    if self.isHovered and isMouseDown then
        if not self.isPressed and wasHovered then
             self.isPressed = true
        end
    else
        if self.isPressed then
            self.isPressed = false
        end
    end
end


--- Draws the button based on its current state.
function Button:draw()
    local bgColor
    local textColor = self.colors.textNormal

    if not self.isEnabled then
        bgColor = self.colors.disabled
        textColor = self.colors.textDisabled
    elseif self.isPressed and self.isHovered then
        bgColor = self.colors.pressed
    elseif self.isHovered then
        bgColor = self.colors.hover
    else
        bgColor = self.colors.normal
    end

    local currentFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.cornerRadius, self.cornerRadius)

    love.graphics.setColor(textColor)
    if self.font then
        love.graphics.setFont(self.font)
        local textHeight = self.font:getHeight()
        local textY = self.y + math.floor((self.height - textHeight) / 2)
        love.graphics.printf(self.label or "", self.x, textY, self.width, "center")
    else
        love.graphics.print("?", self.x + self.width/2, self.y + self.height/2)
    end

    love.graphics.setFont(currentFont)
    love.graphics.setColor(r, g, b, a)
end

--- Handles a potential click event targeting this button.
function Button:handleClick(clickX, clickY)
    print(string.format("Button ID '%s': handleClick called. Enabled: %s. Click: (%.1f, %.1f). Rect: (x:%.1f, y:%.1f, w:%.1f, h:%.1f)",
        tostring(self.id), tostring(self.isEnabled), clickX or -1, clickY or -1, self.x, self.y, self.width, self.height)) -- DEBUG

    if not self.isEnabled then return false end
    if clickX == nil or clickY == nil then return false end

    local inRect = isPointInRect(clickX, clickY, self) -- isPointInRect is local to button.lua
    print(string.format("Button ID '%s': isPointInRect result: %s", tostring(self.id), tostring(inRect))) -- DEBUG

    if inRect then
        if type(self.onClick) == "function" then
            print(string.format("Button ID '%s': Executing onClick.", tostring(self.id))) -- DEBUG
            self.onClick(self) -- Pass self as an argument if the callback needs button info
            return true -- Click was handled
        else
            print(string.format("Button ID '%s': Clicked, but no onClick function.", tostring(self.id))) -- DEBUG
            return true -- Click was inside, even if no action taken
        end
    end
    return false -- Click was outside this button
end

--- Returns the bounding rectangle of the button.
function Button:getRect()
    return { x = self.x, y = self.y, width = self.width, height = self.height }
end

--- Sets the enabled state of the button.
function Button:setEnabled(enabled)
    self.isEnabled = (enabled == true) -- Ensure boolean
    if not self.isEnabled then -- Reset visual state if disabled
        self.isHovered = false
        self.isPressed = false
    end
end

--- Updates the button's label text.
function Button:setLabel(newLabel)
    self.label = tostring(newLabel or "") -- Ensure label is a string
end

return Button
