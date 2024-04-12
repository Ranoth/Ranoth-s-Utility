local SpellMessages = RanothUtils:GetModule("SpellMessages")
local Commands = RanothUtils:GetModule("Commands")

function RanothUtils:UNIT_SPELLCAST_SENT(self, unit, _, _, spellId)
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    SpellMessages:PlayerCastSent(unit, _, _, spellId)
end

function RanothUtils:UNIT_SPELLCAST_START(self, unit, castGUID, spellId)
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    SpellMessages:NpcCastStart(unit, castGUID, spellId)
end

function RanothUtils:UNIT_SPELLCAST_INTERRUPTED(self, unit, _, spellId)
    RanothUtils:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    RanothUtils:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    SpellMessages:PlayerCastInterrupted(unit, _, spellId)
end

function RanothUtils:UNIT_SPELLCAST_SUCCEEDED(self, unit, _, spellId)
    RanothUtils:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    RanothUtils:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    SpellMessages:PlayerCastSucceeded(unit, _, spellId)
    SpellMessages:NpcCastSucceeded(unit, _, spellId)
end

-- function RanothUtils:UNIT_SPELLCAST_STOP(self, unit, _, spellId)
-- end

function RanothUtils:COMBAT_LOG_EVENT_UNFILTERED(self, _)
    SpellMessages:InterruptedSpellCast()
end

function RanothUtils:OnInitialize()
    Commands:RegisterAdditionalSlashCommands()
end

function RanothUtils:OnEnable()
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_SENT")
    RanothUtils:RegisterEvent("UNIT_SPELLCAST_START")
    RanothUtils:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function RanothUtils:OnDisable()
    RanothUtils:UnhookAll()
    RanothUtils:UnregisterAllEvents()
end
