local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")


function addon:GUILDBANKFRAME_OPENED()
    self.bankIsOpen = true

    self:UpdateGuildDatabase() -- Ensure guild bank database is formatted
    self:ScanGuildBank(true) -- AutoScan
end


function addon:GUILDBANKFRAME_CLOSED()
    -- Warn user if scan is canceled before finishing
    if self.isScanning then
        if self.isScanning ~= "auto" or self.db.global.settings.autoScanAlert then
            self:Print(L["Scan failed."])
        end

        self.isScanning = nil
    end

    self.bankIsOpen = nil
end


function addon:ScanGuildBank(isAutoScan)
    -- Alert user of progress
    if not self.bankIsOpen then
        self:Print(L.BankClosedError)
        return
    elseif not isAutoScan or self.db.global.settings.autoScanAlert then
        self:Print(L["Scanning"].."...")
    end

    self.isScanning = isAutoScan and "auto" or true

    -- Query guild bank tabs
    local numTabs = self.db.global.guilds[self:GetGuildID()].numTabs
    for tab = 1, numTabs  do
        QueryGuildBankTab(tab)
        QueryGuildBankLog(tab)
    end
    QueryGuildBankLog(MAX_GUILDBANK_TABS + 1)

    -- Scan bank
    C_Timer.After(self.db.global.settings.autoScanDelay, function()
        local db = {totalMoney = 0, moneyTransactions = {}, tabs = {}}

        -- Item transactions
        for tab = 1, numTabs do
            db.tabs[tab] = {items = {}, transactions = {}}
            local tabDB = db.tabs[tab]

            for index = 1, GetNumGuildBankTransactions(tab) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = GetGuildBankTransaction(tab, index)

                tinsert(tabDB.transactions, AceSerializer:Serialize(transactionType, name, itemLink, count, moveOrigin or 0, moveDestination or 0, year, month, day, hour))
            end

            for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
                local slotItemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)
                if slotItemID then
                    local _, slotItemCount = GetGuildBankItemInfo(tab, slot)
                    tabDB.items[slotItemID] = tabDB.items[slotItemID] and tabDB.items[slotItemID] + slotItemCount or slotItemCount
                end
            end
        end

        -- Money transactions
        db.totalMoney = GetGuildBankMoney()
        for i = 1, GetNumGuildBankMoneyTransactions() do
            tinsert(db.moneyTransactions, AceSerializer:Serialize(GetGuildBankMoneyTransaction(i)))
        end

        -- Validation
        self:ValidateScan(db)
    end)
end


function addon:ValidateScan(db)
    if not self.bankIsOpen then self:Print(L.BankClosedError) return end
    if not self.isScanning then return end

    local scans = self.db.global.guilds[self:GetGuildID()].scans

    local isValid
    for scanTime, scan in self.pairs(scans, function(a, b) return b < a end) do
        -- Money changed
        if scan.totalMoney ~= db.totalMoney then
            isValid = true
            break
        end

        for tab, tabDB in pairs(scan.tabs) do
            -- Item was withdrawn
            for k, v in pairs(tabDB.items) do
                if v ~= db.tabs[tab].items[k] then
                    isValid = true
                    break
                end
            end

            -- Item was deposited
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

    -- Save scan
    if isValid then
        self.db.global.guilds[self:GetGuildID()].scans[time()] = db
    end

    -- Alert scan finished
    if addon.isScanning ~= "auto" or self.db.global.settings.autoScanAlert then
        self:Print(L["Scan finished."], not isValid and L["No changes detected."] or "")
    end

    addon.isScanning = nil    
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end