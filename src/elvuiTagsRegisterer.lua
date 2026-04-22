local addon_name, _ = ...
local RanothUtils = LibStub("AceAddon-3.0"):GetAddon(addon_name)
local ElvuiTagsRegisterer = RanothUtils:NewModule("ElvuiTagsRegisterer")

local Debug = RanothUtils:GetModule("Debug")
local unpack = table.unpack or unpack
local tagsRegistered = false

local function RegisterTags()
    if tagsRegistered then return true end
    if not ElvUI then return false end

    local E, L, V, P, G = unpack(ElvUI)
    if not E or type(E.AddTag) ~= "function" then
        return false
    end

    E:AddTag("hpplusabsorbs", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED", function(unit)
        local ok, text = pcall(function()
            local health = UnitHealth(unit)
            local absorb = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0

            -- Secret numbers are safe to stringify, but not safe for arithmetic.
            local healthText = tostring(health or 0)
            local absorbText = tostring(absorb or 0)

            if absorbText ~= "0" then
                return healthText .. " +" .. absorbText
            end

            return healthText
        end)

        if ok then
            return text
        end

        print("Error in hpplusabsorbs tag:", text)
        return ""
    end)

    tagsRegistered = true
    return true
end

function RanothUtils:ADDON_LOADED(_, loadedAddon)
    if loadedAddon ~= "ElvUI" then return end

    if RegisterTags() then
        RanothUtils:UnregisterEvent("ADDON_LOADED")
    end
end

function ElvuiTagsRegisterer:OnEnable()
    if not RegisterTags() then
        RanothUtils:RegisterEvent("ADDON_LOADED")
    end
end

function ElvuiTagsRegisterer:OnDisable()
    RanothUtils:UnregisterEvent("ADDON_LOADED")
end
