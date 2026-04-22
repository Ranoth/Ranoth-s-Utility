--- Initialize the addon and set up the settings database.
--- @module "Init"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):NewAddon(addon_name, "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0", "AceTimer-3.0")

local defaults = {
    profile = {
        language = "enUS",
        debug = false,
        autoOpen = false,
        threeDViewer = true,
        lootAsker = true,
        spellMessages = true,
        elvuiTags = true,
        growDirection = 1,
        checkIfSelfCanEquip = true,
        checkItemQuality = true,
        minItemQuality = 2,
        checkIfNotWarbound = false,
        lootAnchorPoint = "CENTER",
        lootAnchorRelativePoint = "CENTER",
        lootAnchorX = 0,
        lootAnchorY = 0,
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
