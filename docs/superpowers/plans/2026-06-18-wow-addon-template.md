# WoW Addon Template (Midnight-era, drift-resistant) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a GitHub template repo (`wow-addon-template`) — a barebones, headlessly-testable Lua skeleton whose `CLAUDE.md` forces current-state research before any addon is built, so the template never bakes stale WoW-patch or library assumptions.

**Architecture:** Commit only the durable skeleton (namespace module pattern + the pure-Lua test harness + `.pkgmeta` library resolution + tag-driven release CI). The real product is `CLAUDE.md`, structured as RESEARCH-FIRST → Conventions → addon-specific. UI/config modules are NOT committed — they are built per-addon after the research gate confirms current Midnight practice (e.g. Secret Values, numeric AceConfig IDs).

**Tech Stack:** Lua 5.4 (`/opt/homebrew/bin/lua`), Ace3 family + LibDataBroker/LibDBIcon/LibSharedMedia (resolved at build via `.pkgmeta` externals, never committed), BigWigs packager + CurseForge, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-06-18-wow-addon-template-design.md`

**Governing principle (applies to every task):** *Resolve, don't assume.* Never commit a hardcoded interface number or a pinned library version. Anything that rots ships as an explicit unresolved marker or a resolver instruction in `CLAUDE.md`.

---

## File Structure

| File | Responsibility |
|---|---|
| `__ADDON__.toc` | Load manifest; name + `## Interface:` ship as **unresolved markers** |
| `Core.lua` | AceAddon bootstrap stub; `local ADDON, ns = ...`; runs only in-client |
| `Logic.lua` | Pure-logic example (no WoW globals) — proves the test path |
| `tests/run.lua` | The reusable asset: ns loader, `eq()`, AceLocale shim, sample test |
| `tests/fixtures.lua` | Test data builders |
| `.pkgmeta` | `externals` (canonical trunk URLs) + `ignore`; library resolution |
| `Libs/embeds.xml` | Only tracked file under `Libs/`; in-client load manifest for libs |
| `.gitignore` | Ignore `Libs/*` except `embeds.xml` |
| `.github/workflows/release.yml` | Tag-driven CurseForge packaging |
| `.github/workflows/test.yml` | Runs `lua tests/run.lua` on push (keep-green) |
| `CLAUDE.md` | **The product:** RESEARCH-FIRST gate, conventions, addon-specific section |
| `README.md` | Human-facing: "Use this template, then ask Claude to set it up" |

---

## Task 1: Initialize the template repo

**Files:**
- Create: `~/projects/wow-addon-template/` (new git repo)

- [ ] **Step 1: Create the repo directory and init git**

Run:
```bash
mkdir -p ~/projects/wow-addon-template && git -C ~/projects/wow-addon-template init
```
Expected: `Initialized empty Git repository in .../wow-addon-template/.git/`

- [ ] **Step 2: Create the `tests/` and `Libs/` and workflow directories**

Run:
```bash
mkdir -p ~/projects/wow-addon-template/tests ~/projects/wow-addon-template/Libs ~/projects/wow-addon-template/.github/workflows
```
Expected: no output (directories created).

- [ ] **Step 3: Commit the empty scaffold marker**

Create `~/projects/wow-addon-template/.gitkeep` (empty), then:
```bash
cd ~/projects/wow-addon-template && git add .gitkeep && git commit -m "chore: initialize template repo"
```
Expected: one file committed.

---

## Task 2: Test harness + `Logic.lua` (TDD)

The harness is the durable core. Build it test-first so the sample test drives the module path.

**Files:**
- Create: `~/projects/wow-addon-template/tests/fixtures.lua`
- Create: `~/projects/wow-addon-template/tests/run.lua`
- Create: `~/projects/wow-addon-template/Logic.lua`

- [ ] **Step 1: Write the fixtures**

Create `tests/fixtures.lua`:
```lua
-- Reusable test data builders. Load with dofile; returns a table.
local F = {}

function F.numbers()
  return { 1, 2, 3 }
end

return F
```

- [ ] **Step 2: Write the failing test harness**

