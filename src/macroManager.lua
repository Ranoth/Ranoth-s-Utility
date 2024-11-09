local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local MacroManager = RanothUtils:NewModule("MacroManager")

local Debug = RanothUtils:GetModule("Debug")
local Printer = RanothUtils:GetModule("Printer")

local function CheckIfSpellOnCD(spellId)
    local startTime, duration, enable = C_Spell.GetSpellCooldown(spellId)
    local cd = startTime + duration - GetTime()
    if cd > 0 then
        return true
    else
        return false
    end
end

local function CheckIfItemOnCD(itemId)
    local startTime, duration, enable = C_Container.GetItemCooldown(itemId)
    local cd = startTime + duration - GetTime()
    if cd > 0 then
        return true
    else
        return false
    end
end

local function checkIfItemInInventory(itemId)
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemlink = C_Container.GetContainerItemLink(bag, slot)
            if itemlink and string.find(itemlink, itemId) then
                return true
            end
        end
    end
    return false
end

local function ToHP()
    local macroName = "HEALME"
    local macroBody =
    "#showtooltip\n/ranu updatehealme\n/use [@mouseover,exists,mod:shift][@player,mod:shift]Soulstone;[mod:alt]Subjugate Demon;[mod:ctrl]Soulburn;[btn:2]Fel Domination;[btn:1]item:211879"

    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then
        -- Macro doesn't exist, create it
        CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroBody, nil)
    else
        -- Macro exists, edit it
        EditMacro(macroIndex, macroName, nil, macroBody)
    end
end

local function ToHS()
    local macroName = "HEALME"
    local macroBody =
    "#showtooltip\n/ranu updatehealme\n/use [@mouseover,exists,mod:shift][@player,mod:shift]Soulstone;[mod:alt]Subjugate Demon;[mod:ctrl]Soulburn;[btn:2]Fel Domination;[btn:1]item:224464"

    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex == 0 then
        -- Macro doesn't exist, create it
        CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroBody, nil)
    else
        -- Macro exists, edit it
        EditMacro(macroIndex, macroName, nil, macroBody)
    end
end

function MacroManager:UpdateHEALME()
    if CheckIfItemOnCD(224464) then
        -- Printer:Print("Healthstone is on CD")
        ToHP()
    else
        -- Printer:Print("Healthstone is not on CD")
        ToHS()
    end
    if not checkIfItemInInventory(224464) then
        -- Printer:Print("No Healthstone in backpack")
        ToHP()
    end
end

-- function RanothUtils:BAG_UPDATE_COOLDOWN()
--     Printer:Print("Ticking" .. math.random(1, 100))
-- end

-- function RanothUtils:SPELL_UPDATE_COOLDOWN()
--     UpdateHEALME()
-- end

-- function MacroManager:OnEnable()
--     RanothUtils:RegisterEvent("SPELL_UPDATE_COOLDOWN")
-- end

-- function MacroManager:OnDisable()
--     RanothUtils:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
--     RanothUtils:UnregisterEvent("BAG_UPDATE_COOLDOWN")
-- end
