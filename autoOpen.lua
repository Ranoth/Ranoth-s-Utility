local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local AutoOpen = RanothUtils:NewModule("AutoOpen")
local Debug = RanothUtils:GetModule("Debug")

local toggled

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
            ---@diagnostic disable-next-line: undefined-field
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

function AutoOpen:Open(bagID)
    Debug:Print("AutoOpen:Open(" .. bagID .. ")" )
    singleBagOpenAllContainers(bagID)
end

function AutoOpen:Toggle()
    toggled = not toggled
    RanothUtils.db.profile.autoOpen = toggled
    print("AutoOpen is now " .. (toggled and "enabled" or "disabled"))
end

function AutoOpen:OnInitialize()
    toggled = RanothUtils.db.profile.autoOpen
end