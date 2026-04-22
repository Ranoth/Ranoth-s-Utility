local addon_name = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local Options = RanothUtils:NewModule("Options")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local pendingReload = false

local function PromptReload()
    if not pendingReload then return end

    StaticPopupDialogs["RANOTHSUTILITY_RELOAD_UI"] = StaticPopupDialogs["RANOTHSUTILITY_RELOAD_UI"] or {
        text = "Some changes require a UI reload. Reload now?",
        button1 = ACCEPT,
        button2 = CANCEL,
        OnAccept = function()
            pendingReload = false
            ReloadUI()
        end,
        OnCancel = function()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("RANOTHSUTILITY_RELOAD_UI")
end

local function SetToggle(key, value, requiresReload, moduleName)
    RanothUtils.db.profile[key] = value
    if moduleName then
        if value then
            RanothUtils:EnableModule(moduleName)
        else
            RanothUtils:DisableModule(moduleName)
        end
    end

    if requiresReload then
        pendingReload = true
        PromptReload()
    end
end

local function openBlizzardOptions(frame)
    if Settings and Settings.OpenToCategory and frame and frame.ID then
        Settings.OpenToCategory(frame.ID)
        return
    end
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(frame)
        InterfaceOptionsFrame_OpenToCategory(frame) -- legacy quirk
    end
end

function Options:OnInitialize()
    local opts = {
        type = "group",
        name = "Ranoth's Utility",
        args = {
            enabled = {
                type = "group",
                name = "Modules",
                args = {
                    debug = {
                        order = 1,
                        type = "toggle",
                        name = "Debug Mode",
                        get = function() return RanothUtils.db.profile.debug end,
                        set = function(_, v)
                            SetToggle("debug", v, false, "Debug")
                        end,
                    },
                    autoOpen = {
                        order = 2,
                        type = "toggle",
                        name = "Auto Open Containers",
                        get = function() return RanothUtils.db.profile.autoOpen end,
                        set = function(_, v)
                            SetToggle("autoOpen", v, false, "AutoOpen")
                        end,
                    },
                    threeDViewer = {
                        order = 3,
                        type = "toggle",
                        name = "3D Viewer Context Menu",
                        desc = "Disabling may require /reload to fully remove menu injection.",
                        get = function() return RanothUtils.db.profile.threeDViewer end,
                        set = function(_, v)
                            SetToggle("threeDViewer", v, true, "ThreeDViewer")
                        end,
                    },
                    lootAsker = {
                        order = 4,
                        type = "toggle",
                        name = "Loot Asker",
                        get = function() return RanothUtils.db.profile.lootAsker end,
                        set = function(_, v)
                            SetToggle("lootAsker", v, false, "LootAsker")
                        end,
                    },
                    spellMessages = {
                        order = 5,
                        type = "toggle",
                        name = "Spell Messages",
                        get = function() return RanothUtils.db.profile.spellMessages end,
                        set = function(_, v)
                            SetToggle("spellMessages", v, false, "SpellMessages")
                        end,
                    },
                    elvuiTags = {
                        order = 6,
                        type = "toggle",
                        name = "ElvUI Tags",
                        get = function() return RanothUtils.db.profile.elvuiTags end,
                        set = function(_, v)
                            SetToggle("elvuiTags", v, true, "ElvuiTagsRegisterer")
                        end,
                    },
                    lootAskerFilters = {
                        order = 7,
                        type = "group",
                        name = "Loot Asker Filters",
                        args = {
                            growDirection = {
                                order = 1,
                                type = "select",
                                name = "Grow Direction",
                                values = {
                                    [1] = "Up",
                                    [2] = "Down",
                                    [3] = "Left",
                                    [4] = "Right",
                                },
                                get = function() return RanothUtils.db.profile.growDirection end,
                                set = function(_, v)
                                    SetToggle("growDirection", v, false)
                                end,
                            },
                            checkIfSelfCanEquip = {
                                order = 3,
                                type = "toggle",
                                name = "Only show if self can equip",
                                get = function() return RanothUtils.db.profile.checkIfSelfCanEquip end,
                                set = function(_, v)
                                    SetToggle("checkIfSelfCanEquip", v, false)
                                end,
                            },
                            checkItemQuality = {
                                order = 4,
                                type = "toggle",
                                name = "Only show if item quality is above a certain threshold",
                                get = function() return RanothUtils.db.profile.checkItemQuality end,
                                set = function(_, v)
                                    SetToggle("checkItemQuality", v, false)
                                end,
                            },
                            minItemQuality = {
                                order = 5,
                                type = "select",
                                name = "Minimum Item Quality",
                                values = {
                                    [0] = "Poor (Gray)",
                                    [1] = "Common (White)",
                                    [2] = "Uncommon (Green)",
                                    [3] = "Rare (Blue)",
                                    [4] = "Epic (Purple)",
                                    [5] = "Legendary (Orange)",
                                    [6] = "Artifact (Gold)",
                                    [7] = "Heirloom (Light Yellow)",
                                },
                                get = function() return RanothUtils.db.profile.minItemQuality end,
                                set = function(_, v)
                                    SetToggle("minItemQuality", v, false)
                                end,
                            },
                            checkIfNotWarbound = {
                                order = 6,
                                type = "toggle",
                                name = "Only show if item is not warbound",
                                get = function() return RanothUtils.db.profile.checkIfNotWarbound end,
                                set = function(_, v)
                                    SetToggle("checkIfNotWarbound", v, false)
                                end,
                            },
                        }
                    }
                },
            }
        },
    }

    AceConfig:RegisterOptionsTable(addon_name, opts)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(addon_name, "Ranoth's Utility")
end

function Options:Open()
    openBlizzardOptions(self.optionsFrame)
end
