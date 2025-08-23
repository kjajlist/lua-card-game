-- File: core_game.lua (Final, Maximally Expanded Formatting)
-- Contains core game data definitions and all core game logic functions.

local CoreGame = {}

-- =============================================================================
-- DATA DEFINITIONS
-- =============================================================================

-- Card definitions: { data = { card properties }, count = number_in_deck }
local cardDefinitions = {
    -- Plants (Flowers) - Lower values, more common
    {
        data = { id = 1, name = "Rose", value = 7, family = "Plant", subType = "Flower", description = "A classic beauty.", objectColor = { 1, 0, 0 }, cost = 5 },
        count = 4
    },
    {
        data = { id = 2, name = "Tulip", value = 2, family = "Plant", subType = "Flower", description = "Comes in many colors.", objectColor = { 1, 1, 0 }, cost = 2 },
        count = 6
    },
    {
        data = { id = 3, name = "Daisy", value = 3, family = "Plant", subType = "Flower", description = "Simple and cheerful.", objectColor = { 1, 1, 1 }, cost = 2 },
        count = 5
    },
    {
        data = { id = 4, name = "Sunflower", value = 9, family = "Plant", subType = "Flower", description = "Tall and bright.", objectColor = { 1, 0.5, 0 }, cost = 7 },
        count = 2
    },
    {
        data = { id = 5, name = "Lavender", value = 6, family = "Plant", subType = "Herb", description = "Known for its scent.", objectColor = { 0.5, 0, 0.5 }, cost = 4 },
        count = 4
    },
    {
        data = { id = 6, name = "Orchid", value = 8, family = "Plant", subType = "Flower", description = "Elegant and exotic.", objectColor = { 0.8, 0.2, 0.8 }, cost = 8 },
        count = 2
    },
    {
        data = { id = 7, name = "Poppy", value = 4, family = "Plant", subType = "Flower", description = "Often red.", objectColor = { 1, 0, 0 }, cost = 3 },
        count = 5
    },
    {
        data = { id = 8, name = "Lily", value = 7, family = "Plant", subType = "Flower", description = "Fragrant and stately.", objectColor = { 1, 1, 1 }, cost = 5 },
        count = 3
    },
    {
        data = { id = 9, name = "Carnation", value = 4, family = "Plant", subType = "Flower", description = "Popular for bouquets.", objectColor = { 1, 0, 0 }, cost = 3 },
        count = 4
    },
    {
        data = { id = 10, name = "Marigold", value = 2, family = "Plant", subType = "Flower", description = "Easy to grow.", objectColor = { 1, 0.5, 0 }, cost = 2 },
        count = 6
    },
    {
        data = { id = 16, name = "Sage", value = 5, family = "Plant", subType = "Herb", description = "Aromatic.", objectColor = { 0.7, 0.8, 0.7 }, cost = 4 },
        count = 4
    },
    {
        data = { id = 17, name = "Mint", value = 3, family = "Plant", subType = "Herb", description = "Refreshing.", objectColor = { 0.4, 0.9, 0.4 }, cost = 3 },
        count = 5
    },
    -- New Plant cards for better balance
    {
        data = { id = 18, name = "Dandelion", value = 1, family = "Plant", subType = "Flower", description = "Common and resilient.", objectColor = { 1, 1, 0.8 }, cost = 1 },
        count = 7
    },
    {
        data = { id = 19, name = "Thyme", value = 4, family = "Plant", subType = "Herb", description = "Culinary herb.", objectColor = { 0.6, 0.8, 0.6 }, cost = 3 },
        count = 4
    },
    {
        data = { id = 20, name = "Basil", value = 3, family = "Plant", subType = "Herb", description = "Fresh and fragrant.", objectColor = { 0.5, 0.9, 0.5 }, cost = 3 },
        count = 5
    },
    {
        data = { id = 21, name = "Iris", value = 6, family = "Plant", subType = "Flower", description = "Purple beauty.", objectColor = { 0.6, 0.3, 0.9 }, cost = 4 },
        count = 3
    },
    {
        data = { id = 22, name = "Peony", value = 5, family = "Plant", subType = "Flower", description = "Large and showy.", objectColor = { 1, 0.7, 0.8 }, cost = 4 },
        count = 3
    },
    -- Magic - Keep rare but add some lower value options
    {
        data = { id = 11, name = "Pixie Dust", value = 10, family = "Magic", subType = "Dust", description = "Glimmering magic.", objectColor = { 0.8, 0.6, 1 }, cost = 10 },
        count = 1
    },
    {
        data = { id = 12, name = "Star Dust", value = 10, family = "Magic", subType = "Dust", description = "For shiny magic.", objectColor = { 0, 0.8, 1 }, cost = 10 },
        count = 1
    },
    {
        data = { id = 13, name = "Eternal Embers", value = 10, family = "Magic", subType = "Elemental", description = "Fire magic.", objectColor = { 1, 0.4, 0 }, cost = 10 },
        count = 1
    },
    {
        data = { id = 14, name = "Pure Water", value = 10, family = "Magic", subType = "Elemental", description = "Water magic.", objectColor = { 0.4, 0.6, 1 }, cost = 10 },
        count = 1
    },
    {
        data = { id = 15, name = "Thunderbolts", value = 10, family = "Magic", subType = "Elemental", description = "Bottled up.", objectColor = { 0.3, 0.7, 1 }, cost = 10 },
        count = 1
    },
    -- New Magic cards with lower values
    {
        data = { id = 23, name = "Sparkle Powder", value = 5, family = "Magic", subType = "Dust", description = "Minor magical dust.", objectColor = { 0.9, 0.9, 0.5 }, cost = 6 },
        count = 3
    },
    {
        data = { id = 24, name = "Mist Essence", value = 4, family = "Magic", subType = "Elemental", description = "Gentle water magic.", objectColor = { 0.7, 0.9, 1 }, cost = 5 },
        count = 4
    },
    {
        data = { id = 25, name = "Warm Glow", value = 3, family = "Magic", subType = "Elemental", description = "Soft fire magic.", objectColor = { 1, 0.8, 0.6 }, cost = 4 },
        count = 5
    },
    {
        data = { id = 26, name = "Breeze Whisper", value = 2, family = "Magic", subType = "Elemental", description = "Gentle wind magic.", objectColor = { 0.8, 1, 0.8 }, cost = 3 },
        count = 6
    },
}

-- Potion definitions based on card patterns - New Framework
local PotionCombinationEffects = {
    -- Flushes (all same type/subtype)
    flushes = {
        type = { 
            name = "Type Concoction", baseScore = 8, baseMoney = 3, 
            drinkEffect = { type="upgrade_recipe", value=2, description="Upgrade this recipe's power by 2!" }
        },
        subtype = { 
            name = "Pure Essence", baseScore = 20, baseMoney = 8,
            drinkEffect = { type="upgrade_recipe", value=5, description="Upgrade this recipe's power by 5!" }
        }
    },
    
    -- Matching by card type (ID)
    typeMatches = {
        [2] = { name = "Type Pair", baseScore = 3, baseMoney = 1,
                drinkEffect = { type="upgrade_recipe", value=1, description="Upgrade this recipe's power by 1!" } },
        [3] = { name = "Type Triple", baseScore = 8, baseMoney = 3,
                drinkEffect = { type="upgrade_recipe", value=2, description="Upgrade this recipe's power by 2!" } },
        [4] = { name = "Type Quad", baseScore = 18, baseMoney = 6,
                drinkEffect = { type="upgrade_recipe", value=4, description="Upgrade this recipe's power by 4!" } },
        [5] = { name = "Type Quint", baseScore = 35, baseMoney = 12,
                drinkEffect = { type="upgrade_recipe", value=6, description="Upgrade this recipe's power by 6!" } },
        [6] = { name = "Type Hexa", baseScore = 60, baseMoney = 20,
                drinkEffect = { type="upgrade_recipe", value=9, description="Upgrade this recipe's power by 9!" } },
        [7] = { name = "Type Septa", baseScore = 100, baseMoney = 35,
                drinkEffect = { type="upgrade_recipe", value=15, description="Upgrade this recipe's power by 15!" } }
    },
    
    -- Matching by value
    valueMatches = {
        [2] = { name = "Value Pair", baseScore = 4, baseMoney = 2,
                drinkEffect = { type="upgrade_recipe", value=1, description="Upgrade this recipe's power by 1!" } },
        [3] = { name = "Value Triple", baseScore = 10, baseMoney = 4,
                drinkEffect = { type="upgrade_recipe", value=3, description="Upgrade this recipe's power by 3!" } },
        [4] = { name = "Value Quad", baseScore = 22, baseMoney = 8,
                drinkEffect = { type="upgrade_recipe", value=5, description="Upgrade this recipe's power by 5!" } },
        [5] = { name = "Value Quint", baseScore = 42, baseMoney = 15,
                drinkEffect = { type="upgrade_recipe", value=8, description="Upgrade this recipe's power by 8!" } },
        [6] = { name = "Value Hexa", baseScore = 70, baseMoney = 25,
                drinkEffect = { type="upgrade_recipe", value=12, description="Upgrade this recipe's power by 12!" } },
        [7] = { name = "Value Septa", baseScore = 120, baseMoney = 40,
                drinkEffect = { type="upgrade_recipe", value=20, description="Upgrade this recipe's power by 20!" } }
    },
    
    default = {
        name = "Murky Mixture", 
        baseScore = 0, 
        baseMoney = 0,
        bonusPoints = 0,
        drinkEffect = { type="upgrade_recipe", value=1, description="Upgrade this recipe's power by 1!" }
    }
}

