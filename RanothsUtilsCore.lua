local Addon = LibStub("AceAddon-3.0"):NewAddon("RanothsUtility", "AceEvent-3.0", "AceHook-3.0")

local _G = getfenv(0)
local SecureButton
local WorldFrame = _G.WorldFrame

local SpellMessagePrefixMap = {
    SENT = "",
    STARTED = "",
    INTERRUPTED = "{Cross} Failed to ",
    STOPPED = "{Cross} Failed to ",
    SUCCEEDED = "{Triangle} Successfully ",
}

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

local function soulstoneMessage(msgType)
    local _, isAlive = selectTarget()

    local soulstoneMessages = {
        ["sent"] = function() if isAlive then return "Placing a" else return "Resurrecting" end end,
        ["started"] = function() if isAlive then return "Placing a" else return "Resurrecting" end end,
        ["interrupted"] = function() if isAlive then return "place a" else return "resurrect" end end,
        ["stopped"] = function() if isAlive then return "place a" else return "resurrect" end end,
        ["succeeded"] = function() if isAlive then return "placed a" else return "resurrected" end end,
    }

    return soulstoneMessages[msgType]()
end

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


local function createSpellMessage(prefix, msg, spellId, itemId, plural, target, groupName)
    if msg == "" then return end

    local itemLink = itemId and select(2, GetItemInfo(itemId)) or ""
    local spellLink = spellId and GetSpellLink(spellId) or ""
    local link = (itemLink ~= "" and itemLink or spellLink) .. (plural and "s" or "")
    local groupNameDisplay = groupName and (" " .. select(2, selectChannel())) or ""
    local targetDisplay = target and (" " .. selectTarget()) or ""
    local groupOrTarget = groupNameDisplay ~= "" and groupNameDisplay or targetDisplay

    if spellId == 200218 then
        link = "Blingtron-6000"
    elseif spellId == 20707 and not select(2, selectTarget()) then
        link = ""
        groupOrTarget = groupOrTarget:match("^%s*(.-)%s*$")
    end

    return prefix .. msg .. " " .. link .. groupOrTarget .. "!"
end

local function createSpellMessageEntry(spellId, itemId, sentMsg, startedMsg, interruptedMsg, stoppedMsg, succeededMsg,
                                       plural, target, group)
    return {
        spellId = spellId,
        itemId = itemId,
        plural = plural,
        link = link,
        sentMsg = sentMsg,
        startedMsg = startedMsg,
        interruptedMsg = interruptedMsg,
        stoppedMsg = stoppedMsg,
        succeededMsg = succeededMsg,
        target = target,
        group = group,
    }
end

local SpellMessageMap = {
    -- Add more entries like this:
    -- [spellId] = createSpellMessageEntry(spellId, itemId, sentMsg, startedMsg, interruptedMsg, stoppedMsg, succeededMsg, plural, target, group)

    [29893] = createSpellMessageEntry(29893, 5512, "Making", "", "make", "", "made", true, false, true), -- Create Soulwell, Healthstone
    [698] = createSpellMessageEntry(698, false, "Using", "", "", "", "", false),                         -- Ritual of Summoning, No Item
    [20707] = createSpellMessageEntry(20707, false, soulstoneMessage("sent"), "", soulstoneMessage("interrupted"), "",
        soulstoneMessage("succeeded"),
        false, true),                                                                                         -- Soulstone, No Item
    [187748] = createSpellMessageEntry(187748, 127770, "Placing a", "", "place a", "", "placed a", false),    -- Brazier of Awakening, Brazier of Awakening
    [67826] = createSpellMessageEntry(67826, 49040, "", "", "", "", "summoned", true),                        -- Jeeves, Jeeves
    [256153] = createSpellMessageEntry(256153, 153647, "Placing a", "", "place a", "", "placed a", false),    -- Deployable Attire Rearranger, Tome of the Quiet Mind
    [384908] = createSpellMessageEntry(384908, 198268, "Placing a", "", "place a", "", "placed a", false),    -- Portable Tinker's Workbench, Portable Tinker's Workbench
    [299127] = createSpellMessageEntry(299127, 168222, "Placing an", "", "place an", "", "placed an", false), -- Encrypted Black Market Radio, Encrypted Black Market Radio
    [200218] = createSpellMessageEntry(200218, false, "", "Placing a", "place a", "", "placed a", false),     -- Blingtron-6000, No Item
    [200205] = createSpellMessageEntry(200205, 132514, "", "Placing an", "place an", "", "placed an", false), -- Reaves Module: Repair Mode, Auto-Hammer
}

