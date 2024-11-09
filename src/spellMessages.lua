--- Send messages to warn the party about party utilities being used.
--- @module "SpellMessages"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local SpellMessages = RanothUtils:NewModule("SpellMessages")

local Debug = RanothUtils:GetModule("Debug")

local spellMessageDb = {}
local petOwners = {}
local messageQueue = {}

local function selectTarget()
    local target = UnitExists("mouseover") and "mouseover" or "player"
    local isAlive = not UnitIsDeadOrGhost(target)
    if UnitIsPlayer(target) then
        if target == "player" or UnitIsUnit(target, "player") then
            return "on myself", isAlive
        else
            return "on" .. " " .. UnitName(target), isAlive
        end
    else
        return "on myself", isAlive
    end
end

--- @return string, string -- The chat channel and a flair message reflecting the channel selected.
--- @usage Select the appropriate chat channel based on the player's current group status.
local function selectChannel()
    if IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT", "for the instance raid"
    elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return "RAID", "for the raid"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT", "for the instance party"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return "PARTY", "for the party"
    else
        return "EMOTE", "for... me"
    end
end

-- function SpellMessages:CheckDuplicateInterruptTrigger(unit, spellId)
--     local currentTime = GetTime()
--     local currentSpell = unit .. spellId .. currentTime

--     if lastInterruptedSpell == currentSpell or unit ~= "player" then
--         return false
--     else
--         lastInterruptedSpell = currentSpell
--         return true
--     end
-- end

--- Prepare the message to be sent to the relevent chat channel.
--- @param message (string) -- message to be sent
--- @usage `SpellMessages:PrepareSendChatMessage("Hello, World!")`
function SpellMessages:PrepareSendChatMessage(message)
    if not message then return end
    local channel, _ = selectChannel()
    if channel == nil then return end
    SendChatMessage(message, channel)
end

--- Enum of message prefixes for each spell message type.
local spellMessagePrefixMap = {
    SENT = "{Circle} ",
    STARTED = "{Circle} ",
    INTERRUPTED = "{Cross} Failed to ",
    STOPPED = "{Cross} Failed to ",
    SUCCEEDED = "{Triangle} Successfully ",
}

-- ===========================================================================================================================================================
--- @class SpellMessage
--- @field spellId number -- The ID of the spell associated with the message.
--- @field itemId number|boolean -- The ID of the item associated with the message.
--- @field plural boolean|nil -- Indicates whether the message should be pluralized.
--- @field target boolean|nil -- Indicates whether the message should include the target's name.
--- @field group boolean|nil -- Indicates whether the message should include the group's name.
--- @field messages table -- The messages to be displayed when the spell is sent, started, interrupted, stopped, and successful.
--- @field itemLink string -- The item link associated with the message.
--- @field soulstoneMessage function -- A function to generate a message based on the given `msgType` and `isAlive` parameters.
--- @field buildString function -- A function to build a message based on the given `prefix` and `key` parameters as well as the fields of the object.
--- @field queueMessages function -- A function to queue the messages to be sent to the chat channel.
--- @field dequeueMessages function -- A function to dequeue the messages from the message queue.
local SpellMessage = {}
SpellMessage.__index = SpellMessage

