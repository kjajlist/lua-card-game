-- File: core_game.lua (Final, Maximally Expanded Formatting)
-- Contains core game data definitions and all core game logic functions.

local CoreGame = {}

-- =============================================================================
-- DATA DEFINITIONS
-- =============================================================================

-- Card definitions: { data = { card properties }, count = number_in_deck }
local cardDefinitions = {
    -- Plants
    {
        data = { id = 1, name = "Rose", value = 7, family = "Plant", subType = "Flower", description = "A classic beauty.", objectColor = { 1, 0, 0 }, cost = 5 },
        count = 3
    },
    {
        data = { id = 2, name = "Tulip", value = 2, family = "Plant", subType = "Flower", description = "Comes in many colors.", objectColor = { 1, 1, 0 }, cost = 2 },
        count = 5
    },
    {
        data = { id = 3, name = "Daisy", value = 3, family = "Plant", subType = "Flower", description = "Simple and cheerful.", objectColor = { 1, 1, 1 }, cost = 2 },
        count = 4
    },
    {
        data = { id = 4, name = "Sunflower", value = 9, family = "Plant", subType = "Flower", description = "Tall and bright.", objectColor = { 1, 0.5, 0 }, cost = 7 },
        count = 2
    },
    {
        data = { id = 5, name = "Lavender", value = 6, family = "Plant", subType = "Herb", description = "Known for its scent.", objectColor = { 0.5, 0, 0.5 }, cost = 4 },
        count = 3
    },
    {
        data = { id = 6, name = "Orchid", value = 8, family = "Plant", subType = "Flower", description = "Elegant and exotic.", objectColor = { 0.8, 0.2, 0.8 }, cost = 8 },
        count = 1
    },
    {
        data = { id = 7, name = "Poppy", value = 4, family = "Plant", subType = "Flower", description = "Often red.", objectColor = { 1, 0, 0 }, cost = 3 },
        count = 4
    },
    {
        data = { id = 8, name = "Lily", value = 7, family = "Plant", subType = "Flower", description = "Fragrant and stately.", objectColor = { 1, 1, 1 }, cost = 5 },
        count = 2
    },
    {
        data = { id = 9, name = "Carnation", value = 4, family = "Plant", subType = "Flower", description = "Popular for bouquets.", objectColor = { 1, 0, 0 }, cost = 3 },
        count = 3
    },
    {
        data = { id = 10, name = "Marigold", value = 2, family = "Plant", subType = "Flower", description = "Easy to grow.", objectColor = { 1, 0.5, 0 }, cost = 2 },
        count = 5
    },
    {
        data = { id = 16, name = "Sage", value = 5, family = "Plant", subType = "Herb", description = "Aromatic.", objectColor = { 0.7, 0.8, 0.7 }, cost = 4 },
        count = 3
    },
    {
        data = { id = 17, name = "Mint", value = 3, family = "Plant", subType = "Herb", description = "Refreshing.", objectColor = { 0.4, 0.9, 0.4 }, cost = 3 },
        count = 4
    },
    -- Magic
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
}

-- Potion definitions based on card patterns
local PotionCombinationEffects = {
    sets = {
        [2] = { name = "Double",     baseScore = 2,  baseMoney = 1 },
        [3] = { name = "Triple",     baseScore = 5,  baseMoney = 3 },
        [4] = { name = "Quad",       baseScore = 15, baseMoney = 8 },
        [5] = { name = "Quint",      baseScore = 30, baseMoney = 20 },
        [6] = { name = "Hexa",       baseScore = 50, baseMoney = 35 },
        [7] = { name = "Septa",      baseScore = 100,baseMoney = 60 },
    },
    multi_set = {
        ["2_2"] = { name = "Twin Doubles", baseScore = 5,  baseMoney = 3 },
        ["3_2"] = { name = "Full House",   baseScore = 20, baseMoney = 12 },
        ["3_3"] = { name = "Twin Triples", baseScore = 40, baseMoney = 25 },
        ["4_2"] = { name = "Major House",  baseScore = 50, baseMoney = 30 },
    },
    flushes = {
        family = { 
            name = "Family Concoction", baseScore = 8, baseMoney = 5, 
            drinkEffect = { type="draw_card", value=1, description="Instantly draw 1 card!" }
        },
        subType = { 
            name = "Pure Essence", baseScore = 20, baseMoney = 12,
            drinkEffect = { type="add_money", value=10, description="Instantly gain $10!" }
        },
        color = { 
            name = "Monochromatic Draught", baseScore = 15, baseMoney = 8,
            drinkEffect = { type="add_score", value=10, description="Instantly gain 10 Score!" }
        }
    },
    default = {
        name = "Murky Mixture", 
        baseScore = 0, 
        baseMoney = 1,
        bonusPoints = 0,
        drinkEffect = { type="none", description="No effect." }
    }
}

