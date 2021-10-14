local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")




addon.unitsToSeconds = {
    minutes = 60,
    hours = 60 * 60,
    days = 60 * 60 * 24,
    weeks = 60 * 60 * 24 * 7,
    months = 60 * 60 * 24 * 31,
}

function addon:OnInitialize()
    self:InitializeDatabase()
    self:CleanupDatabase()
    self:InitializeOptions()

    for command, commandInfo in pairs(self.db.global.commands) do
        if commandInfo.enabled then
            self:RegisterChatCommand(command, commandInfo.func)
        end
    end
end


function addon:OnEnable()
    LoadAddOn("Blizzard_GuildBankUI")

    self:RegisterEvent("GUILDBANKFRAME_CLOSED")
    self:RegisterEvent("GUILDBANKFRAME_OPENED")

    -- C_Timer.After(5, function()
    --     ACD:SelectGroup(addonName, "export")
    --     ACD:Open(addonName)
    -- end)
end


function addon:OnDisable()
    self:UnregisterAllEvents()
end


function addon:SlashCommandFunc(input)
    input = strupper(input)
    if input == "SCAN" then
        self:ScanGuildBank()
    else
        ACD:SelectGroup(addonName, "review")
        ACD:Open(addonName)
    end
end


function addon:GetGuildDisplayName(guildID)
    local guild, realm, faction = string.match(guildID, "(.+)%s%-%s(.*)%s%((.+)%)")
    local guildFormat = self.db.global.settings.preferences.guildFormat
    guildFormat = string.gsub(guildFormat, "%%g", guild)
    guildFormat = string.gsub(guildFormat, "%%r", realm)
    guildFormat = string.gsub(guildFormat, "%%f", faction)
    guildFormat = string.gsub(guildFormat, "%%F", strsub(faction, 1, 1)) -- shortened faction

    return guildFormat
end


function addon:GetGuildID()
    local guildName = GetGuildInfo("player")
    local faction = UnitFactionGroup("player")
    local realm = GetRealmName()
    local guildID = format("%s - %s (%s)", guildName, realm, faction)

    return guildID, guildName, faction, realm
end
