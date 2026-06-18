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
