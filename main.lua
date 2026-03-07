--> [main.lua] <--
--> Loads all ljeutil-related files <--

local exists = hook ~= nil

lje.include("modules/string.lua")
lje.include("modules/math.lua")
if (not exists) then --> these should not be hot-reloaded
    lje.include("modules/hook.lua")
    lje.include("modules/util.lua")
end
lje.include("modules/render.lua")
lje.include("modules/draw.lua")
lje.include("modules/file.lua")
lje.include("modules/media.lua")
lje.include("modules/security.lua")
lje.include("modules/convars.lua")