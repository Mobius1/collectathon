function table.len(t)
    local count = 0
    for _,_ in pairs(t) do count = count + 1 end
    return count
end

function GetPlayerID(src)
    for k, v in pairs(GetPlayerIdentifiers(src))do
        if string.sub(v, 1, string.len('license:')) == 'license:' then
            return string.sub(v, 9, string.len(v))
        end
    end 
    
    return false
end

function InTable(t, value)
    for k, v in pairs(t) do
        if v == value then
            return true
        end
    end

    return false
end

function HasHash(t, value)
    for k, v in pairs(t) do
        if GetHashKey(v) == value then
            return true
        end
    end

    return false
end


--- constants
local TRUE = {
    ['true'] = true,
    ['TRUE'] = true,
    ['True'] = true,
};
local FALSE = {
    ['false'] = false,
    ['FALSE'] = false,
    ['False'] = false,
};

function toboolean( str )
    assert( type( str ) == 'string', 'str must be string' )

    if str == 'true' then
        return true
    elseif str == 'false' then
        return false
    else
        return false, string.format( 'cannot convert %q to boolean', str )
    end
end

function CloneTable(t)
    if type(t) ~= 'table' then return t end

    local meta = getmetatable(t)
    local target = {}

    for k,v in pairs(t) do
        if type(v) == 'table' then
            target[k] = CloneTable(v)
        else
            target[k] = v
        end
    end

    setmetatable(target, meta)

    return target
end

function DumpTable(table, nb)
    if nb == nil then
        nb = 0
    end
    
    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end
    
        s = '{\n'
        for k,v in pairs(table) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '['..k..'] = ' .. DumpTable(v, nb + 1) .. ',\n'
        end
    
        for i = 1, nb, 1 do
            s = s .. "    "
        end
    
        return s .. '}'
    else
        return tostring(table)
    end
end