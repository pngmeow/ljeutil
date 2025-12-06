local string_sub = string.sub
local string_find = string.find

function string.ToTable(str)
    str = tostring(str)

    local tbl = {}

    local length = #str
    local i = 1
    ::totable::
    tbl[i] = string_sub(str, i, i)

    if (i == length) then
        return tbl
    end

    i = i + 1
    goto totable
end

local totable = string.ToTable
function string.Explode( separator, str, withpattern )
	if (separator == "") then return totable(str) end

    local length = #str
    if (length == 0) then
        return {}
    end

    local dopattern = not withpattern
    local ret = {"", ""} --> the table is guaranteed to have at least two elements in it - this saves some re-allocations
	local currentpos = 1

    local i = 1
    ::explode::
    local startpos, endpos = string_find(str, separator, currentpos, dopattern)
    if (startpos) then
        ret[i] = string_sub(str, currentpos, startpos - 1)
        currentpos = endpos + 1

        if (i ~= length) then
            i = i + 1
            goto explode
        end
    end

	ret[i + 1] = string_sub(str, currentpos)

	return ret
end

local string_Explode = string.Explode
function string.Split(str, delimiter)
    return string_Explode(delimiter, str)
end