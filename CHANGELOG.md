# Changelog

## 1.0.2

* The addon now loads on the WoW Forever beta (interface 16001) and on the
  current Classic Era client (interface 11509) instead of showing as
  incompatible.
* CurseForge releases are tagged for both Classic Era and Forever.

## 1.0.1

* Fixed an error on every spell tooltip on current Classic Era clients, where
  `GetSpellInfo` and the other spell globals have moved into the `C_Spell`
  namespace.
* All game API access now goes through a compatibility layer that works with
  either API shape and degrades quietly when a call is unavailable.
* A failure while building a tooltip is now reported once instead of erroring
  on every hover.
* Tests run against the current API, the legacy API, and a client exposing
  neither.

## 1.0.0

* Spell power coefficients added to spell tooltips in the spellbook, on action
  bars, and in chat links.
* Direct, periodic, channelled, and hybrid components reported separately.
* Values derived from the client's cast time per rank, with known spell data
  overriding the formula where it differs.
* Sub-level-20 scaling penalty applied.
* Optional line converting the coefficient to your current spell power.
* Settings via `/scf`, stored per account.
