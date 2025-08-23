-- File: ui/game_over_overlay.lua
local Button

local GameOverOverlay = {}
GameOverOverlay.__index = GameOverOverlay

function GameOverOverlay:new(config)
    assert(config and config.name, "GameOverOverlay:new requires config.name")
    assert(config.uiManager, "GameOverOverlay:new requires config.uiManager")
    assert(config.gameState, "GameOverOverlay:new requires config.gameState")
    assert(config.theme and config.theme.fonts and config.theme.colors and config.theme.layout and config.theme.helpers, "GameOverOverlay:new requires theme with fonts/colors/layout/helpers")
    assert(config.ButtonClass, "GameOverOverlay:new requires ButtonClass")

    local instance = setmetatable({}, GameOverOverlay)
    instance.name = config.name
    instance.uiManager = config.uiManager
    instance.gameState = config.gameState
    instance.theme = config.theme
    Button = config.ButtonClass

    instance.panelRect = instance.theme.helpers.calculateOverlayPanelRect(instance.theme) or { x = 20, y = 20, width = 300, height = 200 }

    local theme = instance.theme
    local paddingSmall = theme.layout.paddingSmall or 5
    local closeButtonSize = theme.sizes.overlayCloseButtonSize or 25
    local closeButtonColor = theme.colors.buttonClose or {0.9, 0.5, 0.5, 1}

    instance.restartButton = Button:new({
        id = "gameOverRestart",
        x = 0, y = 0, width = 160, height = 40,
        label = "Restart",
        font = theme.fonts.ui,
        colors = { normal = theme.colors.buttonPotionActive or {0.6, 0.9, 0.6, 1} },
        onClick = function()
            print("Restart button clicked!")
            if instance.uiManager and instance.uiManager.sharedDependencies then
                local deps = instance.uiManager.sharedDependencies
                if deps.coreGame and deps.config and deps.gameState then
                    print("Calling resetGame...")
                    deps.coreGame.resetGame(deps.gameState, deps.config, deps)
                    -- Hide the game over overlay after restart
                    instance.uiManager:hide()
                else
                    print("Missing dependencies for restart!")
                end
            else
                print("Missing uiManager or sharedDependencies for restart!")
            end
        end,
        defaultFont = theme.fonts.default,
        defaultCornerRadius = theme.cornerRadius.default or 5,
        defaultColors = theme.colors
    })

    instance.closeButton = Button:new({
        id = "gameOverClose",
        x = 0, y = 0, width = closeButtonSize, height = closeButtonSize,
        label = "X",
        font = theme.fonts.ui,
        colors = { normal = closeButtonColor },
        onClick = function() instance.uiManager:hide() end,
        defaultFont = theme.fonts.default,
        defaultCornerRadius = theme.cornerRadius.closeButton or 3,
        defaultColors = theme.colors
    })

    return instance
end

function GameOverOverlay:update(dt, mx, my, isMouseButtonDown)
    if self.restartButton then self.restartButton:update(dt, mx, my, isMouseButtonDown) end
    if self.closeButton then self.closeButton:update(dt, mx, my, isMouseButtonDown) end
end

function GameOverOverlay:draw()
    if self.uiManager:getActiveOverlayName() ~= self.name then return end
    local theme = self.theme
    local helpers = theme.helpers
    local colors = theme.colors
    local fonts = theme.fonts
    local layout = theme.layout

    self.panelRect = helpers.calculateOverlayPanelRect(theme)
    helpers.drawOverlayBase(self.panelRect, theme)

    local titleFont = fonts.large or fonts.default
    local textFont = fonts.ui or fonts.default
    local textColor = colors.textDark or {0.1, 0.1, 0.1, 1}

    local paddingMedium = layout.paddingMedium or 10
    local title = "Game Over"
    local reason = tostring(self.gameState.gameOverReason or "")

    love.graphics.setColor(textColor)
    if titleFont then love.graphics.setFont(titleFont) end
    love.graphics.printf(title, self.panelRect.x, self.panelRect.y + paddingMedium, self.panelRect.width, "center")

    local y = self.panelRect.y + paddingMedium + (titleFont and titleFont:getHeight() or 20) + paddingMedium
    if textFont then love.graphics.setFont(textFont) end
    if reason ~= "" then
        love.graphics.printf("Reason: " .. reason, self.panelRect.x, y, self.panelRect.width, "center")
        y = y + (textFont and textFont:getHeight() or 16) + paddingMedium
    end

    -- Position buttons
    self.restartButton.x = self.panelRect.x + (self.panelRect.width - self.restartButton.width) / 2
    self.restartButton.y = self.panelRect.y + self.panelRect.height - self.restartButton.height - paddingMedium
    self.restartButton:draw()

    self.closeButton.x = self.panelRect.x + self.panelRect.width - self.closeButton.width - (layout.paddingSmall or 5)
    self.closeButton.y = self.panelRect.y + (layout.paddingSmall or 5)
    self.closeButton:draw()
end

function GameOverOverlay:handleClick(x, y)
    if self.restartButton and self.restartButton:handleClick(x, y) then return true end
    if self.closeButton and self.closeButton:handleClick(x, y) then return true end
    local helpers = self.theme and self.theme.helpers
    local isPointInRect = helpers and helpers.isPointInRect
    if isPointInRect and self.panelRect and isPointInRect(x, y, self.panelRect) then return true end
    return false
end

function GameOverOverlay:onShow() print("Game Over Overlay Shown") end
function GameOverOverlay:onHide() print("Game Over Overlay Hidden") end

return GameOverOverlay


