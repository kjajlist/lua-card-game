-- File: bubbles.lua (Formatted)
-- Defines BubbleManager utility for handling bubble particle effect logic.
-- Operates on state and configuration passed as arguments.

local BubbleManager = {}

--- Determines the type of bubble to create based on potion properties.
-- @param potionDisplayState (table) State containing potion info.
-- @return (string) Bubble type: "normal", "magical", "sparkly", or "glowing".
function BubbleManager.determineBubbleType(potionDisplayState)
    local fillColor = potionDisplayState.fillColor or {0.5, 0.5, 0.5}
    local bottleType = potionDisplayState.bottleType or "default"
    
    -- Determine bubble type based on bottle type first, then color
    local magicIntensity = 0
    
    -- Special bottle types get specific bubble types
    if bottleType == "skull" then
        return math.random() < 0.9 and "magical" or "glowing" -- Dark magic bubbles
    elseif bottleType == "crystal_orb" then
        return math.random() < 0.8 and "magical" or "sparkly"
    elseif bottleType == "cauldron" then
        return math.random() < 0.7 and "glowing" or "magical" -- Cauldron bubbling
    elseif bottleType == "nature_vial" or bottleType == "herbal_jar" then
        return math.random() < 0.6 and "glowing" or "normal"
    elseif bottleType == "teapot" then
        return math.random() < 0.8 and "normal" or "glowing" -- Steam-like bubbles
    elseif bottleType == "star" then
        return math.random() < 0.9 and "sparkly" or "magical" -- Starry bubbles
    elseif bottleType == "heart" then
        return math.random() < 0.7 and "glowing" or "sparkly" -- Romantic bubbles
    elseif bottleType == "diamond" then
        return math.random() < 0.95 and "sparkly" or "magical" -- Brilliant sparkles
    elseif bottleType == "grand_flask" then
        return math.random() < 0.7 and "sparkly" or "glowing"
    elseif bottleType == "mystical_vial" then
        return math.random() < 0.9 and "magical" or "sparkly"
    elseif bottleType == "elegant_bottle" then
        return math.random() < 0.5 and "sparkly" or "glowing"
    end
    
    -- Check for magical colors (high blue/purple content)
    if fillColor[3] > 0.7 then -- High blue
        magicIntensity = magicIntensity + 0.3
    end
    if fillColor[1] > 0.8 and fillColor[3] > 0.8 then -- Purple (high red + blue)
        magicIntensity = magicIntensity + 0.4
    end
    
    -- Check for special bottle types
    if bottleType == "round_flask" then
        magicIntensity = magicIntensity + 0.2
    end
    
    -- Random factor
    local randomFactor = math.random()
    
    if magicIntensity > 0.5 or randomFactor < 0.15 then
        return "magical"
    elseif fillColor[1] > 0.8 and fillColor[2] > 0.8 then -- Bright/golden colors
        return randomFactor < 0.3 and "sparkly" or "glowing"
    elseif randomFactor < 0.2 then
        return "glowing"
    else
        return "normal"
    end
end

