--- Registers additional slash commands for the addon and some utility without strings attached.
--- @module "Commands"

-- TODO: Change the way commands are registered to use the AceConsole-3.0 library.
-- TODO: use /ranu as a prefix instead of commands without a prefix.

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)

local AutoOpen = RanothUtils:GetModule("AutoOpen")
local Printer = RanothUtils:GetModule("Printer")
local Debug = RanothUtils:GetModule("Debug")

local Commands = RanothUtils:NewModule("Commands")

--- Registers additional slash commands for the addon.
function Commands:RegisterAdditionalSlashCommands()
    SLASH_DEBUGTESTCOMMAND1 = "/toggledebug"
    --- Toggles debug mode on or off.
    SlashCmdList.DEBUGTESTCOMMAND = function()
        Debug:Toggle()
        Printer:Print(Debug:IsEnabled() and "Debug mode enabled" or "Debug mode disabled")
    end

    SLASH_SWITCHLANGUAGES1 = "/swlang"
    --- Opens all containers in the specified bag.
    SlashCmdList.SWITCHLANGUAGES = function()
        local b, l, c, g = DEFAULT_CHAT_FRAME.editBox, "languageID", GetNumLanguages, GetLanguageByIndex
        for i = 1, c() do
            local n, id = g(i)
            if id == b[l] then
                if i == c() then i = 0 end
                local nn, ni = g(i + 1)
                b[l] = ni
                Printer:Print("Speaking " .. nn)
                break
            end
        end
    end

    SLASH_OPENEGGS1 = "/openeggs"
    --- Opens all Brightly Colored Eggs in the player's bags.
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
    --- Opens all containers in the player's bags.
    SlashCmdList.OPENALLCONTAINERS = AutoOpen.OpenAllContainers

    SLASH_CALCULATRIX1 = "/calc"
    --- Evaluates a mathematical expression and prints the result.
    SlashCmdList.CALCULATRIX = function(expression)
        local result = loadstring("return " .. expression)()
        Printer:Print(result)
    end

    SLASH_TOGGLEAUTOOPEN1 = "/autoopen"
    --- Toggles the AutoOpen module on or off.
    SlashCmdList.TOGGLEAUTOOPEN = AutoOpen.Toggle
end

function Commands:OnInitialize()
    self:RegisterAdditionalSlashCommands()
end
