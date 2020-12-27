local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

------------------------------------------------------------

local pairs, tinsert = pairs, table.insert

local QueryGuildBankLog, QueryGuildBankTab = QueryGuildBankLog, QueryGuildBankTab
local GetNumGuildBankTransactions, GetGuildBankTransaction = GetNumGuildBankTransactions, GetGuildBankTransaction
local GetGuildBankItemLink, GetGuildBankItemInfo, GetItemInfoInstant = GetGuildBankItemLink, GetGuildBankItemInfo, GetItemInfoInstant
local GetDenominationsFromCopper = GetDenominationsFromCopper

local UNKNOWN, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE, GUILD_BANK_LOG_TIME = UNKNOWN, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE, GUILD_BANK_LOG_TIME
local GUILDBANK_DEPOSIT_MONEY_FORMAT, GUILDBANK_WITHDRAW_MONEY_FORMAT, GUILDBANK_REPAIR_MONEY_FORMAT, GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, GUILDBANK_BUYTAB_MONEY_FORMAT, GUILDBANK_UNLOCKTAB_FORMAT, GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT = GUILDBANK_DEPOSIT_MONEY_FORMAT, GUILDBANK_WITHDRAW_MONEY_FORMAT, GUILDBANK_REPAIR_MONEY_FORMAT, GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, GUILDBANK_BUYTAB_MONEY_FORMAT, GUILDBANK_UNLOCKTAB_FORMAT, GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT
local GUILDBANK_DEPOSIT_FORMAT, GUILDBANK_LOG_QUANTITY, GUILDBANK_WITHDRAW_FORMAT, GUILDBANK_LOG_QUANTITY, GUILDBANK_MOVE_FORMAT = GUILDBANK_DEPOSIT_FORMAT, GUILDBANK_LOG_QUANTITY, GUILDBANK_WITHDRAW_FORMAT, GUILDBANK_LOG_QUANTITY, GUILDBANK_MOVE_FORMAT

--*------------------------------------------------------------------------

addon.secondsInHour = 60 * 60
addon.secondsInDay = addon.secondsInHour * 24
addon.secondsInMonth = addon.secondsInDay * (365 / 12)
addon.secondsInYear = addon.secondsInMonth * 12

------------------------------------------------------------

function addon:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * addon.secondsInHour) + (day * addon.secondsInDay) + (month * addon.secondsInMonth) + (year * addon.secondsInYear)
    return scanTime - sec
end

------------------------------------------------------------

function addon:GetMoneyTransactionInfo(transaction)
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

------------------------------------------------------------

function addon:GetTransactionInfo(transaction)
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

------------------------------------------------------------

function addon:GetMoneyTransactionLabel(transaction, approxDate)
    local info = self:GetMoneyTransactionInfo(transaction)

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
        if amount > 0 then
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

------------------------------------------------------------

function addon:GetTransactionLabel(transaction, snapshotDate)
    local info = self:GetTransactionInfo(transaction)

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
    if snapshotDate then
        local difference = difftime(time() - snapshotDate)
        local currentTransactionDate = addon:GetTransactionDate(time(), info.year, info.month, info.day, info.hour)
        local newTransactionDate = date("*t", currentTransactionDate - difference)
        local oldDate = date("*t", currentTransactionDate)
        recentDate = RecentTimeDate(oldDate.year - newTransactionDate.year, oldDate.month - newTransactionDate.month, oldDate.day - newTransactionDate.day, oldDate.hour - newTransactionDate.hour)
    end

    if snapshotDate then
        -- local difference = difftime(time(), snapshotDate)
        local currentTransactionDate = addon:GetTransactionDate(snapshotDate, info.year, info.month, info.day, info.hour)
        -- local newTransactionDate = currentTransactionDate - difference
        -- local oldDate = date("*t", currentTransactionDate)
        msg = msg and (date(addon.db.global.settings.dateFormat, snapshotDate).." "..snapshotDate.." " .. strtrim(GUILD_BANK_LOG_TIME_PREPEND)..date(addon.db.global.settings.dateFormat, currentTransactionDate).."|r "..msg)
    else
        -- msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..date(addon.db.global.settings.dateFormat, addon:GetTransactionDate(time(), info.year, info.month, info.day, info.hour)))
        msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..format(GUILD_BANK_LOG_TIME, recentDate))
    end

    return msg
