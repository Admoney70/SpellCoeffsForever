-- Compat.lua -- one place for every game API the addon reads.
--
-- Classic Era moved the spell and addon APIs into the C_Spell and C_AddOns
-- namespaces, and older clients only have the globals. Each accessor here
-- prefers the namespaced call, falls back to the global, and returns nil or 0
-- rather than erroring when neither exists, so a tooltip is never broken by a
-- missing API.

local ADDON, SCF = ...

local API = {}
SCF.API = API

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g
end

-- Cast time in seconds, or nil when the spell has none (instants, periodic
-- effects) or is unknown to the client.
function API.GetCastTime(spellID)
    if not spellID then return nil end
    local castMs

    if C_Spell and C_Spell.GetSpellInfo then
        local info = call(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" then
            castMs = info.castTime
        end
    end

    if castMs == nil and type(GetSpellInfo) == "function" then
        -- The global form returns name, rank, icon, castTime, ...
        local _, _, _, legacyCast = call(GetSpellInfo, spellID)
        castMs = legacyCast
    end

    if type(castMs) ~= "number" or castMs <= 0 then return nil end
    return castMs / 1000
end

function API.GetSpellName(spellID)
    if not spellID then return nil end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = call(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" and info.name then
            return info.name
        end
    end

    if type(GetSpellInfo) == "function" then
        local name = call(GetSpellInfo, spellID)
        if type(name) == "string" then return name end
    end

    return nil
end

-- The level of the given rank, or nil when the client will not tell us.
function API.GetSpellLevel(spellID)
    if not spellID then return nil end

    local level
    if C_Spell and C_Spell.GetSpellLevelLearned then
        level = call(C_Spell.GetSpellLevelLearned, spellID)
    end
    if type(level) ~= "number" or level <= 0 then
        level = call(GetSpellLevelLearned, spellID)
    end
    if type(level) == "number" and level > 0 then
        return level
    end
    return nil
end

function API.GetSpellBonusDamage(school)
    local bonus
    if C_Spell and C_Spell.GetSpellBonusDamage then
        bonus = call(C_Spell.GetSpellBonusDamage, school)
    end
    if type(bonus) ~= "number" then
        bonus = call(GetSpellBonusDamage, school)
    end
    return type(bonus) == "number" and bonus or 0
end

function API.GetSpellBonusHealing()
    local bonus
    if C_Spell and C_Spell.GetSpellBonusHealing then
        bonus = call(C_Spell.GetSpellBonusHealing)
    end
    if type(bonus) ~= "number" then
        bonus = call(GetSpellBonusHealing)
    end
    return type(bonus) == "number" and bonus or 0
end

function API.GetAddOnVersion(addon)
    local version
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        version = call(C_AddOns.GetAddOnMetadata, addon, "Version")
    end
    if type(version) ~= "string" then
        version = call(GetAddOnMetadata, addon, "Version")
    end
    return type(version) == "string" and version or "unknown"
end

-- Name and spell ID for whatever a tooltip is currently showing.
function API.GetTooltipSpell(tooltip)
    if type(tooltip) ~= "table" and type(tooltip) ~= "userdata" then return nil end
    if type(tooltip.GetSpell) ~= "function" then return nil end
    local name, spellID = call(tooltip.GetSpell, tooltip)
    if type(spellID) ~= "number" then
        -- Some clients return only the ID, or the ID in the first slot.
        if type(name) == "number" then
            return API.GetSpellName(name), name
        end
        return nil
    end
    if type(name) ~= "string" then
        name = API.GetSpellName(spellID)
    end
    return name, spellID
end

function API.IsShiftDown()
    local down = call(IsShiftKeyDown)
    return down and true or false
end
