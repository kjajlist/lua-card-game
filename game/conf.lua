-- File: conf.lua (Formatted with Energy Mechanic Additions)
-- Defines LÖVE engine settings and global configuration/state tables.
-- Emphasizes passing Config/GameState data rather than direct global access from modules.

-- =============================================================================
-- LÖVE Engine Configuration Function (`love.conf`)
-- =============================================================================
-- Called by LÖVE at startup to configure the engine settings.
function love.conf(t)
    t.identity = "potion_game_revised" -- Unique identifier for save directory (updated to avoid conflict if old save exists)
    t.version = "11.4"                 -- Specify LÖVE version compatibility
    t.console = true                   -- Enable the debug console (very useful for development)
    t.window.title = "Potion Craft Alchemist" -- Window title

    -- Set initial window size (matches virtual resolution for consistency on startup)
    t.window.width = 400
    t.window.height = 600

    -- Graphics settings
    t.window.resizable = true     -- IMPORTANT: Allow the window to be resized
    t.window.minwidth = 400       -- Optional: Set a minimum reasonable width
    t.window.minheight = 300      -- Optional: Set a minimum reasonable height
    t.window.vsync = 1            -- 1 = Enable VSync (recommended to prevent tearing, 0 to disable)
    t.window.msaa = 4             -- Optional: Antialiasing (0 to disable, common values 2, 4, 8)
    t.window.highdpi = true       -- IMPORTANT: Use full resolution on High-DPI displays for sharpness

    -- List of modules to enable (LÖVE enables most by default)
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = true        -- Enable touch input (for potential mobile support)
    t.modules.window = true
    t.modules.sound = true        -- Often used alongside audio for sound effects

    -- Disable modules you are definitely not using (optional micro-optimization)
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.thread = false
    t.modules.video = false
end -- End of love.conf(t)