local function prepareSendChatMessage(message, channel)
    if channel == nil then return end
    SendChatMessage(message, channel)
end

local function registerAdditionalSlashCommands()
    SLASH_DEBUGTESTCOMMAND1 = "/dbt"
    SlashCmdList.DEBUGTESTCOMMAND = function(id)
        local map = SpellMessageMap[id]

        prepareSendChatMessage(
            createSpellMessage(SpellMessagePrefixMap.SENT, map.interruptedMsg, map.spellId, map.itemId, map.plural,
                map.target or false, map.group or false), selectChannel())
    end

    SLASH_SWITCHLANGUAGES1 = "/swlang"
    SlashCmdList.SWITCHLANGUAGES = function()
        local b, l, c, g = DEFAULT_CHAT_FRAME.editBox, "languageID", GetNumLanguages, GetLanguageByIndex
        for i = 1, c() do
            local n, id = g(i)
            if id == b[l] then
                if i == c() then i = 0 end
                local nn, ni = g(i + 1)
                b[l] = ni
                print("Speaking " .. nn)
                break
            end
        end
    end

    SLASH_OPENEGGS1 = "/openeggs"
    SlashCmdList.OPENEGGS = function()
        local delay = 0
        for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local itemlink = C_Container.GetContainerItemLink(bag, slot)
                if itemlink and string.find(itemlink, "Brightly Colored Egg") then
                    local _, _, locked = C_Container.GetContainerItemInfo(bag, slot)
                    if not locked then
                        C_Timer.After(delay, function()
                            C_Container.UseContainerItem(bag, slot)
                            CloseLoot()
                        end)
                        delay = delay + 0.4
                    end
                end
            end
        end
    end

    SLASH_OPENALLCONTAINERS1 = "/openall"
    SlashCmdList.OPENALLCONTAINERS = function()
        local delay = 0
        for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local itemlink = C_Container.GetContainerItemLink(bag, slot)
                local tooltipText
                if itemlink then
                    local itemTooltip = _G["ItemTooltip"] or
                        CreateFrame("GameTooltip", "ItemTooltip", UIParent, "GameTooltipTemplate")
                    itemTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                    itemTooltip:SetBagItem(bag, slot)
                    for i = 1, itemTooltip:NumLines() do
                        tooltipText = _G["ItemTooltipTextLeft" .. i]:GetText()
                    end
                end
                if tooltipText and string.find(tooltipText, _G.ITEM_OPENABLE) then
                    local _, _, locked = C_Container.GetContainerItemInfo(bag, slot)
                    if not locked then
                        C_Timer.After(delay, function()
                            C_Container.UseContainerItem(bag, slot)
                            CloseLoot()
                        end)
                        delay = delay + 0.4
                    end
                end
            end
        end
    end
end

local function PlayerCastSent(unit, _, _, spellId)
    if unit ~= "player" then return end

    Addon:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellCastInterrupted")
    Addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellcastSucceeded")

    local map = SpellMessageMap[spellId]

    prepareSendChatMessage(
        createSpellMessage(SpellMessagePrefixMap.SENT, map.sentMsg, map.spellId, map.itemId, map.plural,
            map.target or false, map.group or false), selectChannel())
end

local function PlayerCastInterrupted(unit, _, spellId)
    if unit ~= "player" then return end

    Addon:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    Addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    local map = SpellMessageMap[spellId]

    prepareSendChatMessage(
        createSpellMessage(SpellMessagePrefixMap.INTERRUPTED, map.interruptedMsg, map.spellId, map.itemId, map.plural,
            map.target or false, map.group or false), selectChannel())
