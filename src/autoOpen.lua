--- Auto Open containers from the backpack.
--- @module "AutoOpen"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)

local Debug = RanothUtils:GetModule("Debug")
local Printer = RanothUtils:GetModule("Printer")

local AutoOpen = RanothUtils:NewModule("AutoOpen")

local canOpen

--- Open all containers from the specified bag.
--- @param bagID number
--- @usage `AutoOpen:SingleBagOpenAllContainers(1)`
function AutoOpen:SingleBagOpenAllContainers(bagID)
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
        --- @diagnostic disable-next-line: undefined-field
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

--- Toggle the module off when the bank or guild bank is opened.
--- @param eventName any
--- @param closedEventName any
--- @usage `AutoOpen:HandleFrameOpened("BANKFRAME_OPENED", "BANKFRAME_CLOSED")`
function AutoOpen:HandleFrameOpened(eventName, closedEventName)
    RanothUtils:UnregisterEvent(eventName)
    Debug:Print(eventName)
    if not AutoOpen:IsEnabled() then return end
    canOpen = false
    RanothUtils:RegisterEvent(closedEventName)
end

--- Toggle the module back on when the bank or guild bank is closed.
--- @param eventName any
--- @param openedEventName any
--- @usage `AutoOpen:HandleFrameClosed("BANKFRAME_CLOSED", "BANKFRAME_OPENED")`
function AutoOpen:HandleFrameClosed(eventName, openedEventName)
    RanothUtils:UnregisterEvent(eventName)
    Debug:Print(eventName)
    if not AutoOpen:IsEnabled() then return end
    canOpen = true
    RanothUtils:RegisterEvent(openedEventName)
end

--- Open all containers from the backpack.
function AutoOpen:OpenAllContainers()
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        AutoOpen:SingleBagOpenAllContainers(bag)
    end
end

--- Open all containers from the bag where the item has landed.
function AutoOpen:Open(bagID)
    if not canOpen then return end
    Debug:Print("AutoOpen:Open(" .. bagID .. ")")
    AutoOpen:SingleBagOpenAllContainers(bagID)
end

--- Toggle the module on or off.
function AutoOpen:Toggle()
    if AutoOpen:IsEnabled() then
        AutoOpen:Disable()
    else
        AutoOpen:Enable()
    end
    Debug:Print("Toggled AutoOpen " .. (AutoOpen:IsEnabled() and "enabled" or "disabled"))
    Printer:Print("AutoOpen is now " .. (AutoOpen:IsEnabled() and "enabled" or "disabled"))
end

-- Event handlers block.
-- ====================================================================================================================
function RanothUtils:BAG_UPDATE(self, bagID)
    Debug:Print("BAG_UPDATE: " .. bagID)
    AutoOpen:Open(bagID)
end

function RanothUtils:BANKFRAME_OPENED()
    AutoOpen:HandleFrameOpened("BANKFRAME_OPENED", "BANKFRAME_CLOSED")
end

function RanothUtils:BANKFRAME_CLOSED()
    AutoOpen:HandleFrameClosed("BANKFRAME_CLOSED", "BANKFRAME_OPENED")
end

function RanothUtils:GUILDBANKFRAME_OPENED()
    AutoOpen:HandleFrameOpened("GUILDBANKFRAME_OPENED", "GUILDBANKFRAME_CLOSED")
end

function RanothUtils:GUILDBANKFRAME_CLOSED()
    AutoOpen:HandleFrameClosed("GUILDBANKFRAME_CLOSED", "GUILDBANKFRAME_OPENED")
end

-- ====================================================================================================================

function AutoOpen:OnInitialize()
    canOpen = true
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
    RanothUtils:RegisterEvent("GUILDBANKFRAME_OPENED")
end

function AutoOpen:OnDisable()
    RanothUtils.db.profile.autoOpen = AutoOpen:IsEnabled()
    RanothUtils:UnregisterEvent("BAG_UPDATE")
    RanothUtils:UnregisterEvent("BANKFRAME_OPENED")
    RanothUtils:UnregisterEvent("GUILDBANKFRAME_OPENED")
end
