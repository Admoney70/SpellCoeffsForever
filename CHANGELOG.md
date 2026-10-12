# Changelog

## 1.0.2

* Added `SpellCoeffsForever_Vanilla.toc`, the flavor file Classic Era clients
  and the CurseForge packager look for before the plain TOC name, so uploads
  are matched to Classic Era rather than left without a flavor.
* Added `build.sh` and a release workflow producing a zip with the single
  top-level addon folder the CurseForge app expects.
* Raised the declared interface version to 11509.

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
