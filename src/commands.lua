--- Registers additional slash commands for the addon and some utility without strings attached.
--- @module "Commands"

-- TODO: Change the way commands are registered to use the AceConsole-3.0 library.
-- TODO: use /ranu as a prefix instead of commands without a prefix to minimize chances of conflicts with other addons.

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)

local AutoOpen = RanothUtils:GetModule("AutoOpen")
local Printer = RanothUtils:GetModule("Printer")
local Debug = RanothUtils:GetModule("Debug")

local Commands = RanothUtils:NewModule("Commands")

--- prints the help message for the addon's slash commands
local function printHelp()
    Printer:Print("Available commands:")
    Printer:Print(" /ranu toggledebug - Toggles debug mode")
    Printer:Print(" /ranu swlang - Switches the language of the chat box")
    Printer:Print(" /ranu openeggs - Opens all Brightly Colored Eggs in your bags")
    Printer:Print(" /ranu openall - Opens all containers in your bags")
    Printer:Print(" /ranu calc <expression> - Evaluates a mathematical expression")
    Printer:Print(" /ranu autoopen - Toggles auto-opening containers in your bags")
end

--- Registers additional slash commands for the addon
function Commands:RegisterAdditionalSlashCommands()
    RanothUtils:RegisterChatCommand("ranu", function(input)
        local command, args = RanothUtils:GetArgs(input, 2)
        if not command then
            printHelp()
            return
        end
        commandList = {
            ["help"] = printHelp,
            ["toggledebug"] = Debug.Toggle,
            ["swlang"] = function()
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
            end,
            ["openeggs"] = function()
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
            end,
            ["openall"] = AutoOpen.OpenAllContainers,
            ["calc"] = function(args)
                local expression = input:match("calc%s+(.+)")
                local result = loadstring("return " .. expression)()
                Printer:Print(result)
            end,
            ["autoopen"] = AutoOpen.Toggle
        }
        if commandList[command] then
            commandList[command](args)
        else
            Printer:Print("Unknown command: " .. command)
            printHelp()
        end
    end)
end

function Commands:OnInitialize()
    self:RegisterAdditionalSlashCommands()
end
