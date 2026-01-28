--*> hook.lua <*--
--*> lje hook library made by detouring hook.Call inside the registry <*--
--*> made by eyoko1 <*--

--> handles detouring hook.Call
--> there is quite a lot of duplicated code here since the alternatives are slower and a hooking library should be designed with speed in mind
--> both the hook library itself and the registry searching method are optimised a pretty good amount

--> unpack is never used because it is really slow

--> micro-optimisations since a lot of functions are detoured
local detour = lje.detour
local registry = lje.util.get_registry()

local environment = lje.env.get()
local gmgui = gmgui

local next = next
local isfunction = isfunction
local rawequal = rawequal
local select = select

local hook = {
    list = {}, --> event table
    disabled = false,

    pre = function(event, identifier, callback) end, --> adds an event to be run before normal gmod callbacks are ran for an event
                                                     --> if an identifier is not passed, one will be generated and returned
    post = function(event, identifier, callback) end, --> adds an event to be run after normal gmod callbacks are ran for an event
                                                     --> if an identifier is not passed, one will be generated and returned
    
    before = function(event, identifier, callback) end, --> alias for hook.pre
    after = function(event, identifier, callback) end, --> alias for hook.post

    --> these removal functions can be quite expensive with large hook tables as they use table.remove on the sequential table section
    removepre = function(event, identifier) end, --> removes an event that is run before normal gmod callbacks are ran for an event
    removepost = function(event, identifier) end, --> removes an event that is run after normal gmod callbacks are ran for an event

    removebefore = function(event, identifier) end, --> alias for hook.removepre
    removeafter = function(event, identifier) end, --> alias for hook.removepost

    callpre = function(event, ...) end, --> executes lje callbacks for the given pre hook event
    callpost = function(event, ...) end, --> executes lje callbacks for the given post hook event

    disable = function() end, --> stops hooks from running - useful when re-rendering the scene, or using DrawModel
    enable = function() end --> re-enables hooks
}
environment.hook = hook

local PRE_HOOKS_SEQ = 1
local POST_HOOKS_SEQ = 2
local PRE_HOOKS_MAP = 3
local POST_HOOKS_MAP = 4
local PRE_HOOKS_LEN = 5
local POST_HOOKS_LEN = 6

local hookcount = -1
local function gethookcount()
    hookcount = hookcount + 1
    return hookcount
end

local disabled = false
local disablelje = false
--> Call this to allow the default gmod callbacks to be executed - Do not call this while a hook is in progress as nothing will happen; see below for an alternative
--> If in hook.pre, use hook.immediatereturn instead
--> If 'disableljehooks' is true or nil, no hooks at all will be called (neither ones registered with hook.pre/post, nor the default gmod library ones with hook.Add)
function hook.disable(disableljehooks)
    disabled = true
    if (disableljehooks == nil) then
        disablelje = true
    else
        disablelje = disableljehooks
    end
end

--> Call this to enable the default gmod callbacks being executed - See warning with hook.disable
function hook.enable()
    disabled = false
end

local ignorelua = true
--> Call this to disallow lua functions to be in the callstack when a hook is called
function hook.disallowlua()
    ignorelua = true
end

--> Call this to allow lua functions to be in the callstack when a hook is called
function hook.allowlua()
    ignorelua = false
end

function hook.pre(event, identifier, callback)
    local generated = false
    if (isfunction(identifier)) then
        callback = identifier
        identifier = gethookcount()
        generated = true
    end

    local hooks = hook.list[event]
    if (hooks) then
        local index = hooks[PRE_HOOKS_MAP][identifier]
        if (index) then
            hooks[PRE_HOOKS_SEQ][index] = callback
        else
            local length = hooks[PRE_HOOKS_LEN] + 1
            hooks[PRE_HOOKS_LEN] = length
            hooks[PRE_HOOKS_SEQ][length] = callback
            hooks[PRE_HOOKS_MAP][identifier] = length
        end
    else
        hook.list[event] = {
            {callback}, --> pre hooks (sequential table)
            {}, --> post hooks (sequential table)
            {[identifier] = 1}, --> pre hooks (dictionary [identifier]: index)
            {}, --> post hooks (dictionary [identifier]: index)
            1, --> length of pre hooks
            0 --> length of post hooks
        }
    end

    if (generated) then
        return identifier
    end
end

function hook.post(event, identifier, callback)
    local generated = false
    if (isfunction(identifier)) then
        callback = identifier
        identifier = gethookcount()
        generated = true
    end

    local hooks = hook.list[event]
    if (hooks) then
        local index = hooks[PRE_HOOKS_MAP][identifier]
        if (index) then
            hooks[POST_HOOKS_SEQ][index] = callback
        else
            local length = hooks[POST_HOOKS_LEN] + 1
            hooks[POST_HOOKS_LEN] = length
            hooks[POST_HOOKS_SEQ][length] = callback
            hooks[POST_HOOKS_MAP][identifier] = length
        end
    else
        hook.list[event] = {
            {}, --> pre hooks (sequential table)
            {callback}, --> post hooks (sequential table)
            {}, --> pre hooks (dictionary [identifier]: index)
            {[identifier] = 1}, --> post hooks (dictionary [identifier]: index)
            0, --> length of pre hooks
            1 --> length of post hooks
        }
    end

    if (generated) then
        return identifier
    end
