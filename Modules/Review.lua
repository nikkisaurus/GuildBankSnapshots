local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
addon.review = {}




function addon:GetMoneyTransactionInfo(transaction)
    if not transaction then return end

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


function addon:GetMoneyTransactionLabel(transaction)
    local info = addon:GetMoneyTransactionInfo(transaction)

    if not info then return end

    info.name = info.name or UNKNOWN
    info.name = NORMAL_FONT_COLOR_CODE..info.name..FONT_COLOR_CODE_CLOSE
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

    if addon.db.global.settings.preferences.dateType == "approx" then
        msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..date(addon.db.global.settings.preferences.dateFormat, addon:GetTransactionDate(addon.review.scan or time(), info.year, info.month, info.day, info.hour)))
    else
        msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..format(GUILD_BANK_LOG_TIME, RecentTimeDate(info.year, info.month, info.day, info.hour)))
    end

    return msg
end


function addon:GetReviewOptions()
    local moneyTab = MAX_GUILDBANK_TABS  + 1

    local options = {
        selectGuild = {
            order = 1,
            type = "select",
            style = "dropdown",
            name = L["Guild"],
            width = "full",
            get = function()
                return addon.review.guildID or addon:SelectReviewGuild(addon.db.global.settings.preferences.defaultGuild)
            end,
            set = function(_, guildID)
                addon:SelectReviewGuild(guildID)
            end,
            disabled = function()
                return addon.tcount(addon.db.global.guilds) == 0
            end,
            values = function()
                local guilds = {}

                for guildID, guildInfo in addon.pairs(addon.db.global.guilds) do
                    guilds[guildID] = addon:GetGuildDisplayName(guildID)
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
                return addon.review.scan
            end,
            set = function(_, scanID)
                addon:SelectReviewScan(scanID)
            end,
            disabled = function()
                return not addon.review.guildID or addon.tcount(addon.db.global.guilds[addon.review.guildID].scans) == 0
            end,
            values = function()
                if not addon.review.guildID then return {} end

                local scans = {}

                for scanID, _ in pairs(addon.db.global.guilds[addon.review.guildID].scans) do
                    scans[scanID] = date(addon.db.global.settings.preferences.dateFormat, scanID)
                end

                return scans
            end,
            sorting = function()
                if not addon.review.guildID then return {} end

                local scans = {}

                for scanID, _ in addon.pairs(addon.db.global.guilds[addon.review.guildID].scans, function(a, b) return b < a end) do
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
                return not addon.review.scan
            end,
            func = function(info)
                ACD:SelectGroup(addonName, "analyze")
                addon:SelectAnalyzeGuild(addon.review.guildID)
                addon:SelectAnalyzeScan(addon.review.scan, info)
            end,
        },
        deleteScan = {
            order = 4,
            type = "execute",
            name = L["Delete Scan"],
            disabled = function()
                return not addon.review.scan
            end,
            confirm = function()
                return addon.db.global.settings.preferences.confirmDeletions and L.ConfirmDeleteScan
            end,
            func = function()
                addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan] = nil
                addon:SelectReviewScan()
            end,
        },
    }

    for tab = 1, moneyTab do
        options["tab"..tab] = {
            order = tab + 4,
            type = "group",
            name = tab == moneyTab and L["Money Tab"] or format("%s %d", L["Tab"], tab),
            disabled = function()
                return not addon.review.scan or (tab~= moneyTab and addon.db.global.guilds[addon.review.guildID].numTabs < tab)
            end,
            args = {},
        }

        local i = 1
        for line = 25, 1, -1 do
            options["tab"..tab].args["line"..line] = {
                order = i,
                type = "description",
                hidden = function()
                    return not addon.review.scan
                end,
                name = function()
                    local scan = addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan]
                    local transactions = addon.review.scan and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)
                    return addon.review.scan and (tab < moneyTab and addon:GetTransactionLabel(transactions[line]) or addon:GetMoneyTransactionLabel(transactions[line])) or ""
                end,
                width = "full",
            }
            i = i + 1
        end
    end

    return options
end


function addon:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * 60 * 60) + (day * 60 * 60 * 24) + (month * 60 * 60 * 24 * 31) + (year * 60 * 60 * 24 * 31 * 12)
    return scanTime - sec
end


function addon:GetTransactionInfo(transaction)
    if not transaction then return end

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


function addon:GetTransactionLabel(transaction)
    local info = addon:GetTransactionInfo(transaction)
    if not info then return end

    info.name = info.name or UNKNOWN
    info.name = NORMAL_FONT_COLOR_CODE..info.name..FONT_COLOR_CODE_CLOSE

    local msg
    if info.transactionType == "deposit" then
        msg = format(GUILDBANK_DEPOSIT_FORMAT, info.name, info.itemLink)
        if info.count > 1 then
            msg = msg..format(GUILDBANK_LOG_QUANTITY, info.count)
        end
    elseif info.transactionType == "withdraw" then
        msg = format(GUILDBANK_WITHDRAW_FORMAT, info.name, info.itemLink)
        if info.count > 1 then
            msg = msg..format(GUILDBANK_LOG_QUANTITY, info.count)
        end
    elseif info.transactionType == "move" then
		msg = format(GUILDBANK_MOVE_FORMAT, info.name, info.itemLink, info.count, info.moveOrigin, info.moveDestination) -- TODO: Get tab name
    end

    local recentDate = RecentTimeDate(info.year, info.month, info.day, info.hour)
    if addon.db.global.settings.preferences.dateType == "approx" then
        msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..date(addon.db.global.settings.preferences.dateFormat, addon:GetTransactionDate(addon.review.scan or time(), info.year, info.month, info.day, info.hour)))
    else
        msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..format(GUILD_BANK_LOG_TIME, recentDate))
    end

    return msg
end


function addon:SelectReviewGuild(guildID)
    addon.review.guildID = guildID
    addon.review.scan = nil
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    return guildID
end


function addon:SelectReviewScan(scanID)
    addon.review.scan = scanID
    ACD:SelectGroup(addonName, "review", "tab1")
    return scanID
end
