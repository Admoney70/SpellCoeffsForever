-- Minimal stand-ins for the WoW API so the addon can be loaded and exercised
-- outside the game. Only what SpellCoeffsForever touches is provided.

local stub = {}

stub.spells = {}      -- [spellID] = { name, castMs, level }
stub.spellPower = { damage = 0, healing = 0 }
stub.shift = false

function stub.install()
    _G.GetAddOnMetadata = function() return "test" end

    _G.GetSpellInfo = function(spellID)
        local spell = stub.spells[spellID]
        if not spell then return nil end
        return spell.name, nil, nil, spell.castMs
    end

    _G.GetSpellLevelLearned = function(spellID)
        local spell = stub.spells[spellID]
        return spell and spell.level or 0
    end

    _G.GetSpellBonusDamage = function(school)
        return school == 6 and stub.spellPower.damage or 0
    end

    _G.GetSpellBonusHealing = function() return stub.spellPower.healing end

    _G.IsShiftKeyDown = function() return stub.shift end

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
function stub.newTooltip()
    local tooltip = { lines = {} }
    function tooltip:IsForbidden() return false end
    function tooltip:AddLine(text) self.lines[#self.lines + 1] = { text } end
    function tooltip:AddDoubleLine(left, right) self.lines[#self.lines + 1] = { left, right } end
    return tooltip
end

function stub.load()
    local SCF = {}
    for _, file in ipairs({ "Data.lua", "Core.lua", "Options.lua" }) do
        assert(loadfile(file))("SpellCoeffsForever", SCF)
    end
    _G.SpellCoeffsForeverDB = nil
    stub.frame.handler(stub.frame, "ADDON_LOADED", "SpellCoeffsForever")
    return SCF
end

return stub