--- Creates a new spell message object with the given parameters.
--- @param spellId number -- The ID of the spell associated with the message.
--- @param itemId number|boolean -- The ID of the item associated with the message. If no item is associated with the message, set this to `false`.
--- @param sentMsg string -- The message to be displayed when the spell is sent.
--- @param startedMsg string -- The message to be displayed when the spell is started.
--- @param interruptedMsg string -- The message to be displayed when the spell is interrupted.
--- @param stoppedMsg string -- The message to be displayed when the spell is stopped.
--- @param succeededMsg string -- The message to be displayed when the spell is successful.
--- @param plural boolean|nil -- (optional) Indicates whether the message should be pluralized.
--- @param target boolean|nil -- (optional) Indicates whether the message should include the target's name.
--- @param group boolean|nil -- (optional) Indicates whether the message should include the group's name.
--- @return table -- The new spell message object.
--- @usage `SpellMessage(6201, 5512, "Making", "", "make", "", "made", true, false, true)` Note it is intended that empty strings will not generate a message.
function SpellMessage:new(spellId, itemId, sentMsg, startedMsg, interruptedMsg, stoppedMsg, succeededMsg, plural, target,
                          group)
    local obj = {}
    setmetatable(obj, SpellMessage)

    obj.spellId = spellId
    obj.itemId = itemId
    obj.plural = plural
    obj.target = target or false
    obj.group = group or false
    obj.messages = {
        SENT = sentMsg,
        STARTED = startedMsg,
        INTERRUPTED = interruptedMsg,
        STOPPED = stoppedMsg,
        SUCCEEDED = succeededMsg,
    }

    obj.itemLink = ""

    return obj
end

function SpellMessage:requestItemLink()
    if not self.itemId then return end
    if not C_Item.IsItemDataCachedByID(self.itemId) then
        C_Item.RequestLoadItemDataByID(self.itemId)
    end
    local itemLink = select(2, C_Item.GetItemInfo(self.itemId))
    if itemLink then self.itemLink = itemLink end
end

--- Generates a message based on the given `msgType` and `isAlive` parameters.
--- @param msgType string The type of message. Defaults to "INTERRUPTED" if not provided.
--- @param isAlive boolean Indicates whether the player is alive. Defaults to `false` if not provided.
--- @return string The generated message based on the `msgType` and `isAlive` parameters.
--- @usage `soulstoneMessage(key, isAlive)` Intended to be used in the `buildString` function of a `newSpellMessage` object.
function SpellMessage:soulstoneMessage(msgType, isAlive)
    local soulstoneMessages = {
        ["SENT"] = function() if isAlive then return "Placing a" else return "Resurrecting" end end,
        ["STARTED"] = function() return "" end,
        ["INTERRUPTED"] = function() if isAlive then return "place a" else return "resurrect" end end,
        ["STOPPED"] = function() return "" end,
        ["SUCCEEDED"] = function() if isAlive then return "placed a" else return "resurrected" end end,
    }

    return soulstoneMessages[msgType or "INTERRUPTED"]()
end

--- Builds a message based on the given `prefix` and `key` parameters as well as the fields of the object.
--- @param prefix (string) -- The prefix to be used in the message.
--- @param key (string) -- The key to be used to retrieve the message from the `messages` table.
--- @return (string | nil) -- The generated message based on the `prefix` and `key` parameters. Returns `nil` if the message is empty.
--- @usage `self:buildString(prefix, key)` Intended to be used in the `queueMessages` function of a `newSpellMessage` object.
function SpellMessage:buildString(prefix, key)
    local msg = self.messages[key] or ""
    if msg == "" and self.spellId ~= 20707 then return end
    local isAlive = select(2, selectTarget())
    local itemLink = self.itemLink or ""
    -- if self.itemId and itemLink == "" then
    --     if not C_Item.IsItemDataCachedByID(self.itemId) then
    --         C_Item.RequestLoadItemDataByID(self.itemId)
    --     end
    --     itemLink = select(2, C_Item.GetItemInfo(self.itemId))
    -- end
    local spellLink = self.spellId and C_Spell.GetSpellLink(self.spellId) or ""
    local link = (itemLink ~= "" and itemLink or spellLink) .. (self.plural and "s" or "")
    local groupNameDisplay = self.group and (" " .. select(2, selectChannel())) or ""
    local targetDisplay = self.target and (" " .. select(1, selectTarget())) or ""
    local groupOrTarget = groupNameDisplay ~= "" and groupNameDisplay or targetDisplay

    if self.spellId == 200218 then
        link = "Blingtron 6000"
    elseif self.spellId == 20707 and not isAlive then
        msg = self:soulstoneMessage(key, isAlive)
        link = ""
        groupOrTarget = groupOrTarget:match("^%s*(.-)%s*$")
        groupOrTarget = groupOrTarget:gsub("^on ", "")
    elseif self.spellId == 20707 and isAlive then
        msg = self:soulstoneMessage(key, isAlive)
    end

    if msg == "" then return end

    return prefix .. msg .. " " .. link .. groupOrTarget .. "!"
