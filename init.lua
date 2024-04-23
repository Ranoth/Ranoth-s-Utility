local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):NewAddon(addon_name, "AceEvent-3.0", "AceHook-3.0")

local defaults = {
    profile = {
        debug = false,
        language = "enUS",
    },
}

function RanothUtils:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RanothUtilityDB", defaults, true)
end