end

--*------------------------------------------------------------------------

local isScanning, bankIsOpen

------------------------------------------------------------

function addon:GUILDBANKFRAME_CLOSED()
    if isScanning then
        if isScanning ~= "auto" or self.db.global.settings.autoScanAlert then
            self:Print(L["Scan failed."])
        end
        isScanning = nil
    end
    bankIsOpen = nil
end

------------------------------------------------------------

function addon:GUILDBANKFRAME_OPENED()
    bankIsOpen = true
    self:UpdateGuildDatabase()
    self:ScanGuildBank(true)
end

--*------------------------------------------------------------------------

function addon:ScanGuildBank(isAutoScan)
    if not bankIsOpen then self:Print(L.BankClosedError) return end

    if not isAutoScan or self.db.global.settings.autoScanAlert then
        self:Print(L["Scanning"].."...")
    end
    isScanning = isAutoScan and "auto" or true

    ------------------------------------------------------------

    local numTabs = self.db.global.guilds[self:GetGuildID()].numTabs
    for tab = 1, numTabs  do
        QueryGuildBankTab(tab)
        QueryGuildBankLog(tab)
    end
    QueryGuildBankLog(MAX_GUILDBANK_TABS + 1)

    ------------------------------------------------------------

    C_Timer.After(self.db.global.settings.autoScanDelay, function()
        local db = {totalMoney = 0, moneyTransactions = {}, tabs = {}}

        for tab = 1, numTabs do
            db.tabs[tab] = {items = {}, transactions = {}}
            local tabDB = db.tabs[tab]

            ------------------------------------------------------------

            for index = 1, GetNumGuildBankTransactions(tab) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = GetGuildBankTransaction(tab, index)

                tinsert(tabDB.transactions, AceSerializer:Serialize(transactionType, name, itemLink, count, moveOrigin or 0, moveDestination or 0, year, month, day, hour))
            end

            ------------------------------------------------------------

            for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
                local slotItemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)
                if slotItemID then
                    local _, slotItemCount = GetGuildBankItemInfo(tab, slot)
                    tabDB.items[slotItemID] = tabDB.items[slotItemID] and tabDB.items[slotItemID] + slotItemCount or slotItemCount
                end
            end
        end

        db.totalMoney = GetGuildBankMoney()
        for i = 1, GetNumGuildBankMoneyTransactions() do
            tinsert(db.moneyTransactions, AceSerializer:Serialize(GetGuildBankMoneyTransaction(i)))
        end

        self:ValidateScan(db)
    end)
end

------------------------------------------------------------

function addon:ValidateScan(db)
    if not bankIsOpen then self:Print(L.BankClosedError) return end
    if not isScanning then return end

    local scans = self.db.global.guilds[self:GetGuildID()].scans

    local isValid
    for scanTime, scan in self.pairs(scans, function(a, b) return b < a end) do
        -- money changed
        if scan.totalMoney ~= db.totalMoney then
            isValid = true
            break
        end

        for tab, tabDB in pairs(scan.tabs) do
            -- item was withdrawn
            for k, v in pairs(tabDB.items) do
                if v ~= db.tabs[tab].items[k] then
                    isValid = true
                    break
                end
            end

            -- item was deposited
            for k, v in pairs(db.tabs[tab].items) do
                if v ~= tabDB.items[k] then
                    isValid = true
                    break
                end
            end
        end

        break
    end

    isValid = isValid or self.tcount(scans) == 0

    if isValid then
        self.db.global.guilds[self:GetGuildID()].scans[time()] = db
    end

    if isScanning ~= "auto" or self.db.global.settings.autoScanAlert then
        self:Print(L["Scan finished."], not isValid and L["No changes detected."] or "")
    end
    isScanning = nil
end