local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

------------------------------------------------------------

local format, strupper = string.format, string.upper
local pairs = pairs

--*------------------------------------------------------------------------

function addon:OnInitialize()
    self:InitializeDatabase()

    for command, commandInfo in pairs(self.db.global.commands) do
        if commandInfo.enabled then
            self:RegisterChatCommand(command, commandInfo.func)
        end
    end
end

--*------------------------------------------------------------------------

function addon:OnEnable()
    LoadAddOn("Blizzard_GuildBankUI") -- ensures we have the necessary constants

    self:RegisterEvent("GUILDBANKFRAME_CLOSED")
    self:RegisterEvent("GUILDBANKFRAME_OPENED")

    self:InitializeReviewFrame()
end

------------------------------------------------------------

function addon:OnDisable()
    self:UnregisterEvent("GUILDBANKFRAME_CLOSED")
    self:UnregisterEvent("GUILDBANKFRAME_OPENED")
end

--*------------------------------------------------------------------------

function addon:SlashCommandFunc(input)
    input = strupper(input)
    if input == "SCAN" then
        self:ScanGuildBank()
    else
        self.ReviewFrame:Load()
    end
end

--*------------------------------------------------------------------------

function addon:GetGuildID()
    local guildName = GetGuildInfo("player")
    local faction = UnitFactionGroup("player")
    local realm = GetRealmName()
    local guildID = format("%s - %s (%s)", guildName, realm, faction)

    return guildID, guildName, faction, realm
end

------------------------------------------------------------

function addon:GetGuildDisplayName(guildID)
    return guildID
end