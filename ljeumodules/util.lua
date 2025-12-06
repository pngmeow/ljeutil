--*> util.lua <*--
--*> contains optimised functions which perform specific tasks <*--
--*> made by eyoko1 <*--

--> micro-optimisations
local player_GetAll = player.GetAll
local player_GetCount = player.GetCount
local LocalPlayer = LocalPlayer
local string_char = string.char
local math_random = math.random
local table_concat = table.concat
local tonumber = tonumber

--> pre-allocate a table for random_string - this makes the function really fast
local rstringtable = {}
for i = 1, 128 do
    rstringtable[i] = "_"
end

local environment = lje.env.get()

--> this is not used - its purpose is simply for basic documentation
local __lje_util = {
    iterate_players = function(callback) end, --> iterates over all players and calls the given callback with each player, excluding the local player
    random_string = function(length) end, --> generates a random string with either the given length, or 32 characters if not specified
    color_strict = function(r, g, b, a) end --> very fast implementation of color - all arguments must be specified and must be numbers - values are still clamped
}
__lje_util = nil

--> the given callback is called for every player other than the localplayer, and it is passed such player
function lje.util.iterate_players(callback)
    local players = player_GetAll()
    local count = player_GetCount()
    local localplayer = LocalPlayer()

    local i = 1
    ::iterate_players::
    local target = players[i]
    if (target ~= localplayer) then
        callback(target)
    end

    if (i == count) then
        return
    end

    i = i + 1
    goto iterate_players
end

--> generates a random string - this function is really fast so don't worry about overheads for this
function lje.util.random_string(length)
    length = length or 32

    local i = 1
    ::fast_random_string::
    rstringtable[i] = string_char(math_random(32, 126))

    if (i == length) then
        return table_concat(rstringtable, "", 1, length)
    end

    i = i + 1
    goto fast_random_string
end

--> very fast implementation of color - alpha must be specified and the arguments must be numbers - this still clamps values
function lje.util.color_strict(r, g, b, a)
    return {
        r = r < 255 and r or 255,
        g = g < 255 and g or 255,
        b = b < 255 and b or 255,
        a = a < 255 and a or 255
    }
end

--> stripped-down copy of the color function - this is enough for it to be used with any c-function
function Color(r, g, b, a)
    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)
    a = a and tonumber(a) or 255
    return {
        r = r < 255 and r or 255,
        g = g < 255 and g or 255,
        b = b < 255 and b or 255,
        a = a < 255 and a or 255
    }
end