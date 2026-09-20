-- Core.lua -- coefficient maths and tooltip injection.

local ADDON, SCF = ...
local Data = SCF.Data
local API = SCF.API

SCF.name = ADDON
SCF.version = API.GetAddOnVersion(ADDON)

local DEFAULTS = {
    enabled = true,
    showEffective = true,   -- add the "+N with your gear" line
    showFormula = false,    -- add the cast time / duration the value came from
    modifierOnly = false,   -- only show while Shift is held
}

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------

local function round(value, places)
    local mult = 10 ^ (places or 0)
    return math.floor(value * mult + 0.5) / mult
end

-- Level of the rank being inspected, used for the sub-level-20 penalty. The
-- client is asked first; the static table only covers what it will not answer.
local function GetSpellLevel(spellID)
    return API.GetSpellLevel(spellID) or (spellID and Data.rankLevels[spellID]) or nil
end

-- Classic Era has no TBC-style downranking penalty. The only scaling penalty
-- is the one applied to spells whose level is below 20.
function SCF:GetLevelPenalty(spellLevel)
    if not spellLevel or spellLevel >= Data.LOW_LEVEL_THRESHOLD then
        return 1, nil
    end
    local missing = Data.LOW_LEVEL_THRESHOLD - spellLevel
    local factor = 1 - missing * Data.LOW_LEVEL_PENALTY_PER_LEVEL
    if factor < 0 then factor = 0 end
    return factor, missing
end

local function CastSeconds(spellID)
    return API.GetCastTime(spellID)
end

------------------------------------------------------------------------------
-- Coefficients
------------------------------------------------------------------------------

-- Returns a table:
--   { effect = "damage"|"healing",
--     parts  = { { label, base, final, exact, formula }, ... },
--     penalty = number, missingLevels = number|nil, spellLevel = number|nil,
--     aoe = boolean, note = string|nil }
-- or nil when the spell is not one that scales with spell power.
function SCF:GetCoefficients(spellID, spellName)
    local info = Data:GetSpell(spellName)
    if not info then return nil end

    local override = Data:GetOverride(spellName) or {}
    local castTime = CastSeconds(spellID)
    local effectiveCast = math.max(castTime or Data.MIN_CAST_TIME, Data.MIN_CAST_TIME)
    local channelTime = info.channel or castTime
    local spellLevel = GetSpellLevel(spellID)
    local penalty, missingLevels = self:GetLevelPenalty(spellLevel)

    local parts = {}

    local function add(label, base, exact, formula)
        if type(base) ~= "number" or base < 0 then return end
        parts[#parts + 1] = {
            label = label,
            base = base,
            final = base * penalty,
            exact = exact and true or false,
            formula = formula,
        }
    end

    if info.kind == "direct" then
        local base = override.direct or effectiveCast / Data.DIRECT_DIVISOR
        add("Direct", base, override.direct ~= nil,
            string.format("%.1fs cast / %.1f", effectiveCast, Data.DIRECT_DIVISOR))

    elseif info.kind == "channel" then
        local span = math.max(channelTime or Data.MIN_CAST_TIME, Data.MIN_CAST_TIME)
        local base = override.direct or span / Data.DIRECT_DIVISOR
        add("Channel (total)", base, override.direct ~= nil,
            string.format("%.1fs channel / %.1f", span, Data.DIRECT_DIVISOR))

    elseif info.kind == "periodic" then
        local base = override.periodic
        local formula
        if not base and info.duration then
            base = info.duration / Data.PERIODIC_DIVISOR
            formula = string.format("%ds duration / %d", info.duration, Data.PERIODIC_DIVISOR)
        end
        add("Over time (total)", base, override.periodic ~= nil, formula)

    elseif info.kind == "hybrid" then
        if override.direct then
            add("Direct", override.direct, true)
        else
            add("Direct", effectiveCast / Data.DIRECT_DIVISOR, false,
                string.format("%.1fs cast / %.1f", effectiveCast, Data.DIRECT_DIVISOR))
        end
        if override.periodic ~= nil then
            add("Over time (total)", override.periodic, true)
        elseif info.duration then
            add("Over time (total)", info.duration / Data.PERIODIC_DIVISOR, false,
                string.format("%ds duration / %d", info.duration, Data.PERIODIC_DIVISOR))
        end
    end

    if #parts == 0 then return nil end

    return {
        effect = info.effect or "damage",
        parts = parts,
        penalty = penalty,
        missingLevels = missingLevels,
        spellLevel = spellLevel,
        aoe = info.aoe,
        note = override.note,
        exact = override.exact,
    }
