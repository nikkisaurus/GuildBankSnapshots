local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

------------------------------------------------------------

local pairs, tinsert = pairs, table.insert

local QueryGuildBankLog, QueryGuildBankTab = QueryGuildBankLog, QueryGuildBankTab
local GetNumGuildBankTransactions, GetGuildBankTransaction = GetNumGuildBankTransactions, GetGuildBankTransaction
local GetGuildBankItemLink, GetGuildBankItemInfo, GetItemInfoInstant = GetGuildBankItemLink, GetGuildBankItemInfo, GetItemInfoInstant


--*------------------------------------------------------------------------

local hours = 60 * 60
local days = hours * 24
local months = days * (365 / 12)
local years = months * 12

------------------------------------------------------------

function addon:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * hours) + (day * days) + (month * months) + (year * years)
    return scanTime - sec
end

------------------------------------------------------------

function addon:GetTransactionLine(transaction)
    local _, transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = AceSerializer:Deserialize(transaction)

    name = name or UNKNOWN
    name = NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE

    local msg
    if transactionType == "deposit" then
        msg = format(GUILDBANK_DEPOSIT_FORMAT, name, itemLink)
        if count > 1 then
            msg = msg..format(GUILDBANK_LOG_QUANTITY, count)
        end
    elseif transactionType == "withdraw" then
        msg = format(GUILDBANK_WITHDRAW_FORMAT, name, itemLink)
        if count > 1 then
            msg = msg..format(GUILDBANK_LOG_QUANTITY, count)
        end
    elseif transactionType == "move" then
		msg = format(GUILDBANK_MOVE_FORMAT, name, itemLink, count, GetGuildBankTabInfo(moveOrigin), GetGuildBankTabInfo(moveDestination))
    end

    msg = msg and (msg..GUILD_BANK_LOG_TIME_PREPEND..format(GUILD_BANK_LOG_TIME, RecentTimeDate(year, month, day, hour)))

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
    for tab = 1, numTabs do
        QueryGuildBankTab(tab)
        QueryGuildBankLog(tab)
    end

    ------------------------------------------------------------

    C_Timer.After(self.db.global.settings.autoScanDelay, function()
        local db = {}

        for tab = 1, numTabs do
            db[tab] = {items = {}, transactions = {}}
            local tabDB = db[tab]

            ------------------------------------------------------------

            for index = 1, GetNumGuildBankTransactions(tab) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = GetGuildBankTransaction(tab, index)
                -- local itemID = GetItemInfoInstant(itemLink)

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
        for tab, tabDB in pairs(scan) do
            -- item was withdrawn
            for k, v in pairs(tabDB.items) do
                if v ~= db[tab].items[k] then
                    isValid = true
                    break
                end
            end

            -- item was deposited
            for k, v in pairs(db[tab].items) do
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