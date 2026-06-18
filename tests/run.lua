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