Create `tests/run.lua`:
```lua
-- Headless unit test harness. Pure Lua 5.4, no WoW client.
-- Loads modules the way the .toc feeds varargs: chunk("AddonName", ns).
local passed, failed = 0, 0
local function eq(actual, expected, msg)
  if actual == expected then
    passed = passed + 1
  else
    failed = failed + 1
    print(("FAIL: %s\n  expected %s, got %s"):format(msg, tostring(expected), tostring(actual)))
  end
end

-- Minimal LibStub/AceLocale shim so locale files (added per-addon) load headlessly.
_G.LibStub = _G.LibStub or setmetatable({}, {
  __call = function(_, name)
    if name == "AceLocale-3.0" then
      return {
        NewLocale = function() return setmetatable({}, { __newindex = function() end }) end,
        GetLocale = function() return setmetatable({}, { __index = function(_, k) return k end }) end,
      }
    end
  end,
})

local function loadModule(path, ns)
  local chunk = assert(loadfile(path))
  return chunk("__ADDON__", ns)
end

local ns = {}
loadModule("Logic.lua", ns)

local Logic = ns.Logic
local F = dofile("tests/fixtures.lua")

-- Sample tests proving the harness + module path is green.
eq(Logic.sum(F.numbers()), 6, "Logic.sum adds the fixture list")
eq(Logic.clamp(5, 0, 3), 3, "Logic.clamp caps at max")
eq(Logic.clamp(-1, 0, 3), 0, "Logic.clamp floors at min")
eq(Logic.clamp(2, 0, 3), 2, "Logic.clamp passes through in-range")

print(("\n%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
```

- [ ] **Step 3: Run the test to verify it fails**

Run:
```bash
cd ~/projects/wow-addon-template && /opt/homebrew/bin/lua tests/run.lua
```
Expected: FAIL — `cannot open Logic.lua` (assertion in `loadfile`), non-zero exit.

- [ ] **Step 4: Write minimal `Logic.lua`**

Create `Logic.lua`:
```lua
local ADDON, ns = ...

-- Pure-logic example module. No WoW globals at file scope, so the headless
-- harness can load and test it. Delete or replace per-addon.
local Logic = {}

-- Sum a numeric array.
function Logic.sum(list)
  local total = 0
  for _, n in ipairs(list) do
    total = total + n
  end
  return total
end

-- Clamp v into the inclusive range [lo, hi].
function Logic.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

ns.Logic = Logic
```

- [ ] **Step 5: Run the test to verify it passes**

Run:
```bash
cd ~/projects/wow-addon-template && /opt/homebrew/bin/lua tests/run.lua
```
Expected: `4 passed, 0 failed`, exit code 0.

- [ ] **Step 6: Commit**

```bash
cd ~/projects/wow-addon-template && git add Logic.lua tests/ && git commit -m "feat: headless test harness with pure-logic example"
```

---

## Task 3: `Core.lua` bootstrap stub

**Files:**
- Create: `~/projects/wow-addon-template/Core.lua`

- [ ] **Step 1: Write `Core.lua`**

Create `Core.lua`:
```lua
local ADDON, ns = ...

-- AceAddon bootstrap. Library calls execute only in the WoW client; this file
-- is syntax-checked headlessly (loadfile) but never run by the test harness.
-- Before fleshing this out, read CLAUDE.md § RESEARCH FIRST.
local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon:NewAddon(ADDON, "AceConsole-3.0", "AceEvent-3.0")
ns.addon = addon

function addon:OnInitialize()
  -- Set up AceDB, options registration, and the slash command here.
end

function addon:OnEnable()
  -- Register events here.
end
```

- [ ] **Step 2: Syntax-check it**

Run:
```bash
cd ~/projects/wow-addon-template && /opt/homebrew/bin/lua -e "assert(loadfile('Core.lua'))" && echo OK
```
Expected: `OK` (loadfile compiles; the `LibStub` call is not executed).

- [ ] **Step 3: Confirm the harness is still green**

Run:
```bash
cd ~/projects/wow-addon-template && /opt/homebrew/bin/lua tests/run.lua
```
Expected: `4 passed, 0 failed` (the harness loads only `Logic.lua`, not `Core.lua`).

- [ ] **Step 4: Commit**

```bash
cd ~/projects/wow-addon-template && git add Core.lua && git commit -m "feat: AceAddon bootstrap stub"
```

---

## Task 4: `__ADDON__.toc`

**Files:**
- Create: `~/projects/wow-addon-template/__ADDON__.toc`

- [ ] **Step 1: Write the TOC with unresolved markers**

