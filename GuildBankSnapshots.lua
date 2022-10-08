local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")

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
    private:InitializeOptions()
    private:InitializeSlashCommands()

    EventUtil.ContinueOnAddOnLoaded("Blizzard_GuildBankUI", function()
        local version = select(4, GetBuildInfo())
        if version >= 100002 then
            if IsAddOnLoaded("ElvUI") then
                -- get bank frame
            elseif IsAddOnLoaded("ArkInventory") then
                -- get bank frame
            elseif IsAddOnLoaded("Bagnon") then
                -- get bank frame
            else
                private.bankFrame = _G["GuildBankFrame"]
            end

            addon:HookScript(private.bankFrame, "OnShow", addon.GUILDBANKFRAME_OPENED)
            addon:HookScript(private.bankFrame, "OnHide", addon.GUILDBANKFRAME_CLOSED)
        else
            addon:RegisterEvent("GUILDBANKFRAME_CLOSED")
            addon:RegisterEvent("GUILDBANKFRAME_OPENED")
        end

        private:UpdateGuildDatabase()
    end)
end

function addon:OnEnable()
    addon:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function addon:PLAYER_ENTERING_WORLD()
    if private.db.global.debug then
        C_Timer.After(1, function()
            ACD:SelectGroup(addonName)
            ACD:Open(addonName)
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
        if _G["GuildBankSnapshotsExportFrame"] then
            _G["GuildBankSnapshotsExportFrame"]:Hide()
        end
        ACD:SelectGroup(addonName, "review")
        ACD:Open(addonName)
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
