# __ADDON__ — working notes

A World of Warcraft **retail** addon built from the drift-resistant template.
This file is the brain: it forces current-state research before any build, then
records the conventions and the addon-specific decisions.

## § RESEARCH FIRST (hard gate)

**Do not scaffold or write addon code until you have resolved current state from
authoritative sources. Never use this file's memory or model training for any
fact that changes between patches. Resolve, don't assume.**

1. **Interface version.** Resolve the current retail interface number and fill the
   `## Interface:` marker in `__ADDON__.toc`. Authoritative:
   https://warcraft.wiki.gg/wiki/Interface_version, or the current
   `Patch X.Y.Z/API changes` wiki page for the live retail patch, or the live
   client TOC. Never invent the number, and never copy a patch number from this file.
2. **Midnight API restrictions (Interface 12.0+).** Combat data (health, power,
   absorb) is wrapped in **Secret Values** — opaque types you cannot do arithmetic
   on. If this addon touches combat data at all, confirm what is even possible
   before designing. Source:
   https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight
3. **Ace3 current state.** Confirm the latest Ace3 and any Midnight breakages
   before using a library API. Known: `AceConfigDialog-3.0` requires a **numeric
   ID** (via `C_SettingsUtil`), not a name, as of Midnight. Verify the `.pkgmeta`
   external URLs still resolve. Source: https://www.curseforge.com/wow/addons/ace3
4. **Prior art.** Mine https://github.com/DennysOliveira/wow-addon-dev for current
   Secret Values / migration specifics when in doubt.

Record what you resolved in the addon-specific section below.

## § Conventions (verify against § RESEARCH, then apply)

- **Substitution markers.** Replace `__ADDON__`, `__AUTHOR__`, `__NOTES__`,
  `__CATEGORY__`, `__INTERFACE_VERSION__` per-addon. Note `__ADDON__` also composes
  into `__ADDON__DB` (the SavedVariables name in the `.toc`) and `chunk("__ADDON__", ns)`
  in `tests/run.lua` — a global replace of `__ADDON__` handles all of them.
- **Module/namespace pattern.** Every Lua file starts `local ADDON, ns = ...` and
  touches **no WoW globals at file scope** (so the headless tests can load it).
  Cross-module access goes through `ns`. The `.toc` load order matters: libs,
  then pure-logic modules, then `Core.lua` last.
- **Headless testing.** `lua tests/run.lua` runs pure-logic units (no WoW client).
  Syntax-check any file with `lua -e "assert(loadfile('X.lua'))"`. Everything
  visual/behavioral is confirmed by the user `/reload`-ing and screenshotting.
  Keep the tests green.
- **Libraries: resolve, don't commit.** Libs are fetched at build by `.pkgmeta`
  `externals` from canonical sources and are **gitignored**; only
  `Libs/embeds.xml` (the load manifest) is tracked. Never commit vendored library
  code, never pin a version.
- **Dev/live deploy.** Add a `deploy.sh` per-addon that rsyncs the working tree to
  the live AddOns folder and **preserves the live `Libs/`** (so a code deploy can
  never wipe the fetched libraries), then the user `/reload`s.
- **Tag-driven release.** Pushing a `vX.Y.Z` tag fires the packager
  (`.github/workflows/release.yml`) → CurseForge; `@project-version@` is
  substituted at build; tag name sets the channel (no alpha/beta ⇒ release).
- **Verify, never guess.** WoW API names, atlas/icon paths, AceConfig widths,
  library APIs: confirm against the API wiki, vendored library source, or the
  running game. If it can't be verified, say so.
- **Sounds via LibSharedMedia**, not engine `SOUNDKIT` (SOUNDKIT names are partly
  unverifiable and cause silent failures).
- **Tone/workflow.** Discuss before implementing; the user directs commits and
  releases; terse, no sycophancy; proper, concise English in UI labels.

## § Decisions & gotchas (addon-specific)

_Empty. Record per-addon Midnight findings and design decisions here so they never
leak back into the shared conventions above. Start with what § RESEARCH resolved:
the interface version you set, and any Secret Values / Ace3 constraints that shaped
this addon._
