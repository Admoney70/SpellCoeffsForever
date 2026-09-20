-- Data.lua -- static spell knowledge for SpellCoeffsForever.
--
-- The addon derives most coefficients from the two vanilla base formulas:
--   direct / channelled damage or healing : castTime / 3.5
--   periodic damage or healing            : duration / 15
-- Cast times come from the client at runtime, so they are always correct for
-- the exact rank the player is hovering. Everything the formulas cannot know
-- (a spell's periodic duration, how a hybrid spell splits its coefficient, and
-- the handful of spells Blizzard tuned away from the formula) lives here.

local ADDON, SCF = ...

SCF.Data = SCF.Data or {}
local Data = SCF.Data

-- Base cast time (seconds) used by the direct formula, and the divisors.
Data.MIN_CAST_TIME = 1.5
Data.DIRECT_DIVISOR = 3.5
Data.PERIODIC_DIVISOR = 15.0

-- The level-20 scaling penalty and the downranking penalty.
Data.LOW_LEVEL_PENALTY_PER_LEVEL = 0.0375
Data.LOW_LEVEL_THRESHOLD = 20
Data.DOWNRANK_BONUS_LEVELS = 6
Data.MAX_PLAYER_LEVEL = 60

-- kind:
--   "direct"    single burst of damage or healing on impact
--   "periodic"  damage or healing over time only
--   "hybrid"    both an impact component and a periodic component
--   "channel"   damage or healing ticked out over the channel
-- effect: "damage" or "healing" (drives which spell power stat we report)
-- duration: periodic duration in seconds
-- channel: full channel time in seconds, when it differs from the cast time
-- aoe: true when the spell hits several targets (vanilla tuned most of these
--      below the formula, so they are reported as estimates)
--
-- Keys are enUS spell names. On other clients the formulas still apply; only
-- these per-spell refinements are skipped.
Data.spells = {
    -- Mage ---------------------------------------------------------------
    ["Fireball"]            = { kind = "hybrid",   effect = "damage", duration = 8 },
    ["Frostbolt"]           = { kind = "direct",   effect = "damage" },
    ["Fire Blast"]          = { kind = "direct",   effect = "damage" },
    ["Scorch"]              = { kind = "direct",   effect = "damage" },
    ["Pyroblast"]           = { kind = "hybrid",   effect = "damage", duration = 12 },
    ["Frost Nova"]          = { kind = "direct",   effect = "damage", aoe = true },
    ["Cone of Cold"]        = { kind = "direct",   effect = "damage", aoe = true },
    ["Arcane Missiles"]     = { kind = "channel",  effect = "damage" },
    ["Arcane Explosion"]    = { kind = "direct",   effect = "damage", aoe = true },
    ["Blizzard"]            = { kind = "channel",  effect = "damage", channel = 8, aoe = true },
    ["Flamestrike"]         = { kind = "hybrid",   effect = "damage", duration = 8, aoe = true },
    ["Blast Wave"]          = { kind = "direct",   effect = "damage", aoe = true },

    -- Warlock ------------------------------------------------------------
    ["Shadow Bolt"]         = { kind = "direct",   effect = "damage" },
    ["Searing Pain"]        = { kind = "direct",   effect = "damage" },
    ["Soul Fire"]           = { kind = "direct",   effect = "damage" },
    ["Shadowburn"]          = { kind = "direct",   effect = "damage" },
    ["Immolate"]            = { kind = "hybrid",   effect = "damage", duration = 15 },
    ["Corruption"]          = { kind = "periodic", effect = "damage", duration = 18 },
    ["Curse of Agony"]      = { kind = "periodic", effect = "damage", duration = 24 },
    ["Siphon Life"]         = { kind = "periodic", effect = "damage", duration = 30 },
    ["Drain Life"]          = { kind = "channel",  effect = "damage", channel = 5 },
    ["Drain Soul"]          = { kind = "channel",  effect = "damage", channel = 15 },
    ["Death Coil"]          = { kind = "direct",   effect = "damage" },
    ["Hellfire"]            = { kind = "channel",  effect = "damage", channel = 15, aoe = true },
    ["Rain of Fire"]        = { kind = "channel",  effect = "damage", channel = 8, aoe = true },
    ["Health Funnel"]       = { kind = "channel",  effect = "healing", channel = 10 },

    -- Priest -------------------------------------------------------------
    ["Smite"]               = { kind = "direct",   effect = "damage" },
    ["Holy Fire"]           = { kind = "hybrid",   effect = "damage", duration = 10 },
    ["Mind Blast"]          = { kind = "direct",   effect = "damage" },
    ["Mind Flay"]           = { kind = "channel",  effect = "damage", channel = 3 },
    ["Shadow Word: Pain"]   = { kind = "periodic", effect = "damage", duration = 18 },
    ["Devouring Plague"]    = { kind = "periodic", effect = "damage", duration = 24 },
    ["Holy Nova"]           = { kind = "direct",   effect = "damage", aoe = true },
    ["Lesser Heal"]         = { kind = "direct",   effect = "healing" },
    ["Heal"]                = { kind = "direct",   effect = "healing" },
    ["Greater Heal"]        = { kind = "direct",   effect = "healing" },
    ["Flash Heal"]          = { kind = "direct",   effect = "healing" },
    ["Renew"]               = { kind = "periodic", effect = "healing", duration = 15 },
    ["Prayer of Healing"]   = { kind = "direct",   effect = "healing", aoe = true },

    -- Druid --------------------------------------------------------------
    ["Wrath"]               = { kind = "direct",   effect = "damage" },
    ["Starfire"]            = { kind = "direct",   effect = "damage" },
    ["Moonfire"]            = { kind = "hybrid",   effect = "damage", duration = 12 },
    ["Insect Swarm"]        = { kind = "periodic", effect = "damage", duration = 12 },
    ["Hurricane"]           = { kind = "channel",  effect = "damage", channel = 10, aoe = true },
    ["Healing Touch"]       = { kind = "direct",   effect = "healing" },
    ["Regrowth"]            = { kind = "hybrid",   effect = "healing", duration = 21 },
    ["Rejuvenation"]        = { kind = "periodic", effect = "healing", duration = 12 },
    ["Tranquility"]         = { kind = "channel",  effect = "healing", channel = 10, aoe = true },

    -- Shaman -------------------------------------------------------------
    ["Lightning Bolt"]      = { kind = "direct",   effect = "damage" },
    ["Chain Lightning"]     = { kind = "direct",   effect = "damage" },
    ["Earth Shock"]         = { kind = "direct",   effect = "damage" },
    ["Frost Shock"]         = { kind = "direct",   effect = "damage" },
    ["Flame Shock"]         = { kind = "hybrid",   effect = "damage", duration = 12 },
    ["Healing Wave"]        = { kind = "direct",   effect = "healing" },
    ["Lesser Healing Wave"] = { kind = "direct",   effect = "healing" },
    ["Chain Heal"]          = { kind = "direct",   effect = "healing" },

    -- Paladin ------------------------------------------------------------
    ["Holy Light"]          = { kind = "direct",   effect = "healing" },
    ["Flash of Light"]      = { kind = "direct",   effect = "healing" },
    ["Holy Shock"]          = { kind = "direct",   effect = "healing" },
    ["Consecration"]        = { kind = "periodic", effect = "damage", duration = 8, aoe = true },
    ["Holy Wrath"]          = { kind = "direct",   effect = "damage", aoe = true },
    ["Exorcism"]            = { kind = "direct",   effect = "damage" },
}

