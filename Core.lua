local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")


function addon:OnInitialize()
    self:InitializeDatabase()
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
    
    C_Timer.After(5, function()
        ACD:SelectGroup(addonName, "analyze", "tab1")
        ACD:Open(addonName)
    end)
end


function addon:OnDisable()
    self:UnregisterAllEvents()
end


function addon:SlashCommandFunc(input)
    input = strupper(input)
    if input == "SCAN" then
        self:ScanGuildBank()
    elseif input == "DEFAULT" then
        self.db.global.settings.defaultGuild = self:GetGuildID()
    else
        ACD:SelectGroup(addonName, "review")
        ACD:Open(addonName)
    end
end


function addon:GetGuildDisplayName(guildID)
    return guildID
end


function addon:GetGuildID()
    local guildName = GetGuildInfo("player")
    local faction = UnitFactionGroup("player")
    local realm = GetRealmName()
    local guildID = format("%s - %s (%s)", guildName, realm, faction)

    return guildID, guildName, faction, realm
end