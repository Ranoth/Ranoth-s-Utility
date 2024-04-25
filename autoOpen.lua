local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local AutoOpen = RanothUtils:NewModule("AutoOpen")
local Debug = RanothUtils:GetModule("Debug")

local function singleBagOpenAllContainers(bagID)
    local delay = 0
    for slot = 1, C_Container.GetContainerNumSlots(bagID) do
        local itemlink = C_Container.GetContainerItemLink(bagID, slot)
        Debug:Print("itemlink: " .. (itemlink or "nil"))
        local tooltipText
        if itemlink then
            local itemTooltip = _G["ItemTooltip"] or
                CreateFrame("GameTooltip", "ItemTooltip", UIParent, "GameTooltipTemplate")
            itemTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            itemTooltip:SetBagItem(bagID, slot)
            for i = 1, itemTooltip:NumLines() do
                tooltipText = _G["ItemTooltipTextLeft" .. i]:GetText()
            end
        end
        ---@diagnostic disable-next-line: undefined-field
        if tooltipText and string.find(tooltipText, _G.ITEM_OPENABLE) then
            local _, _, locked = C_Container.GetContainerItemInfo(bagID, slot)
            if not locked then
                C_Timer.After(delay, function()
                    C_Container.UseContainerItem(bagID, slot)
                    CloseLoot()
                end)
                delay = delay + 0.4
            end
        end
    end
end

function AutoOpen:OpenAllContainers()
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        singleBagOpenAllContainers(bag)
    end
end

function AutoOpen:Open(bagID)
    Debug:Print("AutoOpen:Open(" .. bagID .. ")")
    singleBagOpenAllContainers(bagID)
end

function AutoOpen:Toggle()
    if AutoOpen:IsEnabled() then
        AutoOpen:Disable()
    else
        AutoOpen:Enable()
    end
    print("AutoOpen is now " .. (AutoOpen:IsEnabled() and "enabled" or "disabled"))
end

function RanothUtils:BAG_UPDATE(self, bagID)
    if not AutoOpen:IsEnabled() then return end
    Debug:Print("BAG_UPDATE: " .. bagID)
    AutoOpen:Open(bagID)
end

function RanothUtils:BANKFRAME_OPENED()
    RanothUtils:UnregisterEvent("BANKFRAME_OPENED")
    if not AutoOpen:IsEnabled() then return end
    Debug:Print("BANKFRAME_OPENED")
    RanothUtils:RegisterEvent("BANKFRAME_CLOSED")
    AutoOpen:Disable()
end

function RanothUtils:BANKFRAME_CLOSED()
    RanothUtils:UnregisterEvent("BANKFRAME_CLOSED")
    if AutoOpen:IsEnabled() then return end
    Debug:Print("BANKFRAME_CLOSED")
    RanothUtils:RegisterEvent("BANKFRAME_OPENED")
    AutoOpen:Enable()
end

function AutoOpen:OnInitialize()
    self.db = RanothUtils.db.profile.autoOpen
    if self.db then
        self:Enable()
    else
        self:Disable()
    end
end

function AutoOpen:OnEnable()
    RanothUtils.db.profile.autoOpen = AutoOpen:IsEnabled()
    RanothUtils:RegisterEvent("BAG_UPDATE")
    RanothUtils:RegisterEvent("BANKFRAME_OPENED")
end

function AutoOpen:OnDisable()
    RanothUtils.db.profile.autoOpen = AutoOpen:IsEnabled()
    RanothUtils:UnregisterEvent("BAG_UPDATE")
end
