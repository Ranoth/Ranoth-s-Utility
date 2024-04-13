local SpellMessages = RanothUtils:NewModule("SpellMessages")

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

function SpellMessages:PrepareSendChatMessage(message)
    if not message then return end
    local channel, _ = selectChannel()
    if channel == nil then return end
    SendChatMessage(message, channel)
end

local spellMessagePrefixMap = {
    SENT = "",
    STARTED = "",
    INTERRUPTED = "{Cross} Failed to ",
    STOPPED = "{Cross} Failed to ",
    SUCCEEDED = "{Triangle} Successfully ",
}

local function SpellMessage(spellId, itemId, sentMsg, startedMsg, interruptedMsg, stoppedMsg, succeededMsg,
                            plural, target, group)
    return {
        spellId = spellId,
        itemId = itemId,
        plural = plural,
        link = link,
        target = target or false,
        group = group or false,
        messages = {
            SENT = sentMsg,
            STARTED = startedMsg,
            INTERRUPTED = interruptedMsg,
            STOPPED = stoppedMsg,
            SUCCEEDED = succeededMsg,
        },
        createSpellMessage = function(self, prefix, key)
            local msg = self.messages[key]
            if msg == "" then return end

            local itemLink = itemId and select(2, GetItemInfo(itemId)) or ""
            local spellLink = spellId and GetSpellLink(spellId) or ""
            local link = (itemLink ~= "" and itemLink or spellLink) .. (plural and "s" or "")
            local groupNameDisplay = group and (" " .. select(2, selectChannel())) or ""
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
    }
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

local spellMessageDb = {
    -- Add more entries like this:
    -- [spellId] = createSpellMessageEntry(spellId, itemId, sentMsg, startedMsg, interruptedMsg, stoppedMsg, succeededMsg, plural, target, group)

    [29893] = SpellMessage(29893, 5512, "Making", "", "make", "", "made", true, false, true), -- Create Soulwell, Healthstone
    [698] = SpellMessage(698, false, "Using", "", "", "", "", false),                         -- Ritual of Summoning, No Item
    [20707] = SpellMessage(20707, false, soulstoneMessage("sent"), "", soulstoneMessage("interrupted"), "",
        soulstoneMessage("succeeded"),
        false, true),                                                                              -- Soulstone, No Item
    [187748] = SpellMessage(187748, 127770, "Placing a", "", "place a", "", "placed a", false),    -- Brazier of Awakening, Brazier of Awakening
    [67826] = SpellMessage(67826, 49040, "", "", "", "", "summoned", true),                        -- Jeeves, Jeeves
    [256153] = SpellMessage(256153, 153647, "Placing a", "", "place a", "", "placed a", false),    -- Deployable Attire Rearranger, Tome of the Quiet Mind
    [384908] = SpellMessage(384908, 198268, "Placing a", "", "place a", "", "placed a", false),    -- Portable Tinker's Workbench, Portable Tinker's Workbench
    [299127] = SpellMessage(299127, 168222, "Placing an", "", "place an", "", "placed an", false), -- Encrypted Black Market Radio, Encrypted Black Market Radio
    [200218] = SpellMessage(200218, false, "", "Placing a", "place a", "", "placed a", false),     -- Blingtron-6000, No Item
    [200205] = SpellMessage(200205, 132514, "", "Placing an", "place an", "", "placed an", false), -- Reaves Module: Repair Mode, Auto-Hammer
}

function SpellMessages:PlayerCastSent(unit, _, _, spellId)
    local spellMessage = spellMessageDb[spellId]
    if unit ~= "player" or spellMessage == nil then return end

    SpellMessages:PrepareSendChatMessage(spellMessage:createSpellMessage(spellMessagePrefixMap.SENT,
        "SENT"))
end

function SpellMessages:PlayerCastInterrupted(unit, _, spellId)
    local spellMessage = spellMessageDb[spellId]
    if unit ~= "player" or spellMessage == nil then return end

    SpellMessages:PrepareSendChatMessage(spellMessage:createSpellMessage(spellMessagePrefixMap.INTERRUPTED,
        "INTERRUPTED"))
end

function SpellMessages:PlayerCastSucceeded(unit, _, spellId)
    local spellMessage = spellMessageDb[spellId]
    if unit ~= "player" or spellMessage == nil then return end

    SpellMessages:PrepareSendChatMessage(spellMessage:createSpellMessage(spellMessagePrefixMap.SUCCEEDED,
        "SUCCEEDED"))
end

function SpellMessages:NpcCastStart(unit, castGUID, spellId)
    local spellMessage = spellMessageDb[spellId]
    if unit ~= "target" or spellMessage == nil then return end

    SpellMessages:PrepareSendChatMessage(spellMessage:createSpellMessage(spellMessagePrefixMap.STARTED,
        "STARTED"))
end

function SpellMessages:NpcCastSucceeded(unit, castGUID, spellId)
    local spellMessage = spellMessageDb[spellId]
    if unit ~= "target" or spellMessage == nil then return end

    SpellMessages:PrepareSendChatMessage(spellMessage:createSpellMessage(spellMessagePrefixMap.SUCCEEDED,
        "SUCCEEDED"))
end

function SpellMessages:InterruptedSpellCast()
    local _, subevent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
    if subevent == "SPELL_INTERRUPT" and (sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("pet")) then
        local extraSpellId = select(15, CombatLogGetCurrentEventInfo())
        SpellMessages:PrepareSendChatMessage("Interrupted " .. destName .. "'s " .. GetSpellLink(extraSpellId) .. "!")
    end
end
