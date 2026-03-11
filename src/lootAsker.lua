local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local LootAsker = RanothUtils:NewModule("LootAsker")

local Debug = RanothUtils:GetModule("Debug")

--#region Initialization
local lootItems = {}
local iconFrames = {}
local itemInfo = nil

local anchorFrame
local moveMode = false
--#endregion Initialization

--#region Loot filtering logic
local class = select(2, UnitClass("player"))
local armorProficiencies = {
    DRUID = "Leather",
    ROGUE = "Leather",
    MONK = "Leather",
    DEMONHUNTER = "Leather",
    HUNTER = "Mail",
    SHAMAN = "Mail",
    EVOKER = "Mail",
    WARRIOR = "Plate",
    PALADIN = "Plate",
    DEATHKNIGHT = "Plate",
    PRIEST = "Cloth",
    MAGE = "Cloth",
    WARLOCK = "Cloth",
}
local weaponProficiencies = {
    DEATHKNIGHT = { "One-Handed Axes", "One-Handed Swords", "One-Handed Maces", "Two-Handed Axes", "Two-Handed Swords", "Two-Handed Maces", "Polearms" },
    DEMONHUNTER = { "Warglaives", "Fist Weapons", "One-Handed Swords" },
    DRUID = { "Staves", "Fist Weapons", "One-Handed Maces", "Two-Handed Maces", "Daggers", "Polearms" },
    EVOKER = { "Staves", "Daggers", "One-Handed Swords" },
    HUNTER = { "Bows", "Guns", "Crossbows", "Polearms", "Staves" },
    MAGE = { "Staves", "One-Handed Swords", "Daggers", "Wands" },
    MONK = { "Staves", "Fist Weapons", "One-Handed Swords", "One-Handed Axes", "One-Handed Maces", "Polearms" },
    PALADIN = { "One-Handed Swords", "One-Handed Axes", "One-Handed Maces", "Two-Handed Swords", "Two-Handed Axes", "Two-Handed Maces", "Polearms" },
    PRIEST = { "Staves", "One-Handed Maces", "Daggers", "Wands" },
    ROGUE = { "Daggers", "Fist Weapons", "One-Handed Swords", "One-Handed Axes", "One-Handed Maces" },
    SHAMAN = { "Staves", "One-Handed Axes", "One-Handed Maces", "Two-Handed Axes", "Two-Handed Maces", "Daggers", "Fist Weapons" },
    WARLOCK = { "Staves", "One-Handed Swords", "Daggers", "Wands" },
    WARRIOR = { "One-Handed Swords", "One-Handed Axes", "One-Handed Maces", "Two-Handed Swords", "Two-Handed Axes", "Two-Handed Maces", "Polearms" },
}
local inventorySlotsForItemLink = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_CLOAK = 15,
    INVTYPE_CHEST = 5,
    INVTYPE_ROBE = 5,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_FINGER = 11,
    INVTYPE_TRINKET = 12,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_RANGED = 18,
    INVTYPE_RANGEDRIGHT = 18,
    INVTYPE_THROWN = 18,
    INVTYPE_RELIC = 18,
}

local function MakeCompareTooltip(itemLink, tooltipName)
    if not UpgradeEquiperItemLinkTooltip or not UpgradeEquiperItemLinkTooltip.SetOwner then
        UpgradeEquiperItemLinkTooltip = CreateFrame("GameTooltip", "UpgradeEquiperItemLinkTooltip", nil,
            "GameTooltipTemplate")
    end
    local tooltip = UpgradeEquiperItemLinkTooltip
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)
    return tooltip, tooltipName
end

local function ExtractItemLevelFromTooltip(itemLink)
    local tooltip = MakeCompareTooltip(itemLink, "LootAskerItemLinkTooltip")
    tooltip:Show()
    for i = 1, tooltip:NumLines() do
        local left = _G[tooltip:GetName() .. "TextLeft" .. i]
        local text = left and left:GetText()
        if text then
            local pat = ITEM_LEVEL:gsub("%%d", "(%%d+)")
            local found = text:match(pat)
            if found then
                tooltip:Hide()
                return tonumber(found)
            end
        end
    end
    tooltip:Hide()
    return nil
