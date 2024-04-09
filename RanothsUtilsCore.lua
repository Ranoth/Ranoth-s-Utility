local _G = getfenv(0)
local SecureButton
local WorldFrame = _G.WorldFrame
local npcCastGUID

local function SelectChannel()
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

local function SelectTarget()
    local target = UnitExists("mouseover") and "mouseover" or "player"
    local isAlive = not UnitIsDeadOrGhost(target)
    if UnitIsPlayer(target) then
        if target == "player" or UnitIsUnit(target, "player") then
            return "myself", isAlive
        else
            return UnitName(target), isAlive
        end
    else
        return "myself", isAlive
    end
end

local Addon = LibStub("AceAddon-3.0"):NewAddon("RanothsUtility", "AceEvent-3.0", "AceHook-3.0")

local function MakeSecureButton()
    SecureButton = CreateFrame("Button", "RanothsUtility", UIParent, "SecureActionButtonTemplate")
    SecureButton:Hide()
    SecureButton:EnableMouse(true)
    SecureButton:RegisterForClicks("RightButtonDown", "RightButtonUp")
    SecureButton:SetAttribute("action", "nil")

    SecureButton:SetScript("PostClick", function(self, button, up)
        if up then return end
        ClearOverrideBindings(self)
    end)
end

local function PrepareSendChatMessage(message, channel)
    if channel == nil then return end
    SendChatMessage(message, channel)
end

local function RegisterAdditionalSlashCommands()
    SLASH_DEBUGTESTCOMMAND1 = "/debugtest"
    SlashCmdList.DEBUGTESTCOMMAND = function()
        print(UnitId(101527))
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

    local channel, _ = SelectChannel()
    local spellMessage = "Using "
    local itemMessage

    local spellItemMap = {
        [29893] = function() return GetSpellLink(29893) end,
        [698] = function() return GetSpellLink(698) end,
        [20707] = function()
            local target, isAlive = SelectTarget()
            if isAlive then
                return "Placing a " .. GetSpellLink(20707) .. " on " .. target
            else
                return "Resurrecting " .. target
            end
        end,
        [187748] = function() return "Placing a " .. select(2, GetItemInfo(127770)) end,
    }

    itemMessage = spellItemMap[spellId] and spellItemMap[spellId]()

    if itemMessage then
        PrepareSendChatMessage(spellMessage .. itemMessage .. "!", channel)
    end
end

local function PlayerCastInterrupted(unit, _, spellId)
    if unit ~= "player" then return end

    Addon:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    Addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    local channel, _ = SelectChannel()
    local spellMessage = "{Cross} Failed to "
    local itemMessage

    local spellItemMap = {
        [187748] = function() return "place a " .. select(2, GetItemInfo(127770)) end,
        [20707] = function()
            local target, isAlive = SelectTarget()
            if isAlive then
                return "place a " .. GetSpellLink(20707) .. " on " .. target
            else
                return "resurrect " .. target
            end
        end,
        [29893] = function() return "use " .. GetSpellLink(29893) end,
    }

    itemMessage = spellItemMap[spellId] and spellItemMap[spellId]()

    if itemMessage then
        PrepareSendChatMessage(spellMessage .. itemMessage .. "!", channel)
    end
end

local function PlayerCastSucceeded(unit, _, spellId)
    if unit ~= "player" then return end

    Addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    Addon:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")

    local channel, groupName = SelectChannel()
    local spellMessage = "{Triangle} Successfully "
    local itemMessage, target, isAlive

    local spellItemMap = {
        [29893] = function() return "made " .. select(2, GetItemInfo(5512)) .. "s " .. groupName end,
        [187748] = function() return "placed a " .. select(2, GetItemInfo(127770)) end,
        [20707] = function()
            target, isAlive = SelectTarget()
            if isAlive then
                return "placed a " .. GetSpellLink(20707) .. " on " .. target
            else
                return "resurrected " .. target
            end
        end,
        [67826] = function() return "Summoned " .. select(2, GetItemInfo(49040)) end,
        [256153] = function() return "Placed a " .. select(2, GetItemInfo(153647)) end,
        [384908] = function() return "Placed a " .. select(2, GetItemInfo(198268)) end,
        [299127] = function() return "Placed an " .. select(2, GetItemInfo(168222)) end,
    }

    itemMessage = spellItemMap[spellId] and spellItemMap[spellId]()

    if itemMessage then
        PrepareSendChatMessage(spellMessage .. itemMessage .. "!", channel)
    end
end

local function NPCCastStart(unit, castGUID, spellID)
    if unit ~= "target" then return end
    local channel, _ = SelectChannel()
    npcCastGUID = nil

    Addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellcastSucceeded")

    local spellItemMap = {
        [200218] = function() return "Placing a Blingtron-6000!" end,
        [200205] = function() return "Placing an " .. select(2, GetItemInfo(132514)) .. "!" end,
    }

    local message = spellItemMap[spellID] and spellItemMap[spellID]()

    if message then
        npcCastGUID = castGUID
    end
end

local function NPCCastSucceeded(unit, castGUID, spellID)
    if unit ~= "target" then return end
    local channel, _ = SelectChannel()

    Addon:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellcastSucceeded")

    if castGUID == npcCastGUID then
        local spellItemMap = {
            [200218] = function() return "Placed a Blingtron-6000!" end,
            [200205] = function() return "Placed an " .. select(2, GetItemInfo(132514)) .. "!" end,
        }

        local message = spellItemMap[spellID] and spellItemMap[spellID]()
        if message then
            PrepareSendChatMessage(message, channel)
        end
        npcCastGUID = nil
    end
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
        local channel, _ = SelectChannel()
        local extraSpellName = select(16, CombatLogGetCurrentEventInfo())
        PrepareSendChatMessage("Interrupted " .. destName .. "'s " .. extraSpellName .. "!", channel)
    elseif subevent == "ENVIRONMENTAL_SUMMON" and sourceGUID == UnitGUID("player") then
        local channel, _ = SelectChannel()
        local spellId = select(12, CombatLogGetCurrentEventInfo())
        -- if spellId == 200061 then
        PrepareSendChatMessage("Summoned " .. destName .. "!", channel)
        -- end
    end
end

function Addon:OnInitialize()
    RegisterAdditionalSlashCommands()
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