--- Calculates bubble spawning boundaries based on bottle type, dimensions, and boundary config.
-- @param bottleType (string) The key for boundaryConfig (e.g., "standard", "round_flask").
-- @param W (number) Total width of the bottle drawing area.
-- @param H (number) Total height of the bottle drawing area.
-- @param boundaryConfig (table) Configuration containing boundary data (e.g., Config.Bubble.boundaryData).
-- @return liquidTopY, liquidBottomY, spawnWidth, liquidBodyHeight (absolute values relative to bottle center 0,0), or fallback values on error.
function BubbleManager.getBoundaries(bottleType, W, H, boundaryConfig)
    -- 1. Validate Input Parameters
    if not boundaryConfig or type(boundaryConfig) ~= "table" then
        print("Error (BubbleManager.getBoundaries): boundaryConfig table is missing or invalid!")
        local safeW = (type(W) == "number" and W > 0) and W or 100 -- Use W if valid, else default
        local safeH = (type(H) == "number" and H > 0) and H or 100 -- Use H if valid, else default
        -- Fallback: top 30% from center, bottom 50% from center, 80% width
        return -safeH * 0.3, safeH * 0.5, safeW * 0.8, safeH * 0.8 
    end

    if type(W) ~= "number" or W <= 0 or type(H) ~= "number" or H <= 0 then
        print(string.format("Error (BubbleManager.getBoundaries): Invalid W (%s) or H (%s) parameters.", tostring(W), tostring(H)))
        return 0, 0, 0, 0 -- Return zero values indicating an error in dimensions
    end

    -- 2. Determine which boundary data to use
    local typeToUseKey = bottleType or "default" -- Use provided type or fallback to "default"
    local specificBoundaryData = boundaryConfig[typeToUseKey]
    local dataToUse = specificBoundaryData

    if not specificBoundaryData then
        dataToUse = boundaryConfig["default"] -- Try "default" if specific type not found
        if typeToUseKey ~= "default" then
            print(string.format("Warning (BubbleManager.getBoundaries): Unknown bottle type '%s'. Using default boundaries.", tostring(typeToUseKey)))
        end
    end

    if not dataToUse or type(dataToUse) ~= "table" then
        print(string.format("Warning (BubbleManager.getBoundaries): Missing boundary data for type '%s' AND missing/invalid 'default' entry. Using hardcoded relative fallbacks.", tostring(typeToUseKey)))
        -- Hardcoded relative fallbacks if even 'default' entry is problematic
        return -H * 0.3, H * 0.5, W * 0.8, H * 0.8 
    end

    -- 3. Calculate Boundaries from Data (relative to bottle height H and width W)
    -- Values are offsets from bottle center (0,0). liquidTopY is negative, liquidBottomY is positive.
    local liquidTopYRel = dataToUse.liquidTopYRel or -0.3 -- Default: Top of liquid is 30% up from center
    local liquidBottomYRel = dataToUse.liquidBottomYRel or 0.5 -- Default: Bottom of liquid is 50% down from center
    
    local liquidTopAbsoluteY = liquidTopYRel * H
    local liquidBottomAbsoluteY = liquidBottomYRel * H
    
    local defaultBodyWidthRatio = dataToUse.bodyW or 0.8 -- Default width of the bottle body as ratio of W
    local spawnWidthRatioToUse = dataToUse.spawnWidthRatio or defaultBodyWidthRatio -- Spawn width can be specific or same as body
    local spawnAreaWidth = spawnWidthRatioToUse * W
    
    local liquidBodyActualHeight = liquidBottomAbsoluteY - liquidTopAbsoluteY
    if liquidBodyActualHeight < 0 then 
        liquidBodyActualHeight = 0 -- Prevent negative height if config is illogical
    end

    return liquidTopAbsoluteY, liquidBottomAbsoluteY, spawnAreaWidth, liquidBodyActualHeight
end

--- Initializes the necessary bubble state within a given state table.
-- @param targetState (table) The state table to initialize (e.g., GameState.potionDisplay).
function BubbleManager.setup(targetState)
    if not targetState or type(targetState) ~= "table" then
        print("Error (BubbleManager.setup): Requires a valid targetState table.")
        return
    end

    targetState.bubbles = targetState.bubbles or {}
    targetState.isBubbling = targetState.isBubbling or false
    targetState.bubblesSpawned = targetState.bubblesSpawned or false -- Tracks if initial burst has happened for current potion
    print("BubbleManager setup complete for target state.")
end