-- Curated goals for the first 10 rounds
local RoundsData = {
    { round = 1, goalType = "score_earned_round", goalTarget = 20, description = "Earn 20 Score This Round" },
    { round = 2, goalType = "potions_made", goalTarget = 2, goalSubtype = "Plant", description = "Make 2 Plant Potions" },
    { round = 3, goalType = "money_earned_round", goalTarget = 30, description = "Earn $30 This Round" },
    { round = 4, goalType = "cards_played_type", goalTarget = 3, goalSubtype = "Magic", description = "Use 3 Magic Cards in Potions" },
    { round = 5, goalType = "score_reached_total", goalTarget = 100, description = "Reach a Total Score of 100" },
    { round = 6, goalType = "potions_made", goalTarget = 2, goalSubtype = "Magic", description = "Brew 2 Arcane Potions" },
    { round = 7, goalType = "cards_played_type", goalTarget = 5, goalSubtype = "Plant", description = "Utilize 5 Plant Cards in Potions" },
    { round = 8, goalType = "money_earned_round", goalTarget = 50, description = "Prosper: Earn $50 This Round" },
    { round = 9, goalType = "potions_made", goalTarget = 1, goalSubtype = "Mixed", description = "Craft 1 'Mixed' Potion" },
    { round = 10, goalType = "score_reached_total", goalTarget = 250, description = "Grand Alchemist: Reach 250 Total Score" }
}

local numPredefinedRounds = #RoundsData

