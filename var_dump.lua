-- modified from https://gist.github.com/lunixbochs/5b0bb27861a396ab7a86

local function string(o)
    return '"' .. tostring(o) .. '"'
end

local function recurse(o, indent)
    if indent == nil then indent = '' end
    local indent2 = indent .. ''
    if type(o) == 'table' then
        local isArray = table.getn(o) > 0

        local objectMargin = '' -- ' '

        local closureStart = '{'
        local closureEnd = '}'
        if isArray then
            closureStart = '['
            closureEnd = ']'
        end

        local s = indent .. closureStart .. objectMargin
        local first = true
        for k,v in pairs(o) do
            if first == false then s = s .. ', ' end
            if type(k) ~= 'number' then 
                k = string(k)
                s = s .. indent2 .. '' .. k .. ':' .. recurse(v, indent2)
            else
                s = s .. indent2 .. '' .. recurse(v, indent2)
            end
            first = false
        end
        return s .. objectMargin .. indent .. closureEnd
    else
        return string(o)
    end
end

function var_dump(...)
    local args = {...}

    local strOut = ""

    if #args > 1 then
        strOut = strOut .. var_dump(args)
    else
        strOut = strOut .. recurse(args[1])
    end

    return strOut
end