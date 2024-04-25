local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)

local Printer = RanothUtils:NewModule("Printer")

local colorizedAddonName = "|cffc66ff0" .. addon_name .. "|r"

function Printer:Print(...)
    local args = { ... }
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    print(colorizedAddonName .. ": " .. table.concat(args, " "))
end