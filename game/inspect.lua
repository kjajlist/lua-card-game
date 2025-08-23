-- inspect.lua - v3.1.0 | MIT license | https://github.com/kikito/inspect.lua
-- A basic pretty-printer for Lua tables and values. Handles cycles correctly.

local inspect = {} -- Module table

local function _inspect(value, options, seen, level)
    local valueType = type(value)
    local processedValue = options.process(value, valueType) -- User-defined processing function

    if processedValue then
        return processedValue -- Return if user function handled it
    end

    if valueType == 'string' then
        return string.format('%q', value)
    end

    if valueType ~= 'table' then
        return tostring(value)
    end

    -- Handle tables that have already been seen (cycle detection)
    if seen[value] then
        return seen[value] -- Return the placeholder string for a seen table
    end

    level = level + 1
    seen[value] = string.format('<table %d>', level) -- Placeholder for current table before full processing

    if level > options.depth then
        seen[value] = '{...}' -- Mark as too deep
        return seen[value]
    end

    local parts = {}          -- Stores the "key = value" string parts
    local keysToProcess = {}  -- For collecting and sorting keys
    local metatableKeys = {}  -- For keys from the metatable if options.metatables is true
    local keyTypeCounts = {}  -- To aid in formatting, e.g., aligning numeric keys

    local metatable = getmetatable(value)
    local hasIpairsProtocol = type(metatable) == 'table' and type(metatable.__ipairs) == 'function'
    local hasPairsProtocol = type(metatable) == 'table' and type(metatable.__pairs) == 'function'

    -- Determine iteration strategy for table keys
    if hasPairsProtocol then -- Prefer __pairs if available
        for k, _ in metatable.__pairs(value) do -- Only need keys for sorting
            local key_type = type(k)
            keyTypeCounts[key_type] = (keyTypeCounts[key_type] or 0) + 1
            table.insert(keysToProcess, k)
        end
    else -- Standard pairs iteration
        local numericKeysMap = {}
        local otherKeysList = {}
        local maxNumericKey = 0
        for k in pairs(value) do
            local key_type = type(k)
            keyTypeCounts[key_type] = (keyTypeCounts[key_type] or 0) + 1
            if key_type == 'number' and k % 1 == 0 and k >= 1 then
                numericKeysMap[k] = true
                maxNumericKey = math.max(maxNumericKey, k)
            else
                table.insert(otherKeysList, k)
            end
        end
        -- Add numeric keys in sequence first (array part)
        for i = 1, maxNumericKey do
            if numericKeysMap[i] then
                table.insert(keysToProcess, i)
            end
        end
        -- Then add other keys (hash part)
        for _, k_other in ipairs(otherKeysList) do
            table.insert(keysToProcess, k_other)
        end
    end

    -- Sort keys if the option is enabled
    local sortKeysOption = options.sort_keys
    if sortKeysOption then
        table.sort(keysToProcess, function(a, b)
            local type_a, type_b = type(a), type(b)
            if sortKeysOption == 'type' and type_a ~= type_b then
                return type_a < type_b -- Sort by type first if specified
            end
            -- Try direct comparison
            local success, lessThan = pcall(function() return a < b end)
            if success then return lessThan end
            -- Fallback to string comparison if direct comparison fails
            local string_a, string_b = tostring(a), tostring(b)
            return string_a < string_b
        end)
    end

    -- Process metatable keys if requested
    if options.metatables and metatable and type(metatable) == 'table' then
        for k_meta in pairs(metatable) do
            table.insert(metatableKeys, k_meta)
        end
        if sortKeysOption and #metatableKeys > 0 then -- Sort metatable keys as well
            table.sort(metatableKeys, function(a, b)
                local type_a, type_b = type(a), type(b)
                if sortKeysOption == 'type' and type_a ~= type_b then return type_a < type_b end
                local success, lessThan = pcall(function() return a < b end)
                if success then return lessThan end
                return tostring(a) < tostring(b)
            end)
        end
    end

    -- Determine maximum length for numeric key alignment if enabled
    local maxNumericKeyLength = 0
    if options.align_keys and keyTypeCounts.number and keyTypeCounts.number > 1 then
        for _, k_align in ipairs(keysToProcess) do
            if type(k_align) == 'number' then
                maxNumericKeyLength = math.max(maxNumericKeyLength, #string.format('%.16g', k_align))
            end
        end
    end

    local currentIndent = string.rep(options.indent, level)
    local nextIndent = string.rep(options.indent, level + 1)
    local entrySeparator = options.newline .. nextIndent

    -- Construct string representation for each key-value pair
    local isFirstEntry = true
    for _, k_inspect in ipairs(keysToProcess) do
        local v_inspect = value[k_inspect]
        local keyString
        local key_type_inspect = type(k_inspect)

        if key_type_inspect == 'number' then
            if options.align_keys and maxNumericKeyLength > 0 then
                keyString = string.format('[%-' .. maxNumericKeyLength .. 's]', string.format('%.16g', k_inspect))
            else
                keyString = string.format('[%s]', tostring(k_inspect))
            end
        elseif key_type_inspect == 'string' and k_inspect:match('^[_%a][_%w]*$') then -- Simple string key
            keyString = k_inspect
        else -- Complex key (boolean, table, or string needing quotes)
            keyString = '[' .. _inspect(k_inspect, options, seen, level) .. ']'
        end

        local valueString = _inspect(v_inspect, options, seen, level)
        
        if not isFirstEntry then
            table.insert(parts, ',')
        end
        table.insert(parts, entrySeparator .. keyString .. ' = ' .. valueString)
        isFirstEntry = false
    end

    -- Add metatable representation if applicable
    if options.metatables and #metatableKeys > 0 then
        -- Inspect the metatable itself as a table
        local metatableString = _inspect(metatable, options, seen, level)
        if not isFirstEntry then
            table.insert(parts, ',')
        end
        table.insert(parts, entrySeparator .. '<metatable>' .. ' = ' .. metatableString)
        -- isFirstEntry = false -- Not strictly needed here as it's the last potential part
    end

    local resultString
    if #parts > 0 then
        resultString = '{' .. table.concat(parts) .. options.newline .. currentIndent .. '}'
    else
        resultString = '{}' -- Empty table
    end

    seen[value] = resultString -- Store the fully processed string for this table
    return resultString
end

local default_inspect_options = {
    depth = 5,                -- Maximum depth for nested tables
    newline = '\n',             -- String used for newlines
    indent = '  ',              -- String used for indentation (two spaces is common for inspect.lua)
    sort_keys = false,          -- Whether to sort keys (false, true for alphabetical, or 'type')
    align_keys = false,         -- Whether to align numeric keys
    metatables = true,          -- Whether to include metatables in the output
    process = function() end    -- Custom function to pre-process values
}

function inspect.inspect(value, options)
    -- Allow global options to be set via a metatable on the inspect module itself
    local M = getmetatable(inspect) 
    local globalDefaultOptions = (type(M) == 'table' and M.__options) or {}

    options = options or {}
    local effectiveOptions = {}

    -- Merge options: library defaults < global defaults < local call options
    for k, v_default in pairs(default_inspect_options) do
        effectiveOptions[k] = v_default
    end
    for k, v_global in pairs(globalDefaultOptions) do
        effectiveOptions[k] = v_global
    end
    for k, v_local in pairs(options) do
        effectiveOptions[k] = v_local
    end

    -- Validate crucial options to prevent errors
    if type(effectiveOptions.depth) ~= 'number' or effectiveOptions.depth < 0 then
        effectiveOptions.depth = math.huge -- Effectively infinite depth if invalid value provided
    end
    if type(effectiveOptions.newline) ~= 'string' then
        effectiveOptions.newline = default_inspect_options.newline
    end
    if type(effectiveOptions.indent) ~= 'string' then
        effectiveOptions.indent = default_inspect_options.indent
    end
    if type(effectiveOptions.process) ~= 'function' then
        effectiveOptions.process = default_inspect_options.process
    end

    local seenTables = {} -- Initialize 'seen' table for each top-level inspect call
    return _inspect(value, effectiveOptions, seenTables, 0)
end

-- Return the main inspection function directly for convenience when requiring
return inspect.inspect