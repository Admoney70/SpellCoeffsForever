-- Options.lua -- slash command interface.

local ADDON, SCF = ...

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66c7ffSpellCoeffsForever|r: " .. message)
end

local function Status(value)
    return value and "|cff40ff40on|r" or "|cffff4040off|r"
end

local function Usage()
    local db = SpellCoeffsForeverDB
    Print("commands:")
    Print("  /scf toggle    tooltip lines are " .. Status(db.enabled))
    Print("  /scf effective gear-adjusted line is " .. Status(db.showEffective))
    Print("  /scf formula   show the cast time or duration used: " .. Status(db.showFormula))
    Print("  /scf shift     require Shift to show: " .. Status(db.modifierOnly))
    Print("  /scf reset     restore defaults")
end

SLASH_SPELLCOEFFSFOREVER1 = "/scf"
SLASH_SPELLCOEFFSFOREVER2 = "/spellcoeffs"

SlashCmdList["SPELLCOEFFSFOREVER"] = function(input)
    local db = SpellCoeffsForeverDB
    if not db then return end
    local command = strlower(strtrim(input or ""))

    if command == "toggle" then
        db.enabled = not db.enabled
        Print("tooltip lines " .. Status(db.enabled))
    elseif command == "effective" then
        db.showEffective = not db.showEffective
        Print("gear-adjusted line " .. Status(db.showEffective))
    elseif command == "formula" then
        db.showFormula = not db.showFormula
        Print("formula line " .. Status(db.showFormula))
    elseif command == "shift" then
        db.modifierOnly = not db.modifierOnly
        Print("Shift requirement " .. Status(db.modifierOnly))
    elseif command == "reset" then
        for key, value in pairs(SCF.DEFAULTS) do
            db[key] = value
        end
        Print("settings restored to defaults")
    else
        Usage()
    end
end
