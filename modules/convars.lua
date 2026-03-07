--> [convars.lua] <--
--> Adds a utility hook for convars <--

local rawget = rawget
local rawequal = rawequal
local callpre = hook.callpre
local callpost = hook.callpost
local handlecall = lje.vm.handle_engine_call

local function onconvarchanged(func, name, oldvalue, newvalue)
    callpre("ljeutil/convarchanged", name, oldvalue, newvalue)
    handlecall()
    func()
    callpost("ljeutil/convarchanged", name, oldvalue, newvalue)
end

hook.pre("ljeutil/unknownenginecall", "__ljeutil_convars", function(func, nargs, nresults, ...)
    local cvars = rawget(_G, "cvar")
    if (cvars) then
        local onchanged = rawget(cvars, "OnConVarChanged")
        if (onchanged and rawequal(func, onchanged)) then
            hook.removepre("ljeutil/unknownenginecall", "__ljeutil_convars")
            return onconvarchanged
        end
    end
end)