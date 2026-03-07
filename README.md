# ljeutil
A utility library made for [LJ-Expand](https://github.com/lj-expand/lj-expand/) which re-adds a lot of functions implemented purely in GLua, as well as new functions which would be useful, and provides security features which would otherwise need to be manually created

# Best practices
- When rendering anything to the screen, push 'lje.util.rendertarget' to the screen before, and then pop it after
- Use the utility functions provided by ljeutil instead of making your own implementations
- Do not modify the table returned by player.GetAll
- Disabling debug hooks, metatables, and saving/restoring the random state is not necessary for lua hooks, but should still be done in other places such as detours
- If you have any issues with this library you can contact me through the LJE Discord server, or directly with my username: 'eyoko1'
- Use sumneko's lua language server (and the Garry's Mod addon) to get annotations for ljeutil

# List of added hooks
```lua
--> format: {comment, name, ...args}
{
    ----------------------------------------------------------------------
    --> Called when the safe render target is drawn to the screen
    "ljeutil/render", --> (): nil
    ----------------------------------------------------------------------
    --> Called when a player joins the server
    --> [1] player: Player
    "ljeutil/playerconnect", --> (player: Player): nil
    ----------------------------------------------------------------------
    --> Called when a player leaves the server
    --> [1] player: Player
    "ljeutil/playerdisconnect", --> (player: Player): nil
    ----------------------------------------------------------------------
    --> Called when an engine call targets a function which is not currently recognised - arguments are shared with set_engine_call_hook
    --> [1] func: fun(...): ...
    --> [2] nargs: integer
    --> [3] nresults: integer
    --> [4] ...: any
    --> Return either a function, or nil
    "ljeutil/unknownenginecall",
        --> Example:
        hook.pre("ljeutil/unknownenginecall", "example", function(func, nargs, nresults, ...)
            --> this function is rarely called so this doesn't matter too much
            if (func == lje.get_global("matproxy", "Call")) then
                return function(func, ...)
                    if (freecam:isenabled()) then
                        lje.vm.handle_engine_call()
                        return
                    end
                end
            end
        end)
    ----------------------------------------------------------------------
    --> Called when a convar is changed - exactly the same as cvars.OnConVarChanged / cvars.AddChangeCallback
    --> [1] name: string
    --> [2] oldvalue: string
    --> [3] newvalue: string
    "ljeutil/convarchanged",
    ----------------------------------------------------------------------
    --> Provides a context where you can use lje.input.* functions - only the pre hook provides this context
    --> [1] cusercmd: CUserCmd
    "ljeutil/input"
    ----------------------------------------------------------------------
}
```

# List of (re)added functions
```lua
{ --> draw
    SimpleText = function(text, font, x, y, color, xalign, yalign) end,
    SimpleTextOutlined = function(text, font, x, y, color, xalign, yalign, outlinewidth, outlinecolor) end,
    DrawText = function(text, font, x, y, color, xalign) end,
    GetFontHeight = function(font) end,
    NoTexture = function() end,
    RoundedBoxEx = function(radius, x, y, width, height, color, topleft, topright, bottomleft, bottomright) end,
    RoundedBox = function(radius, x, y, width, height, color) end,
    Text = function(textdata) end, --> do not use this unless it is absolutely necessary
    TextShadow = function(textdata, distance, alpha) end, --> do not use this unless it is absolutely necessary
    TexturedQuad = function(texturedata) end,
    WordBox = function(bordersize, x, y, text, font, boxcolor, textcolor, xalign, yalign) end
}

{ --> string
    ToTable = function(str) end,
    Explode = function(separator, str, withpattern) end,
    Split = function(str, separator) end,
    StartsWith = function(str, start) end,
    EndsWith = function(str, endstr) end,
    Replace = function(str, tofind, toreplace) end
}

{ --> math
    Round = function(number, idp) end,
    Clamp = function(number, low, high) end,
    Rand = function(low, high) end,
    IsNearlyEqual = function(a, b, tolerance) end,
    DistanceSqr = function(x1, y1, x2, y2) end,
    Distance = function(x1, y1, x2, y2) end,
    Dist = function(x1, y1, x2, y2) end
}

{ --> hook
    list = {}, --> event table

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

    disable = function(disableljehooks) end, --> stops hooks from running - useful when re-rendering the scene, or using DrawModel - if disableljehooks is false (must be specified) then hooks registered with this library will still be called, otherwise if true or not specified, they will not be called
    enable = function() end, --> re-enables hooks
    isdisabled = function() end, --> returns whether or not hooks are disabled

    disallowlua = function() end, --> sets a flag to true that prevents lje hooks from being called when lua is in the callstack (any lua, not just foreign lua)
    allowlua = function() end --> sets the above flag to false
}

{ --> cam
    Start2D = function() end,
    Start3D = function(pos, ang, fov, x, y, w, h, znear, zfar) end
}

{ --> _G
    Color = function(r, g, b, a) end,
    IsValid = function(obj) end,
    LocalPlayer = function() end,
    ScrW = function() end,
    ScrH = function() end
}

{ --> player
    GetAll = function() end, --> do not modify the value returned by this
    GetCount = function() end
}

{ --> file
    Read = function(filename, path) end,
    Write = function(filename, contents) end,
    Append = function(filename, contents) end
}

{ --> lje.util
    rendertarget = GetRenderTargetEx(...), --> a render target which is safe to render to - this cannot be screengrabbed
    rt = GetRenderTargetEx(...), --> alias for lje.util.rendertarget - these are exactly the same
    iterate_players = function(callback) end, --> iterates over all players and calls the given callback with each player, excluding the local player
    iterate_npcs = function(callback) end, --> fast way to iterate over every npc that is currently available to the client
    random_string = function(length) end, --> generates a random string with either the given length, or 32 characters if not specified
    color_strict = function(r, g, b, a) end, --> very fast implementation of color - all arguments must be specified and must be numbers - values are still clamped
    is_player = function(entity) end, --> should be used instead of ENTITY.IsPlayer or PLAYER.IsPlayer
    is_npc = function(entity) end, --> should be used instead of ENTITY.IsNPC or NPC.IsNPC
    get_mutable_players = function() end, --> equivalent to player.GetAll, but the value returned can be modified
    disable_engine_calls = function() end, --> disables all calls to engine functions
    enable_engine_calls = function() end --> enables all calls to engine functions
}

{ --> lje.media
    --> this does not work right now since lje doesn't have a filesystem / data api yet
    load = function(path, callback) end, --> loads media (sounds, images, etc) from the given path in the lje filesystem - the callback is passed the virtual path of the media once it has been written to the data folder - the function returns whether or not it was successful, and the value returned by the callback
}
```

To use ljeutil, add it as a dependency in your info.toml script.
