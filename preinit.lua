--> taken from the lj-expand repository
local function cloneMetaTable(name, base)
    local mt = FindMetaTable(name)

    local newMt = {}
    local function deepCopy(orig)
        if type(orig) ~= "table" then
            return orig
        end

        local copy = {}
        for k, v in pairs(orig) do
            if type(v) == "table" and v ~= orig then
                copy[k] = deepCopy(v)
            else
                copy[k] = v
            end
        end
        return copy
    end

    newMt = deepCopy(mt)
    -- link to cloned base metatable if exists
    if base then
        newMt.BaseMetaClass = base
        -- Additionally we need to merge the base metatable functions
        for k, v in pairs(base) do
          if newMt[k] == nil then -- avoids overwriting important functions
            newMt[k] = v
          end
        end
    end

    newMt.__original_index = newMt.__index
    newMt.__index = newMt
    return newMt
end

cloned_mts["Weapon"] = cloneMetaTable("Weapon")
cloned_mts["VMatrix"] = cloneMetaTable("VMatrix")
cloned_mts["NPC"] = cloneMetaTable("NPC")