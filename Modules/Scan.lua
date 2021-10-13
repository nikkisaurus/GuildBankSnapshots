local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")




local function ValidateScan(db)
    if not addon.bankIsOpen then addon:Print(L.BankClosedError) return end
    if not addon.isScanning then return end

    local scans = addon.db.global.guilds[addon:GetGuildID()].scans

    local isValid
    for scanTime, scan in addon.pairs(scans, function(a, b) return b < a end) do
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

    isValid = isValid or addon.tcount(scans) == 0

    -- Save scan
    if isValid then
        local scanTime = time()
        local scanSettings = addon.db.global.settings.scans

        -- Save db
        addon.db.global.guilds[addon:GetGuildID()].scans[scanTime] = db

        if addon:DeleteCorruptedScans(scanTime) then
            addon:Print(L.CorruptScan)
        else
            -- Open the review frame
            if not corrupt and ((addon.isScanning ~= "auto" and scanSettings.review) or (addon.isScanning == "auto" and scanSettings.autoScan.review)) then
                ACD:SelectGroup(addonName, scanSettings.reviewPath)
                ACD:Open(addonName)

                if scanSettings.reviewPath ~= "export" then
                    -- Select guild and scan
                    addon["Select"..strupper(strsub(scanSettings.reviewPath, 1, 1))..strsub(scanSettings.reviewPath, 2).."Guild"](addon, addon:GetGuildID())
                    addon["Select"..strupper(strsub(scanSettings.reviewPath, 1, 1))..strsub(scanSettings.reviewPath, 2).."Scan"](addon, scanTime)
                end
            end
        end
    end

    -- Alert scan finished
    if addon.isScanning ~= "auto" or addon.db.global.settings.scans.autoScan.alert then
        addon:Print(L["Scan finished."], not isValid and L["No changes detected."] or "")
    end

    addon.isScanning = nil
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end


local function ValidateScanFrequency(autoScanSettings)
    if not autoScanSettings.frequency.enabled then return true end

    -- Convert frequency to seconds
    local frequency = autoScanSettings.frequency.measure * addon.unitsToSeconds[autoScanSettings.frequency.unit]

    -- Get the last scan date and compare
    for scanID, _ in addon.pairs(addon.db.global.guilds[addon:GetGuildID()].scans, function(a, b) return b < a end) do
        return (scanID < time() - frequency)
    end
end




function addon:GUILDBANKFRAME_OPENED()
    self.bankIsOpen = true
    self:UpdateGuildDatabase() -- Ensure guild bank database is formatted

    local autoScanSettings = self.db.global.settings.scans.autoScan
    if autoScanSettings.enabled and ValidateScanFrequency(autoScanSettings) then
        self:ScanGuildBank(true) -- AutoScan
    end
end


function addon:GUILDBANKFRAME_CLOSED()
    -- Warn user if scan is canceled before finishing
    if self.isScanning then
        if self.isScanning ~= "auto" or self.db.global.settings.scans.autoScan.alert then
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
    elseif not isAutoScan or self.db.global.settings.scans.autoScan.alert then
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
    C_Timer.After(self.db.global.settings.scans.delay, function()
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
        ValidateScan(db)
    end)
end
