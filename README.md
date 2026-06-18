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
