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
        cardToPotionDuration = 0.8, -- Duration for cards flying into potion bottle
        deckDrawY = 10,             -- Y position for cards animating FROM deck (deckDrawX calculated in love.load)
    },
    Layout = {
        -- Professional Spacing System (based on 8pt grid)
        spacingXS = 4,              -- Extra small spacing
        spacingS = 8,               -- Small spacing
        spacingM = 16,              -- Medium spacing (base unit)
        spacingL = 24,              -- Large spacing
        spacingXL = 32,             -- Extra large spacing
        spacingXXL = 48,            -- Extra extra large spacing
        
        -- Legacy spacing (for backward compatibility)
        paddingSmall = 8,           -- Updated to align with spacing system
        paddingMedium = 16,         -- Updated to align with spacing system
        paddingLarge = 32,          -- Updated to align with spacing system
        layoutGap = 20,             -- Updated to align with spacing system

        -- Hand Layout (improved for mobile)
        handArcDepth = 20,          -- Slightly deeper arc for better visual
        handMaxRotation = 8,        -- Reduced rotation for cleaner look
        handSpacing = -20,          -- Optimized overlap for mobile
        handHighlightOffsetY = 12,  -- Increased for better visibility
        -- handBaseY is calculated in love.load

        -- Card Drawing Details (improved readability)
        cardCornerRadius = 8,       -- Increased for modern look
        cardObjectCircleYRatio = 0.18, -- Adjusted for better balance
        cardObjectCircleRadiusRatio = 0.22, -- Slightly smaller for cleaner look
        cardNameYRatio = 0.12,      -- More padding from top
        cardValueYRatio = 0.72,     -- Adjusted for better balance
        cardTextPadding = 8,        -- Increased for better text readability
        
        -- Touch Target Sizes (iOS Human Interface Guidelines)
        minTouchTarget = 44,        -- Minimum touch target size
        preferredTouchTarget = 48,  -- Preferred touch target size
        
        -- Improved Visual Hierarchy
        shadowOffset = 2,           -- Shadow offset for depth
        shadowBlur = 4,             -- Shadow blur radius
        borderWidth = 1,            -- Standard border width
        focusBorderWidth = 2,       -- Focus state border width
    },
    UI = {
        Colors = {
            -- Professional Color System (iOS-inspired)
            -- Primary Colors
            primary = {0.0, 0.48, 1.0, 1.0},      -- iOS Blue
            primaryDark = {0.0, 0.32, 0.74, 1.0}, -- Darker blue for pressed states
            primaryLight = {0.2, 0.6, 1.0, 1.0},  -- Lighter blue for hover
            
            -- Secondary Colors
            secondary = {0.35, 0.34, 0.84, 1.0},  -- iOS Purple
            accent = {1.0, 0.58, 0.0, 1.0},       -- iOS Orange
            
            -- Semantic Colors
            success = {0.2, 0.78, 0.35, 1.0},     -- iOS Green
            warning = {1.0, 0.8, 0.0, 1.0},      -- iOS Yellow
            error = {1.0, 0.23, 0.19, 1.0},      -- iOS Red
            
            -- Background Colors
            background = {0.95, 0.95, 0.97, 1.0}, -- iOS Light Gray background
            backgroundSecondary = {0.98, 0.98, 0.98, 1.0}, -- Secondary background
            surface = {1.0, 1.0, 1.0, 1.0},      -- Pure white for cards/panels
            
            -- Text Colors (improved contrast)
            textPrimary = {0.0, 0.0, 0.0, 0.87},  -- Primary text (87% opacity)
            textSecondary = {0.0, 0.0, 0.0, 0.6}, -- Secondary text (60% opacity)
            textTertiary = {0.0, 0.0, 0.0, 0.38}, -- Tertiary text (38% opacity)
            textOnPrimary = {1.0, 1.0, 1.0, 1.0}, -- White text on primary colors
            
            -- Legacy text colors (updated for better contrast)
            textDark = {0.0, 0.0, 0.0, 0.87},     -- Updated primary text
            textLight = {1.0, 1.0, 1.0, 0.87},    -- Updated light text
            textDescription = {0.0, 0.0, 0.0, 0.6}, -- Updated secondary text
            textScore = {0.35, 0.34, 0.84, 1.0},   -- Purple for scores
            textEnergy = {0.0, 0.48, 1.0, 1.0},    -- Primary blue for energy
            textError = {0.9, 0.3, 0.3, 1.0},      -- Red for errors/warnings
            textMoney = {1.0, 0.58, 0.0, 1.0},     -- Orange for money
            textPoints = {1.0, 0.8, 0.4, 1.0},     -- Gold for points
            highlight = {0.0, 0.48, 1.0, 0.15},   -- Subtle blue highlight

            -- Modern Button System
            buttonPrimary = {0.0, 0.48, 1.0, 1.0},        -- Primary button (iOS Blue)
            buttonPrimaryHover = {0.2, 0.6, 1.0, 1.0},     -- Primary hover
            buttonPrimaryPressed = {0.0, 0.32, 0.74, 1.0}, -- Primary pressed
            
            buttonSecondary = {0.94, 0.94, 0.96, 1.0},     -- Secondary button (light gray)
            buttonSecondaryHover = {0.9, 0.9, 0.92, 1.0},   -- Secondary hover
            buttonSecondaryPressed = {0.84, 0.84, 0.86, 1.0}, -- Secondary pressed
            
            buttonTertiary = {0.0, 0.0, 0.0, 0.0},         -- Transparent tertiary
            buttonTertiaryHover = {0.0, 0.0, 0.0, 0.04},    -- Subtle hover
            buttonTertiaryPressed = {0.0, 0.0, 0.0, 0.08},  -- Subtle pressed
            
            buttonDisabled = {0.94, 0.94, 0.96, 1.0},      -- Disabled background
            
            -- Legacy button colors (updated)
            button = {0.94, 0.94, 0.96, 1.0},              -- Updated default
            buttonHover = {0.9, 0.9, 0.92, 1.0},           -- Updated hover
            buttonPressed = {0.84, 0.84, 0.86, 1.0},       -- Updated pressed
            text = {0.0, 0.0, 0.0, 0.87},                   -- Updated text color
            textDisabled = {0.0, 0.0, 0.0, 0.38},          -- Updated disabled text

            -- Semantic Action Colors (iOS-style)
            buttonDiscardActive = {1.0, 0.23, 0.19, 1.0},   -- iOS Red for destructive actions
            buttonPotionActive = {0.2, 0.78, 0.35, 1.0},    -- iOS Green for create actions
            buttonSortActive = {0.35, 0.34, 0.84, 1.0},     -- iOS Purple for utility
            buttonRecipeActive = {0.0, 0.48, 1.0, 1.0},     -- iOS Blue for info
            buttonDeckViewActive = {0.35, 0.34, 0.84, 1.0}, -- iOS Purple for navigation
            buttonSpellActive = {0.35, 0.34, 0.84, 1.0},    -- iOS Purple for magic
            buttonClose = {1.0, 0.23, 0.19, 1.0},           -- iOS Red for close
            buttonToggleActive = {0.2, 0.78, 0.35, 1.0},    -- iOS Green for active
            buttonToggleInactive = {0.94, 0.94, 0.96, 1.0}, -- Light gray for inactive
            buttonDrink = {0.2, 0.78, 0.35, 1.0},           -- iOS Green for positive action
            buttonSell = {1.0, 0.58, 0.0, 1.0},             -- iOS Orange for commerce
            
            -- Focus and Selection States
            focus = {0.0, 0.48, 1.0, 0.2},              -- Subtle blue focus indicator
            selection = {0.0, 0.48, 1.0, 0.15},         -- Selection background
            selectionBorder = {0.0, 0.48, 1.0, 1.0},    -- Selection border

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
            panelBorder = {0.3, 0.3, 0.4, 0.8},         -- Border color for panels
            
            -- Progress Bar Colors
            progressBarBackground = {0.1, 0.1, 0.15, 0.8},  -- Background color for progress bars
            progressBarFill = {0.3, 0.7, 1.0, 1.0},         -- Fill color for energy progress bar (blue)
            progressBarBorder = {0.3, 0.3, 0.4, 0.8},       -- Border color for progress bars
        },

        -- Modern Corner Radius System (iOS-style)
        cornerRadiusS = 6,              -- Small elements (buttons, small cards)
        cornerRadiusM = 10,             -- Medium elements (cards, inputs)
        cornerRadiusL = 16,             -- Large elements (panels, overlays)
        cornerRadiusXL = 20,            -- Extra large elements (main containers)
        
        -- Legacy corner radius (updated)
        cornerRadius = 6,               -- Updated default
        panelCornerRadius = 16,         -- Updated for modern look
        closeButtonCornerRadius = 6,    -- Updated for consistency

        -- Enhanced Button System (iOS touch targets)
        discardButton = { width = 120, height = 48, padding = 16, label = "Discard", cornerRadius = 6 },
        makePotionButton = { width = 140, height = 48, padding = 16, label = "Make Potion", cornerRadius = 6 },
        castSpellButton = { width = 120, height = 48, padding = 16, label = "Cast Spell", cornerRadius = 6 },
        sortButton = { width = 140, height = 36, label = "Sort: ", cornerRadius = 6 },
        potionListButton = { width = 100, height = 36, label = "Recipes", cornerRadius = 6 },
        deckViewButton = { width = 100, height = 36, label = "Deck", cornerRadius = 6 },

        -- Area Config (Dimensions/properties for specific UI regions)
        potionDisplayArea = { height = 140 }, -- Height of the central potion display area (x,y,width calculated in love.load)
        bottleWidth = 60,
        bottleHeight = 90,
        goalDisplay = { height = 65, padding = 8, roundTextYOffset = 0, goalTextYOffset = 18, progressTextYOffset = 38 }, -- (x,y,width calculated)
        potentialPotionDisplay = { width = 300, height = 75, padding = 5 }, -- (x,y calculated)
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
            ["default"]       = { neckH=0.2,  bodyH=0.8,  bodyW=0.8,  neckBottomYRel = -0.3, liquidTopYRel = -0.3, liquidBottomYRel = 0.5, spawnWidthRatio = 0.75 },
            ["standard"]      = { neckH=0.2,  bodyH=0.8,  bodyW=0.8,  neckBottomYRel = -0.3, liquidTopYRel = -0.3, liquidBottomYRel = 0.5, spawnWidthRatio = 0.75 },
            ["round_flask"]   = { neckH=0.3,  bulbRadiusRatio=0.45,   neckBottomYRel = -0.2, liquidTopYRel = -0.2, liquidBottomYRel = 0.5 - (0.45*2) + 0.45, spawnWidthRatio = 0.45 * 1.8 },
            ["tall_flask"]    = { neckH=0.15, bodyH=0.85, bodyW=0.6,  neckBottomYRel = -0.35,liquidTopYRel = -0.35,liquidBottomYRel = 0.5, spawnWidthRatio = 0.55 },
            ["small_vial"]    = { neckH=0.0,  bodyH=0.7,  bodyW=0.6,  neckBottomYRel = -0.35,liquidTopYRel = -0.35,liquidBottomYRel = 0.35, spawnWidthRatio = 0.55 },
            ["bulb"]          = { neckH=0.2,  bodyH=0.8,  bodyW=0.6,  neckBottomYRel = -0.3, liquidTopYRel = -0.3, liquidBottomYRel = 0.5, spawnWidthRatio = 0.55 },
            -- New unique bottle types
            ["crystal_orb"]   = { neckH=0.1,  bulbRadiusRatio=0.4,    neckBottomYRel = -0.4, liquidTopYRel = -0.35, liquidBottomYRel = 0.35, spawnWidthRatio = 0.7 },
            ["nature_vial"]   = { neckH=0.25, bodyH=0.75, bodyW=0.7,  neckBottomYRel = -0.35,liquidTopYRel = -0.3, liquidBottomYRel = 0.45, spawnWidthRatio = 0.65 },
            ["grand_flask"]   = { neckH=0.2,  bodyH=0.8,  bodyW=0.9,  neckBottomYRel = -0.25,liquidTopYRel = -0.25,liquidBottomYRel = 0.55, spawnWidthRatio = 0.85 },
            ["elegant_bottle"]= { neckH=0.3,  bodyH=0.7,  bodyW=0.65, neckBottomYRel = -0.35,liquidTopYRel = -0.3, liquidBottomYRel = 0.4, spawnWidthRatio = 0.6 },
            ["mystical_vial"] = { neckH=0.15, bodyH=0.85, bodyW=0.55, neckBottomYRel = -0.4, liquidTopYRel = -0.35,liquidBottomYRel = 0.5, spawnWidthRatio = 0.5 },
            ["herbal_jar"]    = { neckH=0.1,  bodyH=0.9,  bodyW=0.85, neckBottomYRel = -0.45,liquidTopYRel = -0.4, liquidBottomYRel = 0.5, spawnWidthRatio = 0.8 },
            ["heart"]         = { neckH=0.25, bodyH=0.75, bodyW=0.7,  neckBottomYRel = -0.35,liquidTopYRel = -0.3, liquidBottomYRel = 0.45, spawnWidthRatio = 0.65 },
        }
    },
    Game = {
        initialHandSize = 7,
        maxHandSize = 10,
        energyPerRound = 100,         -- Total energy for the day (doesn't replenish between rounds)
        makePotionEnergyCost = 15,    -- Base energy cost to attempt making a potion (deprecated - use variable cost)
        makePotionBaseCost = 10,      -- Base energy cost for 2-card potions
        makePotionCostPerCard = 3,    -- Additional energy cost per card beyond 2
        shopRefreshCost = 5,          -- Cost to refresh the shop
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
    currentEnergy = 0,              -- Player's current energy for the day (doesn't replenish between rounds)

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
    selectedSpellId = nil,          -- Currently selected spell for casting
    selectingSpellTarget = false,   -- Flag: Is the player currently choosing a target?
    spellCastingMode = false,       -- Flag: Is the player in spell casting mode?

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