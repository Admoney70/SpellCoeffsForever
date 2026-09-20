-- Minimal stand-ins for the WoW API so the addon can be loaded and exercised
-- outside the game. Only what SpellCoeffsForever touches is provided.

local stub = {}

stub.spells = {}      -- [spellID] = { name, castMs, level }
stub.spellPower = { damage = 0, healing = 0 }
stub.shift = false

-- mode "modern" exposes only the C_Spell / C_AddOns namespaces, as current
-- Classic Era clients do. mode "legacy" exposes only the old globals. mode
-- "none" exposes neither, standing in for a client that renamed them again.
function stub.install(mode)
    mode = mode or "modern"
    stub.mode = mode

    local function castTime(spellID)
        local spell = stub.spells[spellID]
        return spell and spell.castMs or 0
    end

    local function spellLevel(spellID)
        local spell = stub.spells[spellID]
        return spell and spell.level or 0
    end

    local function bonusDamage(school)
        return school == 6 and stub.spellPower.damage or 0
    end

    _G.GetAddOnMetadata, _G.GetSpellInfo, _G.GetSpellLevelLearned = nil, nil, nil
    _G.GetSpellBonusDamage, _G.GetSpellBonusHealing = nil, nil
    _G.C_Spell, _G.C_AddOns = nil, nil

    if mode == "modern" then
        _G.C_AddOns = { GetAddOnMetadata = function() return "test" end }
        _G.C_Spell = {
            GetSpellInfo = function(spellID)
                local spell = stub.spells[spellID]
                if not spell then return nil end
                return { name = spell.name, castTime = spell.castMs }
            end,
            GetSpellLevelLearned = spellLevel,
            GetSpellBonusDamage = bonusDamage,
            GetSpellBonusHealing = function() -- Drives the same entry point the game calls when a spell tooltip is built.
function stub.fireSpellTooltip(tooltip)
    assert(stub.onSpellTooltip, "tooltip hook was not captured")
    stub.onSpellTooltip(tooltip)
end

return stub.spellPower.healing end,
        }
    elseif mode == "legacy" then
        _G.GetAddOnMetadata = function() return "test" end
        _G.GetSpellInfo = function(spellID)
            local spell = stub.spells[spellID]
            if not spell then return nil end
            return spell.name, nil, nil, castTime(spellID)
        end
        _G.GetSpellLevelLearned = spellLevel
        _G.GetSpellBonusDamage = bonusDamage
        _G.GetSpellBonusHealing = function() -- Drives the same entry point the game calls when a spell tooltip is built.
function stub.fireSpellTooltip(tooltip)
    assert(stub.onSpellTooltip, "tooltip hook was not captured")
    stub.onSpellTooltip(tooltip)
end

return stub.spellPower.healing end
    end

    _G.IsShiftKeyDown = function() -- Drives the same entry point the game calls when a spell tooltip is built.
function stub.fireSpellTooltip(tooltip)
    assert(stub.onSpellTooltip, "tooltip hook was not captured")
    stub.onSpellTooltip(tooltip)
end

return stub.shift end
    _G.print = print

    _G.CreateFrame = function()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:UnregisterEvent() end
        function frame:SetScript(_, handler) frame.handler = handler end
        function frame:HookScript() end
        stub.frame = frame
        return frame
    end

    _G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) stub.lastMessage = message end }
    _G.SlashCmdList = {}
    _G.strlower = string.lower
    _G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
    _G.GameTooltip, _G.ItemRefTooltip = nil, nil
    _G.TooltipDataProcessor, _G.Enum = nil, nil
end

-- Collects the lines the addon would add to a tooltip.
function stub.newTooltip(spellID)
    local tooltip = { lines = {} }
    function tooltip:GetSpell()
        local spell = spellID and stub.spells[spellID]
        if not spell then return nil end
        return spell.name, spellID
    end
    function tooltip:IsForbidden() return false end
    function tooltip:AddLine(text) self.lines[#self.lines + 1] = { text } end
    function tooltip:AddDoubleLine(left, right) self.lines[#self.lines + 1] = { left, right } end
    return tooltip
end

function stub.load()
    local SCF = {}
    for _, file in ipairs({ "Compat.lua", "Data.lua", "Core.lua", "Options.lua" }) do
        assert(loadfile(file))("SpellCoeffsForever", SCF)
    end
    _G.SpellCoeffsForeverDB = nil
    stub.frame.handler(stub.frame, "ADDON_LOADED", "SpellCoeffsForever")
    stub.onSpellTooltip = SCF.OnSpellTooltip
    return SCF
end

-- Drives the same entry point the game calls when a spell tooltip is built.
function stub.fireSpellTooltip(tooltip)
    assert(stub.onSpellTooltip, "tooltip hook was not captured")
    stub.onSpellTooltip(tooltip)
end

return stub
