local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function addon:OnInitialize()
    private:InitializeDatabase()
    private:InitializeFrame()
end

function addon:OnEnable()
    -- MOVE TO SLASH COMMAND
    private.frame:Show()
    -- private:LoadTransactions()
end

function addon:OnDisable() end

function private:GetGuildDisplayName(guildID)
    local guild, realm, faction = string.match(guildID, "(.+)%s%-%s(.*)%s%((.+)%)")
    local guildFormat = private.db.global.settings.preferences.guildFormat
    guildFormat = string.gsub(guildFormat, "%%g", guild)
    guildFormat = string.gsub(guildFormat, "%%r", realm)
    guildFormat = string.gsub(guildFormat, "%%f", faction)
    guildFormat = string.gsub(guildFormat, "%%F", strsub(faction, 1, 1)) -- shortened faction

    return guildFormat
end
