local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

GUILD_BANK_LOG_TIME_PREPEND = GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   "

function private:GetFilterNames(guildKey, scanID, none)
    local scan = private.db.global.guilds[guildKey].scans[scanID]
    local names, sorting = {}, {}

    if not scan then
        return names, sorting
    end

    for _, tabInfo in pairs(scan.tabs) do
        for _, transaction in pairs(tabInfo.transactions) do
            local info = private:GetTransactionInfo(transaction)
            names[info.name] = info.name
        end
    end

    for _, transaction in pairs(scan.moneyTransactions) do
        local info = private:GetMoneyTransactionInfo(transaction)
        names[info.name] = info.name
    end

    for name, _ in addon.pairs(names) do
        tinsert(sorting, name)
    end

    if none then
        names.clear = L["None"]
        tinsert(sorting, "clear")
    end

    return names, sorting
end

function private:GetFilterItems(guildKey, scanID, none)
    local scan = private.db.global.guilds[guildKey].scans[scanID]
    local items, sorting = {}, {}

    if not scan then
        return items, sorting
    end

    for _, tabInfo in pairs(scan.tabs) do
        for _, transaction in pairs(tabInfo.transactions) do
            local info = private:GetTransactionInfo(transaction)
            items[info.itemLink or "1"] = info.itemLink
        end
    end

    for itemLink, _ in
        addon.pairs(items, function(a, b)
            local _, _, itemA = strfind(select(3, strfind(a or UNKNOWN, "|H(.+)|h")) or UNKNOWN, "%[(.+)%]") or UNKNOWN
            local _, _, itemB = strfind(select(3, strfind(b or UNKNOWN, "|H(.+)|h")) or UNKNOWN, "%[(.+)%]") or UNKNOWN

            return (itemA or UNKNOWN) < (itemB or UNKNOWN)
        end)
    do
        tinsert(sorting, itemLink)
    end

    if none then
        items.clear = L["None"]
        tinsert(sorting, "clear")
    end

    return items, sorting
end

function private:GetFilterTypes(guildKey, scanID)
    local scan = private.db.global.guilds[guildKey].scans[scanID]
    local types, sorting = {}, {}

    if not scan then
        return types, sorting
    end

    for _, tabInfo in pairs(scan.tabs) do
        for _, transaction in pairs(tabInfo.transactions) do
            local info = private:GetTransactionInfo(transaction)
            types[info.transactionType] = addon.StringToTitle(info.transactionType)
        end
    end

    for _, transaction in pairs(scan.moneyTransactions) do
        local info = private:GetMoneyTransactionInfo(transaction)
        types[info.transactionType] = addon.StringToTitle(info.transactionType)
    end

    for transactionType, _ in addon.pairs(types) do
        tinsert(sorting, transactionType)
    end

    types.clear = L["None"]
    tinsert(sorting, "clear")

    return types, sorting
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

function private:GetMoneyTransactionLabel(scanID, transaction)
    local info = private:GetMoneyTransactionInfo(transaction)

    if not info then
        return
    end

    info.name = info.name or UNKNOWN
    info.name = NORMAL_FONT_COLOR_CODE .. info.name .. FONT_COLOR_CODE_CLOSE
    local money = GetDenominationsFromCopper(info.amount)

    local msg
    if info.transactionType == "deposit" then
        msg = format(GUILDBANK_DEPOSIT_MONEY_FORMAT, info.name, money)
    elseif info.transactionType == "withdraw" then
        msg = format(GUILDBANK_WITHDRAW_MONEY_FORMAT, info.name, money)
    elseif info.transactionType == "repair" then
        msg = format(GUILDBANK_REPAIR_MONEY_FORMAT, info.name, money)
    elseif info.transactionType == "withdrawForTab" then
        msg = format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, info.name, money)
    elseif info.transactionType == "buyTab" then
        if info.amount > 0 then
            msg = format(GUILDBANK_BUYTAB_MONEY_FORMAT, info.name, money)
        else
            msg = format(GUILDBANK_UNLOCKTAB_FORMAT, info.name)
        end
    elseif info.transactionType == "depositSummary" then
        msg = format(GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT, money)
    end

    local t = date("*t", time())
    local s = date("*t", scanID)
    local recentDate = RecentTimeDate(info.year + (t.year - s.year), info.month + (t.month - s.month), info.day + (t.day - s.day), info.hour + (t.hour - s.hour))
    if private.db.global.settings.preferences.dateType == "approx" then
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(scanID or time(), info.year, info.month, info.day, info.hour)))
    else
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. format(GUILD_BANK_LOG_TIME, recentDate))
    end

    return msg
end

function private:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * 60 * 60) + (day * 60 * 60 * 24) + (month * 60 * 60 * 24 * 31) + (year * 60 * 60 * 24 * 31 * 12)
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
        itemLink = itemLink,
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

function private:GetTransactionLabel(scanID, transaction)
    local info = private:GetTransactionInfo(transaction)
    if not info then
        return
    end

    info.name = info.name or UNKNOWN
    info.name = NORMAL_FONT_COLOR_CODE .. info.name .. FONT_COLOR_CODE_CLOSE

    local msg
    if info.transactionType == "deposit" then
        msg = format(GUILDBANK_DEPOSIT_FORMAT, info.name, info.itemLink)
        if info.count > 1 then
            msg = msg .. format(GUILDBANK_LOG_QUANTITY, info.count)
        end
    elseif info.transactionType == "withdraw" then
        msg = format(GUILDBANK_WITHDRAW_FORMAT, info.name, info.itemLink)
        if info.count > 1 then
            msg = msg .. format(GUILDBANK_LOG_QUANTITY, info.count)
        end
    elseif info.transactionType == "move" then
        msg = format(GUILDBANK_MOVE_FORMAT, info.name, info.itemLink, info.count, info.moveOrigin, info.moveDestination)
    end

    local t = date("*t", time())
    local s = date("*t", scanID)
    local recentDate = RecentTimeDate(info.year + (t.year - s.year), info.month + (t.month - s.month), info.day + (t.day - s.day), info.hour + (t.hour - s.hour))
    if private.db.global.settings.preferences.dateType == "approx" then
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(scanID or time(), info.year, info.month, info.day, info.hour)))
    else
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. format(GUILD_BANK_LOG_TIME, recentDate))
    end

    return msg
end
