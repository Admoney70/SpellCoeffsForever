# SpellCoeffsForever

A World of Warcraft Classic Era addon that adds spell power coefficients to spell
tooltips, so you can see how much of your +damage or +healing a given spell and
rank actually uses.

![Interface](https://img.shields.io/badge/Interface-11507-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## What it shows

Hover any spell in your spellbook, on an action bar, or in a chat link:

```
Flash Heal (Rank 1)
  Spell power coefficient
    Direct                                  0.429
      +300 from 700 healing power
```

* **Direct** — the coefficient applied on impact.
* **Over time (total)** — the coefficient spread across the whole periodic
  effect, not per tick.
* **Channel (total)** — the coefficient for a full channel.
* Hybrid spells such as Immolate or Regrowth list both components separately.

A `~` in front of a value means it was derived from the base formulas rather
than taken from known spell data.

## Installation

Install it from CurseForge, or by hand:

1. Download or clone this repository, or run `./build.sh` for a packaged zip.
2. Copy the folder into `World of Warcraft/_classic_era_/Interface/AddOns/`,
   named `SpellCoeffsForever`.
3. Restart the game, or run `/reload` if it is already running.

The folder name must match the `.toc` file name for the client to load it.

## Packaging

`./build.sh` writes `dist/SpellCoeffsForever-<version>.zip` containing a single
top-level `SpellCoeffsForever/` folder, which is the layout both the CurseForge
app and a manual install expect. Pushing a `v*` tag runs the same script and
attaches the zip to a GitHub release.

Two TOC files ship. `SpellCoeffsForever_Vanilla.toc` is the flavor file Classic
Era clients and the CurseForge packager look for first, and
`SpellCoeffsForever.toc` is the fallback for clients that do not use flavor
suffixes. Both carry the same interface version; confirm it against your client
with `/dump (select(4, GetBuildInfo()))` after a patch.

If the CurseForge app reports "Game was not found or not supported by the
application", the cause is project metadata or the app's game detection rather
than the addon:

* The project must be listed under World of Warcraft, and each uploaded file
  must be tagged with a Classic Era game version (1.15.x). A file left untagged,
  or tagged only for Retail, gives the app no flavor to install into.
* The app must have detected a Classic Era install. Check its WoW settings and
  point it at the `_classic_era_` folder if the path is missing.

## Commands

| Command          | Effect                                                    |
| ---------------- | --------------------------------------------------------- |
| `/scf`           | Show the current settings                                 |
| `/scf toggle`    | Turn the tooltip lines on or off                          |
| `/scf effective` | Toggle the line converting the coefficient to your gear   |
| `/scf formula`   | Toggle showing the cast time or duration behind the value |
| `/scf shift`     | Only show the lines while Shift is held                    |
| `/scf reset`     | Restore defaults                                          |

`/spellcoeffs` works as an alias.

## How the numbers are produced

Classic Era derives most coefficients from two base formulas:

| Component                     | Formula              |
| ----------------------------- | -------------------- |
| Direct or channelled effect   | cast time / 3.5      |
| Periodic effect               | duration / 15        |

Cast times are read from the client for the exact rank being hovered, with the
usual 1.5 second floor, so downranked spells are handled correctly. Periodic
durations, hybrid splits, and the spells Blizzard tuned away from the formula
live in `Data.lua`.

One penalty is applied on top: spells whose own level is below 20 lose 3.75%
of their scaling per level below 20, so a level 1 rank keeps 28.75%. Classic
Era does **not** have the level-based downranking penalty introduced in The
Burning Crusade, so no such penalty is applied here.

Every game API the addon reads goes through `Compat.lua`, which prefers the
`C_Spell` and `C_AddOns` namespaces used by current clients and falls back to
the old globals. When an API is missing entirely the accessor returns nothing
and the affected line is simply left out.

Two limitations are worth knowing:

* The client does not expose a spell's school in Classic, so the gear-adjusted
  line uses your highest school bonus for damage spells.
* Area spells were tuned individually in vanilla, so their values are marked as
  estimates.

The refinements in `Data.lua` are keyed by English spell names. On other locales
the formulas still apply, but those per-spell corrections are skipped.

## Tests

The coefficient maths runs outside the game against a small stub of the WoW API.
The stub can present the current `C_Spell` namespace, the older globals, or
neither, so an API rename shows up as a test failure instead of a tooltip error:

```sh
lua5.4 tests/test_coefficients.lua modern
lua5.4 tests/test_coefficients.lua legacy
lua5.4 tests/test_bare_client.lua
```

## Contributing

Corrections to `Data.lua` are the most useful contribution. Add a per-rank learn
level to `Data.rankLevels` if your client returns 0 for a spell, and add an entry
to `Data.overrides` with `exact = true` only when the value comes from spell data
rather than from the formula.

## License

MIT, see [LICENSE](LICENSE).