--- Updates bubble state (spawning, movement, lifetime, removal).
-- @param dt Delta time.
-- @param potionDisplayState (table) State containing bubble info (e.g., GameState.potionDisplay).
-- @param bubbleConfig (table) Configuration for bubble behavior (e.g., Config.Bubble).
-- @param uiConfig (table) Configuration for UI elements, specifically bottle dimensions (e.g., Config.UI).
function BubbleManager.update(dt, potionDisplayState, bubbleConfig, uiConfig)
    -- 1. Validate Inputs
    if not potionDisplayState or type(potionDisplayState) ~= "table" then print("Error (BubbleManager.update): Missing or invalid potionDisplayState."); return end
    if not bubbleConfig or type(bubbleConfig) ~= "table" then print("Error (BubbleManager.update): Missing or invalid bubbleConfig."); return end
    if not uiConfig or type(uiConfig) ~= "table" then print("Error (BubbleManager.update): Missing or invalid uiConfig."); return end
    if not bubbleConfig.boundaryData then print("Error (BubbleManager.update): Requires bubbleConfig.boundaryData."); return end

    -- Ensure core bubble state structures exist
    potionDisplayState.bubbles = potionDisplayState.bubbles or {}
    potionDisplayState.isBubbling = potionDisplayState.isBubbling or false
    -- potionDisplayState.bubblesSpawned is managed based on fill level / animation

    -- 2. Get Configuration Values with Defaults
    local minSpeed = bubbleConfig.minSpeed or 35
    local maxSpeed = bubbleConfig.maxSpeed or 75
    local minRadius = bubbleConfig.minRadius or 5.0
    local maxRadius = bubbleConfig.maxRadius or 9.0
    local minLifetime = bubbleConfig.minLifetime or 1.2
    local maxLifetime = bubbleConfig.maxLifetime or 3.0
    local spawnEdgeMargin = bubbleConfig.spawnMargin or 5 -- Renamed for clarity
    local fadeOutDuration = bubbleConfig.fadeDuration or 0.4
    if fadeOutDuration <= 0 then fadeOutDuration = 0.01 end -- Prevent division by zero / instant fade

    local burstMinCount = bubbleConfig.burstMinCount or 3
    local burstMaxCount = bubbleConfig.burstMaxCount or 7
    local fillLevelSpawnThreshold = bubbleConfig.updateThreshold or 0.999 -- Fill level to trigger spawn
    local spawnDepthRatioInLiquid = bubbleConfig.spawnDepthRatio or 0.3 -- 0=surface, 1=deepest

    -- 3. Get Bottle Dimensions and Boundaries
    local bottleWidth = uiConfig.bottleWidth or 60
    local bottleHeight = uiConfig.bottleHeight or 90
    local currentBottleShape = potionDisplayState.bottleType or "default"

    local liquidSurfaceY, liquidBottomY, spawnableWidth, liquidColumnHeight = BubbleManager.getBoundaries(
        currentBottleShape, bottleWidth, bottleHeight, bubbleConfig.boundaryData
    )

    -- 4. Determine if a New Bubble Burst is Needed
    local currentFillLevel = potionDisplayState.fillLevel or 0
    local isFillNearlyComplete = currentFillLevel >= fillLevelSpawnThreshold
    
    -- Conditions for spawning an initial burst of bubbles:
    -- A. Potion is actively filling (but not just started, wait till it's mostly full).
    -- B. Potion fill is complete (or nearly) and bubbles haven't been spawned for this instance yet.
    local needsToSpawnBurst = false
    if potionDisplayState.isAnimatingFill then
        if currentFillLevel >= 0.95 then -- Only spawn if fill animation is well underway
            needsToSpawnBurst = not potionDisplayState.bubblesSpawned
        end
    elseif isFillNearlyComplete and not potionDisplayState.bubblesSpawned then
        needsToSpawnBurst = true
    end
    
    -- Spawn Initial Burst
    if needsToSpawnBurst then
        potionDisplayState.bubblesSpawned = true -- Mark that burst has occurred for this fill
        potionDisplayState.isBubbling = true     -- Set bubbling animation state
        local numBubblesToSpawn = math.random(burstMinCount, burstMaxCount)
        -- print("Spawning bubble burst: " .. numBubblesToSpawn .. ". isBubbling = true") -- DEBUG

        for _ = 1, numBubblesToSpawn do
            local bubbleType = BubbleManager.determineBubbleType(potionDisplayState)
            local newBubble = {
                radius = math.random() * (maxRadius - minRadius) + minRadius,
                speed = math.random() * (maxSpeed - minSpeed) + minSpeed,
                lifetime = math.random() * (maxLifetime - minLifetime) + minLifetime,
                alpha = 1.0,
                x = 0, y = 0, -- Will be set below
                bubbleType = bubbleType,
                shimmer = 0, -- For magical shimmer effect
                pulsePhase = math.random() * math.pi * 2 -- Random phase for pulsing
            }
            
            -- Enhance properties based on bubble type
            if bubbleType == "magical" then
                newBubble.radius = newBubble.radius * 1.2 -- Slightly larger
                newBubble.speed = newBubble.speed * 0.8 -- Slower, more majestic
                newBubble.lifetime = newBubble.lifetime * 1.5 -- Last longer
            elseif bubbleType == "sparkly" then
                newBubble.radius = newBubble.radius * 0.7 -- Smaller
                newBubble.speed = newBubble.speed * 1.3 -- Faster
                newBubble.sparkles = {} -- Will contain sparkle particles
            elseif bubbleType == "glowing" then
                newBubble.glowIntensity = 0.5 + math.random() * 0.5 -- Random glow strength
                newBubble.glowColor = {1, 1, 0.8} -- Warm glow
            end
            
            local spawnPaddingFromEdge = spawnEdgeMargin + newBubble.radius

            -- Spawn towards the bottom of the liquid column
            local depthOffsetFromBottom = 0
            if liquidColumnHeight > spawnPaddingFromEdge * 2 then -- Ensure there's room to spawn
                depthOffsetFromBottom = math.random() * liquidColumnHeight * spawnDepthRatioInLiquid
            end
            newBubble.y = liquidBottomY - spawnPaddingFromEdge - depthOffsetFromBottom
            newBubble.y = math.min(newBubble.y, liquidBottomY - spawnPaddingFromEdge) -- Clamp below bottom boundary
            newBubble.y = math.max(newBubble.y, liquidSurfaceY + spawnPaddingFromEdge) -- Clamp above top boundary (surface)

            -- Spawn horizontally within the calculated spawnableWidth
            local halfSpawnableWidth = (spawnableWidth / 2) - spawnPaddingFromEdge
            if halfSpawnableWidth > 0 then
                newBubble.x = (math.random() * 2 - 1) * halfSpawnableWidth -- Randomly +/- from center
            else
                newBubble.x = 0 -- Default to center if spawn width is too small
            end
            table.insert(potionDisplayState.bubbles, newBubble)
        end
    end

    -- 5. Update and Remove Existing Bubbles
    if #potionDisplayState.bubbles > 0 then
        for i = #potionDisplayState.bubbles, 1, -1 do -- Iterate backwards for safe removal
            local bubble = potionDisplayState.bubbles[i]
            if type(bubble) == "table" then
                -- Ensure properties exist, provide defaults if somehow missing
                local currentSpeed = bubble.speed or minSpeed
                local currentLifetime = bubble.lifetime or minLifetime
                local currentRadius = bubble.radius or minRadius
                local currentYPos = bubble.y or liquidBottomY 

                -- Move bubble upwards
                bubble.y = currentYPos - currentSpeed * dt
                -- Decrease lifetime
                bubble.lifetime = currentLifetime - dt

                -- Update magical properties based on bubble type
                if bubble.bubbleType == "magical" then
                    -- Magical bubbles shimmer and wobble slightly
                    bubble.shimmer = bubble.shimmer + dt * 8
                    bubble.x = bubble.x + math.sin(bubble.shimmer) * 2
                    bubble.pulsePhase = bubble.pulsePhase + dt * 4
                elseif bubble.bubbleType == "sparkly" then
                    -- Sparkly bubbles generate tiny sparkle particles
                    if not bubble.sparkles then bubble.sparkles = {} end
                    if math.random() < 0.3 then -- 30% chance per frame to spawn sparkle
                        local sparkle = {
                            x = bubble.x + math.random(-3, 3),
                            y = bubble.y + math.random(-3, 3),
                            life = 0.2 + math.random() * 0.3,
                            maxLife = 0.2 + math.random() * 0.3,
                            size = 0.5 + math.random()
                        }
                        table.insert(bubble.sparkles, sparkle)
                    end
                    
                    -- Update existing sparkles
                    for j = #bubble.sparkles, 1, -1 do
                        local sparkle = bubble.sparkles[j]
                        sparkle.life = sparkle.life - dt
                        if sparkle.life <= 0 then
                            table.remove(bubble.sparkles, j)
                        end
                    end
                elseif bubble.bubbleType == "glowing" then
                    -- Glowing bubbles pulse their glow intensity
                    if bubble.glowIntensity then
                        bubble.glowIntensity = 0.3 + 0.4 * (math.sin(bubble.pulsePhase) + 1) * 0.5
                        bubble.pulsePhase = bubble.pulsePhase + dt * 6
                    end
                end

                -- Calculate alpha for fading based on remaining lifetime
                if bubble.lifetime < fadeOutDuration then
                    bubble.alpha = math.max(0, bubble.lifetime / fadeOutDuration)
                else
                    bubble.alpha = 1.0
                end

                -- Check removal conditions
                local shouldRemoveBubble = false
                if bubble.lifetime <= 0 then
                    shouldRemoveBubble = true
                -- Remove when bottom edge of bubble passes the liquid surface
                elseif (bubble.y + currentRadius) < liquidSurfaceY then 
                    shouldRemoveBubble = true
                end

                if shouldRemoveBubble then
                    table.remove(potionDisplayState.bubbles, i)
                end
            else
                -- Invalid entry found in bubbles table, remove it
                print("Warning (BubbleManager.update): Found invalid (non-table) entry in potionDisplayState.bubbles at index " .. i .. ". Removing.")
                table.remove(potionDisplayState.bubbles, i)
            end
        end
    end

    -- 6. Update Overall Bubbling Status
    if potionDisplayState.isBubbling and #potionDisplayState.bubbles == 0 then
        potionDisplayState.isBubbling = false
        -- print("Bubble animation finished. isBubbling = false") -- DEBUG
        -- Note: bubblesSpawned flag is reset when a new potion fill starts or fill level drops significantly.
        -- This might be handled by the code that initiates potion filling.
        -- Example: if currentFillLevel < 0.1 then potionDisplayState.bubblesSpawned = false end
    end

    -- If fill animation just completed, ensure bubblesSpawned reflects this for subsequent static display
    if not potionDisplayState.isAnimatingFill and isFillNearlyComplete then
        potionDisplayState.bubblesSpawned = true 
    end
end

-- Note: BubbleManager does not include a draw function.
-- Drawing is handled elsewhere by iterating over GameState.potionDisplay.bubbles.

return BubbleManager