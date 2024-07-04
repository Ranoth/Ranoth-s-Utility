--- Registers additional slash commands for the addon and some utility without strings attached.
--- @module "Commands"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)

local AutoOpen = RanothUtils:GetModule("AutoOpen")
local Printer = RanothUtils:GetModule("Printer")
local Debug = RanothUtils:GetModule("Debug")
local ThreeDViewer = RanothUtils:GetModule("ThreeDViewer")

local Commands = RanothUtils:NewModule("Commands")

--- prints the help message for the addon's slash commands
local function printHelp()
    Printer:Print("Available commands")
    Printer:Print("|cffffff00/ranu toggledebug|r - Toggles debug mode")
    Printer:Print("|cffffff00/ranu swlang|r - Switches the language of the chat box")
    Printer:Print("|cffffff00/ranu openeggs|r - Opens all Brightly Colored Eggs in your bags")
    Printer:Print("|cffffff00/ranu openall|r - Opens all containers in your bags")
    Printer:Print("|cffffff00/ranu calc|r |cff00ff00<expression>|r - Evaluates a mathematical expression")
    Printer:Print("|cffffff00/ranu autoopen|r - Toggles auto-opening containers in your bags")
    Printer:Print("|cffffff00/ranu view|r |cff00ff00<(optionnal)displayID>|r - Opens a 3D viewer of the unit under your mouse or from the provided Display ID")
end

--- Registers additional slash commands for the addon
function Commands:RegisterAdditionalSlashCommands()
    RanothUtils:RegisterChatCommand("ranu", function(input)
        local command, args = RanothUtils:GetArgs(input, 2)
        if not command then
            printHelp()
            return
        end

        --- @type table<string, function>
        local commandList = {
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
            ["autoopen"] = AutoOpen.Toggle,
            ["view"] = function(args)
                local arguments = input:match("view%s+(.+)")
                if not arguments then
                    local unit = "mouseover"
                    ThreeDViewer:CreateThreeDViewerFrame(UnitGUID(unit), unit)
                else
                    ThreeDViewer:CreateThreeDViewerFrame(nil, nil, tonumber(arguments))
                end
            end,
            ["toggleviewer"] = ThreeDViewer.Toggle,
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