-- Coefficients Blizzard set away from the formula, or splits the formula
-- cannot derive. `exact = true` marks a value taken from the spell data rather
-- than estimated, so the tooltip can say so.
--
-- direct   coefficient applied to the impact component
-- periodic coefficient applied to the whole periodic component
Data.overrides = {
    -- Frostbolt and the other spells carrying a movement-slowing effect pay a
    -- 5% coefficient tax: 3.0 / 3.5 * 0.95.
    ["Frostbolt"]        = { direct = 0.8143, exact = true,
                             note = "5% reduction for the slow effect" },
    -- Fireball's periodic component does not scale with spell power at all.
    ["Fireball"]         = { direct = 1.0, periodic = 0, exact = true,
                             note = "periodic component does not scale" },
    ["Pyroblast"]        = { direct = 1.0, periodic = 0.15, exact = true },
    ["Shadow Bolt"]      = { direct = 0.8571, exact = true },
    ["Searing Pain"]     = { direct = 0.4286, exact = true },
    ["Immolate"]         = { direct = 0.2, periodic = 0.65, exact = true },
    ["Corruption"]       = { periodic = 1.2, exact = true },
    ["Lightning Bolt"]   = { direct = 0.8571, exact = true },
    ["Chain Lightning"]  = { direct = 0.7143, exact = true,
                             note = "jumps deal reduced damage" },
    ["Healing Wave"]     = { direct = 0.8571, exact = true },
    ["Lesser Healing Wave"] = { direct = 0.4286, exact = true },
    ["Holy Light"]       = { direct = 0.8571, exact = true },
    ["Flash of Light"]   = { direct = 0.4286, exact = true },
    ["Greater Heal"]     = { direct = 0.8571, exact = true },
    ["Heal"]             = { direct = 0.8571, exact = true },
    ["Flash Heal"]       = { direct = 0.4286, exact = true },
    ["Renew"]            = { periodic = 1.0, exact = true },
    ["Rejuvenation"]     = { periodic = 1.0, exact = true },
    ["Healing Touch"]    = { direct = 0.8571, exact = true },
    ["Regrowth"]         = { direct = 0.3429, periodic = 0.5143, exact = true },
    ["Chain Heal"]       = { direct = 0.7143, exact = true,
                             note = "jumps heal for less" },
    ["Shadow Word: Pain"] = { periodic = 1.2, exact = true },
    ["Devouring Plague"] = { periodic = 1.2, exact = true },
}

-- Optional per-rank learn levels, keyed by spell ID, for clients where
-- GetSpellLevelLearned is unavailable or returns 0. The addon asks the client
-- first and only falls back to this table, so it ships empty rather than
-- risking stale numbers. Format:
--   Data.rankLevels[116] = 4   -- Frostbolt (Rank 2) is learned at level 4
Data.rankLevels = {}

function Data:GetSpell(name)
    return name and self.spells[name] or nil
end

function Data:GetOverride(name)
    return name and self.overrides[name] or nil
end
