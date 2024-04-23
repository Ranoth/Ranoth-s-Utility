local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local Core = RanothUtils:NewModule("Core")
local SpellMessages = RanothUtils:GetModule("SpellMessages")
local AutoOpen = RanothUtils:GetModule("AutoOpen")
local Debug = RanothUtils:GetModule("Debug")

function RanothUtils:UNIT_SPELLCAST_SENT(self, unit, _, _, spellId)
    SpellMessages:PlayerCastSent(unit, _, _, spellId)
end

function RanothUtils:UNIT_SPELLCAST_START(self, unit, castGUID, spellId)
    SpellMessages:NpcCastStart(unit, castGUID, spellId)
end

function RanothUtils:UNIT_SPELLCAST_INTERRUPTED(self, unit, _, spellId)
    if unit == "pet" then return end
    if SpellMessages:CheckDuplicateInterruptTrigger(unit, spellId) then return end
    SpellMessages:PlayerCastInterrupted(unit, _, spellId)

    RanothUtils:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    C_Timer.After(0.1, function()
        RanothUtils:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    end)
end

function RanothUtils:UNIT_SPELLCAST_SUCCEEDED(self, unit, _, spellId)
    if unit == "pet" then return end
    SpellMessages:PlayerCastSucceeded(unit, _, spellId)
    SpellMessages:NpcCastSucceeded(unit, _, spellId)
end

function RanothUtils:COMBAT_LOG_EVENT_UNFILTERED()
    local eventInfo = { CombatLogGetCurrentEventInfo() }
    if eventInfo[2] == "SPELL_SUMMON" then
        SpellMessages:SummonedGuardian(unpack(eventInfo))
    elseif eventInfo[2] == "SPELL_INTERRUPT" then
        SpellMessages:InterruptedSpellCast(unpack(eventInfo))
    end
end

function RanothUtils:BAG_UPDATE(self, bagID)
    Debug:Print("BAG_UPDATE: " .. bagID)
    AutoOpen:Open(bagID)
end

function Core:OnEnable()
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_SENT")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_START")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    RanothUtils:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    RanothUtils:RegisterEvent("BAG_UPDATE")
end

function Core:OnDisable()
    RanothUtils:UnhookAll()
    RanothUtils:UnregisterAllEvents()
end
