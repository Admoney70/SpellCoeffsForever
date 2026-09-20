-- Run from the addon root: lua5.4 tests/test_coefficients.lua

local stub = dofile("tests/wow_stub.lua")
stub.install()

stub.spells = {
    [116]   = { name = "Frostbolt",          castMs = 3000, level = 4 },
    [133]   = { name = "Fireball",           castMs = 3500, level = 1 },
    [686]   = { name = "Shadow Bolt",        castMs = 3000, level = 1 },
    [172]   = { name = "Corruption",         castMs = 2000, level = 4 },
    [2054]  = { name = "Heal",               castMs = 3000, level = 16 },
    [2061]  = { name = "Flash Heal",         castMs = 1500, level = 20 },
    [139]   = { name = "Renew",              castMs = 0,    level = 8 },
    [8936]  = { name = "Regrowth",           castMs = 2000, level = 12 },
    [1949]  = { name = "Hellfire",           castMs = 0,    level = 30 },
    [1454]  = { name = "Life Tap",           castMs = 0,    level = 6 },
    [10938] = { name = "Power Word: Fortitude", castMs = 0,  level = 48 },
}

local SCF = stub.load()

local failures, checks = 0, 0

local function check(label, actual, expected)
    checks = checks + 1
    local ok
    if type(expected) == "number" then
        ok = actual and math.abs(actual - expected) < 0.0005
    else
        ok = actual == expected
    end
    if not ok then
        failures = failures + 1
        print(string.format("FAIL %s: got %s, expected %s",
            label, tostring(actual), tostring(expected)))
    end
end

local function part(spellID, index)
    local name = select(1, GetSpellInfo(spellID))
    local result = SCF:GetCoefficients(spellID, name)
    return result, result and result.parts[index]
end

-- Known values override the formula.
local _, frostbolt = part(116, 1)
check("Frostbolt base", frostbolt.base, 0.8143)
check("Frostbolt is exact", frostbolt.exact, true)

local _, shadowbolt = part(686, 1)
check("Shadow Bolt base", shadowbolt.base, 0.8571)
check("Shadow Bolt rank 1 penalty", shadowbolt.final, 0.8571 * (1 - 19 * 0.0375))

-- Fireball's periodic component is explicitly non-scaling.
local fireball = part(133, 1)
check("Fireball direct", fireball.parts[1].base, 1.0)
check("Fireball periodic", fireball.parts[2].base, 0)

-- Periodic totals.
local _, corruption = part(172, 1)
check("Corruption periodic", corruption.base, 1.2)
local _, renew = part(139, 1)
check("Renew periodic", renew.base, 1.0)

-- Hybrid healing splits.
local regrowth = part(8936, 1)
check("Regrowth direct", regrowth.parts[1].base, 0.3429)
check("Regrowth periodic", regrowth.parts[2].base, 0.5143)

-- The sub-level-20 penalty scales the final value, not the base value.
local renewResult = part(139, 1)
check("Renew level penalty", renewResult.penalty, 1 - 12 * 0.0375)
check("Renew final", renewResult.parts[1].final, 1.0 * (1 - 12 * 0.0375))
check("Renew missing levels", renewResult.missingLevels, 12)

local flash = part(2061, 1)
check("Flash Heal has no penalty", flash.penalty, 1)
check("Flash Heal missing levels", flash.missingLevels, nil)

-- Channels use the channel duration from the data table.
local _, hellfire = part(1949, 1)
check("Hellfire channel", hellfire.base, 15 / 3.5)

-- Formula fallback for a spell with no override: Heal at 3.0s cast.
local heal = part(2054, 1)
check("Heal effect", heal.effect, "healing")

-- Spells that do not scale with spell power produce nothing.
check("Life Tap ignored", part(1454, 1), nil)
check("Buff ignored", part(10938, 1), nil)

-- Effective-value reporting picks the right stat.
stub.spellPower.damage, stub.spellPower.healing = 500, 700
local power, label = SCF:GetSpellPower("damage")
check("damage power", power, 500)
check("damage label", label, "spell damage")
power, label = SCF:GetSpellPower("healing")
check("healing power", power, 700)
check("healing label", label, "healing power")

-- Tooltip rendering emits a header plus one line per component.
local tooltip = stub.newTooltip()
SpellCoeffsForeverDB.showEffective = false
SCF:Render(tooltip, 2061, "Flash Heal")
check("tooltip header", tooltip.lines[1][1], "Spell power coefficient")
check("tooltip value", tooltip.lines[2][2], "0.429")

-- The Shift-only option suppresses output until Shift is held.
tooltip = stub.newTooltip()
SpellCoeffsForeverDB.modifierOnly = true
SCF:Render(tooltip, 2061, "Flash Heal")
check("hidden without shift", #tooltip.lines, 0)
stub.shift = true
SCF:Render(tooltip, 2061, "Flash Heal")
check("shown with shift", #tooltip.lines > 0, true)

print(string.format("%d checks, %d failures", checks, failures))
os.exit(failures == 0 and 0 or 1)
