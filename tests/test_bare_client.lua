local stub = dofile("tests/wow_stub.lua")
stub.install("none")
stub.spells = { [8938] = { name = "Regrowth", castMs = 2000, level = 12 } }
local SCF = stub.load()
-- No spell API at all: the addon must stay silent instead of erroring.
assert(SCF.API.GetCastTime(8938) == nil)
assert(SCF.API.GetSpellName(8938) == nil)
assert(SCF.API.GetSpellLevel(8938) == nil)
assert(SCF.API.GetSpellBonusHealing() == 0)
local tooltip = stub.newTooltip(8938)
stub.fireSpellTooltip(tooltip)
-- Name still comes from the tooltip itself, so the formula path is used.
local result = SCF:GetCoefficients(8938, "Regrowth")
assert(result and result.parts[1].base == 0.3429, "override should still apply")
assert(result.penalty == 1, "unknown level means no penalty")
print("bare-client checks passed, tooltip lines: " .. #tooltip.lines)