end

local function GetEquippedItemLevelAtSlot(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    if itemLink then
        local itemLevel = select(4, GetItemInfo(itemLink))
        return itemLevel or 0
    end
    return 0
end

local function IsLooterDifferentFromSelf(playerName)
    local nameOnly = playerName and playerName:match("([^%-]+)")
    return nameOnly ~= UnitName("player")
end

local function IsItemReceivedMessage(msg)
    if not msg then return false end
    local stringsToFind = { "receives loot", "receive loot", "receive item" }
    for _, str in ipairs(stringsToFind) do
        if msg:lower():find(str) then
            return true
        end
    end
    return false
end

local function CanSelfEquip(itemLink)
    if not RanothUtils.db.profile.checkIfSelfCanEquip then return true end
    local _, _, _, _, _, itemType, itemSubType, _, equipSlot = GetItemInfo(itemLink)
    if equipSlot == INVTYPE_NON_EQUIP_IGNORE then return false end

    if itemType == "Armor" then
        if itemSubType == "Miscellaneous" then return true end
        return itemSubType == armorProficiencies[class]
    elseif itemType == "Weapon" then
        for _, v in ipairs(weaponProficiencies[class]) do
            if v == itemSubType then return true end
        end
    end
    return false
end

local function IsUpgrade(itemLink, slotId)
    if slotId then
        local equippedItemLevel = GetEquippedItemLevelAtSlot(slotId)
        -- print("Comparing item levels: ", e.itemInfo[4], equippedItemLevel)
        if ExtractItemLevelFromTooltip(itemLink) > equippedItemLevel then
            return true
        end
    end
    return false
end

local function QualityFilter(itemLink)
    if not RanothUtils.db.profile.checkItemQuality then return true end
    local quality = select(3, GetItemInfo(itemLink))
    return quality >= RanothUtils.db.profile.minItemQuality
end

local function IsNotWarbound(itemLink)
    if not RanothUtils.db.profile.checkIfNotWarbound then return true end

    if not LootAskerItemLinkTooltip or not LootAskerItemLinkTooltip.SetOwner then
        LootAskerItemLinkTooltip = CreateFrame("GameTooltip", "LootAskerItemLinkTooltip", nil, "GameTooltipTemplate")
    end
    local tooltip = LootAskerItemLinkTooltip
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)
    tooltip:Show()
    for i = 1, tooltip:NumLines() do
        local line = _G["LootAskerItemLinkTooltipTextLeft" .. i]
        local text = line and line:GetText() or ""
        -- if string.find(text, string.format(BIND_TRADE_TIME_REMAINING, ".*")) or string.find(text, string.format(ITEM_BIND_ON_EQUIP, ".*")) or string.find(text, string.format(ITEM_BIND_ON_USE, ".*")) then
        -- if string.find(text, string.format(ITEM_BIND_ON_EQUIP, ".*")) then
        if string.find(text, string.format(ITEM_BIND_TO_ACCOUNT_UNTIL_EQUIP, ".*")) then
            tooltip:Hide()
            return false
        end
    end
    tooltip:Hide()
    return true
end

local function CheckUpgradeOrNotSelf(itemLink, slotId, playerName)
    if IsLooterDifferentFromSelf(playerName) then
        return true
    else
        return IsUpgrade(itemLink, slotId)
    end
end

local function MatchingFilters(itemLink, playerName, msg, slotId)
    local filters = {
        IsItemReceivedMessage(msg),
        CheckUpgradeOrNotSelf(itemLink, slotId, playerName),
        CanSelfEquip(itemLink),
        QualityFilter(itemLink),
        IsNotWarbound(itemLink),
    }

    for _, filter in ipairs(filters) do
        if not filter then return false end
    end
    return true
end
--#endregion Loot filtering logic

