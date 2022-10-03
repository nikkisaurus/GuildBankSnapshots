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
        deposit = L["Deposit"],
        repair = L["Repair"],
        withdraw = L["Withdraw"],
        clear = L["Clear Filter"],
    },
    moneyTypesSort = { "deposit", "repair", "withdraw", "clear" },
    types = {
        deposit = L["Deposit"],
        move = L["Move"],
        withdraw = L["Withdraw"],
        clear = L["Clear Filter"],
    },
    typesSort = { "deposit", "move", "withdraw", "clear" },
}

local function GetInfo(tab, moneyTab, transaction)
    return tab == moneyTab and private:GetMoneyTransactionInfo(transaction) or private:GetTransactionInfo(transaction)
end

local function GetTransactions(tab, moneyTab)
    local scan = private.review.guildID and private.db.global.guilds[private.review.guildID].scans[private.review.scan]
    return private.review.scan and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)
end

function private:GetMoneyTransactionInfo(transaction)
    if not transaction then
        return
    end

    local transactionType, name, amount, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

    local info = {
        transactionType = transactionType,
        name = name,
        amount = amount,
        year = year,
        month = month,
        day = day,
        hour = hour,
    }

    return info
end

function private:GetMoneyTransactionLabel(transaction)
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

    if private.db.global.settings.preferences.dateType == "approx" then
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(private.review.scan or time(), info.year, info.month, info.day, info.hour)))
    else
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. format(GUILD_BANK_LOG_TIME, RecentTimeDate(info.year, info.month, info.day, info.hour)))
    end

    return msg
end

function private:GetReviewOptions()
    local moneyTab = MAX_GUILDBANK_TABS + 1

    local options = {
        selectGuild = {
            order = 1,
            type = "select",
            style = "dropdown",
            name = L["Guild"],
            width = "full",
            get = function()
                return private.review.guildID or private:SelectReviewGuild(private.db.global.settings.preferences.defaultGuild)
            end,
            set = function(_, guildID)
                private:SelectReviewGuild(guildID)
            end,
            disabled = function()
                return addon.tcount(private.db.global.guilds) == 0
            end,
            values = function()
                local guilds = {}

                for guildID, guildInfo in addon.pairs(private.db.global.guilds) do
                    guilds[guildID] = private:GetGuildDisplayName(guildID)
                end

                return guilds
            end,
        },
        selectScan = {
            order = 2,
            type = "select",
            style = "dropdown",
            name = L["Scan"],
            width = "full",
            get = function()
                return private.review.scan
            end,
            set = function(_, scanID)
                private:SelectReviewScan(scanID)
            end,
            disabled = function()
                return not private.review.guildID or addon.tcount(private.db.global.guilds[private.review.guildID].scans) == 0
            end,
            values = function()
                if not private.review.guildID then
                    return {}
                end

                local scans = {}

                for scanID, _ in pairs(private.db.global.guilds[private.review.guildID].scans) do
                    scans[scanID] = date(private.db.global.settings.preferences.dateFormat, scanID)
                end

                return scans
            end,
            sorting = function()
                if not private.review.guildID then
                    return {}
                end

                local scans = {}

                for scanID, _ in
                    addon.pairs(private.db.global.guilds[private.review.guildID].scans, function(a, b)
                        return b < a
                    end)
                do
                    tinsert(scans, scanID)
                end

                return scans
            end,
        },
        analyzeScan = {
            order = 3,
            type = "execute",
            name = L["Analyze Scan"],
            disabled = function()
                return not private.review.scan
            end,
            func = function(info)
                ACD:SelectGroup(addonName, "analyze")
                private:SelectAnalyzeGuild(private.review.guildID)
                private:SelectAnalyzeScan(private.review.scan, info)
            end,
        },
        deleteScan = {
            order = 4,
            type = "execute",
            name = L["Delete Scan"],
            disabled = function()
                return not private.review.scan
            end,
            confirm = function()
                return private.db.global.settings.preferences.confirmDeletions and L.ConfirmDeleteScan
            end,
            func = function()
                private.db.global.guilds[private.review.guildID].scans[private.review.scan] = nil
                private:SelectReviewScan()
            end,
        },
        sorting = {
            order = 5,
            type = "select",
            style = "dropdown",
            name = L["Sorting"],
            values = {
                asc = L["Ascending"],
                des = L["Descending"],
            },
            disabled = function()
                return not private.review.scan
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
            order = 6,
            type = "toggle",
            name = L["Copy Text"],
            disabled = function()
                return not private.review.scan
            end,
            get = function()
                return private.review.copyText
            end,
            set = function(_, value)
                private.review.copyText = value
            end,
        },
    }

    for tab = 1, moneyTab do
        options["tab" .. tab] = {
            order = tab + 6,
            type = "group",
            name = function()
                local tabName
                if tab == moneyTab then
                    tabName = L["Money Tab"]
                elseif private.review.scan then
                    tabName = private.db.global.guilds[private.review.guildID].tabs[tab].name
                end
                tabName = tabName ~= "" and tabName or format("%s %d", L["Tab"], tab)
                return tabName
            end,
            disabled = function()
                return not private.review.scan or (tab ~= moneyTab and private.db.global.guilds[private.review.guildID].numTabs < tab)
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
                        local transactions = GetTransactions(tab, moneyTab)

                        if filterType == "name" then
                            for _, transaction in pairs(transactions) do
                                local info = private:GetTransactionInfo(transaction)
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
                                local info = private:GetTransactionInfo(transaction)
                                values[info.itemLink] = info.itemLink
                            end
                        end

                        return values
                    end,
                    sorting = function()
                        local values = {}

                        local filterType = private.review.filterType
                        local transactions = GetTransactions(tab, moneyTab)

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
                                local info = private:GetTransactionInfo(transaction)
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
                                local info = private:GetTransactionInfo(transaction)
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
                        local transactions = GetTransactions(tab, moneyTab)

                        for transactionID, transaction in
                            addon.pairs(transactions, function(a, b)
                                if private.db.global.settings.preferences.sorting == "des" then
                                    return a > b
                                else
                                    return a < b
                                end
                            end)
                        do
                            local info = GetInfo(tab, moneyTab, transactions[transactionID])
                            local line = (tab < moneyTab and private:GetTransactionLabel(transactions[transactionID]) or private:GetMoneyTransactionLabel(transactions[transactionID])) or ""

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
            options["tab" .. tab].args["line" .. line] = {
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
                    local transactions = GetTransactions(tab, moneyTab)
                    local info = GetInfo(tab, moneyTab, transactions[line])

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
                    end

                    return not private.review.scan
                end,
                name = function()
                    local transactions = GetTransactions(tab, moneyTab)
                    return private.review.scan and (tab < moneyTab and private:GetTransactionLabel(transactions[line]) or private:GetMoneyTransactionLabel(transactions[line])) or ""
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

    return options
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
        name = name,
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

function private:GetTransactionLabel(transaction)
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

    local recentDate = RecentTimeDate(info.year, info.month, info.day, info.hour)
    if private.db.global.settings.preferences.dateType == "approx" then
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(private.review.scan or time(), info.year, info.month, info.day, info.hour)))
    else
        msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. format(GUILD_BANK_LOG_TIME, recentDate))
    end

    return msg
end

function private:SelectReviewGuild(guildID)
    private.review.guildID = guildID
    private.review.scan = nil
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    return guildID
end

function private:SelectReviewScan(scanID)
    private.review.scan = scanID
    ACD:SelectGroup(addonName, "review", "tab1")
    return scanID
end
