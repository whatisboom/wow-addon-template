# WoW Addon Template (Midnight-era, drift-resistant) — Design

**Date:** 2026-06-18
**Status:** Approved design, pending implementation plan
**Note:** This is the genesis spec for a **separate** repo (`wow-addon-template`),
written here because this is the established specs home. It travels to the new
repo's `docs/` once that repo is created.

## Context

We build multiple WoW retail addons (VaultTracker, DEFunnel, EnchantCheck,
SpillAura). Each one re-derives the same scaffolding by hand — the
namespace/module pattern, the headless Lua test harness, locale setup, `.pkgmeta`
library embedding, the tag-driven CurseForge release flow, the dev/live
`deploy.sh` split — and that hand-copying drifts. We want a **GitHub template
repo** so a new addon starts off the ground instead of from a blank file.

Two forces shape the design:

1. **Drift is the enemy, on four axes** (all in scope): WoW patch / interface
   version, library versions, boilerplate between addons, and best-practice /
   convention drift.
2. **Midnight (Interface 12.0.x) moved the ground.** The model's training cannot
   be trusted for current addon practice, so the template must not bake
   War Within-era assumptions. Verified findings:
   - **Secret Values:** combat data (health, power, absorb) is wrapped in opaque
     types you cannot do arithmetic on — combat is a black box. WeakAuras is
     **discontinued on retail** as of 12.0; DBM/BigWigs/Plater heavily curtailed.
     ([Blizzard: Addon Disarmament](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight))
   - **Ace3 changed for Midnight:** `AceConfigDialog-3.0` now requires a **numeric
     ID** (new `C_SettingsUtil` API), not a name. Latest Ace3 is `Release-r1390`
     (2026-02-03). ([CurseForge Ace3](https://www.curseforge.com/wow/addons/ace3))
   - **Authoritative version source exists:** Warcraft Wiki
     [`Patch 12.0.x/API changes`](https://warcraft.wiki.gg/wiki/Patch_12.0.7/API_changes).
   - **Prior art to mine:** [`DennysOliveira/wow-addon-dev`](https://github.com/DennysOliveira/wow-addon-dev)
     — Claude Code skills for Midnight 12.0+ Secret Values, API migration, templates.

The intended outcome: a barebones, testable Lua skeleton whose **CLAUDE.md is the
real product** — a brain that forces a future Claude to *research current state
before building*, so the template stays correct across patches it cannot predict.

## Governing principle: *resolve, don't assume*

The template never ships a **frozen snapshot of a truth that rots**. It ships
**mechanisms that resolve the truth from an authoritative source** when needed.

| Thing that drifts | ❌ Assumption | ✅ Resolve |
|---|---|---|
| Interface version | Hardcode `## Interface: 120007` | Resolved on setup from the live API / wiki patch page; `.toc` ships an unresolved marker, never a baked number |
| Library versions | Commit vendored Ace3 | `.pkgmeta` externals fetch canonical trunk at build; never committed |
| Addon identity | Hand-edit a name across files | One setup pass substitutes `__ADDON__` from a single input |
| Conventions / API reality | A README that ages | `CLAUDE.md` research gate + living conventions; addon-specifics stay out |

Litmus test for anything added to the template: *is this an assumed fact, or a
mechanism that fetches the fact?* If it's an assumed fact that can change, it
becomes a resolver or an explicit unresolved marker instead.

## Decision: no scripts — CLAUDE.md drives setup

Setup (substitute tokens, resolve interface version, verify Ace3 gotchas, drop in
per-addon modules) is a **documented procedure in CLAUDE.md that Claude executes**
on a fresh clone — not a bash/Lua generator. Rationale:

- The user works in Claude Code; the brain belongs where Claude reads it.
- A committed generator script is itself a frozen snapshot that drifts and bakes
  assumptions (e.g. a hardcoded interface source) — the opposite of the principle.
- Setup is research-dependent (it must read current API state), which is Claude's
  job, not a script's.

## Scope

### Committed (barebones — the durable skeleton)

```
addon-template/
├── __ADDON__.toc          # name token; ## Interface line is an UNRESOLVED marker
├── Core.lua               # minimal: `local ADDON, ns = ...`; AceAddon bootstrap stub
├── Logic.lua              # one pure-logic example fn (no WoW globals at file scope)
├── tests/
│   ├── run.lua            # the reusable asset: ns loader, eq(), AceLocale shim, sample test
│   └── fixtures.lua       # data builders
├── .pkgmeta               # externals (canonical trunk URLs, never pinned) + ignore
├── Libs/embeds.xml        # the only tracked file under Libs/
├── .github/workflows/release.yml   # tag-driven CurseForge packaging
├── .gitignore             # Libs/* except embeds.xml; .DS_Store; etc.
└── CLAUDE.md              # the brain (the actual product)
```

### NOT committed (built per-addon, after research)

Broker, Roster, Scanner, Config, locale tables beyond a stub. Reason: Midnight
changed what UI/config patterns are valid (e.g. the AceConfig numeric-ID break),
so shipping pre-baked UI would ship stale assumptions. These are generated
per-addon under CLAUDE.md guidance once research confirms current practice. The
**test harness is the real inheritance.**

## The test harness (carried from VaultTracker `tests/run.lua`)

The harness is the proven, reusable core. It stays dependency-free pure Lua:

- **ns loader:** `loadfile(path)` then `chunk("AddonName", ns)` — mirrors how the
  `.toc` feeds varargs, so cross-module references work headlessly. This **forces**
  the convention every module file starts `local ADDON, ns = ...` and touches no
  WoW globals at file scope.
- **`eq(actual, expected, msg)`** assertion with pass/fail counters.
- **AceLocale shim** so locale files load outside the game.
- **Exit code** `os.exit(failed == 0 and 0 or 1)` for CI.
- Ships with **one sample passing test** over `Logic.lua` proving the path is green.

Run: `lua tests/run.lua`. Syntax-check any file: `lua -e "assert(loadfile('X.lua'))"`.

## `.pkgmeta` (libraries: resolve, don't commit)

`externals` fetch the Ace3 family + LibStub + CallbackHandler from the canonical
WowAce trunk, plus LibDataBroker / LibDBIcon / LibSharedMedia from their official
homes — at build time, never committed. Only `Libs/embeds.xml` (the load manifest)
is tracked. `ignore` keeps dev files (`docs`, `tests`, `CLAUDE.md`, `deploy.sh`)
out of the package. **Setup must verify these external URLs still resolve** (per
the research gate) rather than trusting this file's copy.

## CLAUDE.md structure (the product)

### § RESEARCH FIRST (hard gate)

Before scaffolding or writing any addon code, resolve current state from
**authoritative sources** — never from this file's memory or model training:

1. **Interface version** → live API / Warcraft Wiki `Patch 12.0.x/API changes`;
   fill the `.toc` marker. Never invent a number.
2. **Midnight API restrictions for this addon's domain** → Secret Values black-box
   rules. If the addon touches combat data at all, confirm what is even possible
   before designing around it.
3. **Ace3 current gotchas** → e.g. numeric `AceConfigDialog` IDs; latest release;
   confirm `.pkgmeta` external URLs resolve.
4. Restate *resolve, don't assume* as law; this section is its enforcement.

### § Conventions (verify-then-apply)

Graduated general wisdom from VaultTracker's CLAUDE.md, each framed as "confirm
still valid against §1 research": ns/module pattern and `.toc` load order;
headless test approach (`lua tests/run.lua`, `loadfile` syntax checks,
visual/behavioral confirmed by user `/reload`+screenshot); dev/live `deploy.sh`
rsync split that preserves the live `Libs/`; tag-driven release
(`vX.Y.Z` → packager → CurseForge, `@project-version@` substitution, channel from
tag name); libraries embedded-not-committed; **verify, never guess**; sounds via
LibSharedMedia not engine SOUNDKIT; tone (discuss before implementing, user
directs commits/releases, terse, no sycophancy).

Explicitly **excluded** (VaultTracker-specific, must not graduate): eligibility/
seriousness tier logic, specific vault events, async re-scan timing, CurseForge
project ID, the concrete interface number, the deferred backlog.

### § Decisions & gotchas (addon-specific)

Empty, labeled — where per-addon Midnight findings accumulate so they never leak
back into the shared conventions.

## Open items to resolve during build (not assumed now)

- The exact authoritative source + method for the **current retail interface
  version** (candidates: live API resolution, Warcraft Wiki patch page) — confirm
  one actually resolves before writing it into the procedure.
- Mine [`DennysOliveira/wow-addon-dev`](https://github.com/DennysOliveira/wow-addon-dev)
  for concrete Secret Values / migration checklist items worth citing in §RESEARCH.
- Confirm current Ace3 `.pkgmeta` external URLs resolve and capture any other
  Midnight Ace3 breakages beyond the numeric-ID change.

## Verification

- **Skeleton is green:** fresh clone → `lua tests/run.lua` prints `1 passed, 0 failed`.
- **Syntax:** `lua -e "assert(loadfile('Core.lua'))"` and same for `Logic.lua`.
- **Setup walkthrough:** Claude follows §RESEARCH + setup on a throwaway clone;
  result has a resolved `## Interface:` line (matching the verified current
  version), substituted name across all files, and still-green tests.
- **No baked assumptions audit:** grep the committed tree for any hardcoded
  interface number or pinned library version — there should be none outside an
  explicitly-marked unresolved placeholder.

## Out of scope

- Pre-built Broker/Roster/Scanner/Config modules (built per-addon).
- A generator CLI or bootstrap scripts (setup is a CLAUDE.md procedure).
- Retrofitting existing addons (VaultTracker et al.) onto the template — possible
  later, not part of this work.
- Multi-flavor (Classic/Cata) `.toc` variants — retail-only for now.
</content>
</invoke>
