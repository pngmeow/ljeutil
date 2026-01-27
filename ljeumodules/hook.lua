--*> hook.lua <*--
--*> lje hook library made by detouring hook.Call inside the registry <*--
--*> made by eyoko1 <*--

--> handles detouring hook.Call
--> there is quite a lot of duplicated code here since the alternatives are slower and a hooking library should be designed with speed in mind
--> both the hook library itself and the registry searching method are optimised a pretty good amount

--> micro-optimisations since a lot of functions are detoured
local detour = lje.detour
local enablehooks = lje.hooks.enable
local disablehooks = lje.hooks.disable
local enablemetatables = lje.env.enable_metatables
local disablemetatables = lje.env.disable_metatables
local registry = lje.util.get_registry()

local environment = lje.env.get()
local gmgui = gmgui

local next = next
local isfunction = isfunction
local rawequal = rawequal
local select = select
local unpack = unpack

local originalcall = nil

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

local doimmediatereturn = false
local imm_a, imm_b, imm_c, imm_d, imm_e, imm_f = nil, nil, nil, nil, nil, nil
--> Call this in hook.pre events to allow other lje hooks to be called, but overwrite their returns and prevent the default gmod callbacks from being executed
function hook.immediatereturn(a, b, c, d, e, f)
    doimmediatereturn = true
    imm_a, imm_b, imm_c, imm_d, imm_e, imm_f = a, b, c, d, e, f
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

function hook.callpre(event, ...)
    local hooks = hook.list[event]
    if (not hooks) then
        return
    end

    local length = hooks[PRE_HOOKS_LEN]
    if (length == 0) then
        return
    end

    local sequential = hooks[PRE_HOOKS_SEQ]
    local i = 1
    ::call_pre::
    sequential[i](...)
    if (i == length) then
        return
    end

    i = i + 1
    goto call_pre
end

function hook.callpost(event, ...)
    local hooks = hook.list[event]
    if (not hooks) then
        return
    end

    local length = hooks[POST_HOOKS_LEN]
    if (length == 0) then
        return
    end

    local sequential = hooks[POST_HOOKS_SEQ]
    local i = 1
    ::call_post::
    sequential[i](...)
    if (i == length) then
        return
    end

    i = i + 1
    goto call_post
end

local function executepre(hooks, ...)
    local length = hooks[PRE_HOOKS_LEN]
    if (length == 0) then
        return
    end

    disablemetatables()

    local a1, b1, c1, d1, e1, f1
    local override = nil
    local callbacks = hooks[PRE_HOOKS_SEQ]
    local index = 1
    ::h_execute_pre::
    local a2, b2, c2, d2, e2, f2 = callbacks[index](...)
    if (a) then
        a1, b1, c1, d1, e1, f1 = a2, b2, c2, d2, e2, f2
    end

    if (index == length) then
        enablemetatables()
        return a1, b1, c1, d1, e1, f1
    end

    index = index + 1
    goto h_execute_pre
end

local function executepost(hooks, ...)
    local length = hooks[POST_HOOKS_LEN]
    if (length == 0) then
        return
    end

    disablemetatables()

    local a1, b1, c1, d1, e1, f1
    local override = nil
    local callbacks = hooks[POST_HOOKS_SEQ]
    local index = 1
    ::h_execute_post::
    local a2, b2, c2, d2, e2, f2 = callbacks[index](...)
    if (a) then
        a1, b1, c1, d1, e1, f1 = a2, b2, c2, d2, e2, f2
    end

    if (index == length) then
        enablemetatables()
        return a1, b1, c1, d1, e1, f1
    end

    index = index + 1
    goto h_execute_post
end

local hooklist = hook.list
--local debug_getinfo = debug.getinfo
local is_lua_involved = lje.env.is_lua_involved
local ignore_fn_once = lje.hooks.ignore_fn_once
local function calldetour(event, gm, ...)
    if (disabled) then
        if (disablelje) then
            return
        end

        if (ignorelua and is_lua_involved(1)) then
            return originalcall(event, gm, ...)
        end

        local hooks = hooklist[event]
        if (not hooks) then
            return originalcall(event, gm, ...)
        end

        disablehooks()
            local a, b, c, d, e, f = executepre(hooks, ...)
            if (doimmediatereturn) then
                doimmediatereturn = false
                enablehooks()
                return imm_a, imm_b, imm_c, imm_d, imm_e, imm_f
            end
            a, b, c, d, e, f = executepost(hooks, ...) or override
        enablehooks()

        return a, b, c, d, e, f
    else
        if (ignorelua and is_lua_involved(1)) then
            return originalcall(event, gm, ...)
        end

        local hooks = hooklist[event]
        if (not hooks) then
            return originalcall(event, gm, ...)
        end

        disablehooks()
            local a, b, c, d, e, f = executepre(hooks, ...)
            if (doimmediatereturn) then
                doimmediatereturn = false
                enablehooks()
                return imm_a, imm_b, imm_c, imm_d, imm_e, imm_f
            end
        enablehooks()

        a, b, c, d, e, f = originalcall(event, gm, ...)

        disablehooks()
            a, b, c, d, e, f = executepost(hooks, ...) or override
        enablehooks()

        if (override) then
            ignore_fn_once(unpack)
            return unpack(override)
        end

        return a, b, c, d, e, f
    end
end

--> searches the registry for hook.Call - this is called repeatedly until hook.Call is found
local detoured = setmetatable({}, {__mode = "v"})
local function searchregistry()
    local key, value = next(registry)
    ::r_search:: --> gotos are really fast
    if (key) then
        if (not detoured[key] and isfunction(value)) then
            --> we need to detour all functions, not just lua ones since servers can do some
            --> trickery where they set hook.Call to an invalid value at first to mess with
            --> people detouring hook.Call
            local original = value
            local originalkey = key
            detoured[originalkey] = original
            registry[originalkey] = detour(original, function(...) --> vararg is used to maintain arg count
                disablehooks()

                if (select("#", ...) < 2) then
                    --> this isn't hook.Call, remove this detour
                    registry[originalkey] = original
                    enablehooks()
                    return original(...)
                end

                if (rawequal(..., "PostRender")) then
                    --> this is hook.Call, restore all detours, and exit
                    originalcall = original
                    registry[originalkey] = detour(original, calldetour)
                    detoured[originalkey] = nil
                    
                    local r_key, r_value = next(detoured)
                    ::r_restore::
                    if (r_key) then
                        if (rawequal(registry[r_key], r_value)) then --> detour == original in lje
                            registry[r_key] = r_value
                        end
                        r_key, r_value = next(detoured, r_key)
                        goto r_restore
                    end

                    if (IsValid(LocalPlayer())) then
                        hook.callpre("InitPostEntity")
                        hook.callpost("InitPostEntity")
                    end

                    detoured = {}

                    enablehooks()
                    return original(...)
                end

                enablehooks()
                return original(...)
            end)
        end

        key, value = next(registry, key)
        goto r_search
    end
end

local function searchloop()
    disablehooks()
    if (not originalcall) then
        searchregistry()
        timer.Simple(0.1, searchloop)
    end
    enablehooks()
end

searchloop()