-- =============================================================================
-- Global Configuration Table (`Config`)
-- =============================================================================
-- Contains relatively static game settings, constants, theme data, and parameters.
Config = {
    Screen = {
        width = 400, -- Base virtual screen width
        height = 600 -- Base virtual screen height
    },
    Card = {
        width = 60,
        height = 80
    },
    Animation = {
        dealDuration = 0.3,         -- Duration for card dealing animation
        discardDuration = 0.4,      -- Duration for card discard animation
        potionFillDuration = 0.8,   -- Duration for potion bottle filling animation
        deckDrawY = 10,             -- Y position for cards animating FROM deck (deckDrawX calculated in love.load)
    },
    Layout = {
        -- Hand Layout
        handArcDepth = 15,          -- How much the hand arcs upwards in the center
        handMaxRotation = 10,       -- Max degrees a card rotates in the arc
        handSpacing = -25,          -- Negative for card overlap in hand
        handHighlightOffsetY = 10,  -- Pixels to raise selected cards in hand
        -- handBaseY is calculated in love.load

        -- General Padding/Spacing
        paddingSmall = 5,
        paddingMedium = 10,
        paddingLarge = 20,
        layoutGap = 15,             -- Default vertical gap between major UI sections

        -- Card Drawing Details
        cardCornerRadius = 5,
        cardObjectCircleYRatio = 0.15, -- Ratio of card height for element circle Y offset from card center
        cardObjectCircleRadiusRatio = 0.25, -- Ratio of card width for element circle radius
        cardNameYRatio = 0.1,       -- Ratio of card height for Name Y pos from card top
        cardValueYRatio = 0.75,     -- Ratio of card height for Value Y pos from card top
        cardTextPadding = 4,        -- Padding inside card text areas
    },
    UI = {
        Colors = {
            -- Base UI
            background = {0.85, 0.95, 1.0, 1},    -- Light blue background
            textDark = {0.1, 0.1, 0.1, 1},        -- For text on light backgrounds
            textLight = {0.9, 0.9, 0.9, 1},       -- For text on dark backgrounds
            textDescription = {0.3, 0.3, 0.3, 1}, -- Muted color for descriptions
            textScore = {0.1, 0.1, 0.1, 1},        -- Color for score/wallet text
            textUses = {0.1, 0.4, 0.1, 1},        -- Greenish for spell uses text
            textEnergy = {0.2, 0.2, 0.7, 1},      -- Bluish for energy text (NEW)
            highlight = {1, 1, 0, 1},             -- Highlight color for selected cards

            -- Button States (Defaults)
            button = {0.3, 0.3, 0.4, 1},          -- Default button background
            buttonHover = {0.4, 0.4, 0.5, 1},     -- Default button hover background
            buttonPressed = {0.2, 0.2, 0.3, 1},   -- Default button pressed background
            buttonDisabled = {0.6, 0.6, 0.6, 1},  -- Background for disabled buttons
            text = {0.9, 0.9, 0.9, 1},            -- Default button text color (on dark buttons)
            textDisabled = {0.5, 0.5, 0.5, 1},    -- Text color for disabled buttons

            -- Specific Button Colors / Overrides
            buttonDiscardActive = {0.9, 0.6, 0.6, 1},   -- Reddish for discard
            buttonPotionActive = {0.6, 0.9, 0.6, 1},    -- Greenish for make potion
            buttonSortActive = {0.7, 0.7, 0.9, 1},      -- Bluish for sort
            buttonRecipeActive = {0.6, 0.8, 0.9, 1},    -- Cyan for recipes
            buttonDeckViewActive = {0.9, 0.8, 0.6, 1},  -- Orangey for deck view
            buttonSpellActive = {0.8, 0.6, 0.9, 1},     -- Purplish for cast spell / spell buttons
            buttonClose = {0.9, 0.5, 0.5, 1},           -- Reddish for overlay close buttons
            buttonToggleActive = {0.7, 0.9, 0.7, 1},    -- Active state for toggle buttons
            buttonToggleInactive = {0.8, 0.8, 0.8, 1},  -- Inactive state for toggle buttons
            buttonDrink = {0.6, 0.9, 0.6, 1},           -- Color for Drink button
            buttonSell = {0.9, 0.8, 0.6, 1},            -- Color for Sell button

            -- Card Colors
            cardBorderDark = {0.2, 0.2, 0.2, 1},
            cardBorderLight = {0.7, 0.7, 0.7, 1},
            cardBasePlant = {0.8, 1.0, 0.8, 1},         -- Light green base for plant cards
            cardBaseMagic = {0.1, 0.1, 0.1, 1},         -- Dark base for magic cards
            cardBaseDefault = {0.95, 0.95, 0.95, 1},    -- Default card background

            -- Potion Colors
            potionBottleOutline = {0.3, 0.3, 0.4, 1},
            potionDisplayBg = {0.85, 0.95, 1.0, 1},     -- Background for the potion bottle area
            textPotionName = {0.2, 0.2, 0.4, 1},        -- Color for potion name text
            textPotionBonus = {0.5, 0.2, 0.5, 1},       -- Color for potion bonus effect text

            -- Spell Colors
            textSpell = {0.1, 0.1, 0.1, 1},             -- Color for spell text (using textDark)
            iconBook = {0.6, 0.4, 0.2, 1},              -- Color for placeholder book icon
            iconPageLines = {1, 1, 1, 1},               -- Color for lines on placeholder book icon

            -- Overlay Colors
            overlayBackground = {0.2, 0.2, 0.2, 0.9},   -- Dimming layer behind overlays
            overlayPanel = {0.95, 0.95, 1.0, 1},        -- Background color for overlay panels
            separator = {0.8, 0.8, 0.8, 1},             -- Color for separator lines in lists

            -- Pile Colors (Visual representation of deck/discard)
            deckPile = {0.3, 0.3, 0.7, 0.8},            -- Color for deck visual
            discardPile = {0.7, 0.3, 0.3, 0.8},         -- Color for discard visual

            -- Panel Colors
            panelBackground = {0.2, 0.2, 0.25, 0.9},    -- General panel background (e.g., goal display)
        },

        -- General UI Element properties
        cornerRadius = 5,               -- Default corner radius for standard buttons
        panelCornerRadius = 10,         -- Specific for larger panels like overlays
        closeButtonCornerRadius = 3,    -- Specific for overlay close buttons

        -- Base Button Config (Sizes for common main screen buttons, positions calculated in love.load)
        discardButton = { width = 100, height = 40, padding = 10, label = "Discard" },
        makePotionButton = { width = 100, height = 40, padding = 10, label = "Make Potion" },
        castSpellButton = { width = 100, height = 40, padding = 10, label = "Cast Spell" },
        sortButton = { width = 120, height = 30, label = "Sort: " },
        potionListButton = { width = 80, height = 30, label = "Recipes" },
        deckViewButton = { width = 80, height = 30, label = "Deck" },

        -- Area Config (Dimensions/properties for specific UI regions)
        potionDisplayArea = { height = 140 }, -- Height of the central potion display area (x,y,width calculated in love.load)
        bottleWidth = 60,
        bottleHeight = 90,
        goalDisplay = { height = 65, padding = 8, roundTextYOffset = 0, goalTextYOffset = 18, progressTextYOffset = 38 }, -- (x,y,width calculated)
        potentialPotionDisplay = { width = 300, height = 55, padding = 5 }, -- (x,y calculated)
        -- CountInfoY, ScoreInfoY for deck/discard text positions calculated in love.load

        -- Overlay Settings (General positioning and sizing ratios for panel calculation)
        overlayPanelXRatio = 0.05,      -- Ratio for overlay panel X position relative to screen width
        overlayPanelYRatio = 0.1,       -- Ratio for overlay panel Y position relative to screen height
        overlayPanelWidthRatio = 0.9,   -- Ratio for overlay panel Width relative to screen width
        overlayPanelHeightRatio = 0.8,  -- Ratio for overlay panel Height relative to screen height
        overlayCloseButtonSize = 25,    -- Standard size for the 'X' close button

        -- Potion List Overlay Specific Sizes
        overlayMiniIconWidth = 12,      -- Width for small ingredient icons in recipe list
        overlayMiniIconHeight = 18,     -- Height for small ingredient icons
        overlayMiniIconSpacing = 3,     -- Spacing next to mini icons

        -- Deck View Overlay Specific Sizes
        deckViewMediumIconWidth = 24,   -- Width for card icons in deck view
        deckViewMediumIconHeight = 36,  -- Height for card icons in deck view
        deckViewColumns = 4,            -- Number of columns for the card grid
        deckViewItemPadding = 5,        -- Padding around items in deck view grid
        deckViewToggleButtonWidth = 100,-- Width for 'Remaining'/'Full Deck' toggles
        deckViewToggleButtonHeight = 25,-- Height for 'Remaining'/'Full Deck' toggles

        -- Shop Overlay Specific Sizes
        shopOfferCount = 3,             -- How many items to offer in the shop
        shopItemHeight = 60,            -- Height of each item row in the shop
        shopItemSpacing = 10,           -- Vertical spacing between shop items
        shopBuyButtonWidth = 80,        -- Width of the 'Buy' button
        shopBuyButtonHeight = 30,       -- Height of the 'Buy' button
        shopContinueButtonWidth = 200,  -- Width of the 'Continue' button at the bottom
        shopContinueButtonHeight = 40,  -- Height of the 'Continue' button

        -- Potion Decision Overlay Specific Sizes
        decisionButtonWidth = 120,      -- Width of 'Drink'/'Sell' buttons
        decisionButtonHeight = 40,      -- Height of 'Drink'/'Sell' buttons

        -- Spell Selection Overlay Specific Sizes
        spellSelectItemHeight = 50,     -- Height of each spell row in the list
        spellSelectButtonWidth = 80,    -- Width of the 'Cast' button for each spell
        spellSelectButtonHeight = 25,   -- Height of the 'Cast' button for each spell
    },
    Bubble = {
        minSpeed = 35,
        maxSpeed = 75,
        minRadius = 5.0,
        maxRadius = 9.0,
        minLifetime = 1.2,
        maxLifetime = 3.0,
        spawnMargin = 5,                -- Margin from bottle edge/bottom for spawning
        fadeDuration = 0.4,             -- Time in seconds for bubble to fade out
        burstMinCount = 3,              -- Minimum number of bubbles in an initial burst
        burstMaxCount = 7,              -- Maximum number of bubbles in an initial burst
        updateThreshold = 0.999,        -- Potion fill level threshold for triggering burst
        spawnDepthRatio = 0.3,          -- Ratio of liquid height for spawn depth (0=surface, 1=bottom)
        boundaryData = { -- Ratios relative to bottle center (0,0) and dimensions W, H
            ["default"]     = { neckH=0.2,  bodyH=0.8,  bodyW=0.8,  neckBottomYRel = -0.3, liquidTopYRel = -0.3, liquidBottomYRel = 0.5, spawnWidthRatio = 0.75 },
            ["standard"]    = { neckH=0.2,  bodyH=0.8,  bodyW=0.8,  neckBottomYRel = -0.3, liquidTopYRel = -0.3, liquidBottomYRel = 0.5, spawnWidthRatio = 0.75 },
            ["round_flask"] = { neckH=0.3,  bulbRadiusRatio=0.45,   neckBottomYRel = -0.2, liquidTopYRel = -0.2, liquidBottomYRel = 0.5 - (0.45*2) + 0.45, spawnWidthRatio = 0.45 * 1.8 },
            ["tall_flask"]  = { neckH=0.15, bodyH=0.85, bodyW=0.6,  neckBottomYRel = -0.35,liquidTopYRel = -0.35,liquidBottomYRel = 0.5, spawnWidthRatio = 0.55 },
            ["small_vial"]  = { neckH=0.0,  bodyH=0.7,  bodyW=0.6,  neckBottomYRel = -0.35,liquidTopYRel = -0.35,liquidBottomYRel = 0.35, spawnWidthRatio = 0.55 },
            ["bulb"]        = { neckH=0.2,  bodyH=0.8,  bodyW=0.6,  neckBottomYRel = -0.3, liquidTopYRel = -0.3, liquidBottomYRel = 0.5, spawnWidthRatio = 0.55 },
        }
    },
    Game = {
        initialHandSize = 7,
        maxHandSize = 10,
        energyPerRound = 100,         -- Starting energy per round
        makePotionEnergyCost = 15,    -- Energy cost to attempt making a potion
        -- Spell energy costs are defined per spell in core_game.lua's SpellDefinitions
    },
} -- End of Config definition

