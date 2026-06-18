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
