local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function addon:OnInitialize()
    private:InitializeDatabase()
    private:InitializeFrame()
    private:InitializeSlashCommands()
end

function addon:OnEnable()
    -- MOVE TO SLASH COMMAND
    -- private.frame:Show()
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

function private:GetTabName(guildID, tabID)
    if tabID == MAX_GUILDBANK_TABS + 1 then
        return L["Money Tab"]
    end
    return private.db.global.guilds[guildID].tabs[tabID] and private.db.global.guilds[guildID].tabs[tabID].name or L["Tab"] .. " " .. tabID
end

function private:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * 60 * 60) + (day * 60 * 60 * 24) + (month * 60 * 60 * 24 * 31) + (year * 60 * 60 * 24 * 31 * 12)
    return scanTime - sec
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

function addon:SlashCommandFunc(input)
    local cmd, arg = strsplit(" ", strlower(input))
    if cmd == "scan" then
        addon:ScanGuildBank(nil, arg == "o")
    else
        private:LoadFrame()
    end
end