-- Curated goals for the first 10 rounds (all score-based)
local RoundsData = {
    { round = 1, goalType = "score_earned_round", goalTarget = 35, description = "Earn 35 Score This Round" },
    { round = 2, goalType = "score_earned_round", goalTarget = 50, description = "Earn 50 Score This Round" },
    { round = 3, goalType = "score_earned_round", goalTarget = 65, description = "Earn 65 Score This Round" },
    { round = 4, goalType = "score_earned_round", goalTarget = 80, description = "Earn 80 Score This Round" },
    { round = 5, goalType = "score_reached_total", goalTarget = 200, description = "Reach a Total Score of 200" },
    { round = 6, goalType = "score_earned_round", goalTarget = 100, description = "Earn 100 Score This Round" },
    { round = 7, goalType = "score_earned_round", goalTarget = 120, description = "Earn 120 Score This Round" },
    { round = 8, goalType = "score_earned_round", goalTarget = 140, description = "Earn 140 Score This Round" },
    { round = 9, goalType = "score_earned_round", goalTarget = 160, description = "Earn 160 Score This Round" },
    { round = 10, goalType = "score_reached_total", goalTarget = 500, description = "Grand Alchemist: Reach 500 Total Score" }
}

local numPredefinedRounds = #RoundsData

-- Templates for generating random goals in endless mode (score-based only)
local randomGoalTemplates = {
    { 
        goalType = "score_earned_round", 
        baseTargetMin = 60, baseTargetMax = 120, 
        targetScaleFactor = 4.0, 
        descriptionFormat = "Earn %d Score This Round" 
    },
    { 
        goalType = "score_reached_total", 
        baseTargetMin = 200, baseTargetMax = 400, 
        targetScaleFactor = 6.0, 
        descriptionFormat = "Reach %d Total Score" 
    }
}

-- Spell Definitions with energyCost
local SpellDefinitions = {
    ["transmute_value"] = {
        id = "transmute_value", name = "Transmute Value", uses = 3, cost = 0, target = "hand_card",
        energyCost = 10, description = "Reroll Value. Cost: 1 use, 10 Energy.",
        effect = function(gameState, dependencies, targetData)
            local handIndex = targetData and targetData.handIndex
            if not handIndex or not gameState.hand[handIndex] then return false end
            
            local card = gameState.hand[handIndex]
            local oldValue = card.value
            card.value = math.random(1, 10)
            print(string.format("Spell 'Transmute Value' cast on '%s'. Value %d -> %d.", card.name, oldValue, card.value))
            
            if dependencies.coreGame.updatePotentialPotion then
                dependencies.coreGame.updatePotentialPotion(gameState, dependencies)
            end
            if dependencies.coreGame.recalculateCurrentScore then
                dependencies.coreGame.recalculateCurrentScore(gameState)
            end
            return true
        end
    },
    ["duplicate_card"] = {
        id = "duplicate_card", name = "Duplicate Card", uses = 1, cost = 0, target = "hand_card",
        energyCost = 25, description = "Copy card. Cost: 1 use, 25 Energy.",
        effect = function(gameState, dependencies, targetData)
            local handIndex = targetData and targetData.handIndex
            if not handIndex or not gameState.hand[handIndex] then return false end
            
            local maxHand = (dependencies.config.Game and dependencies.config.Game.maxHandSize) or 10
            if #gameState.hand >= maxHand then
                print("Spell 'Duplicate Card' failed: Hand is full.")
                return false
            end

            local originalCard = gameState.hand[handIndex]
            local cardDef = dependencies.getCardDefinitionById(originalCard.id, dependencies)
            if cardDef then
                local newCard = dependencies.createCard(cardDef.id, cardDef.name, cardDef.value, cardDef.family, cardDef.subType, cardDef.description, cardDef.objectColor)
                if newCard then
                    table.insert(gameState.hand, newCard)
                    print(string.format("Spell 'Duplicate Card' cast on '%s'. Copy added.", originalCard.name))
                    if dependencies.sort.calculateHandLayout then
                        dependencies.sort.calculateHandLayout(gameState, dependencies.config)
                    end
                    return true
                end
            end
            return false
        end
    },
    ["banish_card"] = {
        id = "banish_card", name = "Banish Card", uses = 2, cost = 0, target = "hand_card",
        energyCost = 5, description = "Remove card from game. Cost: 1 use, 5 Energy.",
        effect = function(gameState, dependencies, targetData)
            local handIndex = targetData and targetData.handIndex
            if not handIndex or not gameState.hand[handIndex] then return false end

            local card = gameState.hand[handIndex]
            print(string.format("Spell 'Banish Card' cast on '%s'. Card removed.", card.name))
            table.remove(gameState.hand, handIndex)
            
            local selectionChanged = false
            for i = #gameState.selectedCardIndices, 1, -1 do
                local selIdx = gameState.selectedCardIndices[i]
                if selIdx == handIndex then
                    table.remove(gameState.selectedCardIndices, i)
                    selectionChanged = true
                elseif selIdx > handIndex then
                    gameState.selectedCardIndices[i] = selIdx - 1
                end
            end
            
            if selectionChanged then
                if dependencies.coreGame.recalculateCurrentScore then dependencies.coreGame.recalculateCurrentScore(gameState) end
                if dependencies.coreGame.updatePotentialPotion then dependencies.coreGame.updatePotentialPotion(gameState, dependencies) end
            end
            
            if dependencies.sort.calculateHandLayout then dependencies.sort.calculateHandLayout(gameState, dependencies.config) end
            return true
        end
    },
}

-- Spellbook Definitions
local SpellbookDefinitions = {
    ["minor_alchemy"] = {
        id = "minor_alchemy", name = "Minor Alchemy Tome", shopItemType = "spellbook", cost = 15,
        description = "Learn basic transmutation spells.", spells = {"transmute_value"}
    },
    ["book_of_replication"] = {
        id = "book_of_replication", name = "Book of Replication", shopItemType = "spellbook", cost = 25,
        description = "Learn the Duplicate Card spell.", spells = {"duplicate_card"}
    },
    ["grimoire_of_void"] = {
        id = "grimoire_of_void", name = "Grimoire of the Void", shopItemType = "spellbook", cost = 20,
        description = "Learn the Banish Card spell.", spells = {"banish_card"}
    },
}

-- Energy Elixir Definitions
local EnergyElixirDefinitions = {
    ["minor_energy_elixir"] = {
        id = "minor_energy_elixir", name = "Minor Energy Elixir", shopItemType = "energy_elixir", cost = 8,
        description = "Restore 25 energy when consumed.", energyRestore = 25,
        display = { bottle = "energy", color = {0.3, 0.7, 1.0} }
    },
    ["energy_elixir"] = {
        id = "energy_elixir", name = "Energy Elixir", shopItemType = "energy_elixir", cost = 15,
        description = "Restore 50 energy when consumed.", energyRestore = 50,
        display = { bottle = "energy", color = {0.2, 0.6, 0.9} }
    },
    ["major_energy_elixir"] = {
        id = "major_energy_elixir", name = "Major Energy Elixir", shopItemType = "energy_elixir", cost = 25,
        description = "Restore 100 energy when consumed.", energyRestore = 100,
        display = { bottle = "energy", color = {0.1, 0.5, 0.8} }
    },
    ["supreme_energy_elixir"] = {
        id = "supreme_energy_elixir", name = "Supreme Energy Elixir", shopItemType = "energy_elixir", cost = 40,
        description = "Restore 200 energy when consumed.", energyRestore = 200,
        display = { bottle = "energy", color = {0.0, 0.4, 0.7} }
    },
}

-- =============================================================================
-- Core Game Logic Function Definitions
-- =============================================================================

function CoreGame.shallowcopy(original)
    if type(original) ~= 'table' then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    
    return copy
end

function CoreGame.lerp(a, b, t)
    return a + (b - a) * t
end

function CoreGame.calculateAverageColor(colors)
    if not colors or #colors == 0 then
        return {0.5, 0.5, 0.5}
    end

    local r, g, b, count = 0, 0, 0, 0
    for _, col in ipairs(colors) do
        if col and type(col) == 'table' and #col >= 3 then
            r = r + (col[1] or 0)
            g = g + (col[2] or 0)
            b = b + (col[3] or 0)
            count = count + 1
        end
    end
    
    if count == 0 then
        return {0.5, 0.5, 0.5}
    end
    
    return {r / count, g / count, b / count}
end

function CoreGame.getCardColorGroupName(card)
    if not card or not card.objectColor then
        return "Unknown"
    end
    
    local r, g, b = card.objectColor[1], card.objectColor[2], card.objectColor[3]
    if type(r) ~= 'number' or type(g) ~= 'number' or type(b) ~= 'number' then
        return "Invalid"
    end
    
    local maxC, minC = math.max(r, g, b), math.min(r, g, b)
    
    if maxC - minC < 0.15 then
        if maxC > 0.85 then
            return "White"
        elseif maxC < 0.15 then
            return "Black"
        else
            return "Gray"
        end
    end

    if r > g and r > b then
        return "Red"
    elseif g > r and g > b then
        return "Green"
    elseif b > r and b > g then
        return "Blue"
    elseif r > 0.5 and g > 0.5 then
        return "Yellow"
    elseif r > 0.5 and b > 0.5 then
        return "Purple"
    elseif g > 0.5 and b > 0.5 then
        return "Cyan"
    else
        return "Mixed"
    end
end