end

--- Queues the messages to be sent to the chat channel.
--- @usage `self:queueMessages()` Intended to be used when a cast starts.
function SpellMessage:queueMessages()
    for k, _ in pairs(self.messages) do
        local message = self:buildString(spellMessagePrefixMap[k], k)
        if message ~= nil then
            messageQueue[spellMessagePrefixMap[k]] = message
        end
    end
end

--- Dequeues the messages from the message queue.
--- @usage `self:dequeueMessages()` Intended to be used when the spell cast is interrupted or successful.
function SpellMessage:dequeueMessages()
    if messageQueue == {} then return end
    messageQueue = {}
end

-- ===========================================================================================================================================================

function SpellMessages:MakeSpellMessageDb()
    --- This table, `spellMessageDb`, stores the spell messages for various spells.
    --- Each entry in the table represents a spell and its associated messages.
    --- The key of each entry is the spellId, and the value is an instance of the newSpellMessage function.
    --- The newSpellMessage function takes several parameters to define the spell message entry.
    --- The messages can be customized for different spells and items.
    --- The messages are used to display information to the player when certain events related to the spell occur.
    --- The messages can be queued in the messageQueue using the queueMessages function.
    --- The dynamic data, such as the target's state, is added in the buildString function of the object.
    spellMessageDb = {
        -- Example entries:
        -- [6201] = SpellMessage(6201, 5512, "Making", "", "make", "", "made", true, false, true), -- Create Healthstone, Healthstone

        [29893] = SpellMessage:new(29893, 5512, "Making", "", "make", "", "made", true, false, true),      -- Create Soulwell, Healthstone
        [698] = SpellMessage:new(698, false, "Using", "", "", "", "", false),                              -- Ritual of Summoning, No Item
        [20707] = SpellMessage:new(20707, false, "", "", "", "", "", false, true),                         -- Soulstone, No Item => messages are decided in spellMessageToString
        [187748] = SpellMessage:new(187748, 127770, "Placing a", "", "place a", "", "placed a", false),    -- Brazier of Awakening, Brazier of Awakening
        [67826] = SpellMessage:new(67826, 49040, "", "", "", "", "summoned", true),                        -- Jeeves, Jeeves
        [256153] = SpellMessage:new(256153, 153597, "Placing a", "", "place a", "", "placed a", false),    -- Deployable Attire Rearranger, Deployable Attire Rearranger
        [384908] = SpellMessage:new(384908, 198268, "Placing a", "", "place a", "", "placed a", false),    -- Portable Tinker's Workbench, Portable Tinker's Workbench
        [299127] = SpellMessage:new(299127, 168222, "Placing an", "", "place an", "", "placed an", false), -- Encrypted Black Market Radio, Encrypted Black Market Radio
        [126459] = SpellMessage:new(126459, 87214, "", "", "", "", "placed a", false),                     -- Blingtron 4000, Blingtron 4000
        [161414] = SpellMessage:new(161414, 111821, "", "", "", "", "placed a", false),                    -- Blingtron 5000, Blingtron 5000
        [200218] = SpellMessage:new(200218, false, "", "Placing a", "place a", "", "placed a", false),     -- Blingtron 6000, No Item
        [298926] = SpellMessage:new(298926, 168667, "", "", "", "", "placed a", false),                    -- Blingtron 7000, Blingtron 7000
        [200205] = SpellMessage:new(200205, 132514, "", "Placing an", "place an", "", "placed an", false), -- Reaves Module: Repair Mode, Auto-Hammer
    }
end