end

-- Best available spell power for the given effect. Classic does not expose a
-- spell's school, so damage spells use the highest school bonus on the player.
function SCF:GetSpellPower(effect)
    if effect == "healing" then
        return API.GetSpellBonusHealing(), "healing power"
    end
    local best = 0
    for school = 2, 7 do
        local bonus = API.GetSpellBonusDamage(school)
        if bonus > best then best = bonus end
    end
    return best, "spell damage"
end

------------------------------------------------------------------------------
-- Tooltip
------------------------------------------------------------------------------

local HEADER_COLOR = { 0.4, 0.78, 1.0 }
local VALUE_COLOR = { 1.0, 0.82, 0.0 }
local MUTED_COLOR = { 0.6, 0.6, 0.6 }

local function AddLine(tooltip, left, right, color)
    local c = color or VALUE_COLOR
    if right then
        tooltip:AddDoubleLine(left, right, c[1], c[2], c[3], c[1], c[2], c[3])
    else
        tooltip:AddLine(left, c[1], c[2], c[3])
    end
end

local shown = {}

function SCF:Render(tooltip, spellID, spellName)
    local db = SpellCoeffsForeverDB
    if not db or not db.enabled then return end
    if db.modifierOnly and not API.IsShiftDown() then return end

    local result = self:GetCoefficients(spellID, spellName)
    if not result then return end

    local power, powerLabel = self:GetSpellPower(result.effect)

    AddLine(tooltip, "Spell power coefficient", nil, HEADER_COLOR)

    for _, part in ipairs(result.parts) do
        local value = string.format("%.3f", round(part.final, 3))
        if not part.exact then
            value = "~" .. value
        end
        AddLine(tooltip, "  " .. part.label, value)
        if db.showFormula and part.formula then
            AddLine(tooltip, "    " .. part.formula, nil, MUTED_COLOR)
        end
        if db.showEffective and power > 0 and part.final > 0 then
            local gain = math.floor(part.final * power + 0.5)
            AddLine(tooltip, string.format("    +%d from %d %s", gain, power, powerLabel),
                nil, MUTED_COLOR)
        end
    end

    if result.missingLevels then
        AddLine(tooltip, string.format("  Level %d spell: scaling reduced to %d%%",
            result.spellLevel, math.floor(result.penalty * 100 + 0.5)), nil, MUTED_COLOR)
    end
    if result.aoe then
        AddLine(tooltip, "  Area spell: value is an estimate", nil, MUTED_COLOR)
    end
    if result.note then
        AddLine(tooltip, "  " .. result.note, nil, MUTED_COLOR)
    end
end

local function OnSpellTooltip(tooltip)
    if not tooltip then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    if shown[tooltip] then return end

    local name, spellID = API.GetTooltipSpell(tooltip)
    if not name then return end

    shown[tooltip] = true

    local ok, err = pcall(SCF.Render, SCF, tooltip, spellID, name)
    if not ok and not SCF.reportedError then
        SCF.reportedError = true
        print(string.format("|cff66c7ffSpellCoeffsForever|r error on %s: %s",
            tostring(name), tostring(err)))
    end
end

local function ClearGuard(tooltip)
    shown[tooltip] = nil
end

SCF.OnSpellTooltip = OnSpellTooltip

function SCF:HookTooltips()
    local targets = { GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip)
            if tooltip == GameTooltip or tooltip == ItemRefTooltip then
                OnSpellTooltip(tooltip)
            end
        end)
    else
        for _, tooltip in ipairs(targets) do
            if tooltip and tooltip.HookScript then
                tooltip:HookScript("OnTooltipSetSpell", OnSpellTooltip)
            end
        end
    end

    for _, tooltip in ipairs(targets) do
        if tooltip and tooltip.HookScript then
            tooltip:HookScript("OnTooltipCleared", ClearGuard)
            tooltip:HookScript("OnHide", ClearGuard)
        end
    end
end

------------------------------------------------------------------------------
-- Load
------------------------------------------------------------------------------

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON then return end
    SpellCoeffsForeverDB = SpellCoeffsForeverDB or {}
    for key, value in pairs(DEFAULTS) do
        if SpellCoeffsForeverDB[key] == nil then
            SpellCoeffsForeverDB[key] = value
        end
    end
    SCF.db = SpellCoeffsForeverDB
    SCF:HookTooltips()
    loader:UnregisterEvent("ADDON_LOADED")
end)

SCF.DEFAULTS = DEFAULTS
