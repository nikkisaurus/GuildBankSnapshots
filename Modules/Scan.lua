local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local function ValidateScan(db, override)
    if not private.bankIsOpen then
        addon:Print(L.BankClosedError)
        return
    end
    if not private.isScanning then
        return
    end

    local scans = private.db.global.guilds[private:GetGuildID()].scans

    local isValid = override
    for scanTime, scan in
        addon.pairs(scans, function(a, b)
            return b < a
        end)
    do
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
        local scanSettings = private.db.global.settings.scans

        -- Save db
        private.db.global.guilds[private:GetGuildID()].scans[scanTime] = db

        if private:DeleteCorruptedScans(scanTime) then
            addon:Print(L.CorruptScan)
        else
            -- Open the review frame
            if not corrupt and ((private.isScanning ~= "auto" and scanSettings.review) or (private.isScanning == "auto" and scanSettings.autoScan.review)) then
                private:LoadFrame(addon.StringToTitle(scanSettings.reviewPath), private:GetGuildID(), scanTime)
                if scanSettings.reviewPath == "analyze" then
                    private.frame:GetUserData("reviewTabGroup"):SelectTab("Analyze")
                end
            end
        end
    end

    -- Alert scan finished
    if private.isScanning ~= "auto" or private.db.global.settings.scans.autoScan.alert then
        addon:Print(L["Scan finished."], not isValid and L["No changes detected."] or "")
    end

    private.isScanning = nil
end

local function ValidateScanFrequency(autoScanSettings)
    if not autoScanSettings.frequency.enabled then
        return true
    end

    -- Convert frequency to seconds
    local frequency = autoScanSettings.frequency.measure * private.unitsToSeconds[autoScanSettings.frequency.unit]

    -- Get the last scan date and compare
    for scanID, _ in
        addon.pairs(private.db.global.guilds[private:GetGuildID()].scans, function(a, b)
            return b < a
        end)
    do
        return (time() > (scanID + frequency))
    end

    return true
end

function addon:GUILDBANKFRAME_CLOSED()
    if not addon:IsEnabled() then
        return
    end

    -- Warn user if scan is canceled before finishing
    if private.isScanning then
        if private.isScanning ~= "auto" or private.db.global.settings.scans.autoScan.alert then
            addon:Print(L["Scan failed."])
        end

        private.isScanning = nil
    end

    private.bankIsOpen = nil
end

function addon:GUILDBANKFRAME_OPENED()
    if not addon:IsEnabled() then
        return
    end

    private.bankIsOpen = true
    private:UpdateGuildDatabase() -- Ensure guild bank database is formatted

    local autoScanSettings = private.db.global.settings.scans.autoScan
    if autoScanSettings.enabled and ValidateScanFrequency(autoScanSettings) then
        addon:ScanGuildBank(true) -- AutoScan
    end
end

function addon:ScanGuildBank(isAutoScan, override)
    -- Alert user of progress
    if not private.bankIsOpen then
        addon:Print(L.BankClosedError)
        return
    elseif not isAutoScan or private.db.global.settings.scans.autoScan.alert then
        addon:Print(L["Scanning"] .. "...")
    end

    private.isScanning = isAutoScan and "auto" or true

    -- Query guild bank tabs
    local numTabs = private.db.global.guilds[private:GetGuildID()].numTabs
    for tab = 1, numTabs do
        QueryGuildBankTab(tab)
        QueryGuildBankLog(tab)
    end
    QueryGuildBankLog(MAX_GUILDBANK_TABS + 1)

    -- Scan bank
    C_Timer.After(private.db.global.settings.scans.delay, function()
        local db = { totalMoney = 0, moneyTransactions = {}, tabs = {} }

        -- Item transactions
        for tab = 1, numTabs do
            db.tabs[tab] = { items = {}, transactions = {} }
            local tabDB = db.tabs[tab]

            for index = 1, GetNumGuildBankTransactions(tab) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = GetGuildBankTransaction(tab, index)
                name = name or UNKNOWN

                tinsert(tabDB.transactions, AceSerializer:Serialize(transactionType, name, itemLink, count, moveOrigin or 0, moveDestination or 0, year, month, day, hour))
            end

            for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
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
            local transactionType, name, amount, years, months, days, hours = GetGuildBankMoneyTransaction(i)
            name = name or UNKNOWN

            tinsert(db.moneyTransactions, AceSerializer:Serialize(transactionType, name, amount, years, months, days, hours))
        end

        -- Validation
        ValidateScan(db, override)
    end)
end