--- This function is called when a player casts a spell and the cast is sent to the server.
--- It retrieves the spell message associated with the spell ID and queues the messages.
--- It then prepares and sends a chat message using the prepared message queue.
--- @param unit string The unit that casted the spell.
--- @param spellId number The ID of the spell that was casted.
--- @usage `SpellMessages:PlayerCastSent("player", 12345)`
function SpellMessages:PlayerCastSent(unit, spellId)
    local spellMessage = spellMessageDb[spellId]
    if not spellMessage then return end
    if unit ~= "player" then return end

    spellMessage:queueMessages()

    SpellMessages:PrepareSendChatMessage(messageQueue[spellMessagePrefixMap.SENT])
end

--- This function is called when a player casts a spell and the cast is interrupted.
--- It retrieves the spell message associated with the spell ID and dequeues the messages.
--- It then prepares and sends a chat message using the prepared message queue.
--- @param unit string The unit that casted the spell.
--- @param spellId number The ID of the spell that was casted.
--- @usage `SpellMessages:PlayerCastInterrupted("player", 12345)`
function SpellMessages:PlayerCastInterrupted(unit, spellId)
    local spellMessage = spellMessageDb[spellId]
    if not spellMessage then return end
    if unit ~= "player" then return end

    SpellMessages:PrepareSendChatMessage(messageQueue[spellMessagePrefixMap.INTERRUPTED])
    for key, message in pairs(messageQueue) do Debug:Print(key, message) end

    spellMessage:dequeueMessages()
end

--- This function is called when a player casts a spell and the cast is successful.
--- It retrieves the spell message associated with the spell ID and dequeues the messages.
--- It then prepares and sends a chat message using the prepared message queue.
--- @param unit string The unit that casted the spell.
--- @param spellId number The ID of the spell that was casted.
--- @usage SpellMessages:PlayerCastSucceeded("player", 12345)
function SpellMessages:PlayerCastSucceeded(unit, spellId)
    local spellMessage = spellMessageDb[spellId]
    if not spellMessage then return end
    if unit ~= "player" then return end

    SpellMessages:PrepareSendChatMessage(messageQueue[spellMessagePrefixMap.SUCCEEDED])

    spellMessage:dequeueMessages()
end

--- This function is called when an NPC casts a spell and the cast is started.
--- It retrieves the spell message associated with the spell ID and queues the messages.
--- It then prepares and sends a chat message using the prepared message queue.
--- @param unit any -- The unit that casted the spell.
--- @param spellId any -- The ID of the spell that was casted.
function SpellMessages:NpcCastStart(unit, _, spellId)
    local spellMessage = spellMessageDb[spellId]
    if not spellMessage then return end
    if unit ~= "target" then return end

    spellMessage:queueMessages()

    SpellMessages:PrepareSendChatMessage(messageQueue[spellMessagePrefixMap.STARTED])
end

--- This function is called when an NPC casts a spell and the cast is successful.
--- It retrieves the spell message associated with the spell ID and dequeues the messages.
--- It then prepares and sends a chat message using the prepared message queue.
--- @param unit string -- The unit that casted the spell.
--- @param spellId integer -- The ID of the spell that was casted.
--- @usage `SpellMessages:NpcCastSucceeded("target", _, 12345)`
function SpellMessages:NpcCastSucceeded(unit, spellId)
    -- Debug:Print("NpcCastSucceeded called with unit: " .. tostring(unit) .. ", spellId: " .. tostring(spellId))
    local spellMessage = spellMessageDb[spellId]
    if not spellMessage then return end
    if unit ~= "target" then return end

    SpellMessages:PrepareSendChatMessage(messageQueue[spellMessagePrefixMap.SUCCEEDED])

    spellMessage:dequeueMessages()
end