end

hook.before = hook.pre
hook.after = hook.post

function hook.removepre(event, identifier)
    local hooks = hook.list[event]
    if (not hooks) then
        return
    end

    local index = hooks[PRE_HOOKS_MAP][identifier]
    if (not index) then
        return
    end

    local length = hooks[PRE_HOOKS_LEN] - 1
    hooks[PRE_HOOKS_LEN] = length
    table.remove(hooks[PRE_HOOKS_SEQ], index)

    if (length == 0 and hooks[POST_HOOKS_LEN] == 0) then
        hook.list[event] = nil
    end
end

function hook.removepost(event, identifier)
    local hooks = hook.list[event]
    if (not hooks) then
        return
    end

    local index = hooks[POST_HOOKS_MAP][identifier]
    if (not index) then
        return
    end

    local length = hooks[POST_HOOKS_LEN] - 1
    hooks[POST_HOOKS_LEN] = length
    table.remove(hooks[POST_HOOKS_SEQ], index)

    if (length == 0 and hooks[PRE_HOOKS_LEN] == 0) then
        hook.list[event] = nil
    end
end

hook.removebefore = hook.removepre
hook.removeafter = hook.removepost

local function doerror(message)
    lje.con_printf("$red{%s}", message)
end

local function executepre(hooks, ...)
    local length = hooks[PRE_HOOKS_LEN]
    if (length == 0) then
        return
    end

    local callbacks = hooks[PRE_HOOKS_SEQ]
    local index = 1
    ::h_execute_pre::
    local success, a, b, c, d, e, f = pcall(callbacks[index], ...)
    if (success) then
        if (a) then
            return a, b, c, d, e, f
        end
    else
        doerror(a)
    end

    if (index == length) then
        return
    end

    index = index + 1
    goto h_execute_pre
end

local function executepost(hooks, ...)
    local length = hooks[POST_HOOKS_LEN]
    if (length == 0) then
        return
    end

    local callbacks = hooks[POST_HOOKS_SEQ]
    local index = 1
    ::h_execute_post::
    local success, a, b, c, d, e, f = pcall(callbacks[index], ...)
    if (success) then
        if (a) then
            return a, b, c, d, e, f
        end
    else
        doerror(a)
    end

    if (index == length) then
        return
    end

    index = index + 1
    goto h_execute_post
end

function hook.callpre(event, ...)
    local hooks = hook.list[event]
    if (not hooks) then
        return
    end

    return executepre(hooks, ...)
end

function hook.callpost(event, ...)
    local hooks = hook.list[event]
    if (not hooks) then
        return
    end

    return executepost(hooks, ...)
end

local hooklist = hook.list
local is_lua_involved = lje.env.is_lua_involved
local ignore_fn_once = lje.hooks.ignore_fn_once
local function calldetour(originalcall, event, gm, ...)
    if (disabled) then
        --> Calling the default gmod callback is disabled
        if (disablelje) then
            --> Hooks added with this library are disabled too - no extra computation is needed
            return
        end

        if (ignorelua and is_lua_involved(2)) then
            return originalcall(event, gm, ...)
        end

        local hooks = hooklist[event]
        if (not hooks) then
            return originalcall(event, gm, ...)
        end

        local a, b, c, d, e, f = executepre(hooks, ...)
        if (a) then
            return a, b, c, d, e, f
        end

        return executepost(hooks, ...)
    else
        --> We need to call the default gmod callbacks
        if (ignorelua and is_lua_involved(2)) then
            return originalcall(event, gm, ...)
        end

        local hooks = hooklist[event]
        if (not hooks) then
            return originalcall(event, gm, ...)
        end

        local a, b, c, d, e, f = executepre(hooks, ...)
        if (a) then
            return a, b, c, d, e, f
        end

        local a2, b2, c2, d2, e2, f2 = originalcall(event, gm, ...)

        a, b, c, d, e, f = executepost(hooks, ...) or override
        if (a) then
            return a, b, c, d, e, f
        end

        return a2, b2, c2, d2, e2, f2
    end
end

local _G = _G
lje.vm.add_engine_call_hook(function(func, nargs, nresults, ...)
    local hook = rawget(_G,  "hook")
    if (hook) then
        local call = rawget(hook, "Call")
        if (func == call) then --> even if func had __eq we would be fine as both sides need to have the same metamethod for it to work
            return false, calldetour(func, ...)
        end
    end

    return true
end)