-- =============================================================================
-- Global Font Placeholders
-- =============================================================================
-- These variables are assigned the actual Font objects in love.load.
-- Modules should receive Font objects as dependencies (e.g., via a theme table).
defaultFont = nil
largeFont   = nil
uiFont      = nil
smallFont   = nil

-- =============================================================================
-- Global Game State Table (`GameState`)
-- =============================================================================
-- Holds the dynamic state of the current game.
GameState = {
    -- Core Game Data (Player's resources)
    deck = {},                      -- Array of card instances in the draw pile
    hand = {},                      -- Array of card instances currently in the player's hand
    discardPile = {},               -- Array of card instances in the discard pile
    score = 0,                      -- Player's total score
    wallet = 0,                     -- Player's current money
    currentEnergy = 0,              -- Player's current energy for the round (NEW)

    -- Round Tracking
    currentRoundNumber = 1,         -- The current round number
    currentRoundData = {},          -- Data specific to the current round (e.g., goals)
    roundProgress = {},             -- Tracks progress towards round goals
    moneyEarnedThisRound = 0,       -- Money accumulated within the current round
    scoreEarnedThisRound = 0,       -- Score accumulated within the current round
    cardsPlayedThisRound = { family = {}, subType = {} }, -- Tracks counts of cards played

    -- Gameplay State (Current turn/action state)
    selectedCardIndices = {},       -- Indices of cards currently selected in the hand
    potentialPotionResult = {       -- Details of the potion that *would* be made with selected cards
        name = "Nothing", recipeIndex = nil, baseMoney=0, bonusPoints=0, bonusMoney=0,
        requirementsDesc="", bonusPointsDesc="", bonusMoneyDesc="", 
        display=nil, saleValue=0, drinkEffect=nil
    },
    pendingPotionChoice = nil,      -- Stores the fully defined crafted potion before Drink/Sell decision

    -- Spell State
    knownSpells = {},               -- Table mapping spellId to spell definition copies { spellId = spellDefinitionCopy, ... }
    activeSpellEffects = {},        -- Table tracking ongoing effects { type = ..., value = ..., duration = ... }
    selectedSpellId = nil,          -- ID of the spell chosen from the spell overlay
    selectingSpellTarget = false,   -- Flag: Is the player currently choosing a target?

    -- UI/Interaction State
    sortModes = {"default", "value", "color", "family", "subtype"}, -- Available hand sort modes
    currentSortModeIndex = 1,       -- Index of the currently active sort mode
    mouse = {x = 0, y = 0},         -- Stores virtual mouse coordinates
    drag = { isDragging = false, cardIndex = nil, offsetX = 0, offsetY = 0 }, -- State for card dragging
    activeOverlay = nil,            -- Name (string key) of the currently visible overlay, or nil
    currentShopItems = {},          -- Array of item offers currently available in the shop
    deckViewMode = "remaining",     -- Current mode for the Deck View overlay ("remaining" or "full")

    -- System / Phase State
    gamePhase = "loading",          -- Current game phase
    gameOverReason = nil,           -- Reason for game over (e.g., "out_of_energy") (NEW)
    roundCompletionPending = false, -- Flag indicating the round end sequence should start
    canDiscard = true,              -- Whether the discard action is currently allowed
    isWaitingForDiscard = false,    -- Flag used during discard animation sequence
    discardAnimCounter = 0,         -- Counter for discard animation timing/steps
    numReplacementsToDraw = 0,      -- How many cards to draw after discard completes

    -- Animation/Visual State (Specific visual states not tied to core gameplay logic)
    potionDisplay = {               -- State for the central potion bottle visual
        showPotion = false, fillLevel = 0.0, targetFillLevel = 0.0,
        fillColor = {0.5, 0.5, 0.5}, bottleType = "default",
        bubbles = {}, isBubbling = false, bubblesSpawned = false,
        isAnimatingFill = false, animProgress = 0
    },
} -- End of GameState definition

-- =============================================================================
-- Global Render State Table (`RenderState`)
-- =============================================================================
-- Holds state related to screen scaling and rendering offsets.
RenderState = {
    scale = 1,     -- Current rendering scale factor
    offsetX = 0,   -- Horizontal offset for centering scaled content
    offsetY = 0    -- Vertical offset for centering scaled content
} -- End RenderState

-- =============================================================================
-- Other Global Placeholders (Populated in love.load)
-- =============================================================================
CardDefLookup = {}      -- Holds card definitions, keyed by card ID.
PotionRecipes = {}      -- Holds recipe definitions. (Loaded from CoreGameData in main.lua)
SpellDefinitions = {}   -- Holds spell definitions. (Loaded from CoreGameData in main.lua)

-- UIState is primarily for main screen elements (buttons, regions) not managed by OverlayManager.
UIState = {
    Regions = {}, -- Calculated in love.load
    Buttons = {}  -- Main screen buttons instantiated in love.load
}

print("conf.lua loaded and initial global tables defined.")
-- End of File