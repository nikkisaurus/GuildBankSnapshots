local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:GetFilterNames(guildKey, scanID, none)
    local scan = private.db.global.guilds[guildKey].scans[scanID]
    local names, sorting = {}, {}

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

    for _, tabInfo in pairs(scan.tabs) do
        for _, transaction in pairs(tabInfo.transactions) do
            local info = private:GetTransactionInfo(transaction)
            items[info.itemLink] = info.itemLink
        end
    end

    for itemLink, _ in
        addon.pairs(items, function(a, b)
            local _, _, itemA = strfind(select(3, strfind(a, "|H(.+)|h")), "%[(.+)%]")
            local _, _, itemB = strfind(select(3, strfind(b, "|H(.+)|h")), "%[(.+)%]")

            return itemA < itemB
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