local function EquipItemByLink(link)
    local numBagSlots = NUM_BAG_SLOTS or 5
    for bag = 0, numBagSlots do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local item = C_Container.GetContainerItemLink(bag, slot)
            if item and item == link then
                if (CursorHasItem and CursorHasItem()) or (CursorHasMoney and CursorHasMoney()) or (CursorHasSpell and CursorHasSpell()) then
                    ClearCursor()
                end
                C_Container.PickupContainerItem(bag, slot)
                AutoEquipCursorItem()
                return true
            end
        end
    end
end

local function CreateAnchorFrame()
    if anchorFrame then return end

    anchorFrame = CreateFrame("Frame", "RanothUtilsLootAnchor", UIParent, "BackdropTemplate")
    anchorFrame:SetSize(48, 48)
    anchorFrame:SetMovable(true)
    anchorFrame:EnableMouse(false)
    anchorFrame:RegisterForDrag("LeftButton")

    anchorFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    anchorFrame:SetBackdropColor(0, 0.8, 1, 0.25)
    anchorFrame:SetBackdropBorderColor(0, 0.8, 1, 1)

    anchorFrame.text = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    anchorFrame.text:SetPoint("CENTER")
    anchorFrame.text:SetText("Loot Anchor")

    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(
        RanothUtils.db.profile.lootAnchorPoint,
        UIParent,
        RanothUtils.db.profile.lootAnchorRelativePoint,
        RanothUtils.db.profile.lootAnchorX,
        RanothUtils.db.profile.lootAnchorY
    )

    anchorFrame:SetScript("OnDragStart", function(self)
        if not moveMode then return end
        self:StartMoving()
    end)

    anchorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        RanothUtils.db.profile.lootAnchorPoint = point
        RanothUtils.db.profile.lootAnchorRelativePoint = relativePoint
        RanothUtils.db.profile.lootAnchorX = x
        RanothUtils.db.profile.lootAnchorY = y
    end)

    anchorFrame:Hide()
end

