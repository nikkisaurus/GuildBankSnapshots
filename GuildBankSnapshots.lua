local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded

private.unitsToSeconds = {
    minutes = 60,
    hours = 60 * 60,
    days = 60 * 60 * 24,
    weeks = 60 * 60 * 24 * 7,
    months = 60 * 60 * 24 * 31,
}

function addon:OnInitialize()
    private:InitializeDatabase()
    private:CleanupDatabase()
    private:InitializeFrame()
    private:InitializeSlashCommands()

    EventUtil.ContinueOnAddOnLoaded("Blizzard_GuildBankUI", function()
        addon:HookScript(_G["GuildBankFrame"], "OnShow", addon.GUILDBANKFRAME_OPENED)
        addon:HookScript(_G["GuildBankFrame"], "OnHide", addon.GUILDBANKFRAME_CLOSED)

        if IsAddOnLoaded("ArkInventory") and _G["ARKINV_Frame4"] then
            addon:HookScript(_G["ARKINV_Frame4"], "OnShow", addon.GUILDBANKFRAME_OPENED)
            addon:HookScript(_G["ARKINV_Frame4"], "OnHide", addon.GUILDBANKFRAME_CLOSED)
        elseif IsAddOnLoaded("Bagnon") and _G["BagnonBankFrame1"] then
            addon:HookScript(_G["BagnonBankFrame1"], "OnShow", addon.GUILDBANKFRAME_OPENED)
            addon:HookScript(_G["BagnonBankFrame1"], "OnHide", addon.GUILDBANKFRAME_CLOSED)
        end

        C_Timer.After(5, function()
            -- Added delay because it seems some addons may be loading the guild bank UI before I have the data I need
            private:UpdateGuildDatabase()
        end)
    end)
end

function addon:OnEnable()
    addon:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function addon:PLAYER_ENTERING_WORLD()
    if private.db.global.debug then
        C_Timer.After(1, function()
            private:LoadFrame()
        end)
    end
end

function addon:OnDisable()
    addon:UnregisterAllEvents()
end

function addon:SlashCommandFunc(input)
    local cmd, arg = strsplit(" ", strlower(input))
    if cmd == "scan" then
        addon:ScanGuildBank(nil, arg == "o")
    else
        private:LoadFrame()
    end
end

function private:GetGuildDisplayName(guildID)
    local guild, realm, faction = string.match(guildID, "(.+)%s%-%s(.*)%s%((.+)%)")
    local guildFormat = private.db.global.settings.preferences.guildFormat
    guildFormat = string.gsub(guildFormat, "%%g", guild)
    guildFormat = string.gsub(guildFormat, "%%r", realm)
    guildFormat = string.gsub(guildFormat, "%%f", faction)
    guildFormat = string.gsub(guildFormat, "%%F", strsub(faction, 1, 1)) -- shortened faction

    return guildFormat
end

function private:GetGuildID()
    local guildName = GetGuildInfo("player")
    local faction = UnitFactionGroup("player")
    local realm = GetRealmName()
    if not guildName then
        return
    end
    local guildID = format("%s - %s (%s)", guildName, realm, faction)

    return guildID, guildName, faction, realm
end

function private:InitializeSlashCommands()
    for command, commandInfo in pairs(private.db.global.commands) do
        if commandInfo.enabled then
            addon:RegisterChatCommand(command, commandInfo.func)
        else
            addon:UnregisterChatCommand(command)
        end
    end
end