-- Templates for generating random goals in endless mode
local randomGoalTemplates = {
    { 
        goalType = "score_earned_round", 
        baseTargetMin = 25, baseTargetMax = 60, 
        targetScaleFactor = 2.5, 
        descriptionFormat = "Earn %d Score This Round" 
    },
    { 
        goalType = "potions_made", 
        baseTargetMin = 1, baseTargetMax = 3, 
        targetScaleFactor = 0.2, 
        subtypes = {"Plant", "Magic", "Mixed"}, 
        descriptionFormat = "Brew %d %s Potions" 
    },
    { 
        goalType = "money_earned_round", 
        baseTargetMin = 30, baseTargetMax = 70, 
        targetScaleFactor = 3.5, 
        descriptionFormat = "Amass $%d This Round" 
    },
    { 
        goalType = "cards_played_type", 
        baseTargetMin = 3, baseTargetMax = 6, 
        targetScaleFactor = 0.4, 
        subtypes = {"Plant", "Magic", "Flower", "Herb", "Elemental", "Dust"},
        descriptionFormat = "Utilize %d %s Cards" 
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
        totalCards = #selectedCards, countsById = {}, countsByFamily = {},
        countsBySubType = {}, countsByColor = {}, sets = {}, highestCardValue = 0,
        dominantFamily = nil, dominantSubType = nil, dominantColor = nil
    }
    if analysis.totalCards == 0 then
        return analysis
    end

    for _, card in ipairs(selectedCards) do
        analysis.countsById[card.id] = (analysis.countsById[card.id] or 0) + 1
        analysis.countsByFamily[card.family] = (analysis.countsByFamily[card.family] or 0) + 1
        if card.subType then
            analysis.countsBySubType[card.subType] = (analysis.countsBySubType[card.subType] or 0) + 1
        end
        local colorGroup = CoreGame.getCardColorGroupName(card)
        analysis.countsByColor[colorGroup] = (analysis.countsByColor[colorGroup] or 0) + 1
        analysis.highestCardValue = math.max(analysis.highestCardValue, card.value)
    end

    for _, count in pairs(analysis.countsById) do
        if count >= 2 then
            analysis.sets[count] = (analysis.sets[count] or 0) + 1
        end
    end

    if #selectedCards > 1 then
        for family, count in pairs(analysis.countsByFamily) do
            if count == analysis.totalCards then
                analysis.dominantFamily = family
                break
            end
        end
        for subType, count in pairs(analysis.countsBySubType) do
            if count == analysis.totalCards then
                analysis.dominantSubType = subType
                break
            end
        end
        for color, count in pairs(analysis.countsByColor) do
            if count == analysis.totalCards then
                analysis.dominantColor = color
                break
            end
        end
    end

    return analysis
end

function CoreGame.determinePotionResult(selectedCards, dependencies)
    local result = CoreGame.shallowcopy(PotionCombinationEffects.default)
    result.recipeIndex = nil
    
    if not selectedCards or #selectedCards == 0 then
        result.name = "Nothing"
        return result
    end
    
    local analysis = CoreGame.analyzeHand(selectedCards, dependencies)
    local handRankFound = nil
    local rankedChecks = { "subTypeFlush", "familyFlush", "colorFlush", "multiSet", "singleSet" }

    for _, checkType in ipairs(rankedChecks) do
        if checkType == "subTypeFlush" and analysis.dominantSubType then
            handRankFound = PotionCombinationEffects.flushes.subType
            result.name = string.format("Pure %s Essence", analysis.dominantSubType)
            result.requirementsDesc = string.format("%d-Card %s Flush", analysis.totalCards, analysis.dominantSubType)
            break
        elseif checkType == "familyFlush" and analysis.dominantFamily then
            handRankFound = PotionCombinationEffects.flushes.family
            result.name = string.format("%d-Card %s Concoction", analysis.totalCards, analysis.dominantFamily)
            result.requirementsDesc = result.name
            break
        elseif checkType == "colorFlush" and analysis.dominantColor then
            handRankFound = PotionCombinationEffects.flushes.color
            result.name = string.format("%s Monochromatic Draught", analysis.dominantColor)
            result.requirementsDesc = string.format("%d-Card %s Flush", analysis.totalCards, analysis.dominantColor)
            break
        elseif checkType == "multiSet" then
            local setCounts = {}
            for size, num in pairs(analysis.sets) do 
                for i=1, num do
                    table.insert(setCounts, size)
                end 
            end
            if #setCounts > 1 then
                table.sort(setCounts, function(a,b) return a > b end)
                local setKey = table.concat(setCounts, "_")
                if PotionCombinationEffects.multi_set[setKey] then
                    handRankFound = PotionCombinationEffects.multi_set[setKey]
                    result.name = handRankFound.name
                    result.requirementsDesc = handRankFound.name
                    break
                end
            end
        elseif checkType == "singleSet" then
            local largestSetSize = 0
            if analysis.sets and next(analysis.sets) then
                for size in pairs(analysis.sets) do
                    if size > largestSetSize then
                        largestSetSize = size
                    end
                end
            end
            if largestSetSize > 0 then
                handRankFound = PotionCombinationEffects.sets[largestSetSize]
                result.name = string.format("%s Infusion", handRankFound.name)
                result.requirementsDesc = string.format("%s of a Kind", handRankFound.name)
                break
            end
        end
    end

    if handRankFound then
        result.baseMoney = (handRankFound.baseMoney or 0)
        result.bonusPoints = (handRankFound.baseScore or 0) 
        result.drinkEffect = CoreGame.shallowcopy(handRankFound.drinkEffect or result.drinkEffect)
        
        local cardValueSum = 0
        for _,c in ipairs(selectedCards) do
            cardValueSum = cardValueSum + c.value
        end
        result.bonusPoints = result.bonusPoints + math.floor(cardValueSum / 2)
    else
        result.requirementsDesc = "No combination found"
    end
    
    result.saleValue = result.baseMoney + result.bonusPoints 
    local colorsForAvg = {}
    for _,c in ipairs(selectedCards) do
        table.insert(colorsForAvg, c.objectColor)
    end
    result.display = { bottle = "standard", color = CoreGame.calculateAverageColor(colorsForAvg) }

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
    local numToDraw = numCards or gameConfig.initialHandSize or 7
    
    print(string.format("[drawCards] Attempting to draw %d cards. Deck size before: %d", numToDraw, #gameState.deck))
    
    local drawnCount, deck, discardPile, hand = 0, gameState.deck, gameState.discardPile, gameState.hand
    
    for i = 1, numToDraw do
        if #deck == 0 then
            if discardPile and #discardPile > 0 then
                print("[drawCards] Deck empty. Reshuffling discard pile...")
                local deckDrawX = animConfig.deckDrawX or screenConfig.width
                local deckDrawY = animConfig.deckDrawY or 10
                for j = #discardPile, 1, -1 do 
                    local card = table.remove(discardPile, j)
                    if card then 
                        card.isHighlighted = false
                        card.isAnimating = false
                        card.isDiscarding = false
                        card.x, card.y, card.rotation, card.scale = deckDrawX, deckDrawY, 0, 1
                        card.targetX, card.targetY, card.targetRotation, card.targetScale = card.x, card.y, 0, 1 
                        table.insert(deck, card) 
                    end 
                end
                CoreGame.shuffleDeck(gameState)
                print("[drawCards] Discard pile reshuffled. New deck size:", #deck)
            else
                print("[drawCards] Deck and discard are empty. Cannot draw more cards.")
                break
            end
        end

        if #deck > 0 then
            local drawnCard = table.remove(deck, 1)
            if drawnCard and type(drawnCard) == "table" then 
                drawnCard.isHighlighted = false
                drawnCard.isAnimating = true
                drawnCard.isDiscarding = false
                drawnCard.animProgress = 0
                drawnCard.animDuration = animConfig.dealDuration or 0.3
                drawnCard.startX = drawnCard.x
                drawnCard.startY = drawnCard.y
                drawnCard.startRotation = drawnCard.rotation or 0
                drawnCard.startScale = drawnCard.scale or 0.5
                table.insert(hand, drawnCard)
                drawnCount = drawnCount + 1
            else
                print("Warning: Invalid item drawn from deck (expected card table).")
            end
        end
    end
    
    print(string.format("[drawCards] Drew %d cards. Deck size after: %d, Hand size: %d", drawnCount, #deck, #hand))
    if dependencies.sort and dependencies.sort.calculateHandLayout then dependencies.sort.calculateHandLayout(gameState, config) end
    if CoreGame.recalculateCurrentScore then CoreGame.recalculateCurrentScore(gameState) end
    if CoreGame.updatePotentialPotion then CoreGame.updatePotentialPotion(gameState, dependencies) end
end

function CoreGame.drawReplacements(gameState, config, dependencies, numToDraw)
    if numToDraw and numToDraw > 0 then
        print("Drawing "..numToDraw.." replacement cards.")
        CoreGame.drawCards(gameState, config, dependencies, numToDraw) 
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

    local goalType, goalSubtype = gameState.currentRoundData.goalType, gameState.currentRoundData.goalSubtype
    print(string.format("[initializeRoundProgress] Goal: %s, Subtype: %s", tostring(goalType), tostring(goalSubtype)))
    
    gameState.roundProgress = {}
    
    if goalType == "potions_made" then
        gameState.roundProgress.potions_made = { Plant = 0, Magic = 0, Mixed = 0 }
        if goalSubtype and not gameState.roundProgress.potions_made[goalSubtype] then
            gameState.roundProgress.potions_made[goalSubtype] = 0
        end
    elseif goalType == "cards_played_type" then
        if not gameState.cardsPlayedThisRound or type(gameState.cardsPlayedThisRound.family) ~= "table" then
            gameState.cardsPlayedThisRound = { family = {}, subType = {} }
        end
        local familiesToInit = {"Plant", "Magic", "Flower", "Herb", "Elemental", "Dust"}
        if goalSubtype and not table.concat(familiesToInit,','):match(goalSubtype) then
            table.insert(familiesToInit, goalSubtype)
        end
        for _, key in ipairs(familiesToInit) do
            gameState.cardsPlayedThisRound.family[key] = gameState.cardsPlayedThisRound.family[key] or 0
        end
    end
end

function CoreGame.checkRoundGoalCompletion(gameState)
    if not (gameState and gameState.currentRoundData and gameState.currentRoundData.goalTarget ~= nil) or gameState.roundCompletionPending then
        return false
    end
    
    local goal, goalMet, currentProgress = gameState.currentRoundData, false, "N/A"
    
    if goal.goalType == "potions_made" then
        local subType = goal.goalSubtype
        if subType and gameState.roundProgress and gameState.roundProgress.potions_made and gameState.roundProgress.potions_made[subType] ~= nil then
            currentProgress = gameState.roundProgress.potions_made[subType]
            goalMet = currentProgress >= goal.goalTarget
        end
    elseif goal.goalType == "money_earned_round" then
        currentProgress = (gameState.moneyEarnedThisRound or 0)
        goalMet = currentProgress >= goal.goalTarget
    elseif goal.goalType == "score_reached_total" then
        currentProgress = (gameState.score or 0)
        goalMet = currentProgress >= goal.goalTarget
    elseif goal.goalType == "cards_played_type" then
        local subType = goal.goalSubtype
        if subType and gameState.cardsPlayedThisRound and gameState.cardsPlayedThisRound.family and gameState.cardsPlayedThisRound.family[subType] ~= nil then
            currentProgress = gameState.cardsPlayedThisRound.family[subType]
            goalMet = currentProgress >= goal.goalTarget
        end
    elseif goal.goalType == "score_earned_round" then
        currentProgress = (gameState.scoreEarnedThisRound or 0)
        goalMet = currentProgress >= goal.goalTarget
    end
    
    print(string.format("[GoalCheck] Type:%s, Subtype:%s, Target:%s, Current:%s -> Met:%s", tostring(goal.goalType), tostring(goal.goalSubtype), tostring(goal.goalTarget), tostring(currentProgress), tostring(goalMet)))
    return goalMet
end

function CoreGame.updateRoundProgress(gameState, cardsUsedData, potionResult, dependencies)
    if not (gameState and gameState.currentRoundData and gameState.roundProgress and dependencies) then
        return
    end
    
    local goalType = gameState.currentRoundData.goalType
    
    if goalType == "cards_played_type" and cardsUsedData then
        for _, card in ipairs(cardsUsedData) do
            if card and card.family then
                gameState.cardsPlayedThisRound.family[card.family] = (gameState.cardsPlayedThisRound.family[card.family] or 0) + 1
            end
            if card and card.subType then
                if not gameState.cardsPlayedThisRound.subType then
                    gameState.cardsPlayedThisRound.subType = {}
                end
                gameState.cardsPlayedThisRound.subType[card.subType] = (gameState.cardsPlayedThisRound.subType[card.subType] or 0) + 1
            end
        end
    end
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
            dependencies.overlayManager:hide()
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
    local scoreFromCards = choice.scoreFromCards or 0
    
    print("Drinking Potion:", choice.name)
    gameState.score = (gameState.score or 0) + scoreFromCards
    gameState.scoreEarnedThisRound = (gameState.scoreEarnedThisRound or 0) + scoreFromCards
    
    if effect.type == "add_score" then
        local value = effect.value or 0
        gameState.score = gameState.score + value
        gameState.scoreEarnedThisRound = gameState.scoreEarnedThisRound + value
    elseif effect.type == "add_money" then
        local value = effect.value or 0
        gameState.wallet = (gameState.wallet or 0) + value
        gameState.moneyEarnedThisRound = (gameState.moneyEarnedThisRound or 0) + value
    elseif effect.type == "draw_card" then
        local value = effect.value or 0
        CoreGame.drawCards(gameState, config, dependencies, value)
    end
    
    CoreGame.triggerDiscardAndRefill(gameState, config, choice.usedCardIndices)
    gameState.pendingPotionChoice = nil
    gameState.gamePhase = "playing"
    
    if dependencies.overlayManager then
        dependencies.overlayManager:hide()
    end
    
    local goalMet = CoreGame.checkRoundGoalCompletion(gameState)
    if not gameState.roundCompletionPending and goalMet then
        gameState.roundCompletionPending = true
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

function CoreGame.sellPotion(gameState, config, dependencies)
    if gameState.gamePhase ~= "potion_decision" or not gameState.pendingPotionChoice then
        return
    end

    local choice = gameState.pendingPotionChoice
    local value = choice.saleValue or 0
    local score = choice.scoreFromCards or 0
    
    print("Selling Potion:", choice.name, "for $", value)
    gameState.wallet = (gameState.wallet or 0) + value
    gameState.moneyEarnedThisRound = (gameState.moneyEarnedThisRound or 0) + value
    
    gameState.score = (gameState.score or 0) + score
    gameState.scoreEarnedThisRound = (gameState.scoreEarnedThisRound or 0) + score
    
    CoreGame.triggerDiscardAndRefill(gameState, config, choice.usedCardIndices)
    gameState.pendingPotionChoice = nil
    gameState.gamePhase = "playing"
    
    if dependencies.overlayManager then
        dependencies.overlayManager:hide()
    end
    
    local goalMet = CoreGame.checkRoundGoalCompletion(gameState)
    if not gameState.roundCompletionPending and goalMet then
        gameState.roundCompletionPending = true
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
    
    local uiConfig, cardDefs, bookDefs = config.UI or {}, dependencies.cardDefinitions, dependencies.spellbookDefinitions
    print("Entering Shop Phase")
    gameState.gamePhase = "shop"
    gameState.currentShopItems = {}
    
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
                local bc = CoreGame.shallowcopy(b)
                bc.id = bc.id or id
                table.insert(potentialOffers, {itemType="spellbook", data=bc})
            end
        end
    end
    
    if #potentialOffers == 0 then
        CoreGame.endShoppingPhase(gameState, dependencies)
        return
    end
    
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
    end
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
    
    gameState.currentEnergy = (config.Game and config.Game.energyPerRound) or 100
    gameState.gameOverReason = nil
    print(string.format("    Energy reset to %d for Round %d", gameState.currentEnergy, gameState.currentRoundNumber))
    
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
    
    if not canMake and not canDiscard and deckEmpty and discardEmpty then
        print("[Stalemate Detected]")
        return true
    end
    
    return false
end

function CoreGame.getGoalProgressString(goalData, currentGameState)
    if not (goalData and goalData.goalType and goalData.goalTarget ~= nil and currentGameState) then
        return "Progress: N/A"
    end
    
    local goalType, goalSubtype, target = goalData.goalType, goalData.goalSubtype, goalData.goalTarget
    local progressString, currentProgress = "Progress: Unknown", 0
    
    if goalType == "potions_made" then
        local familyCheck = goalSubtype or "any"
        if currentGameState.roundProgress and currentGameState.roundProgress.potions_made then
            if goalSubtype and currentGameState.roundProgress.potions_made[goalSubtype] then
                currentProgress = currentGameState.roundProgress.potions_made[goalSubtype]
            else
                currentProgress = 0
                for _, v in pairs(currentGameState.roundProgress.potions_made) do
                    currentProgress = currentProgress + v
                end
                familyCheck = "Total"
            end
        end
        progressString = string.format("%s Potions: %d/%d", goalSubtype or "Any", currentProgress, target)
    elseif goalType == "money_earned_round" then
        currentProgress = currentGameState.moneyEarnedThisRound or 0
        progressString = string.format("Money This Round: $%d/$%d", currentProgress, target)
    elseif goalType == "score_reached_total" then
        currentProgress = currentGameState.score or 0
        progressString = string.format("Total Score: %d/%d", currentProgress, target)
    elseif goalType == "cards_played_type" then
        if goalSubtype and currentGameState.cardsPlayedThisRound and currentGameState.cardsPlayedThisRound.family and currentGameState.cardsPlayedThisRound.family[goalSubtype] then
            currentProgress = currentGameState.cardsPlayedThisRound.family[goalSubtype]
        else
            currentProgress = 0
        end
        progressString = string.format("%s Cards Used: %d/%d", goalSubtype or "Any", currentProgress, target)
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

return CoreGame