local Commands = RanothUtils:NewModule("Commands")

function Commands:RegisterAdditionalSlashCommands()
    SLASH_DEBUGTESTCOMMAND1 = "/dbt"
    SlashCmdList.DEBUGTESTCOMMAND = function(id)
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

    SLASH_CALCULATRIX1 = "/calc"
    SlashCmdList.CALCULATRIX = function(expression)
        local result = loadstring("return " .. expression)()
        print(result)
    end
end
