local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
private.review = {}

GUILD_BANK_LOG_TIME_PREPEND = GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   "

local lists = {
    filters = {
        name = L["Name"],
        type = L["Type"],
        item = L["Item"],
        ilvl = L["Item Level"],
        clear = L["Clear Filter"],
    },
    filtersSort = { "name", "type", "item", "ilvl", "clear" },
    moneyFilters = {
        name = L["Name"],
        type = L["Type"],
        clear = L["Clear Filter"],
    },
    moneyFiltersSort = { "name", "type", "clear" },
    moneyTypes = {
        buyTab = L["Buy Tab"],
        deposit = L["Deposit"],
        repair = L["Repair"],
        withdraw = L["Withdraw"],
        withdrawForTab = L["Withdraw For Tab"],
        clear = L["Clear Filter"],
    },
    moneyTypesSort = { "buyTab", "deposit", "repair", "withdraw", "withdrawForTab", "clear" },
    types = {
        deposit = L["Deposit"],
        move = L["Move"],
        withdraw = L["Withdraw"],
        clear = L["Clear Filter"],
    },
    typesSort = { "deposit", "move", "withdraw", "clear" },
}

function private:GetReviewOptions()
    local moneyTab = MAX_GUILDBANK_TABS + 1

    local options = {}

    for guildKey, guild in addon.pairs(private.db.global.guilds) do
        options[guildKey] = {
            type = "group",
            name = private:GetGuildDisplayName(guildKey),
            args = {},
        }

        local i = 0
        for scanID, scan in
            addon.pairs(guild.scans, function(a, b)
                return a > b
            end)
        do
            i = i + 1
            options[guildKey].args[tostring(scanID)] = {
                order = i,
                type = "group",
                name = date(private.db.global.settings.preferences.dateFormat, scanID),
                childGroups = "tab",
                args = {
                    deleteScan = {
                        order = 1,
                        type = "execute",
                        name = L["Delete Scan"],
                        confirm = function()
                            return private.db.global.settings.preferences.confirmDeletions and L.ConfirmDeleteScan
                        end,
                        func = function()
                            private.db.global.guilds[guildKey].scans[scanID] = nil
                            private:RefreshOptions()
                        end,
                    },
                    review = {
                        order = 2,
                        type = "group",
                        name = L["Review"],
                        childGroups = "tab",
                        args = {
                            sorting = {
                                order = 1,
                                type = "select",
                                style = "dropdown",
                                name = L["Sorting"],
                                values = {
                                    asc = L["Ascending"],
                                    des = L["Descending"],
                                },
                                disabled = function()
                                    return addon.tcount(guild.scans) == 0
                                end,
                                get = function()
                                    return private.db.global.settings.preferences.sorting
                                end,
                                set = function(_, value)
                                    private.db.global.settings.preferences.sorting = value
                                    private:RefreshOptions()
                                end,
                            },
                            copyText = {
                                order = 2,
                                type = "toggle",
                                name = L["Copy Text"],
                                disabled = function()
                                    return addon.tcount(guild.scans) == 0
                                end,
                                get = function()
                                    return private.review.copyText
                                end,
                                set = function(_, value)
                                    private.review.copyText = value
                                end,
                            },
                        },
                    },
                    analyze = {
                        order = 3,
                        type = "group",
                        name = L["Analyze"],
                        childGroups = "tab",
                        args = private:GetAnalyzeOptions(guildKey, scanID),
                    },
                },
            }

            for tab = 1, moneyTab do
                options[guildKey].args[tostring(scanID)].args.review.args[tostring(tab)] = {
                    order = tab + 2,
                    type = "group",
                    name = function()
                        local tabName
                        if tab == moneyTab then
                            tabName = L["Money Tab"]
                        elseif private.db.global.guilds[guildKey].tabs[tab] then
                            tabName = private.db.global.guilds[guildKey].tabs[tab].name
                        end
                        tabName = tabName ~= "" and tabName or format("%s %d", L["Tab"], tab)

                        return tabName
                    end,
                    disabled = function()
                        return tab ~= moneyTab and private.db.global.guilds[guildKey].numTabs < tab
                    end,
                    args = {
                        filterType = {
                            order = 1,
                            type = "select",
                            style = "dropdown",
                            name = L["Filter"],
                            values = function()
                                return tab == moneyTab and lists.moneyFilters or lists.filters
                            end,
                            sorting = function()
                                return tab == moneyTab and lists.moneyFiltersSort or lists.filtersSort
                            end,
                            get = function()
                                return private.review.filterType
                            end,
                            set = function(_, value)
                                private.review.filterType = value ~= "clear" and value
                                private.review.filter = nil
                                private.review.minIlvl = nil
                                private.review.maxIlvl = nil
                            end,
                        },
                        filter = {
                            order = 2,
                            type = "select",
                            style = "dropdown",
                            name = function()
                                if tab ~= moneyTab and private.review.filter == "repair" then
                                    private.review.filter = nil
                                end
                                return (private.review.filter and L["Filter"] .. ": " .. private.review.filter) or ""
                            end,
                            values = function()
                                local values = {
                                    clear = L["Clear Filter"],
                                }

                                local filterType = private.review.filterType
                                local transactions = tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions

                                if filterType == "name" then
                                    for _, transaction in pairs(transactions) do
                                        local info = tab < moneyTab and private:GetTransactionInfo(transaction) or private:GetMoneyTransactionInfo(transaction)
                                        values[info.name] = info.name
                                    end
                                elseif filterType == "type" then
                                    if tab == moneyTab then
                                        return lists.moneyTypes
                                    else
                                        return lists.types
                                    end
                                elseif filterType == "item" then
                                    for _, transaction in pairs(transactions) do
                                        local info = tab < moneyTab and private:GetTransactionInfo(transaction) or private:GetMoneyTransactionInfo(transaction)
                                        values[info.itemLink] = info.itemLink
                                    end
                                end

                                return values
                            end,
                            sorting = function()
                                local values = {}

                                local filterType = private.review.filterType
                                local transactions = tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions

                                if not transactions then
                                    tinsert(values, "clear")
                                    return values
                                end

                                if filterType == "name" then
                                    for _, transaction in
                                        addon.pairs(transactions, function(a, b)
                                            return private:GetTransactionInfo(transactions[a]).name < private:GetTransactionInfo(transactions[b]).name
                                        end)
                                    do
                                        local info = tab < moneyTab and private:GetTransactionInfo(transaction) or private:GetMoneyTransactionInfo(transaction)
                                        if not addon.GetTableKey(values, info.name) then
                                            tinsert(values, info.name)
                                        end
                                    end
                                elseif filterType == "type" then
                                    if tab == moneyTab then
                                        return lists.moneyTypesSort
                                    else
                                        return lists.typesSort
                                    end
                                elseif filterType == "item" then
                                    for _, transaction in
                                        addon.pairs(transactions, function(a, b)
                                            local infoA = private:GetTransactionInfo(transactions[a])
                                            local infoB = private:GetTransactionInfo(transactions[b])
                                            local _, _, itemA = strfind(select(3, strfind(infoA.itemLink, "|H(.+)|h")), "%[(.+)%]")
                                            local _, _, itemB = strfind(select(3, strfind(infoB.itemLink, "|H(.+)|h")), "%[(.+)%]")

                                            return itemA < itemB
                                        end)
                                    do
                                        local info = tab < moneyTab and private:GetTransactionInfo(transaction) or private:GetMoneyTransactionInfo(transaction)
                                        if not addon.GetTableKey(values, info.itemLink) then
                                            tinsert(values, info.itemLink)
                                        end
                                    end
                                end

                                tinsert(values, "clear")

                                return values
                            end,
                            hidden = function()
                                if tab == moneyTab and (private.review.filterType == "item" or private.review.filterType == "ilvl") then
                                    private.review.filterType = nil
                                end

                                return not private.review.filterType or private.review.filterType == "ilvl"
                            end,
                            get = function()
                                return private.review.filter ~= "clear" and private.review.filter
                            end,
                            set = function(_, value)
                                private.review.filter = value ~= "clear" and value
                            end,
                        },
                        minIlvl = {
                            order = 3,
                            type = "range",
                            min = 1,
                            max = 304,
                            step = 1,
                            name = L["Min Item Level"],
                            hidden = function()
                                return private.review.filterType ~= "ilvl"
                            end,
                            get = function(info)
                                return private.review[info[#info]] or 1
                            end,
                            set = function(info, value)
                                private.review[info[#info]] = value
                            end,
                        },
                        maxIlvl = {
                            order = 4,
                            type = "range",
                            min = 1,
                            max = 304,
                            step = 1,
                            name = L["Max Item Level"],
                            hidden = function()
                                return private.review.filterType ~= "ilvl"
                            end,
                            get = function(info)
                                return private.review[info[#info]] or 304
                            end,
                            set = function(info, value)
                                private.review[info[#info]] = value
                            end,
                        },
                        copyText = {
                            order = 5,
                            type = "input",
                            multiline = 14,
                            width = "full",
                            name = "",
                            hidden = function()
                                return not private.review.copyText
                            end,
                            get = function()
                                local text = ""
                                local transactions = tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions

                                for transactionID, transaction in
                                    addon.pairs(transactions, function(a, b)
                                        if private.db.global.settings.preferences.sorting == "des" then
                                            return a > b
                                        else
                                            return a < b
                                        end
                                    end)
                                do
                                    local info = tab == moneyTab and private:GetMoneyTransactionInfo(transaction) or private:GetTransactionInfo(transaction)
                                    local line = (tab < moneyTab and private:GetTransactionLabel(scanID, transactions[transactionID]) or private:GetMoneyTransactionLabel(scanID, transactions[transactionID])) or ""

                                    local filterType, isFiltered = private.review.filterType
                                    if filterType then
                                        if filterType == "name" and private.review.filter then
                                            isFiltered = info.name ~= private.review.filter
                                        elseif filterType == "type" and private.review.filter then
                                            isFiltered = info.transactionType ~= private.review.filter
                                        elseif filterType == "item" and private.review.filter then
                                            isFiltered = info.itemLink ~= private.review.filter
                                        elseif filterType == "ilvl" then
                                            local _, _, _, _, _, itemType = GetItemInfo(info.itemLink)
                                            if itemType ~= "Weapon" and itemType ~= "Armor" then
                                                isFiltered = true
                                            else
                                                local ilvl = GetDetailedItemLevelInfo(info.itemLink)
                                                isFiltered = ilvl < (private.review.minIlvl or 1) or ilvl > (private.review.maxIlvl or 304)
                                            end
                                        end
                                    end

                                    if not isFiltered then
                                        text = text == "" and line or (text .. "|r\n" .. line)
                                    end
                                end
                                return text
                            end,
                        },
                    },
                }

                local i = 101
                for line = 25, 1, -1 do
                    options[guildKey].args[tostring(scanID)].args.review.args[tostring(tab)].args["line" .. line] = {
                        order = i,
                        type = "description",
                        dialogControl = "GuildBankSnapshotsTransaction",
                        hidden = function()
                            -- Hide if copying text
                            if private.review.copyText then
                                return true
                            end

                            -- Update filters
                            if tab == moneyTab then
                                if private.review.filterType == "item" or private.review.filterType == "ilvl" then
                                    private.review.filterType = nil
                                end
                                if private.review.filter == "move" then
                                    private.review.filter = nil
                                end
                            elseif private.review.filter == "repair" then
                                private.review.filter = nil
                            end

                            -- Parse filters
                            local filterType = private.review.filterType
                            local transactions = tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions
                            local transaction = transactions[line]

                            if not transaction then
                                return true
                            end

                            local info = tab == moneyTab and private:GetMoneyTransactionInfo(transaction) or private:GetTransactionInfo(transaction)
                            local name = tab < moneyTab and private:GetTransactionLabel(scanID, transaction) or private:GetMoneyTransactionLabel(scanID, transaction)

                            if filterType == "name" and private.review.filter then
                                return info.name ~= private.review.filter
                            elseif filterType == "type" and private.review.filter then
                                return info.transactionType ~= private.review.filter
                            elseif filterType == "item" and private.review.filter then
                                return info.itemLink ~= private.review.filter
                            elseif filterType == "ilvl" then
                                local _, _, _, _, _, itemType = GetItemInfo(info.itemLink)
                                if itemType ~= "Weapon" and itemType ~= "Armor" then
                                    return true
                                end
                                local ilvl = GetDetailedItemLevelInfo(info.itemLink)
                                return ilvl < (private.review.minIlvl or 1) or ilvl > (private.review.maxIlvl or 304)
                            elseif not name or name == "" then
                                return true
                            end
                        end,
                        name = function()
                            local transactions = tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions
                            return tab < moneyTab and private:GetTransactionLabel(scanID, transactions[line]) or private:GetMoneyTransactionLabel(scanID, transactions[line])
                        end,
                        width = "full",
                    }
                    if private.db.global.settings.preferences.sorting == "des" then
                        i = i + 1
                    else
                        i = i - 1
                    end
                end
            end
        end
    end

    return options
end
