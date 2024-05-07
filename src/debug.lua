--- Debug module for RanothUtils.
--- @module "Debug"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local Debug = RanothUtils:NewModule("Debug")

local chatTabName = "Debug" -- replace with the name of your chat tab
local chatFrameIndex = 1    -- replace with the index of your chat frame
local chatFrame = _G["ChatFrame" .. chatFrameIndex] or DEFAULT_CHAT_FRAME
local chatTab = chatTab or _G["ChatFrame" .. chatFrameIndex]

--- Higher order function to neutralize each public function of the module when debug mode is disabled.
--- @param func any
--- @return function
--- @usage `Debug.Print = createToggledFunction(function(self, ...)`
local function createToggledFunction(func)
    return function(...)
        if not Debug:IsEnabled() then return end
        return func(unpack({ ... }))
    end
end

--- Set the chat window to the one specified in the chatTabName variable.
local function setChatWindow()
    for i = 1, NUM_CHAT_WINDOWS do
        local name = GetChatWindowInfo(i)
        if name == chatTabName then
            chatTab = _G["ChatFrame" .. i]
            break
        end
    end
end

--- Toggle debug mode on or off.
function Debug:Toggle()
    if Debug:IsEnabled() then
        Debug:Disable()
    else
        Debug:Enable()
    end
    chatTab:AddMessage(Debug:IsEnabled() and "Debug mode enabled" or "Debug mode disabled")
end

--- Print a message to the chat frame with the colorized addon's name prepended.
--- @param ... any | string | table
--- @usage `Debug:Print("Hello, world!")`
Debug.Print = createToggledFunction(function(self, ...)
    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    chatTab:AddMessage(table.concat(args, " "))
end)

--- Print the event and the name of the unit that triggered the event.
--- @param event string
--- @param unit string
--- @usage `Debug:CombatLogUnitName("UNIT_NAME_UPDATE", "player")`
Debug.CombatLogUnitName = createToggledFunction(function(self, event, unit)
    Debug:Print(event, unit)
end)

--- Print the event, the name of the unit that triggered the event, and the unit's GUID.
--- @param subevent string
--- @param destName string
--- @param destFlags number
--- @usage `Debug:CombatLogGetUnitFlags(subevent, destName, destFlags)`
Debug.CombatLogGetUnitFlags = createToggledFunction(function(self, subevent, destName, destFlags)
    local flags = {
        [COMBATLOG_OBJECT_AFFILIATION_MASK] = {
            [COMBATLOG_OBJECT_AFFILIATION_MINE] = "Affiliation: Mine",
            [COMBATLOG_OBJECT_AFFILIATION_PARTY] = "Affiliation: Party",
            [COMBATLOG_OBJECT_AFFILIATION_RAID] = "Affiliation: Raid",
            [COMBATLOG_OBJECT_AFFILIATION_OUTSIDER] = "Affiliation: Outsider",
        },
        [COMBATLOG_OBJECT_REACTION_MASK] = {
            [COMBATLOG_OBJECT_REACTION_FRIENDLY] = "Reaction: Friendly",
            [COMBATLOG_OBJECT_REACTION_NEUTRAL] = "Reaction: Neutral",
            [COMBATLOG_OBJECT_REACTION_HOSTILE] = "Reaction: Hostile",
        },
        [COMBATLOG_OBJECT_CONTROL_MASK] = {
            [COMBATLOG_OBJECT_CONTROL_PLAYER] = "Control: Player",
            [COMBATLOG_OBJECT_CONTROL_NPC] = "Control: NPC",
        },
        [COMBATLOG_OBJECT_TYPE_MASK] = {
            [COMBATLOG_OBJECT_TYPE_PLAYER] = "Type: Player",
            [COMBATLOG_OBJECT_TYPE_NPC] = "Type: NPC",
            [COMBATLOG_OBJECT_TYPE_PET] = "Type: Pet",
            [COMBATLOG_OBJECT_TYPE_GUARDIAN] = "Type: Guardian",
            [COMBATLOG_OBJECT_TYPE_OBJECT] = "Type: Object",
        },
    }
    local order = { "TYPE", "CONTROL", "REACTION", "AFFILIATION" }
    local t = {}
    table.insert(t, subevent)
    table.insert(t, destName)
    table.insert(t, format("0x%X", destFlags))
    for _, v in pairs(order) do
        local mask = _G["COMBATLOG_OBJECT_" .. v .. "_MASK"]
        local bitfield = bit.band(destFlags, mask)
        local info = flags[mask][bitfield]
        table.insert(t, (info:gsub(": (%a+)", ": |cff71d5ff%1|r"))) -- add some coloring
    end
    Debug:Print(table.concat(t, ", "))
end)

function Debug:OnInitialize()
    self.db = RanothUtils.db.profile.debug
    setChatWindow()
    if self.db then
        self:Enable()
    else
        self:Disable()
    end
end

function Debug:OnEnable()
    setChatWindow()
    RanothUtils.db.profile.debug = Debug:IsEnabled()
end

function Debug:OnDisable()
    RanothUtils.db.profile.debug = Debug:IsEnabled()
end
