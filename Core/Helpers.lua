local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

private.timeInSeconds = {
    second = 1,
    minute = 60,
    hour = 3600,
    day = 86400,
    week = 604800,
    month = 2628000,
    year = 31540000,
}

function private:GetGuildDisplayName(guildID)
    if not guildID then
        return ""
    end

    local guild, realm, faction = string.match(guildID, "(.+)%s%-%s(.*)%s%((.+)%)")
    local guildFormat = private.db.global.settings.preferences.guildFormat
    guildFormat = string.gsub(guildFormat, "%%g", guild)
    guildFormat = string.gsub(guildFormat, "%%r", realm)
    guildFormat = string.gsub(guildFormat, "%%f", faction)
    guildFormat = string.gsub(guildFormat, "%%F", strsub(faction, 1, 1)) -- shortened faction

    return guildFormat
end

function private:GetItemName(itemLink)
    assert(type(itemLink) == "string", "GetItemName: itemLink must be a string")
    return select(3, strfind(select(3, strfind(itemLink, "|H(.+)|h")) or "", "%[(.+)%]"))
end

function private:GetTabName(guildID, tabID)
    if not guildID then
        private:dprint("Invalid guildID:", guildID)
        return
    elseif not tabID then
        private:dprint("Invalid tabID:", tabID)
        return
    end

    if tabID == MAX_GUILDBANK_TABS + 1 then
        return L["Money Tab"]
    end
    return private.db.global.guilds[guildID].tabs[tabID] and private.db.global.guilds[guildID].tabs[tabID].name or L["Tab"] .. " " .. tabID
end

function private:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * private.timeInSeconds.hour) + (day * private.timeInSeconds.day) + (month * private.timeInSeconds.month) + (year * private.timeInSeconds.year)
    return scanTime - sec
end

function private:dprint(...)
    if private.db.global.debug then
        print(...)
    end
end