end

local function PlayerCastSucceeded(unit, _, spellId)
    if unit ~= "player" then return end

    Addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    Addon:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")

    local map = SpellMessageMap[spellId]

    prepareSendChatMessage(
        createSpellMessage(SpellMessagePrefixMap.SUCCEEDED, map.succeededMsg, map.spellId, map.itemId, map.plural,
            map.target or false, map.group or false), selectChannel())
end

local function NPCCastStart(unit, castGUID, spellID)
    if unit ~= "target" then return end
    Addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellcastSucceeded")

    local map = SpellMessageMap[spellID]

    prepareSendChatMessage(
        createSpellMessage(SpellMessagePrefixMap.STARTED, map.startedMsg, map.spellId, map.itemId, map.plural,
            map.target or false, map.group or false), selectChannel())
end

local function NPCCastSucceeded(unit, castGUID, spellID)
    if unit ~= "target" then return end

    Addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellcastSucceeded")

    local map = SpellMessageMap[spellID]

    prepareSendChatMessage(
        createSpellMessage(SpellMessagePrefixMap.SUCCEEDED, map.succeededMsg, map.spellId, map.itemId, map.plural,
            map.target or false, map.group or false), selectChannel())
end

function Addon:OnSpellcastSent(self, unit, _, _, spellId)
    PlayerCastSent(unit, _, _, spellId)
end

function Addon:OnSpellcastStart(self, unit, castGUID, spellId)
    NPCCastStart(unit, castGUID, spellId)
end

function Addon:OnSpellCastInterrupted(self, unit, _, spellId)
    PlayerCastInterrupted(unit, _, spellId)
end

function Addon:OnSpellcastSucceeded(self, unit, _, spellId)
    PlayerCastSucceeded(unit, _, spellId)
    NPCCastSucceeded(unit, _, spellId)
end

function Addon:OnSpellcastStop(self, unit, _, spellId)
end

function Addon:OnCombatLogEventUnfiltered(self, ...)
    local _, subevent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()

    if subevent == "SPELL_INTERRUPT" and (sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("pet")) then
        local channel, _ = selectChannel()
        local extraSpellId = select(15, CombatLogGetCurrentEventInfo())
        prepareSendChatMessage("Interrupted " .. destName .. "'s " .. GetSpellLink(extraSpellId) .. "!", channel)
    end
    -- elseif subevent == "SPELL_PERIODIC_INTERRUPT" and (sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("pet")) then -- TODO: test if the above code can detect interrupted channeling spells
    --     print("test")
    --     local channel, _ = SelectChannel()
    --     local extraSpellId = select(15, CombatLogGetCurrentEventInfo())
    --     PrepareSendChatMessage("Interrupted " .. destName .. "'s " .. GetSpellLink(extraSpellId) .. "!", channel)
    -- end
    -- elseif subevent == "ENVIRONMENTAL_SUMMON" and sourceGUID == UnitGUID("player") then  -- TODO: for now, I can make "kind of" sure that the player is the one summoned the reaves
    --     local channel, _ = SelectChannel()                                               -- TODO: by using the fact that the player must be targetting the Reaves to use its modes
    --     local spellId = select(12, CombatLogGetCurrentEventInfo())                       -- TODO: However this can fail, or not chat anything if the player stops targetting the Reaves
    --     -- if spellId == 200061 then                                                     -- TODO: Make this code work to find the GUID of the summoned Reaves
    --     PrepareSendChatMessage("Summoned " .. destName .. "!", channel)
    --     -- end
    -- end
end

function Addon:OnInitialize()
    registerAdditionalSlashCommands()
    -- MakeSecureButton()
end

function Addon:OnEnable()
    Addon:RegisterEvent("UNIT_SPELLCAST_SENT", "OnSpellcastSent")
    Addon:RegisterEvent("UNIT_SPELLCAST_START", "OnSpellcastStart")
    Addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEventUnfiltered")
end

function Addon:OnDisable()
    Addon:UnhookAll()
    Addon:UnregisterAllEvents()
end
