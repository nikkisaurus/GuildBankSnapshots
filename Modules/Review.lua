local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")


local function SelectGuild(guildID)
    addon.selectedReviewGuild = guildID
    addon.selectedReviewScan = nil
    return guildID
end


local function SelectScan(scanID)
    addon.selectedReviewScan = scanID
    ACD:SelectGroup(addonName, "review", "tab1")
    return scanID
end


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


function addon:GetMoneyTransactionLabel(transaction, approxDate)
    local info = self:GetMoneyTransactionInfo(transaction)

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

    if approxDate then
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
                return addon.selectedReviewGuild or SelectGuild(addon.db.global.settings.defaultGuild)
            end,
            set = function(_, guildID)
                SelectGuild(guildID)
            end,
            disabled = function()
                return addon.tcount(addon.db.global.guilds) == 0
            end,
            values = function()
                local guilds = {}

                for guildID, guildInfo in addon.pairs(addon.db.global.guilds) do
                    guilds[guildID] = guildInfo.guildName
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
                return addon.selectedReviewScan
            end,
            set = function(_, scanID)
                SelectScan(scanID)
            end,
            disabled = function()
                return not addon.selectedReviewGuild or addon.tcount(addon.db.global.guilds[addon.selectedReviewGuild].scans) == 0
            end,
            values = function()
                if not addon.selectedReviewGuild then return {} end

                local scans = {}

                for scanID, _ in pairs(addon.db.global.guilds[addon.selectedReviewGuild].scans) do
                    scans[scanID] = date(addon.db.global.settings.dateFormat, scanID)
                end

                return scans
            end,
            sorting = function()
                if not addon.selectedReviewGuild then return {} end

                local scans = {}

                for scanID, _ in addon.pairs(addon.db.global.guilds[addon.selectedReviewGuild].scans, function(a, b) return b < a end) do
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
                return not addon.selectedReviewScan
            end,
            func = function(info)
                ACD:SelectGroup(addonName, "analyze")
                addon:SelectAnalyzeGuild(addon.selectedReviewGuild)
                addon:SelectAnalyzeScan(addon.selectedReviewScan)
            end,
        },
        exportScan = {
            order = 4,
            type = "execute",
            name = L["Export Scan"],
            disabled = function()
                return true or not addon.selectedReviewScan
            end,
            func = function()
                -- TODO
                print("Export scan")
            end,
        },
        deleteScan = {
            order = 5,
            type = "execute",
            name = L["Delete Scan"],
            disabled = function()
                return not addon.selectedReviewScan
            end,
            confirm = function()
                return L.ConfirmDeleteScan
            end,
            func = function()
                addon.db.global.guilds[addon.selectedReviewGuild].scans[addon.selectedReviewScan] = nil
                SelectScan()
            end,
        },
    }

    for tab = 1, moneyTab do
        options["tab"..tab] = {
            order = tab + 5,
            type = "group",
            name = tab == moneyTab and L["Money Tab"] or format("%s %d", L["Tab"], tab),
            disabled = function()
                return not addon.selectedReviewScan or (tab~= moneyTab and addon.db.global.guilds[addon.selectedReviewGuild].numTabs < tab)
            end,
            args = {},
        }

        local i = 1
        for line = 25, 1, -1 do
            options["tab"..tab].args["line"..line] = {
                order = i,
                type = "description",
                hidden = function()
                    return not addon.selectedReviewScan
                end,
                name = function()
                    local scan = addon.db.global.guilds[addon.selectedReviewGuild].scans[addon.selectedReviewScan]
                    local transactions = addon.selectedReviewScan and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)
                    return addon.selectedReviewScan and (tab < moneyTab and addon:GetTransactionLabel(transactions[line]) or addon:GetMoneyTransactionLabel(transactions[line])) or ""
                end,
                width = "full",
            }
            i = i + 1
        end
    end

    return options
end


function addon:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * addon.secondsInHour) + (day * addon.secondsInDay) + (month * addon.secondsInMonth) + (year * addon.secondsInYear)
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


function addon:GetTransactionLabel(transaction, scanID)
    local info = self:GetTransactionInfo(transaction)
    if not info then return end

    info.name = info.name or UNKNOWN
    info.name = NORMAL_FONT_COLOR_CODE..info.name..FONT_COLOR_CODE_CLOSE
    -- if overrideDate then
    --     info.year = overrideDate.year
    --     info.month = overrideDate.month
    --     info.day = overrideDate.day
    --     info.hour = overrideDate.hour
    --     print(transaction)
    --     for k, v in pairs(overrideDate) do print(k, v) end
    -- end

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
        -- print(info.name, info.itemLink, info.count, info.moveOrigin, info.moveDestination)
		msg = format(GUILDBANK_MOVE_FORMAT, info.name, info.itemLink, info.count, info.moveOrigin, info.moveDestination) -- TODO: Get tab name
    end

    local recentDate = RecentTimeDate(info.year, info.month, info.day, info.hour)
    if scanID then
        local difference = difftime(time() - scanID)
        local currentTransactionDate = addon:GetTransactionDate(time(), info.year, info.month, info.day, info.hour)
        local newTransactionDate = date("*t", currentTransactionDate - difference)
        local oldDate = date("*t", currentTransactionDate)
        recentDate = RecentTimeDate(oldDate.year - newTransactionDate.year, oldDate.month - newTransactionDate.month, oldDate.day - newTransactionDate.day, oldDate.hour - newTransactionDate.hour)
    end

    if scanID then
        -- local difference = difftime(time(), snapshotDate)
        local currentTransactionDate = addon:GetTransactionDate(scanID, info.year, info.month, info.day, info.hour)
        -- local newTransactionDate = currentTransactionDate - difference
        -- local oldDate = date("*t", currentTransactionDate)
        msg = msg and (date(addon.db.global.settings.dateFormat, scanID).." "..scanID.." " .. strtrim(GUILD_BANK_LOG_TIME_PREPEND)..date(addon.db.global.settings.dateFormat, currentTransactionDate).."|r "..msg)
    else
        -- msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..date(addon.db.global.settings.dateFormat, addon:GetTransactionDate(time(), info.year, info.month, info.day, info.hour)))
        msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..format(GUILD_BANK_LOG_TIME, recentDate))
    end

    return msg
end
