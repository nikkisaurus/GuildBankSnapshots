local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

------------------------------------------------------------

local format = string.format

--*------------------------------------------------------------------------

function addon:OnInitialize()
    self:InitializeDatabase()
end

--*------------------------------------------------------------------------

function addon:OnEnable()
    self:RegisterEvent("GUILDBANKFRAME_CLOSED")
    self:RegisterEvent("GUILDBANKFRAME_OPENED")
end

------------------------------------------------------------

function addon:OnDisable()
    self:UnregisterEvent("GUILDBANKFRAME_CLOSED")
    self:UnregisterEvent("GUILDBANKFRAME_OPENED")
end

--*------------------------------------------------------------------------

function addon:GetGuildID()
    local guildName = GetGuildInfo("player")
    local faction = UnitFactionGroup("player")
    local realm = GetRealmName()
    local guildID = format("%s (%s) - %s", guildName, faction, realm)

    return guildID, guildName, faction, realm
end

--*------------------------------------------------------------------------

function addon:GUILDBANKFRAME_CLOSED()
    if self.isScanning then
        if self.isScanning ~= "auto" or self.db.global.settings.autoScanAlert then
            self:Print(L["Scan failed."])
        end
        self.isScanning = nil
    end
end

------------------------------------------------------------

function addon:GUILDBANKFRAME_OPENED()
    self:UpdateGuildDatabase()
    self:ScanGuildBank(true)
end