Create `__ADDON__.toc`:
```
## Interface: __INTERFACE_VERSION__
## Title: __ADDON__
## Notes: __NOTES__
## Author: __AUTHOR__
## Version: @project-version@
## SavedVariables: __ADDON__DB
## X-Category: __CATEGORY__

Libs\embeds.xml
Logic.lua
Core.lua
```

- [ ] **Step 2: Verify the markers are present and no real interface number leaked**

Run:
```bash
cd ~/projects/wow-addon-template && grep -n "__INTERFACE_VERSION__" __ADDON__.toc && ! grep -E "## Interface: [0-9]" __ADDON__.toc && echo "no baked version OK"
```
Expected: prints the marker line and `no baked version OK`.

- [ ] **Step 3: Commit**

```bash
cd ~/projects/wow-addon-template && git add __ADDON__.toc && git commit -m "feat: TOC with unresolved name/interface markers"
```

---

## Task 5: `.pkgmeta`, `Libs/embeds.xml`, `.gitignore`

**Files:**
- Create: `~/projects/wow-addon-template/.pkgmeta`
- Create: `~/projects/wow-addon-template/Libs/embeds.xml`
- Create: `~/projects/wow-addon-template/.gitignore`

- [ ] **Step 1: Write `.pkgmeta`**

Create `.pkgmeta`:
```yaml
# CurseForge / BigWigs packager manifest.
# Libraries are fetched at build time from canonical sources and are NOT
# committed. Verify these URLs still resolve during setup (CLAUDE.md § RESEARCH).
package-as: __ADDON__

externals:
  Libs/LibStub: https://repos.wowace.com/wow/ace3/trunk/LibStub
  Libs/CallbackHandler-1.0: https://repos.wowace.com/wow/ace3/trunk/CallbackHandler-1.0
  Libs/AceAddon-3.0: https://repos.wowace.com/wow/ace3/trunk/AceAddon-3.0
  Libs/AceEvent-3.0: https://repos.wowace.com/wow/ace3/trunk/AceEvent-3.0
  Libs/AceConsole-3.0: https://repos.wowace.com/wow/ace3/trunk/AceConsole-3.0
  Libs/AceDB-3.0: https://repos.wowace.com/wow/ace3/trunk/AceDB-3.0
  Libs/AceConfig-3.0: https://repos.wowace.com/wow/ace3/trunk/AceConfig-3.0

ignore:
  - docs
  - tests
  - CLAUDE.md
  - README.md
```