function CoreGame.analyzeHand(selectedCards, dependencies)
    local analysis = {
        totalCards = #selectedCards, 
        countsById = {}, 
        countsByFamily = {},
        countsBySubType = {}, 
        countsByValue = {},
        highestCardValue = 0,
        dominantFamily = nil, 
        dominantSubType = nil,
        largestTypeMatch = 0,
        largestValueMatch = 0,
        hasTypeFlush = false,
        hasSubtypeFlush = false
    }
    if analysis.totalCards == 0 then
        return analysis
    end

    for _, card in ipairs(selectedCards) do
        analysis.countsById[card.id] = (analysis.countsById[card.id] or 0) + 1
        analysis.countsByFamily[card.family] = (analysis.countsByFamily[card.family] or 0) + 1
        analysis.countsByValue[card.value] = (analysis.countsByValue[card.value] or 0) + 1
        if card.subType then
            analysis.countsBySubType[card.subType] = (analysis.countsBySubType[card.subType] or 0) + 1
        end
        analysis.highestCardValue = math.max(analysis.highestCardValue, card.value)
    end

    -- Find largest type match (by card ID)
    for _, count in pairs(analysis.countsById) do
        if count >= 2 and count > analysis.largestTypeMatch then
            analysis.largestTypeMatch = count
        end
    end

    -- Find largest value match
    for _, count in pairs(analysis.countsByValue) do
        if count >= 2 and count > analysis.largestValueMatch then
            analysis.largestValueMatch = count
        end
    end

    -- Check for flushes (all same type/subtype) - these are bonuses, not primary recipes
    if #selectedCards > 1 then
        for family, count in pairs(analysis.countsByFamily) do
            if count == analysis.totalCards then
                analysis.dominantFamily = family
                analysis.hasTypeFlush = true
                break
            end
        end
        for subType, count in pairs(analysis.countsBySubType) do
            if count == analysis.totalCards then
                analysis.dominantSubType = subType
                analysis.hasSubtypeFlush = true
                break
            end
        end
    end

    return analysis
end

function CoreGame.determinePotionBottleType(analysis, potionResult)
    -- Determine bottle type based on potion characteristics
    local bottleType = "default"
    local hasHighValueCards = analysis.highestCardValue >= 7
    local hasFlush = analysis.hasTypeFlush or analysis.hasSubtypeFlush
    local hasMagic = analysis.dominantFamily == "Magic"
    local hasPlant = analysis.dominantFamily == "Plant"
    local largestMatch = math.max(analysis.largestTypeMatch, analysis.largestValueMatch)
    local totalPoints = potionResult.drinkPoints or 0
    
    -- Determine bottle type based on combination characteristics and fun factor
    if hasFlush and hasMagic and totalPoints >= 50 then
        bottleType = "skull" -- Powerful dark magic gets skull bottles
    elseif hasFlush and hasMagic then
        bottleType = "crystal_orb" -- Magical flush potions get crystal orbs
    elseif hasFlush and hasPlant and totalPoints >= 40 then
        bottleType = "cauldron" -- Powerful plant potions get cauldrons
    elseif hasFlush and hasPlant then
        bottleType = "nature_vial" -- Plant flush potions get nature vials
    elseif largestMatch >= 5 then
        bottleType = "diamond" -- Perfect matches get diamond bottles
    elseif largestMatch >= 4 and totalPoints >= 60 then
        bottleType = "star" -- High-scoring 4+ matches get star bottles
    elseif largestMatch >= 4 then
        bottleType = "grand_flask" -- 4+ matches get grand flasks
    elseif largestMatch >= 3 and hasHighValueCards then
        bottleType = "heart" -- 3+ matches with high values get heart bottles
    elseif largestMatch >= 3 then
        bottleType = "round_flask" -- 3 matches get round flasks
    elseif hasHighValueCards and hasMagic then
        bottleType = "teapot" -- High value magic gets teapot (whimsical)
    elseif hasHighValueCards then
        bottleType = "elegant_bottle" -- High value cards get elegant bottles
    elseif hasMagic then
        bottleType = "mystical_vial" -- Magic cards get mystical vials
    elseif hasPlant then
        bottleType = "herbal_jar" -- Plant cards get herbal jars
    else
        bottleType = "standard" -- Default for simple combinations
    end
    
    return bottleType
end

function CoreGame.determinePotionResult(selectedCards, dependencies)
    local result = CoreGame.shallowcopy(PotionCombinationEffects.default)
    result.recipeIndex = nil
    
    if not selectedCards or #selectedCards == 0 then
        result.name = "Nothing"
        return result
    end
    
    local analysis = CoreGame.analyzeHand(selectedCards, dependencies)
    local totalScore = 0
    local totalMoney = 0
    local combinationDescriptions = {}
    local flushBonus = 0
    local flushDescription = ""
    
    -- Initialize point breakdown for animation
    result.pointBreakdown = {
        typeMatches = {},
        valueMatches = {},
        flushBonus = 0,
        cardValueBonus = 0,
        total = 0
    }
    
    -- Calculate points for ALL type matches (not just the largest)
    for matchSize, count in pairs(analysis.countsById) do
        if count >= 2 then
            local typeMatch = PotionCombinationEffects.typeMatches[count]
            if typeMatch then
                totalScore = totalScore + typeMatch.baseScore
                totalMoney = totalMoney + typeMatch.baseMoney
                table.insert(combinationDescriptions, string.format("%d matching by card type", count))
                table.insert(result.pointBreakdown.typeMatches, {
                    count = count,
                    points = typeMatch.baseScore,
                    money = typeMatch.baseMoney,
                    description = string.format("%d matching by card type", count)
                })
            end
        end
    end
    
    -- Calculate points for ALL value matches (not just the largest)
    for matchSize, count in pairs(analysis.countsByValue) do
        if count >= 2 then
            local valueMatch = PotionCombinationEffects.valueMatches[count]
            if valueMatch then
                totalScore = totalScore + valueMatch.baseScore
                totalMoney = totalMoney + valueMatch.baseMoney
                table.insert(combinationDescriptions, string.format("%d matching by value", count))
                table.insert(result.pointBreakdown.valueMatches, {
                    count = count,
                    points = valueMatch.baseScore,
                    money = valueMatch.baseMoney,
                    description = string.format("%d matching by value", count)
                })
            end
        end
    end
    
    -- Apply flush bonuses and special effects
    local flushEffect = nil
    if analysis.hasSubtypeFlush then
        flushBonus = flushBonus + 10
        flushDescription = flushDescription .. " + Subtype Flush Bonus"
        result.pointBreakdown.flushBonus = 10
        
        -- Check for special flush effects based on card family
        if analysis.dominantFamily == "Magic" then
            flushEffect = { type = "upgrade_recipe", value = 3, description = "Magic flush! Upgrade this recipe's power by 3!" }
        elseif analysis.dominantFamily == "Plant" then
            flushEffect = { type = "restore_energy", value = 20, description = "Plant flush! Restore 20 energy!" }
        end
    elseif analysis.hasTypeFlush then
        flushBonus = flushBonus + 5
        flushDescription = flushDescription .. " + Type Flush Bonus"
        result.pointBreakdown.flushBonus = 5
        
        -- Check for special flush effects based on card family
        if analysis.dominantFamily == "Magic" then
            flushEffect = { type = "upgrade_recipe", value = 2, description = "Magic flush! Upgrade this recipe's power by 2!" }
        elseif analysis.dominantFamily == "Plant" then
            flushEffect = { type = "restore_energy", value = 15, description = "Plant flush! Restore 15 energy!" }
        end
    end
    
    totalScore = totalScore + flushBonus
    
    -- Determine the primary recipe name based on the highest scoring combination
    local primaryRecipe = nil
    if analysis.largestTypeMatch >= 2 and analysis.largestTypeMatch >= analysis.largestValueMatch then
        primaryRecipe = PotionCombinationEffects.typeMatches[analysis.largestTypeMatch]
    elseif analysis.largestValueMatch >= 2 then
        primaryRecipe = PotionCombinationEffects.valueMatches[analysis.largestValueMatch]
    end
    
    if primaryRecipe then
        result.name = primaryRecipe.name
        -- Use flush effect if it exists, otherwise use the primary recipe's effect
        if flushEffect then
            result.drinkEffect = CoreGame.shallowcopy(flushEffect)
        else
            result.drinkEffect = CoreGame.shallowcopy(primaryRecipe.drinkEffect or result.drinkEffect)
        end
    else
        result.name = "Murky Mixture"
        -- Use flush effect even for murky mixtures if there's a flush
        if flushEffect then
            result.drinkEffect = CoreGame.shallowcopy(flushEffect)
        end
    end
    
    -- Build requirements description from all combinations
    if #combinationDescriptions > 0 then
        result.requirementsDesc = table.concat(combinationDescriptions, " + ")
        if flushDescription ~= "" then
            result.requirementsDesc = result.requirementsDesc .. flushDescription
        end
    else
        result.requirementsDesc = "No combination found"
    end
    
    -- Set final scores
    result.drinkPoints = totalScore
    result.saleMoney = totalMoney
    
    -- Add card value bonus to drink points
    local cardValueSum = 0
    for _,c in ipairs(selectedCards) do
        cardValueSum = cardValueSum + c.value
    end
    local cardValueBonus = math.floor(cardValueSum / 2)
    result.drinkPoints = result.drinkPoints + cardValueBonus
    result.pointBreakdown.cardValueBonus = cardValueBonus
    
    -- Set saleValue to match saleMoney for consistency
    result.saleValue = result.saleMoney or 0
    
    -- Calculate total for breakdown
    result.pointBreakdown.total = result.drinkPoints
    
    local colorsForAvg = {}
    for _,c in ipairs(selectedCards) do
        table.insert(colorsForAvg, c.objectColor)
    end
    
    -- Determine unique bottle type based on potion characteristics
    local bottleType = CoreGame.determinePotionBottleType(analysis, result)
    result.display = { bottle = bottleType, color = CoreGame.calculateAverageColor(colorsForAvg) }

    return result
