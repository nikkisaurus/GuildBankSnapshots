local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

private.sortDesc = function(a, b)
    return a > b
end

private.timeInSeconds = {
    seconds = 1,
    minutes = 60,
    hours = 3600,
    days = 86400,
    weeks = 604800,
    months = 2628000,
    years = 31540000,
}

function private:dprint(...)
    if private.db.global.debug then
        print(...)
    end
end

function private:GetClassColor()
    return GetClassColor(select(2, UnitClass("player")))
end

function private:GetGuildDisplayName(guildKey)
    if not guildKey then
        return ""
    end

    local guild, realm, faction = string.match(guildKey, "(.+)%s%-%s(.*)%s%((.+)%)")
    local guildFormat = private.db.global.preferences.guildFormat
    guildFormat = string.gsub(guildFormat, "%%g", guild)
    guildFormat = string.gsub(guildFormat, "%%r", realm)
    guildFormat = string.gsub(guildFormat, "%%f", faction)
    guildFormat = string.gsub(guildFormat, "%%F", strsub(faction, 1, 1)) -- shortened faction

    return guildFormat
end

function private:GetguildKey()
    local guildName = GetGuildInfo("player")
    local faction = UnitFactionGroup("player")
    local realm = GetRealmName()
    local guildKey = format("%s - %s (%s)", guildName, realm, faction)

    return guildKey, guildName, faction, realm
end

function private:GetItemRank(itemLink)
    assert(type(itemLink) == "string", "GetItemRank: itemLink must be a string")
    return tonumber(itemLink:match("|A.-Tier(%d).-|a")) or 0
end

function private:GetItemString(itemLink)
    assert(type(itemLink) == "string", "GetItemString: itemLink must be a string")
    return select(3, strfind(itemLink, "|H(.+)|h"))
end

function private:GetItemName(itemLink)
    return select(3, strfind(private:GetItemString(itemLink) or "", "%[(.+)%]")) or UNKNOWN
end

function private:GetMoneyTransactionInfo(transaction)
    if not transaction then
        return
    end

    local transactionType, name, amount, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

    local info = {
        transactionType = transactionType,
        name = name or UNKNOWN,
        amount = amount,
        year = year,
        month = month,
        day = day,
        hour = hour,
    }

    return info
end

function private:GetTabName(guildKey, tabID)
    if not guildKey then
        private:dprint("Invalid guildKey:", guildKey)
        return
    elseif not tabID then
        private:dprint("Invalid tabID:", tabID)
        return
    end

    if tabID == MAX_GUILDBANK_TABS + 1 then
        return L["Money Tab"]
    end
    return private.db.global.guilds[guildKey].tabs[tabID] and private.db.global.guilds[guildKey].tabs[tabID].name or L["Tab"] .. " " .. tabID
end

function private:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * private.timeInSeconds.hours) + (day * private.timeInSeconds.days) + (month * private.timeInSeconds.months) + (year * private.timeInSeconds.years)
    return scanTime - sec
end

function private:GetTransactionInfo(transaction)
    if not transaction then
        return
    end

    local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

    local info = {
        transactionType = transactionType,
        name = name or UNKNOWN,
        itemLink = (itemLink and itemLink ~= "" and itemLink) or UNKNOWN,
        count = count,
        moveOrigin = moveOrigin,
        moveDestination = moveDestination,
        year = year,
        month = month,
        day = day,
        hour = hour,
    }

    return info
end

function private:IterateGuilds(callback)
    assert(type(callback) == "function", "IterateGuilds: callback must be a function")

    local sortKeys = function(a, b)
        return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
    end

    for guildKey, guild in addon:pairs(private.db.global.guilds, sortKeys) do
        local guildName = private:GetGuildDisplayName(guildKey)
        callback(guildKey, guildName, guild)
    end
end