- [ ] **Step 2: Verify the external URLs resolve (resolve-don't-assume)**

Run:
```bash
svn info https://repos.wowace.com/wow/ace3/trunk/AceAddon-3.0 >/dev/null 2>&1 && echo "AceAddon URL resolves" || echo "VERIFY: AceAddon URL — check current Ace3 path on https://www.curseforge.com/wow/addons/ace3"
```
Expected: `AceAddon URL resolves`. If not, update all `repos.wowace.com/wow/ace3/trunk/*` paths to the current Ace3 layout before continuing. (`svn` available via Homebrew; if absent, open the URL in a browser to confirm.)

- [ ] **Step 3: Write `Libs/embeds.xml`**

Create `Libs/embeds.xml`:
```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
  <Script file="LibStub\LibStub.lua"/>
  <Include file="CallbackHandler-1.0\CallbackHandler-1.0.xml"/>
  <Include file="AceAddon-3.0\AceAddon-3.0.xml"/>
  <Include file="AceEvent-3.0\AceEvent-3.0.xml"/>
  <Include file="AceConsole-3.0\AceConsole-3.0.xml"/>
  <Include file="AceDB-3.0\AceDB-3.0.xml"/>
  <Include file="AceConfig-3.0\AceConfig-3.0.xml"/>
</Ui>
```
Note: these embed paths follow the standard Ace3 module layout. During setup, after the libs are fetched, confirm each referenced file exists (the per-library `.xml`/`.lua` names occasionally change).

- [ ] **Step 4: Write `.gitignore`**

Create `.gitignore`:
```
# Libraries are resolved at build time, never committed — except the manifest.
Libs/*
!Libs/embeds.xml

.DS_Store
```

- [ ] **Step 5: Remove the placeholder `.gitkeep` (Libs/ now has a tracked file)**

Run:
```bash
cd ~/projects/wow-addon-template && git rm -q .gitkeep
```

- [ ] **Step 6: Verify only `embeds.xml` is tracked under `Libs/`**

Run:
```bash
cd ~/projects/wow-addon-template && git add -A && git status --porcelain Libs/
```
Expected: only `A  Libs/embeds.xml` (no other Libs paths).

- [ ] **Step 7: Commit**

```bash
cd ~/projects/wow-addon-template && git commit -m "feat: pkgmeta library resolution + embeds manifest + gitignore"
```

---

## Task 6: CI workflows (release + test)

**Files:**
- Create: `~/projects/wow-addon-template/.github/workflows/release.yml`
- Create: `~/projects/wow-addon-template/.github/workflows/test.yml`

- [ ] **Step 1: Write the release workflow**

Create `.github/workflows/release.yml`:
```yaml
name: Package and release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Package and release to CurseForge
        uses: BigWigsMods/packager@master
        env:
          CF_API_KEY: ${{ secrets.CF_API_KEY }}
          GITHUB_OAUTH: ${{ secrets.GITHUB_TOKEN }}
```
Note: confirm the current packager invocation against
https://github.com/BigWigsMods/packager (action ref vs. `release.sh` curl form)
during setup; update if their README has changed.

- [ ] **Step 2: Write the test workflow**

Create `.github/workflows/test.yml`:
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Lua
        run: sudo apt-get update && sudo apt-get install -y lua5.4
      - name: Run headless tests
        run: lua5.4 tests/run.lua
```

- [ ] **Step 3: Lint the YAML (basic parse check)**

Run:
```bash
cd ~/projects/wow-addon-template && /opt/homebrew/bin/lua -e "for _,f in ipairs({'.github/workflows/release.yml','.github/workflows/test.yml'}) do assert(io.open(f)):close() end" && echo "files present"
```
Expected: `files present`.

- [ ] **Step 4: Commit**

```bash
cd ~/projects/wow-addon-template && git add .github && git commit -m "ci: tag-driven release + headless test workflow"
```

---

## Task 7: `CLAUDE.md` (the product)

The deliverable. Write the three-section brain. The cited facts below were verified
2026-06-18; Step 1 re-confirms the source URLs still resolve before committing.

**Files:**
- Create: `~/projects/wow-addon-template/CLAUDE.md`

- [ ] **Step 1: Re-confirm the cited sources resolve**

Run:
```bash
for u in \
  "https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight" \
  "https://www.curseforge.com/wow/addons/ace3" \
  "https://github.com/DennysOliveira/wow-addon-dev" \
  "https://warcraft.wiki.gg/wiki/Portal:API" ; do
  code=$(curl -s -o /dev/null -w "%{http_code}" -L "$u"); echo "$code  $u"; done
```
Expected: each line begins `200`. If any is not `200`, find the current
authoritative replacement before writing it into `CLAUDE.md`.

- [ ] **Step 2: Write `CLAUDE.md`**

Create `CLAUDE.md`:
```markdown
# __ADDON__ — working notes

A World of Warcraft **retail** addon built from the drift-resistant template.
This file is the brain: it forces current-state research before any build, then
records the conventions and the addon-specific decisions.

## § RESEARCH FIRST (hard gate)

**Do not scaffold or write addon code until you have resolved current state from
authoritative sources. Never use this file's memory or model training for any
fact that changes between patches. Resolve, don't assume.**

1. **Interface version.** Resolve the current retail interface number and fill the
   `## Interface:` marker in `__ADDON__.toc`. Authoritative: the current
   `Patch 12.0.x/API changes` page on Warcraft Wiki
   (https://warcraft.wiki.gg/wiki/Portal:API) or the live client TOC. Never invent
   the number.
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
```

- [ ] **Step 3: Verify no baked interface number slipped into CLAUDE.md**

Run:
```bash
cd ~/projects/wow-addon-template && ! grep -E "Interface: [0-9]{6}" CLAUDE.md && echo "no baked version OK"
```
Expected: `no baked version OK`.

- [ ] **Step 4: Commit**

```bash
cd ~/projects/wow-addon-template && git add CLAUDE.md && git commit -m "docs: CLAUDE.md research-first brain"
```

---

## Task 8: `README.md`

**Files:**
- Create: `~/projects/wow-addon-template/README.md`

- [ ] **Step 1: Write `README.md`**

Create `README.md`:
```markdown
# wow-addon-template

A drift-resistant starting point for World of Warcraft **retail** addons.

It ships a barebones, headlessly-testable Lua skeleton — **not** pre-built UI.
The intelligence lives in `CLAUDE.md`, which forces current-state research
(Midnight Secret Values, current interface version, current Ace3) before any
code is written, so the template never bakes a stale patch assumption.

## Use it

1. Click **Use this template** on GitHub (or clone and re-init git).
2. Open the new repo with Claude Code and say: *"Set up this addon as `<Name>`."*
   Claude follows `CLAUDE.md` § RESEARCH FIRST — resolving the current interface
   version, confirming Midnight/Ace3 constraints — then substitutes the
   `__ADDON__` / `__AUTHOR__` / `__NOTES__` / `__CATEGORY__` / `__INTERFACE_VERSION__`
   markers and builds from there.
3. `lua tests/run.lua` should print `4 passed, 0 failed` on a fresh clone.

## What's inside

- `Logic.lua` + `tests/` — pure-logic example and the headless test harness.
- `Core.lua` — AceAddon bootstrap stub.
- `.pkgmeta` + `Libs/embeds.xml` — libraries resolved at build, never committed.
- `.github/workflows/` — tag-driven CurseForge release + headless test runner.
- `CLAUDE.md` — the brain. Read it first.
```

- [ ] **Step 2: Commit**

```bash
cd ~/projects/wow-addon-template && git add README.md && git commit -m "docs: README with setup instructions"
```

---

## Task 9: Final verification walkthrough

No new files. Prove the skeleton is green and free of baked assumptions.

- [ ] **Step 1: Tests green on a clean checkout**

Run:
```bash
cd /tmp && rm -rf vat-verify && git clone -q ~/projects/wow-addon-template vat-verify && cd vat-verify && /opt/homebrew/bin/lua tests/run.lua
```
Expected: `4 passed, 0 failed`, exit code 0.

- [ ] **Step 2: Syntax-check all committed Lua**

Run:
```bash
cd /tmp/vat-verify && for f in Logic.lua Core.lua; do /opt/homebrew/bin/lua -e "assert(loadfile('$f'))" && echo "$f OK"; done
```
Expected: `Logic.lua OK` and `Core.lua OK`.

- [ ] **Step 3: No-baked-assumptions audit**

Run:
```bash
cd /tmp/vat-verify && grep -rEn "Interface: [0-9]" . --include="*.toc" --include="*.md" && echo "FOUND BAKED VERSION (fail)" || echo "no baked interface version OK"
grep -rn "ace3/trunk" .pkgmeta >/dev/null && echo "libs via externals OK (not committed)"
test -d Libs && ls Libs | grep -qx embeds.xml && [ "$(ls Libs | wc -l | tr -d ' ')" = "1" ] && echo "only embeds.xml tracked in Libs OK"
```
Expected: `no baked interface version OK`, `libs via externals OK (not committed)`, `only embeds.xml tracked in Libs OK`.

- [ ] **Step 4: Confirm markers are intact for `Use this template`**

Run:
```bash
cd /tmp/vat-verify && grep -rl "__ADDON__" . --include="*.toc" --include="*.pkgmeta" --include="*.md" --include="*.lua" | sort
```
Expected: lists `__ADDON__.toc`, `.pkgmeta`, `CLAUDE.md`, `Core.lua`, `Logic.lua`, `tests/run.lua` (the substitution targets).

- [ ] **Step 5: Clean up the verification clone**

Run:
```bash
rm -rf /tmp/vat-verify
```

---

## Self-Review (completed during authoring)

**Spec coverage:** governing principle → header + Task 4/5/7 markers & externals; no-scripts decision → Task 7 CLAUDE.md procedure (no script files created); committed barebones tree → Tasks 2–8 (no Broker/Roster/Scanner/Config); harness carried from VaultTracker → Task 2; `.pkgmeta` resolve-don't-commit → Task 5; CLAUDE.md three sections → Task 7; verification (green tests, loadfile, no-baked-assumptions audit) → Task 9. The `test.yml` CI runner (Task 6) is a small best-practice addition beyond the spec's `release.yml`, serving "keep green."

**Placeholder scan:** the `__ADDON__` / `__INTERFACE_VERSION__` markers are intentional template tokens, not plan gaps. The "VERIFY/confirm" notes in Tasks 5–7 are resolve-don't-assume checks with concrete commands, not deferred work.

**Type consistency:** `Logic.sum`, `Logic.clamp`, `ns.Logic`, `F.numbers`, `loadModule`, `eq` are used identically across Tasks 2, 3, and 9.
</content>