--- This function is called when an NPC casts a spell and the cast is interrupted.
--- It retrieves the spell message associated with the spell ID and dequeues the messages.
--- It then prepares and sends a chat message using the prepared message queue.
--- @param ... any -- The arguments passed to the function.
--- @usage `SpellMessages:NpcCastInterrupted(...)`
function SpellMessages:SummonedGuardian(...)
    local _, subevent, _, sourceGUID, _, _, _, destGUID, destName, destFlags, _ = ...
    Debug:CombatLogGetUnitFlags(subevent, destName, destFlags)
    if not sourceGUID or not destGUID then return end
    petOwners[destGUID] = sourceGUID
end

--- This function is called when an NPC casts a spell and the cast is interrupted.
--- It retrieves the spell message associated with the spell ID and dequeues the messages.
--- It then prepares and sends a chat message using the prepared message queue.
--- @param ... any -- The arguments passed to the function.
--- @usage `SpellMessages:InterruptedSpellCast(...)`
function SpellMessages:InterruptedSpellCast(...)
    local _, _, _, sourceGUID, _, _, _, _, destName, _, _ = ...
    local playerGUID, petGUID = UnitGUID("player"), UnitGUID("pet")
    Debug:Print(petOwners[sourceGUID] == playerGUID or "failed")
    if sourceGUID == playerGUID or sourceGUID == petGUID or petOwners[sourceGUID] == playerGUID then
        local extraSpellId = select(15, CombatLogGetCurrentEventInfo())
        SpellMessages:PrepareSendChatMessage("Interrupted " ..
        destName .. "'s " .. C_Spell.GetSpellLink(extraSpellId) .. "!")
    end
end

-- Event handlers and debouncing logic for spell messages block.
-- ====================================================================================================================
function RanothUtils:GET_ITEM_INFO_RECEIVED(_, itemId, success)
    if success then
        for _, spellMessage in pairs(spellMessageDb) do
            if spellMessage.itemId == itemId then
                local itemLink = select(2, C_Item.GetItemInfo(itemId))
                spellMessage.itemLink = itemLink
            end
        end
    end
end

function RanothUtils:UNIT_SPELLCAST_SENT(_, unit, _, _, spellId)
    SpellMessages:PlayerCastSent(unit, spellId)
end

function RanothUtils:UNIT_SPELLCAST_START(_, unit, castGUID, spellId)
    SpellMessages:NpcCastStart(unit, castGUID, spellId)
end

function RanothUtils:UNIT_SPELLCAST_INTERRUPTED(_, unit, _, spellId)
    if unit == "pet" then return end
    -- if SpellMessages:CheckDuplicateInterruptTrigger(unit, spellId) then return end
    SpellMessages:PlayerCastInterrupted(unit, spellId)

    RanothUtils:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    C_Timer.After(0.1, function()
        RanothUtils:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    end)
end

function RanothUtils:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, spellId)
    if unit == "pet" then return end
    SpellMessages:PlayerCastSucceeded(unit, spellId)
    SpellMessages:NpcCastSucceeded(unit, spellId)
end

function RanothUtils:COMBAT_LOG_EVENT_UNFILTERED()
    local eventInfo = { CombatLogGetCurrentEventInfo() }
    if eventInfo[2] == "SPELL_SUMMON" then
        SpellMessages:SummonedGuardian(unpack(eventInfo))
    elseif eventInfo[2] == "SPELL_INTERRUPT" then
        SpellMessages:InterruptedSpellCast(unpack(eventInfo))
    end
end

-- ====================================================================================================================

function SpellMessages:OnEnable()
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_SENT")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_START")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    RanothUtils:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    RanothUtils:RegisterEvent("GET_ITEM_INFO_RECEIVED")

    SpellMessages:MakeSpellMessageDb()
    for _, spellMessage in pairs(spellMessageDb) do
        spellMessage:requestItemLink()
    end
end

function SpellMessages:OnDisable()
    RanothUtils:UneregisterEvent("UNIT_SPELLCAST_SENT")
    RanothUtils:UneregisterEvent("UNIT_SPELLCAST_START")
    RanothUtils:UneregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    RanothUtils:UneregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    RanothUtils:UneregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    RanothUtils:UneregisterEvent("GET_ITEM_INFO_RECEIVED")
end