end

function CoreGame.updatePotentialPotion(gameState, dependencies)
    if not gameState then
        return
    end

    if not gameState.selectedCardIndices then
        gameState.selectedCardIndices = {}
    end
    
    local selectedCardsData = {}
    for _, handIndex in ipairs(gameState.selectedCardIndices) do 
        if gameState.hand and gameState.hand[handIndex] then 
            table.insert(selectedCardsData, gameState.hand[handIndex])
        end
    end
    
    gameState.potentialPotionResult = CoreGame.determinePotionResult(selectedCardsData, dependencies)
end

function CoreGame.createCardInstance(id, name, value, family, subType, description, objectColor)
    local objColorCopy = nil
    if objectColor and type(objectColor) == "table" and #objectColor >= 3 then
        objColorCopy = {objectColor[1], objectColor[2], objectColor[3]}
    end
    return {
        id = id, name = name or "Unknown", value = value or 0,
        family = family or "Unknown", subType = subType,
        description = description or "", objectColor = objColorCopy,
        x = 0, y = 0, rotation = 0, scale = 1,
        targetX = 0, targetY = 0, targetRotation = 0, targetScale = 1,
        startX = 0, startY = 0, startRotation = 0, startScale = 1,
        isHighlighted = false, isAnimating = false, isDiscarding = false,
        animProgress = 0, animDuration = 0
    }
end

function CoreGame.getCardDefinitionById(id, dependencies)
    if not dependencies or not dependencies.cardDefLookup then
        print("Error: dependencies.cardDefLookup not provided to getCardDefinitionById.")
        return nil
    end
    return dependencies.cardDefLookup[id]
end

function CoreGame.shuffleDeck(gameState)
    if not gameState or not gameState.deck then
        print("Error: Cannot shuffle, gameState.deck missing.")
        return
    end
    
    print("Shuffling deck...")
    local deck, deckSize = gameState.deck, #gameState.deck
    for i = deckSize, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    print("Deck shuffled. Current deck size: " .. deckSize)
end

