local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

private.defaults = {
    gui = {
        backdrop = {
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        },
        borderColor = { 0, 0, 0, 1 },
        bgColor = { 0.1, 0.1, 0.1, 1 },
        darkBgColor = { 0, 0, 0, 0.5 },
        highlightBgColor = { 0.3, 0.3, 0.3, 1 },
        emphasizeBgColor = { 1, 0.82, 0, 0.5 },
        font = { "Fonts\\2002.TTF", 10, "OUTLINE" },
        fontLarge = { "Fonts\\2002.TTF", 12, "OUTLINE" },
        fontColor = { 1, 1, 1, 1 },
        emphasizeFontColor = { 1, 0.82, 0, 1 },
    },
}

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
