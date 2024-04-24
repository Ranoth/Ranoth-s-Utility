local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):NewAddon(addon_name, "AceEvent-3.0", "AceHook-3.0")

local defaults = {
    profile = {
        language = "enUS",
        debug = false,
        autoOpen = false,
    },
}

function RanothUtils:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("RanothUtilityDB", defaults, true)
end

function RanothUtils:OnEnable()
end

function RanothUtils:OnDisable()
    RanothUtils:UnhookAll()
    RanothUtils:UnregisterAllEvents()
end