function CoreGame.drawCards(gameState, config, dependencies, numCards)
    if not (gameState and config and dependencies) then
        print("ERROR: Missing arguments in drawCards.")
        return
    end

    local gameConfig = config.Game or {}
    local animConfig = config.Animation or {}
    local screenConfig = config.Screen or {}
    local targetHandSize = gameConfig.initialHandSize or 7
    local maxHandSize = gameConfig.maxHandSize or 10
    
    -- Calculate how many cards to draw
    local currentHandSize = #gameState.hand
    local numToDraw = 0
    
    if numCards then
        -- If a specific number is requested, use that (but don't exceed max hand size)
        numToDraw = math.min(numCards, maxHandSize - currentHandSize)
    else
        -- If no specific number, draw up to target hand size
        numToDraw = math.max(0, targetHandSize - currentHandSize)
    end
    
    -- Don't draw if we're already at or above the target
    if numToDraw <= 0 then
        print(string.format("[drawCards] Hand already at target size (%d). No cards drawn.", currentHandSize))
        return
    end
    
    print(string.format("[drawCards] Attempting to draw %d cards. Current hand size: %d, Target: %d, Deck size before: %d", 
          numToDraw, currentHandSize, targetHandSize, #gameState.deck))
    
    local drawnCount, deck, discardPile, hand = 0, gameState.deck, gameState.discardPile, gameState.hand
    
    for i = 1, numToDraw do
        if #deck == 0 then
            -- Deck is empty, can't draw more cards
            print("[drawCards] Deck empty, can't draw more cards")
            break
        end

        local drawnCard = table.remove(deck, 1)
        if drawnCard and type(drawnCard) == "table" then 
            drawnCard.isHighlighted = false
            drawnCard.isAnimating = true
            drawnCard.isDiscarding = false
            drawnCard.isAnimatingToPotion = false -- Ensure this is clean
            drawnCard.animProgress = 0
            drawnCard.animDuration = animConfig.dealDuration or 0.3
            drawnCard.startX = drawnCard.x
            drawnCard.startY = drawnCard.y
            drawnCard.startRotation = drawnCard.rotation or 0
            drawnCard.startScale = drawnCard.scale or 0.5
            
            -- Clean up any transformation properties
            drawnCard.dissolveIntensity = nil
            drawnCard.glowIntensity = nil
            drawnCard.magicalTrail = nil
            
            print(string.format("DEBUG: Drawing card '%s' from deck position (%d, %d)", 
                  drawnCard.name or "Unknown", drawnCard.startX or 0, drawnCard.startY or 0))
            
            table.insert(hand, drawnCard)
            drawnCount = drawnCount + 1
        else
            print("Warning: Invalid item drawn from deck (expected card table).")
        end
    end
    
    -- Update hand layout and other game state first
    if dependencies.sort and dependencies.sort.calculateHandLayout then dependencies.sort.calculateHandLayout(gameState, config) end
    if CoreGame.recalculateCurrentScore then CoreGame.recalculateCurrentScore(gameState) end
    if CoreGame.updatePotentialPotion then CoreGame.updatePotentialPotion(gameState, dependencies) end
    
    -- Only end the game if we couldn't draw any cards at all AND the deck is empty
    if drawnCount == 0 and #deck == 0 then
        print("[drawCards] No cards drawn and deck is empty. Game Over: out_of_cards")
        gameState.gamePhase = "game_over"
        gameState.gameOverReason = "out_of_cards"
        if dependencies and dependencies.overlayManager then
            dependencies.overlayManager:show("gameOver")
        end
    end
    
    print(string.format("[drawCards] Drew %d cards. Deck size after: %d, Hand size: %d", drawnCount, #deck, #hand))
end

function CoreGame.drawReplacements(gameState, config, dependencies, numToDraw)
    if not (gameState and config and dependencies) then
        print("ERROR: Missing arguments in drawReplacements.")
        return
    end
    
    local gameConfig = config.Game or {}
    local targetHandSize = gameConfig.initialHandSize or 7
    local currentHandSize = #gameState.hand
    
    -- Calculate how many cards we need to draw to reach target hand size
    local cardsNeeded = math.max(0, targetHandSize - currentHandSize)
    
    if cardsNeeded > 0 then
        print(string.format("Drawing %d replacement cards to reach target hand size of %d (current: %d).", 
              cardsNeeded, targetHandSize, currentHandSize))
        CoreGame.drawCards(gameState, config, dependencies, cardsNeeded)
    else
        print(string.format("Hand already at target size (%d). No replacement cards needed.", currentHandSize))
    end
end

function CoreGame.recalculateCurrentScore(gameState)
    if not (gameState and gameState.selectedCardIndices and gameState.hand) then
        if gameState then gameState.currentScore = 0 end
        return
    end

    local sum = 0
    for _, handIndex in ipairs(gameState.selectedCardIndices) do 
        local card = gameState.hand[handIndex]
        if card and type(card.value) == "number" then
            sum = sum + card.value
        end
    end
    gameState.currentScore = sum
end

function CoreGame.discardSelectedCards(gameState, config, dependencies)
    if not (gameState and config and dependencies and gameState.selectedCardIndices and gameState.hand) or #gameState.selectedCardIndices == 0 then
        return
    end

    if gameState.isWaitingForDiscard or gameState.gamePhase ~= "playing" then
        return
    end

    if not gameState.canDiscard then
        print("Discard action not allowed.")
        return
    end
    
    print("Discarding", #gameState.selectedCardIndices, "selected cards.")
    local animConfig, screenConfig, cardConfig = config.Animation or {}, config.Screen or {}, config.Card or {}
    local numDiscarded = 0
    
    for i = #gameState.selectedCardIndices, 1, -1 do
        local handIndex = gameState.selectedCardIndices[i]
        if handIndex and gameState.hand[handIndex] then
            local card = gameState.hand[handIndex]
            card.isDiscarding = true
            card.isAnimating = true
            card.animProgress = 0
            card.animDuration = animConfig.discardDuration or 0.4
            card.startX = card.x
            card.startY = card.y
            card.startRotation = card.rotation or 0
            card.startScale = card.scale or 1
            card.targetX = (screenConfig.width or 400)/2 - (cardConfig.width or 60)/2
            card.targetY = (screenConfig.height or 600) + (cardConfig.height or 80)
            card.targetRotation = math.rad(math.random(-30,30))
            card.targetScale = 0.3
            card.isHighlighted = false
            numDiscarded = numDiscarded + 1
        end
    end

    gameState.selectedCardIndices = {}
    CoreGame.recalculateCurrentScore(gameState)
    CoreGame.updatePotentialPotion(gameState, dependencies)
    
    if numDiscarded > 0 then 
        gameState.isWaitingForDiscard = true
        gameState.discardAnimCounter = numDiscarded
        gameState.numReplacementsToDraw = numDiscarded
    end
    
    if dependencies.sort.calculateHandLayout then
        dependencies.sort.calculateHandLayout(gameState, config)
    end
end

function CoreGame.deselectAllCards(gameState, dependencies)
    if not (gameState and gameState.selectedCardIndices and gameState.hand) or #gameState.selectedCardIndices == 0 then
        return
    end

    print("Deselecting all cards")
    for _, handIndex in ipairs(gameState.selectedCardIndices) do 
        local card = gameState.hand[handIndex]
        if card then
            card.isHighlighted = false
        end
    end
    
    gameState.selectedCardIndices = {}
    CoreGame.recalculateCurrentScore(gameState)
    CoreGame.updatePotentialPotion(gameState, dependencies)
    
    if dependencies.sort.calculateHandLayout then
        dependencies.sort.calculateHandLayout(gameState, dependencies.config)
    end
end

function CoreGame.selectCard(gameState, dependencies, handIndex)
    if not (gameState and gameState.hand and gameState.hand[handIndex]) or gameState.gamePhase ~= "playing" then
        return
    end

    for _, idx in ipairs(gameState.selectedCardIndices) do
        if idx == handIndex then
            return
        end
    end
    
    table.insert(gameState.selectedCardIndices, handIndex)
    gameState.hand[handIndex].isHighlighted = true
    print("Selected card index:", handIndex)
    
    CoreGame.recalculateCurrentScore(gameState)
    CoreGame.updatePotentialPotion(gameState, dependencies)
    if dependencies.sort.calculateHandLayout then
        dependencies.sort.calculateHandLayout(gameState, dependencies.config)
    end
end

function CoreGame.deselectCard(gameState, dependencies, indexInSelectionList)
    if not (gameState and gameState.selectedCardIndices and gameState.selectedCardIndices[indexInSelectionList]) or gameState.gamePhase ~= "playing" then
        return
    end

    local handIndex = gameState.selectedCardIndices[indexInSelectionList]
    if gameState.hand and gameState.hand[handIndex] then
        gameState.hand[handIndex].isHighlighted = false
    end
    
    table.remove(gameState.selectedCardIndices, indexInSelectionList)
    print("Deselected card index:", handIndex)
    
    CoreGame.recalculateCurrentScore(gameState)
    CoreGame.updatePotentialPotion(gameState, dependencies)
    if dependencies.sort.calculateHandLayout then
        dependencies.sort.calculateHandLayout(gameState, dependencies.config)
    end
end

function CoreGame.initializeRoundProgress(gameState)
    if not (gameState and gameState.currentRoundData and gameState.currentRoundData.goalType) then
        gameState.roundProgress = {}
        return
    end

    local goalType = gameState.currentRoundData.goalType
    print(string.format("[initializeRoundProgress] Goal: %s", tostring(goalType)))
    
    gameState.roundProgress = {}
    -- No complex tracking needed for score-only goals
end

function CoreGame.checkRoundGoalCompletion(gameState)
    if not (gameState and gameState.currentRoundData and gameState.currentRoundData.goalTarget ~= nil) or gameState.roundCompletionPending then
        return false
    end
    
    local goal, goalMet, currentProgress = gameState.currentRoundData, false, "N/A"
    
    if goal.goalType == "score_reached_total" then
        currentProgress = (gameState.score or 0)
        goalMet = currentProgress >= goal.goalTarget
    elseif goal.goalType == "score_earned_round" then
        currentProgress = (gameState.scoreEarnedThisRound or 0)
        goalMet = currentProgress >= goal.goalTarget
    end
    
    -- Only print when goal is met or when debugging is needed
    if goalMet then
        print(string.format("[GoalCheck] Type:%s, Target:%s, Current:%s -> Met:%s", tostring(goal.goalType), tostring(goal.goalTarget), tostring(currentProgress), tostring(goalMet)))
    end
    return goalMet
end

function CoreGame.updateRoundProgress(gameState, cardsUsedData, potionResult, dependencies)
    -- No complex progress tracking needed for score-only goals
    -- Score is now tracked in tryMakePotion function when creating potions
end

function CoreGame.tryMakePotion(gameState, config, dependencies)
    if not (gameState and config and dependencies and gameState.selectedCardIndices and gameState.hand and gameState.potentialPotionResult) or #gameState.selectedCardIndices == 0 or gameState.isWaitingForDiscard or gameState.gamePhase ~= "playing" then
        return
    end

    local makePotionCost = (config.Game and config.Game.makePotionEnergyCost) or 15
    if gameState.currentEnergy < makePotionCost then
        print(string.format("Not enough energy for potion. Need %d, Have %d", makePotionCost, gameState.currentEnergy))
        return
    end

    local potentialResult = gameState.potentialPotionResult
    if not potentialResult or potentialResult.name == "Nothing" or potentialResult.name == "None" then
        return
    end
    
    gameState.currentEnergy = gameState.currentEnergy - makePotionCost
    print(string.format("Making Potion: '%s'. Energy Used: %d. Remaining: %d", potentialResult.name, makePotionCost, gameState.currentEnergy))
    
    -- Award points for making the potion based on matching patterns
    local makingPoints = potentialResult.drinkPoints or 0  -- Use the calculated pattern points
    gameState.score = (gameState.score or 0) + makingPoints
    gameState.scoreEarnedThisRound = (gameState.scoreEarnedThisRound or 0) + makingPoints
    print(string.format("Earned %d points for making potion '%s'", makingPoints, potentialResult.name))
    
    gameState.pendingPotionChoice = CoreGame.shallowcopy(potentialResult)
    gameState.pendingPotionChoice.scoreFromCards = gameState.currentScore or 0
    gameState.pendingPotionChoice.usedCardIndices = CoreGame.shallowcopy(gameState.selectedCardIndices)
    
    local cardsUsedData = {}
    for _, hIdx in ipairs(gameState.selectedCardIndices) do
        local card = gameState.hand[hIdx]
        if card then
            table.insert(cardsUsedData, CoreGame.shallowcopy(card))
        end
    end
    
    if #cardsUsedData > 0 then
        CoreGame.updateRoundProgress(gameState, cardsUsedData, potentialResult, dependencies)
    end
    
    -- Start card-to-potion animation instead of immediately clearing selection
    if CoreGame.animateCardsToPotionBottle then
        CoreGame.animateCardsToPotionBottle(gameState, config, potentialResult, dependencies)
    else
        -- Fallback to old behavior if animation function doesn't exist
        gameState.selectedCardIndices = {}
        CoreGame.recalculateCurrentScore(gameState)
        CoreGame.updatePotentialPotion(gameState, dependencies)
        
        if CoreGame.animatePotionFill then
            CoreGame.animatePotionFill(gameState, config, potentialResult, dependencies)
        end
        
        gameState.gamePhase = "potion_decision"
        print("Phase: potion_decision")
        if dependencies.overlayManager then
            dependencies.overlayManager:show("potionDecision")
        end
    end
    
    local goalMet = CoreGame.checkRoundGoalCompletion(gameState)
    if goalMet then
        gameState.roundCompletionPending = true
        print("Round", gameState.currentRoundNumber, "COMPLETE!")
    end
    
    if gameState.currentEnergy <= 0 and not goalMet then
        print("Out of energy! Game Over.")
        gameState.gamePhase = "game_over"
        gameState.gameOverReason = "out_of_energy"
        if dependencies.overlayManager then
            dependencies.overlayManager:show("gameOver")
        end
    end
end

function CoreGame.drinkPotion(gameState, config, dependencies)
    if gameState.gamePhase ~= "potion_decision" or not gameState.pendingPotionChoice then
        return
    end

    local choice = gameState.pendingPotionChoice
    local effect = choice.drinkEffect
    
    print("Drinking Potion:", choice.name)
    
    -- NO points awarded for drinking - only benefits from effects
    print("Drinking potion provides benefits but no points")
    
    if effect.type == "add_score" then
        -- DISABLED: No longer award points for drinking potions
        local value = effect.value or 0
        print(string.format("Potion effect would have given %d points, but drinking provides no points", value))
    elseif effect.type == "add_money" then
        local value = effect.value or 0
        gameState.wallet = (gameState.wallet or 0) + value
        gameState.moneyEarnedThisRound = (gameState.moneyEarnedThisRound or 0) + value
        print(string.format("Potion effect granted %d money", value))
    elseif effect.type == "draw_card" then
        local value = effect.value or 0
        CoreGame.drawCards(gameState, config, dependencies, value)
        print(string.format("Potion effect drew %d cards", value))
    elseif effect.type == "upgrade_recipe" then
        local value = effect.value or 1
        CoreGame.upgradeRecipe(gameState, dependencies, value)
        print(string.format("Potion effect upgraded recipe by %d", value))
    elseif effect.type == "restore_energy" then
        local value = effect.value or 0
        gameState.currentEnergy = gameState.currentEnergy + value
        print(string.format("Restored %d energy from potion effect. New energy: %d", value, gameState.currentEnergy))
    end
    
    CoreGame.triggerDiscardAndRefill(gameState, config, choice.usedCardIndices)
    gameState.pendingPotionChoice = nil
    
    if dependencies.overlayManager then
        dependencies.overlayManager:hide()
    end
    
    local goalMet = CoreGame.checkRoundGoalCompletion(gameState)
    if not gameState.roundCompletionPending and goalMet then
        gameState.roundCompletionPending = true
    end
    
    -- Check if game should end due to energy or other conditions
    if gameState.currentEnergy <= 0 and not goalMet then
        print("Out of energy! Game Over.")
        gameState.gamePhase = "game_over"
        gameState.gameOverReason = "out_of_energy"
        if dependencies.overlayManager then
            dependencies.overlayManager:show("gameOver")
        end
    else
        -- Only set to playing if the game isn't ending
        gameState.gamePhase = "playing"
    end
end

function CoreGame.sellPotion(gameState, config, dependencies)
    if gameState.gamePhase ~= "potion_decision" or not gameState.pendingPotionChoice then
        return
    end

    local choice = gameState.pendingPotionChoice
    local saleMoney = choice.saleMoney or 0
    
    print("Selling Potion:", choice.name, "for $", saleMoney)
    gameState.wallet = (gameState.wallet or 0) + saleMoney
    gameState.moneyEarnedThisRound = (gameState.moneyEarnedThisRound or 0) + saleMoney
    
    -- NO points awarded for selling - only money
    print("Selling potion provides money but no points")
    
    CoreGame.triggerDiscardAndRefill(gameState, config, choice.usedCardIndices)
    gameState.pendingPotionChoice = nil
    
    if dependencies.overlayManager then
        dependencies.overlayManager:hide()
    end
    
    local goalMet = CoreGame.checkRoundGoalCompletion(gameState)
    if not gameState.roundCompletionPending and goalMet then
        gameState.roundCompletionPending = true
    end
    
    -- Check if game should end due to energy or other conditions
    if gameState.currentEnergy <= 0 and not goalMet then
        print("Out of energy! Game Over.")
        gameState.gamePhase = "game_over"
        gameState.gameOverReason = "out_of_energy"
        if dependencies.overlayManager then
            dependencies.overlayManager:show("gameOver")
        end
    else
        -- Only set to playing if the game isn't ending
        gameState.gamePhase = "playing"
    end
end

function CoreGame.upgradeRecipe(gameState, dependencies, upgradeValue)
    if not (gameState and gameState.pendingPotionChoice and upgradeValue and upgradeValue > 0) then
        print("CoreGame.upgradeRecipe: Invalid parameters")
        return
    end
    
    local choice = gameState.pendingPotionChoice
    local oldBaseScore = choice.baseScore or 0
    local oldBaseMoney = choice.baseMoney or 0
    
    -- Upgrade the recipe's base values
    choice.baseScore = oldBaseScore + upgradeValue
    choice.baseMoney = oldBaseMoney + math.floor(upgradeValue / 2) -- Money increases at half the rate of score
    
    -- Update the sale value to reflect the new base values
    choice.saleValue = choice.baseMoney + choice.bonusPoints
    
    print(string.format("Recipe upgraded! Base Score: %d -> %d, Base Money: %d -> %d", 
          oldBaseScore, choice.baseScore, oldBaseMoney, choice.baseMoney))
    
    -- Update the drink effect description to reflect the new power
    if choice.drinkEffect then
        choice.drinkEffect.description = string.format("Recipe upgraded! Now worth %d score and $%d", 
                                                      choice.baseScore, choice.baseMoney)
    end
end

function CoreGame.triggerDiscardAndRefill(gameState, config, cardIndices)
    if not (gameState and config and cardIndices and #cardIndices > 0 and gameState.hand) then
        return
    end

    local animConfig, screenConfig, cardConfig = config.Animation or {}, config.Screen or {}, config.Card or {}
    local numToDiscard = 0
    
    for _, hIdx in ipairs(CoreGame.shallowcopy(cardIndices)) do
        if hIdx and gameState.hand[hIdx] and not gameState.hand[hIdx].isDiscarding then
            local card = gameState.hand[hIdx]
            card.isDiscarding, card.isAnimating, card.animProgress, card.animDuration = true, true, 0, animConfig.discardDuration or 0.4
            card.startX, card.startY, card.startRotation, card.startScale = card.x, card.y, card.rotation or 0, card.scale or 1
            card.targetX, card.targetY = (screenConfig.width or 400)/2 - (cardConfig.width or 60)/2, (screenConfig.height or 600) + (cardConfig.height or 80)
            card.targetRotation, card.targetScale, card.isHighlighted = math.rad(math.random(-15,15)), 0.5, false
            numToDiscard = numToDiscard + 1
        end
    end

    if numToDiscard > 0 then
        gameState.isWaitingForDiscard = true
        gameState.discardAnimCounter = numToDiscard
        gameState.numReplacementsToDraw = numToDiscard
    end
end

function CoreGame.enterShopPhase(gameState, config, dependencies)
    if not (gameState and config and dependencies) then return end
    
    local uiConfig, cardDefs, bookDefs, elixirDefs = config.UI or {}, dependencies.cardDefinitions, dependencies.spellbookDefinitions, dependencies.energyElixirDefinitions
    print("Entering Shop Phase")
    gameState.gamePhase = "shop"
    gameState.currentShopItems = {}
    
    -- Reset refresh count for new shop phase
    gameState.shopRefreshCount = 0
    
    local numOffers, potentialOffers = uiConfig.shopOfferCount or 3, {}
    
    if cardDefs then
        for _, d in ipairs(cardDefs) do
            if d and d.data and d.data.cost then
                table.insert(potentialOffers, {itemType="card", data=d.data})
            end
        end
    end
    
    if bookDefs then
        for id, b in pairs(bookDefs) do
            if b and b.cost then
                -- Check if this spellbook contains any spells the player doesn't already know
                local hasNewSpells = false
                if b.spells and type(b.spells) == "table" then
                    for _, spellId in ipairs(b.spells) do
                        if not gameState.knownSpells[spellId] then
                            hasNewSpells = true
                            break
                        end
                    end
                end
                
                -- Only add spellbooks that contain at least one new spell
                if hasNewSpells then
                    local bc = CoreGame.shallowcopy(b)
                    bc.id = bc.id or id
                    table.insert(potentialOffers, {itemType="spellbook", data=bc})
                    print("Shop: Adding spellbook '" .. bc.name .. "' (contains new spells)")
                else
                    print("Shop: Skipping spellbook '" .. b.name .. "' (all spells already known)")
                end
            end
        end
    end
    
    if elixirDefs then
        for id, e in pairs(elixirDefs) do
            if e and e.cost then
                local ec = CoreGame.shallowcopy(e)
                ec.id = ec.id or id
                table.insert(potentialOffers, {itemType="energy_elixir", data=ec})
                print("Shop: Adding energy elixir '" .. ec.name .. "'")
            end
        end
    end
    
    if #potentialOffers == 0 then
        print("Shop: No items available for purchase (all spells learned, no cards available)")
        CoreGame.endShoppingPhase(gameState, dependencies)
        return
    end
    
    print("Shop: " .. #potentialOffers .. " items available for purchase")
    
    for i = #potentialOffers, 2, -1 do
        local j = math.random(i)
        potentialOffers[i], potentialOffers[j] = potentialOffers[j], potentialOffers[i]
    end
    
    for i = 1, math.min(#potentialOffers, numOffers) do
        local offer = potentialOffers[i]
        table.insert(gameState.currentShopItems, {itemType=offer.itemType, itemDef=offer.data, isPurchased=false})
    end
    
    if dependencies.overlayManager then
        dependencies.overlayManager:show("shop")
    end
end

function CoreGame.buyShopItem(gameState, dependencies, itemIndex)
    if not (gameState and dependencies and gameState.currentShopItems and gameState.currentShopItems[itemIndex]) then return end
    
    local offer = gameState.currentShopItems[itemIndex]
    local itemDef, itemType = offer.itemDef, offer.itemType
    
    if not itemDef or not itemType or offer.isPurchased or type(itemDef.cost) ~= 'number' or gameState.wallet < itemDef.cost then return end
    
    print("Purchasing:", itemDef.name)
    gameState.wallet = gameState.wallet - itemDef.cost
    offer.isPurchased = true
    
    if itemType == "card" then
        local newCard = CoreGame.createCardInstance(itemDef.id, itemDef.name, itemDef.value, itemDef.family, itemDef.subType, itemDef.description, itemDef.objectColor)
        if newCard then
            table.insert(gameState.discardPile, newCard)
        else
            gameState.wallet = gameState.wallet + itemDef.cost
            offer.isPurchased = false
        end
    elseif itemType == "spellbook" then
        local spellDefs = dependencies.spellDefinitions
        if not spellDefs then
            gameState.wallet = gameState.wallet + itemDef.cost
            offer.isPurchased = false
            return
        end
        if itemDef.spells and type(itemDef.spells) == "table" then
            for _, sId in ipairs(itemDef.spells) do
                if spellDefs[sId] and not gameState.knownSpells[sId] then
                    gameState.knownSpells[sId] = CoreGame.shallowcopy(spellDefs[sId])
                    if gameState.knownSpells[sId].uses then
                        gameState.knownSpells[sId].currentUses = gameState.knownSpells[sId].uses
                    end
                    print("Learned:", spellDefs[sId].name)
                end
            end
        end
    elseif itemType == "energy_elixir" then
        -- Add energy elixir to player's inventory
        if not gameState.energyElixirs then
            gameState.energyElixirs = {}
        end
        local elixirCopy = CoreGame.shallowcopy(itemDef)
        table.insert(gameState.energyElixirs, elixirCopy)
        print("Purchased energy elixir:", itemDef.name, "Energy restore:", itemDef.energyRestore)
    end
end

function CoreGame.consumeEnergyElixir(gameState, elixirIndex)
    if not (gameState and gameState.energyElixirs and gameState.energyElixirs[elixirIndex]) then 
        print("CoreGame.consumeEnergyElixir: Invalid elixir index or no elixirs available")
        return false 
    end
    
    local elixir = gameState.energyElixirs[elixirIndex]
    local energyRestore = elixir.energyRestore or 0
    
    if energyRestore > 0 then
        gameState.currentEnergy = gameState.currentEnergy + energyRestore
        table.remove(gameState.energyElixirs, elixirIndex)
        print(string.format("Consumed %s. Energy restored: %d. New energy: %d", elixir.name, energyRestore, gameState.currentEnergy))
        return true
    else
        print("CoreGame.consumeEnergyElixir: Elixir has no energy restore value")
        return false
    end
end

function CoreGame.refreshShop(gameState, dependencies)
    if not (gameState and dependencies) then return end
    if gameState.gamePhase ~= "shop" then print("Warn: refreshShop called outside shop.") end
    
    local baseRefreshCost = (dependencies.config and dependencies.config.Game and dependencies.config.Game.shopRefreshCost) or 5
    local refreshCount = gameState.shopRefreshCount or 0
    
    -- Calculate current refresh cost using logarithmic scaling
    local currentRefreshCost = baseRefreshCost
    if refreshCount > 0 then
        local multiplier = 1 + math.log(refreshCount + 1)
        currentRefreshCost = math.floor(baseRefreshCost * multiplier)
    end
    
    if gameState.wallet < currentRefreshCost then
        print("Not enough money to refresh shop. Need $", currentRefreshCost, "Have $", gameState.wallet)
        return
    end
    
    print("Refreshing shop for $", currentRefreshCost, "(refresh #", refreshCount + 1, ")")
    gameState.wallet = gameState.wallet - currentRefreshCost
    
    -- Increment refresh count
    gameState.shopRefreshCount = refreshCount + 1
    
    -- Clear current shop items and regenerate them
    gameState.currentShopItems = {}
    CoreGame.enterShopPhase(gameState, dependencies.config, dependencies)
end

function CoreGame.endShoppingPhase(gameState, dependencies)
    if not (gameState and dependencies) then return end
    if gameState.gamePhase ~= "shop" then print("Warn: endShoppingPhase called outside shop.") end
    print("Ending shop phase...")
    if dependencies.overlayManager then dependencies.overlayManager:hide() end
    CoreGame.startNextRound(gameState, dependencies.config, dependencies)
end

function CoreGame.generateRandomRoundGoal(gameState, config, dependencies)
    if not (gameState and config and dependencies) then
        gameState.currentRoundData = {round=gameState.currentRoundNumber, goalType="score_earned_round", goalTarget=10, description="Survive!"}
        return
    end

    local template = randomGoalTemplates[math.random(#randomGoalTemplates)]
    local newGoalData = {round=gameState.currentRoundNumber, goalType=template.goalType, goalSubtype=nil, goalTarget=0, description=""}
    local baseTarget = math.random(template.baseTargetMin, template.baseTargetMax)
    local endlessIter = gameState.currentRoundNumber - numPredefinedRounds
    newGoalData.goalTarget = math.floor(baseTarget + math.max(0, endlessIter - 1) * template.targetScaleFactor)
    newGoalData.goalTarget = math.max(1, newGoalData.goalTarget)

    if template.subtypes and #template.subtypes > 0 then
        newGoalData.goalSubtype = template.subtypes[math.random(#template.subtypes)]
    end

    if newGoalData.goalSubtype then
        newGoalData.description = string.format(template.descriptionFormat, newGoalData.goalTarget, newGoalData.goalSubtype)
    else
        newGoalData.description = string.format(template.descriptionFormat, newGoalData.goalTarget)
    end
    
    gameState.currentRoundData = newGoalData
    print(string.format("[generateRandomRoundGoal] For Round %d: %s", gameState.currentRoundNumber, newGoalData.description))
end

function CoreGame.startNextRound(gameState, config, dependencies)
    if not (gameState and config and dependencies) then return end
    
    local gameConfig = config.Game or {}
    gameState.currentRoundNumber = gameState.currentRoundNumber + 1
    print(string.format("[startNextRound] Advancing to Round %d", gameState.currentRoundNumber))
    
    -- Energy is no longer reset each round - it represents the day's total energy
    gameState.gameOverReason = nil
    print(string.format("    Energy remaining: %d for Round %d", gameState.currentEnergy, gameState.currentRoundNumber))
    
    if gameState.currentRoundNumber <= numPredefinedRounds then
        local predefinedRounds = dependencies.roundsData or RoundsData
        if predefinedRounds and gameState.currentRoundNumber <= #predefinedRounds then
            gameState.currentRoundData = CoreGame.shallowcopy(predefinedRounds[gameState.currentRoundNumber])
            print(string.format("Starting Predefined Round %d: Goal = %s", gameState.currentRoundNumber, gameState.currentRoundData.description or "N/A"))
        else
            CoreGame.generateRandomRoundGoal(gameState, config, dependencies)
        end
    else
        print(string.format("Round %d is endless mode.", gameState.currentRoundNumber))
        CoreGame.generateRandomRoundGoal(gameState, config, dependencies)
    end
    
    gameState.scoreEarnedThisRound = 0
    gameState.moneyEarnedThisRound = 0
    gameState.cardsPlayedThisRound = { family = {}, subType = {} }
    CoreGame.initializeRoundProgress(gameState)
    
    if gameState.hand and #gameState.hand > 0 then
        print("Adding hand to deck.")
        for i = #gameState.hand, 1, -1 do
            local card = table.remove(gameState.hand, i)
            if card then table.insert(gameState.deck, card) end
        end
    end
    
    gameState.selectedCardIndices = {}
    if gameState.discardPile and #gameState.discardPile > 0 then
        print("Adding discard to deck.")
        for i = #gameState.discardPile, 1, -1 do
            local card = table.remove(gameState.discardPile, i)
            if card then table.insert(gameState.deck, card) end
        end
    end
    
    CoreGame.shuffleDeck(gameState)
    print("Drawing fresh hand.")
    CoreGame.drawCards(gameState, config, dependencies, gameConfig.initialHandSize or 7)
    
    if CoreGame.recalculateCurrentScore then CoreGame.recalculateCurrentScore(gameState) end
    if CoreGame.updatePotentialPotion then CoreGame.updatePotentialPotion(gameState, dependencies) end
    if dependencies.sort and dependencies.sort.calculateHandLayout then dependencies.sort.calculateHandLayout(gameState, config) end
    
    gameState.gamePhase = "playing"
    if dependencies.overlayManager and dependencies.overlayManager:getActiveOverlayName() == "shop" then
        dependencies.overlayManager:hide()
    end
    
    print(string.format("Round %d started. Phase: playing. Goal: %s", gameState.currentRoundNumber, gameState.currentRoundData.description or "N/A"))
end

function CoreGame.animateCardsToPotionBottle(gameState, config, potionResult, dependencies)
    if not (gameState and config and gameState.selectedCardIndices and gameState.hand) then
        print("Warning: animateCardsToPotionBottle missing required parameters")
        return
    end
    
    local animConfig = config.Animation or {}
    local screenConfig = config.Screen or {}
    local uiConfig = config.UI or {}
    
    -- Calculate potion bottle center position
    local bottleX = (screenConfig.width or 400) / 2
    local bottleY = (screenConfig.height or 600) * 0.4 -- Upper portion of screen
    
    print(string.format("Starting card-to-potion animation for %d cards", #gameState.selectedCardIndices))
    
    -- Set up animation state for each selected card
    local numAnimatingCards = 0
    for i = #gameState.selectedCardIndices, 1, -1 do
        local handIndex = gameState.selectedCardIndices[i]
        if handIndex and gameState.hand[handIndex] then
            local card = gameState.hand[handIndex]
            
            -- Mark card as animating to potion
            card.isAnimatingToPotion = true
            card.isAnimating = true
            card.animProgress = 0
            card.animDuration = animConfig.cardToPotionDuration or 0.8
            
            -- Store starting position
            card.startX = card.x
            card.startY = card.y
            card.startRotation = card.rotation or 0
            card.startScale = card.scale or 1
            
            -- Set target position (potion bottle with slight randomness)
            local offsetX = math.random(-20, 20)
            local offsetY = math.random(-15, 15)
            card.targetX = bottleX + offsetX
            card.targetY = bottleY + offsetY
            card.targetRotation = math.rad(math.random(-45, 45))
            card.targetScale = 0.2 -- Shrink as they go into potion
            
            -- Add magical trail effect data
            card.magicalTrail = {
                particles = {},
                lastSpawnTime = 0,
                spawnRate = 0.05, -- Spawn particle every 0.05 seconds
                color = card.objectColor or {1, 1, 1}
            }
            
            card.isHighlighted = false
            numAnimatingCards = numAnimatingCards + 1
        end
    end
    
    -- Set up potion animation state
    gameState.potionAnimationState = {
        isAnimatingCardsToPotionBottle = true,
        cardsAnimatingCount = numAnimatingCards,
        totalAnimationTime = animConfig.cardToPotionDuration or 0.8,
        potionResult = potionResult,
        dependencies = dependencies
    }
    
    print(string.format("Card-to-potion animation started for %d cards", numAnimatingCards))
end

function CoreGame.animatePotionFill(gameState, config, potionResult, dependencies)
    if not (gameState and gameState.potionDisplay and potionResult and type(potionResult) == "table") then
        if gameState and gameState.potionDisplay then
            gameState.potionDisplay.showPotion = false
            gameState.potionDisplay.isAnimatingFill = false
        end
        return
    end

    local shallow = dependencies and dependencies.shallowcopy or CoreGame.shallowcopy
    local displayInfo = potionResult.display or {}
    local bottleType = displayInfo.bottle or "default"
    local fillColor = displayInfo.color or {0.5, 0.5, 0.5}
    local inspectF = dependencies and dependencies.inspect or function() return "{inspect_unavailable}" end
    
    print("Animating potion fill:", potionResult.name or "Unknown", "Bottle:", bottleType, "Color:", inspectF(fillColor))
    
    local pd = gameState.potionDisplay
    pd.showPotion = true
    pd.bottleType = bottleType
    pd.fillColor = shallow(fillColor)
    pd.fillLevel = 0.0
    pd.targetFillLevel = 1.0
    pd.isAnimatingFill = true
    pd.animProgress = 0
    pd.bubbles = {}
    pd.bubblesSpawned = false
    pd.isBubbling = false
    
    -- Enhanced magical effects for potion filling
    pd.magicalEffects = {
        swirls = {},
        sparkles = {},
        glowPulse = 0,
        colorShift = 0,
        lastSparkleTime = 0,
        lastSwirlTime = 0
    }
    
    -- Create initial swirl patterns
    for i = 1, 3 do
        local swirl = {
            angle = math.random() * math.pi * 2,
            radius = 10 + math.random() * 15,
            speed = 2 + math.random() * 3,
            life = 1.0,
            maxLife = 1.0,
            direction = (i % 2 == 0) and 1 or -1, -- Alternate clockwise/counterclockwise
            color = {fillColor[1], fillColor[2], fillColor[3], 0.7}
        }
        table.insert(pd.magicalEffects.swirls, swirl)
    end
    
    print("Enhanced potion fill animation started with magical effects")
end

function CoreGame.applySpellEffect(gameState, dependencies, spellId, targetData)
    if not (gameState and dependencies and gameState.knownSpells and spellId) then return false end
    
    local spell = gameState.knownSpells[spellId]
    if not spell then return false end
    if not spell.effect or type(spell.effect) ~= "function" then return false end
    
    local canCastUses = true
    if spell.uses and spell.uses > 0 then
        if not spell.currentUses or spell.currentUses <= 0 then
            canCastUses = false
        end
    end
    if not canCastUses then
        gameState.selectedSpellId, gameState.selectingSpellTarget = nil, false
        return false
    end
    
    local spellEnergyCost = spell.energyCost or 0
    if gameState.currentEnergy < spellEnergyCost then
        print("Not enough energy for spell")
        gameState.selectedSpellId, gameState.selectingSpellTarget = nil, false
        return false
    end
    
    print("Casting spell:", spell.name)
    gameState.currentEnergy = gameState.currentEnergy - spellEnergyCost
    print("Energy used:", spellEnergyCost, "Remaining:", gameState.currentEnergy)
    
    local success = spell.effect(gameState, dependencies, targetData or {})
    if success then
        if spell.uses and spell.uses > 0 then
            spell.currentUses = spell.currentUses - 1
        end
        if CoreGame.recalculateCurrentScore then CoreGame.recalculateCurrentScore(gameState) end
        if CoreGame.updatePotentialPotion then CoreGame.updatePotentialPotion(gameState, dependencies) end
        if dependencies.sort.calculateHandLayout then dependencies.sort.calculateHandLayout(gameState, dependencies.config) end
    end
    
    gameState.selectedSpellId, gameState.selectingSpellTarget = nil, false
    
    local goalMet = CoreGame.checkRoundGoalCompletion(gameState)
    if gameState.currentEnergy <= 0 and not goalMet then
        print("Out of energy! Game Over.")
        gameState.gamePhase = "game_over"
        gameState.gameOverReason = "out_of_energy"
        if dependencies.overlayManager then
            dependencies.overlayManager:show("gameOver")
        end
    end
    
    return success
end

function CoreGame.checkStalemate(gameState, dependencies)
    if not (gameState and dependencies and dependencies.handlers and dependencies.handlers.isButtonEnabled) or gameState.gamePhase ~= "playing" then
        return false
    end
    
    local canMake = dependencies.handlers.isButtonEnabled("makePotion", gameState, dependencies)
    local canDiscard = dependencies.handlers.isButtonEnabled("discard", gameState, dependencies)
    local deckEmpty = (#(gameState.deck or {}) == 0)
    local discardEmpty = (#(gameState.discardPile or {}) == 0)
    
    -- Check for out of energy condition (can't make potions)
    local goalMet = CoreGame.checkRoundGoalCompletion(gameState)
    local config = dependencies.config
    local makePotionCost = (config and config.Game and config.Game.makePotionEnergyCost) or 15
    
    if gameState.currentEnergy < makePotionCost and not goalMet then
        print(string.format("[Out of Energy Detected] Energy: %d, Cost: %d", gameState.currentEnergy, makePotionCost))
        return "out_of_energy"
    end
    
    if not canMake and not canDiscard and deckEmpty and discardEmpty then
        print("[Stalemate Detected]")
        return "stalemate"
    end
    
    return false
end

function CoreGame.getGoalProgressString(goalData, currentGameState)
    if not (goalData and goalData.goalType and goalData.goalTarget ~= nil and currentGameState) then
        return "Progress: N/A"
    end
    
    local goalType, target = goalData.goalType, goalData.goalTarget
    local progressString, currentProgress = "Progress: Unknown", 0
    
    if goalType == "score_reached_total" then
        currentProgress = currentGameState.score or 0
        progressString = string.format("Total Score: %d/%d", currentProgress, target)
    elseif goalType == "score_earned_round" then
        currentProgress = currentGameState.scoreEarnedThisRound or 0
        progressString = string.format("Score This Round: %d/%d", currentProgress, target)
    else
        progressString = "Goal: " .. tostring(goalData.description)
    end
    
    return progressString
end

function CoreGame.resetGame(gameState, config, dependencies)
    if not (gameState and config and dependencies) then return end
    local cardDefs, spellDefs, baseRoundsData = dependencies.cardDefinitions, dependencies.spellDefinitions, dependencies.roundsData
    local shallowCopyFunc = dependencies.shallowcopy or CoreGame.shallowcopy
    if not cardDefs or not baseRoundsData then print("ERROR: Missing critical data for resetGame."); return end
    
    print("[resetGame] Resetting Game State...")
    gameState.deck = {}
    gameState.discardPile = {}
    gameState.hand = {}
    gameState.selectedCardIndices = {}
    gameState.currentShopItems = {}
    gameState.knownSpells = {}
    gameState.activeSpellEffects = {}
    gameState.score, gameState.wallet, gameState.currentScore, gameState.currentRoundNumber = 0, 0, 0, 0
    gameState.moneyEarnedThisRound, gameState.scoreEarnedThisRound = 0, 0
    gameState.cardsPlayedThisRound = { family = {}, subType = {} }
    gameState.currentEnergy = (config.Game and config.Game.energyPerRound) or 100
    gameState.gameOverReason = nil
    gameState.potentialPotionResult = { name="Nothing", recipeIndex=nil, baseMoney=0, bonusPoints=0, bonusMoney=0, requirementsDesc="", bonusPointsDesc="", bonusMoneyDesc="", display=nil, saleValue=0, drinkEffect=nil }
    gameState.pendingPotionChoice = nil
    gameState.selectedSpellId = nil
    gameState.selectingSpellTarget = false
    gameState.drag = {isDragging=false, cardIndex=nil, offsetX=0, offsetY=0}
    gameState.activeOverlay = nil
    gameState.deckViewMode = "remaining"
    gameState.gamePhase = "loading"
    gameState.roundCompletionPending = false
    gameState.canDiscard = true
    gameState.isWaitingForDiscard = false
    gameState.discardAnimCounter = 0
    gameState.numReplacementsToDraw = 0
    gameState.potionDisplay = { showPotion=false, fillLevel=0.0, targetFillLevel=0.0, fillColor={0.5,0.5,0.5}, bottleType="default", bubbles={}, isBubbling=false, bubblesSpawned=false, isAnimatingFill=false, animProgress=0 }
    gameState.energyElixirs = {}
    
    if spellDefs then
        local startId="transmute_value"
        if spellDefs[startId] then 
            gameState.knownSpells[startId] = shallowCopyFunc(spellDefs[startId])
            if gameState.knownSpells[startId].uses and gameState.knownSpells[startId].uses > 0 then
                gameState.knownSpells[startId].currentUses = gameState.knownSpells[startId].uses
            end
            print("Added starting spell:", gameState.knownSpells[startId].name)
        end
    end

    print("Populating deck for new game...")
    local added, dX, dY = 0, (config.Animation and config.Animation.deckDrawX) or 0, (config.Animation and config.Animation.deckDrawY) or 0
    for _, defEntry in ipairs(cardDefs) do 
        if defEntry and type(defEntry)=='table' and defEntry.data and type(defEntry.data)=='table' then 
            local cd,ct = defEntry.data, defEntry.count
            if cd.id and type(ct)=='number' and ct>0 then 
                for _=1,ct do 
                    local inst=CoreGame.createCardInstance(cd.id,cd.name,cd.value,cd.family,cd.subType,cd.description,cd.objectColor)
                    if inst and type(inst)=='table' then
                        inst.x, inst.y, inst.targetX, inst.targetY = dX, dY, dX, dY
                        table.insert(gameState.deck,inst)
                        added = added + 1
                    end 
                end 
            end 
        end 
    end
    print("Added", added, "cards to deck. Deck size:", #gameState.deck)
    CoreGame.shuffleDeck(gameState)
    print("Deck shuffled. Final count:", #gameState.deck)
    
    CoreGame.startNextRound(gameState, config, dependencies) 
    print("Deck and Game State reset complete.")
end

-- =============================================================================
-- Final Return Statement
-- =============================================================================

-- Add the data tables directly to the CoreGame table to be exported
CoreGame.cardDefinitions = cardDefinitions
CoreGame.PotionCombinationEffects = PotionCombinationEffects
CoreGame.RoundsData = RoundsData
CoreGame.SpellDefinitions = SpellDefinitions
CoreGame.SpellbookDefinitions = SpellbookDefinitions
CoreGame.EnergyElixirDefinitions = EnergyElixirDefinitions

return CoreGame