--#region Icon frames display logic
local function UpdateLootIconTooltip(iconFrame)
    if not iconFrame or not iconFrame:IsShown() then return end
    GameTooltip:SetOwner(iconFrame, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(iconFrame.itemLink)
    GameTooltip:AddLine("Player: " .. (iconFrame.playerName or "?"), 1, 1, 1)
    GameTooltip:Show()
    if IsModifiedClick("COMPAREITEMS") or (GetCVar("alwaysCompareItems") == "1") then
        if GameTooltip.SetCompareItem then
            GameTooltip:SetCompareItem(GameTooltip)
        else
            GameTooltip_ShowCompareItem()
        end
    end
end

-- Global frame for modifier state tracking
local LootAskerTooltipModFrame = LootAskerTooltipModFrame or CreateFrame("Frame")
local hoveredIcon = nil
LootAskerTooltipModFrame:SetScript("OnEvent", function(_, event, key)
    if event == "MODIFIER_STATE_CHANGED" and hoveredIcon and (key == "LSHIFT" or key == "RSHIFT") then
        UpdateLootIconTooltip(hoveredIcon)
    end
end)
LootAskerTooltipModFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

local function MakeIconFrames(itemLink, playerName)
    if not lootItems[itemLink] then lootItems[itemLink] = {} end
    if not iconFrames[itemLink] then iconFrames[itemLink] = {} end
    if lootItems[itemLink][playerName] then return end
    lootItems[itemLink][playerName] = true

    CreateAnchorFrame()

    local iconFrame = CreateFrame("Button", nil, UIParent)
    iconFrame:SetSize(40, 40)

    local count = 0
    for _, playerIcons in pairs(iconFrames) do
        for _ in pairs(playerIcons) do
            count = count + 1
        end
    end

    local x, y = 0, 0
    local growDirection = RanothUtils.db.profile.growDirection
    if growDirection == 1 then
        y = count * 45
    elseif growDirection == 2 then
        y = -count * 45
    elseif growDirection == 3 then
        x = -count * 45
    elseif growDirection == 4 then
        x = count * 45
    end

    iconFrame:SetPoint("CENTER", anchorFrame, "CENTER", x, y)

    iconFrame.texture = iconFrame:CreateTexture(nil, "BACKGROUND")
    iconFrame.texture:SetAllPoints()
    iconFrame.texture:SetTexture(select(10, GetItemInfo(itemLink)))
    iconFrame.itemLink = itemLink
    iconFrame.playerName = playerName

    if ActionButton_ShowOverlayGlow then
        ActionButton_ShowOverlayGlow(iconFrame)
    else
        local glow = iconFrame:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.8)
        glow:SetWidth(70)
        glow:SetHeight(70)
        glow:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        iconFrame.glow = glow
    end

    -- Tooltip
    iconFrame:SetScript("OnEnter", function(self)
        hoveredIcon = self
        UpdateLootIconTooltip(self)
    end)
    iconFrame:SetScript("OnLeave", function(self)
        hoveredIcon = nil
        GameTooltip:Hide()
    end)

    iconFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            self:Hide()

            lootItems[self.itemLink][self.playerName] = nil
            -- if next(lootItems[self.itemLink]) == nil then lootItems[self.itemLink] = nil end
            iconFrames[self.itemLink][self.playerName] = nil
            -- if next(iconFrames[self.itemLink]) == nil then iconFrames[self.itemLink] = nil end
        elseif button == "LeftButton" then
            if self.glow then self.glow:Hide() end
            if ActionButton_HideOverlayGlow then ActionButton_HideOverlayGlow(self) end

            if IsLooterDifferentFromSelf(self.playerName) then
                SendChatMessage("Do you need " .. self.itemLink .. "?", "WHISPER", nil, self.playerName)
            else
                EquipItemByLink(self.itemLink)

                self:Hide()
                lootItems[self.itemLink][self.playerName] = nil
                iconFrames[self.itemLink][self.playerName] = nil
            end
        end
    end)

    iconFrames[itemLink][playerName] = iconFrame
    iconFrame:Show()
end
--#endregion Icon frames display logic

--#region Entry points
function RanothUtils:CHAT_MSG_LOOT(event, ...)
    local playerName = select(2, ...)

    local msg = select(1, ...)
    if not msg then return end
    local itemLink = msg and msg:match("|c.-|r")
    if not itemLink then return end
    itemInfo = { GetItemInfo(itemLink) }
    if not itemInfo then return end

    local slotId = inventorySlotsForItemLink[itemInfo[9]]
    if slotId == 12 or slotId == 11 or slotId == 2 then return false end -- Trinkets, Rings and Necks are not checked for upgrades

    if not MatchingFilters(itemLink, playerName, msg, slotId) then return end

    MakeIconFrames(itemLink, playerName)
    return true
end

function RanothUtils:CheckIfIconsToDisplay()
    if not iconFrames then return false end
    for _, playerIcons in pairs(iconFrames) do
        if type(playerIcons) == "table" then
            for _, iconFrame in pairs(playerIcons) do
                if iconFrame and iconFrame.IsShown and iconFrame:IsShown() then
                    return true
                end
            end
        end
    end
    return false
end

--#endregion Entry points

function LootAsker:SetMoveMode(enabled)
    moveMode = enabled
    if moveMode then
        CreateAnchorFrame()
        anchorFrame:Show()
        anchorFrame:EnableMouse(true)
    else
        if anchorFrame then
            anchorFrame:EnableMouse(false)
            anchorFrame:Hide()
        end
    end
end

function LootAsker:ToggleMoveMode()
    self:SetMoveMode(not moveMode)
end

function LootAsker:OnEnable()
    RanothUtils:RegisterEvent("CHAT_MSG_LOOT")

    RanothUtils:CheckIfIconsToDisplay()
end

function LootAsker:OnDisable()
    RanothUtils:UnregisterEvent("CHAT_MSG_LOOT")
end
