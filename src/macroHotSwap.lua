local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local MacroHotSwap = RanothUtils:NewModule("MacroHotSwap")

local Printer = RanothUtils:GetModule("Printer")

local potMacroName = "MISC"
local burstPotsIds = {
    ["ll"] = {
        ["longName"] = "Liquid Luster",
        ["1"] = 271886,
        ["2"] = 271887,
        ["flt"] = 274764
    },
    ["reck"] = {
        ["longName"] = "Potion of Recklessness",
        ["1"] = 241289,
        ["2"] = 241288,
        ["flt"] = 245902
    },
    ["lp"] = {
        ["longName"] = "Light's Potential",
        ["1"] = 241308,
        ["2"] = 241309,
        ["flt"] = 245898
    }
}

local function PasteInMacro(macroName, macroText)
    local name, body = GetMacroInfo(macroName)
    if name then
        EditMacro(name, nil, nil, macroText)
    end
end

local function BuildPotMacroBody(potName, quality)
    local potInfo = burstPotsIds[potName]
    if potInfo and potInfo[quality] then
        return
            "#showtooltip\n" .. "/dismount [mounted]\n" .. "/stopmacro [mounted]\n" .. "/cancelaura Burning Rush\n" ..
                "/use [mod:ctrl]item:" .. potInfo[quality] ..
                ";[mod:shift]Gladiator's Medallion;[known:111400]Burning Rush;[noknown:111400]Nether Ward"
    end
    return ""
end

function MacroHotSwap:UpdatePotMacro(potName, quality)
    local macroText = BuildPotMacroBody(potName, quality)
    PasteInMacro(potMacroName, macroText)
    Printer:Print(potMacroName .. " macro's burst potion updated with " .. burstPotsIds[potName].longName ..
                      " of quality " .. quality)
end

function MacroHotSwap:OnEnable()
end

function MacroHotSwap:OnDisable()
end
