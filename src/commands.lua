--- Registers additional slash commands for the addon and some utility without strings attached.
--- @module "Commands"

local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local Commands = RanothUtils:NewModule("Commands")

local AutoOpen = RanothUtils:GetModule("AutoOpen")
local Printer = RanothUtils:GetModule("Printer")
local Debug = RanothUtils:GetModule("Debug")
local ThreeDViewer = RanothUtils:GetModule("ThreeDViewer")
local SpellMessages = RanothUtils:GetModule("SpellMessages")

local addonShortHand = string.lower("ranu")

local function colorizeShortHand(shortHand)
    return "|cffffff00" .. shortHand .. "|r"
end

local function colorizeArgHelp(argsHelp)
    return "|cff00ff00" .. argsHelp .. "|r"
end

--- @type table<string, table>
local commandList = {
    ["help"] = {
        func = Commands.PrintHelp,
        help = "Prints the help message for the addon's slash commands"
    },
    ["toggledebug"] = {
        func = Debug.Toggle,
        help = "Toggles debug mode"
    },
    ["swlang"] = {
        func = function()
            local b, l, c, g = DEFAULT_CHAT_FRAME.editBox, "languageID", GetNumLanguages, GetLanguageByIndex
            for i = 1, c() do
                local _, id = g(i)
                if id == b[l] then
                    if i == c() then i = 0 end
                    local nn, ni = g(i + 1)
                    b[l] = ni -- luacheck: ignore
                    Printer:Print("Speaking " .. nn)
                    break
                end
            end
        end,
        help = "Switches the language of the chat box"
    },
    ["openeggs"] = {
        func = function()
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
        help = "Opens all Brightly Colored Eggs in your bags"
    },
    ["openall"] = {
        func = AutoOpen.OpenAllContainers,
        help = "Opens all containers in your bags"
    },
    ["calc"] = {
        func = function(args) -- luacheck: no unused args
            local expression = args:gsub("[^%d%+%-%*/%%%^%.%s%(%)]", ""):gsub("%s+", "")
            if not expression then
                Printer:Print("No expression provided")
                return
            end
            local result = loadstring("return " .. expression)()
            Printer:Print(result)
        end,
        help = "Evaluates a mathematical expression",
        argsHelp = "<expression>"
    },
    ["autoopen"] = {
        func = AutoOpen.Toggle,
        help = "Toggles auto-opening containers in your bags"
    },
    ["view"] = {
        func = function(args) -- luacheck: no unused args
            local arguments = tonumber(args)
            if not arguments then
                local unit = "mouseover"
                local GUID = UnitGUID(unit)
                if not GUID then
                    Printer:Print("No unit under your mouse")
                    return
                end
                ThreeDViewer:CreateThreeDViewerFrame(GUID, unit)
            else
                ThreeDViewer:CreateThreeDViewerFrame(nil, nil, tonumber(arguments))
            end
        end,
        help = "Opens a 3D viewer of the unit under your mouse or from the provided Display ID",
        argsHelp = "<(optionnal)displayID>"
    },
    ["toggleviewer"] = {
        func = ThreeDViewer.Toggle,
        help = "Toggles the model viewer's button. UI Reload needed to toggle off."
    },
    ["interfaceversion"] = {
        func = function()
            Printer:Print("Interface version: " .. select(4, GetBuildInfo()))
        end,
        help = "Prints the interface version"
    },
    ["dumpplayerbuffs"] = {
        func = function()
            for i = 1, 40 do
                local aura = C_UnitAuras.GetBuffDataByIndex("player", i)
                if not aura then return end
                for k, v in pairs(aura) do
                    Printer:Print(k .. ": " .. tostring(v))
                    if type(v) == "table" then
                        for kk, vv in pairs(v) do
                            Printer:Print(k .. "." .. kk .. ": " .. tostring(vv))
                        end
                    end
                end
                Printer:Print("--------------------------------------------")
            end
        end,
        help = "Dumps the player's buffs data"
    },
    ["catalyst"] = {
        func = function()
            local charges = C_CurrencyInfo.GetCurrencyInfo(2813).quantity or 0
            Printer:Print("Catalyst charges: " .. charges)
        end,
        help = "Prints the current amount of catalyst charges"
    },
    ["click"] = {
        func = function()
            SpellMessages:PrepareSendChatMessage("CLICK ON THE TP")
        end,
        help = "Sends a click message to the raid"
    },
}

--- prints the help message for the addon's slash commands
function Commands:PrintHelp()
    Printer:Print("Available commands")
    for command, info in pairs(commandList) do
        local argText = info.argsHelp and " " .. colorizeArgHelp(info.argsHelp) or ""
        if info.help then
            Printer:Print(colorizeShortHand(addonShortHand) .. " " .. command .. argText .. " - " .. info.help)
        end
    end
end

--- Registers additional slash commands for the addon
RanothUtils:RegisterChatCommand(addonShortHand, function(input)
    local command, args = input:match("^(%S*)%s*(.-)$") -- match the first word as the command then the rest of the input as a string of arguments

    local commandInfo = commandList[command]
    if commandInfo and commandInfo.func then
        commandInfo.func(args)
    else
        Commands:PrintHelp()
        Printer:Print("Unknown or invalid command: " .. "\"" .. command .. "\"")
    end
end)
