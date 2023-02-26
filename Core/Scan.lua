local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local function ValidateScan(db, override)
    if not private.bankIsOpen then
        addon:Print(L["Please open your guild bank frame and try again."])
        return
    end
    if not private.isScanning then
        return
    end

    local guildKey = private:GetGuildID()
    local scans = private.db.global.guilds[guildKey].scans

    local isValid = override
    for scanTime, scan in
        addon:pairs(scans, function(a, b)
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

    isValid = isValid or addon:tcount(scans) == 0

    -- Save scan
    if isValid then
        local scanTime = time()
        local scanSettings = private.db.global.guilds[guildKey].settings

        -- Save db
        private.db.global.guilds[guildKey].scans[scanTime] = db

        if private:DeleteCorruptedScans(scanTime) then
            addon:Print(L["Scan corrupt. Please try again."])
        else
            private:AddScanToMaster(guildKey, scanTime)
            -- Open the review frame
            if not corrupt and ((private.isScanning ~= "auto" and scanSettings.review) or (private.isScanning == "auto" and scanSettings.autoScan.review)) then
                private:LoadFrame(addon:StringToTitle(scanSettings.reviewPath), private:GetGuildID())
            end
        end
    end

    -- Alert scan finished
    if private.isScanning ~= "auto" or private.db.global.guilds[guildKey].settings.autoScan.alert then
        addon:Print(L["Scan finished."], not isValid and L["No changes detected."] or "")
    end

    private.isScanning = nil
end

local function ValidateScanFrequency(autoScanSettings)
    if not autoScanSettings.frequency.enabled then
        return true
    end

    -- Convert frequency to seconds
    local frequency = autoScanSettings.frequency.measure * private.timeInSeconds[autoScanSettings.frequency.unit]

    -- Get the last scan date and compare
    for scanID, _ in addon:pairs(private.db.global.guilds[private:GetGuildID()].scans, private.sortDesc) do
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
        if private.isScanning ~= "auto" or private.db.global.guilds[private:GetGuildID()].settings.autoScan.alert then
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

    local autoScanSettings = private.db.global.guilds[private:GetGuildID()].settings.autoScan
    if autoScanSettings.enabled and ValidateScanFrequency(autoScanSettings) then
        addon:ScanGuildBank(true) -- AutoScan
    end
end

function addon:ScanGuildBank(isAutoScan, override)
    local guildKey = private:GetGuildID()

    -- Alert user of progress
    if not private.bankIsOpen then
        addon:Print(L["Please open your guild bank frame and try again."])
        return
    elseif not isAutoScan or private.db.global.guilds[guildKey].settings.autoScan.alert then
        addon:Print(L["Scanning"] .. "...")
    end

    -- Commands are passing a table to this function, so need to verify that isAutoScan is actually true, not just the passed table
    private.isScanning = type(isAutoScan) == "boolean" and isAutoScan and "auto" or true

    -- Query guild bank tabs
    local numTabs = private.db.global.guilds[guildKey].numTabs
    for tab = 1, numTabs do
        QueryGuildBankTab(tab)
        QueryGuildBankLog(tab)
        -- Query transactions
        for index = 1, GetNumGuildBankTransactions(tab) do
            GetGuildBankTransaction(tab, index)
        end
    end

    QueryGuildBankLog(MAX_GUILDBANK_TABS + 1)
    for i = 1, GetNumGuildBankMoneyTransactions() do
        GetGuildBankMoneyTransaction(i)
    end

    -- Scan bank
    C_Timer.After(private.db.global.preferences.delay, function()
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

function private:InitializeScanner()
    EventUtil.ContinueOnAddOnLoaded("Blizzard_GuildBankUI", function()
        addon:HookScript(_G["GuildBankFrame"], "OnShow", addon.GUILDBANKFRAME_OPENED)
        addon:HookScript(_G["GuildBankFrame"], "OnHide", addon.GUILDBANKFRAME_CLOSED)

        if IsAddOnLoaded("ArkInventory") and _G["ARKINV_Frame4"] then
            addon:HookScript(_G["ARKINV_Frame4"], "OnShow", addon.GUILDBANKFRAME_OPENED)
            addon:HookScript(_G["ARKINV_Frame4"], "OnHide", addon.GUILDBANKFRAME_CLOSED)
        elseif IsAddOnLoaded("Bagnon") and _G["BagnonBankFrame1"] then
            addon:HookScript(_G["BagnonBankFrame1"], "OnShow", addon.GUILDBANKFRAME_OPENED)
            addon:HookScript(_G["BagnonBankFrame1"], "OnHide", addon.GUILDBANKFRAME_CLOSED)
        end

        C_Timer.After(5, function()
            -- Added delay because it seems some addons may be loading the guild bank UI before I have the data I need
            private:UpdateGuildDatabase()
        end)
    end)
end

local entries = {}
function private:AddScanToMaster(guildKey, scanID)
    local scan = private.db.global.guilds[guildKey].scans[scanID]

    if not scan then
        return
    end

    for tabID, tab in addon:pairs(scan.tabs) do
        for _, transaction in addon:pairs(tab.transactions) do
            local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

            local approxDate = private:GetTransactionDate(scanID, year, month, day, hour)
            local mins = tonumber(date("%M", approxDate))
            local transactionDate = approxDate - (mins * private.timeInSeconds.minutes)

            local elementData = {
                transactionID = #private.db.global.guilds[guildKey].masterScan + 1,
                scanID = scanID,
                tabID = tabID,
                transactionDate = transactionDate,

                transactionType = transactionType,
                name = name or UNKNOWN,
                itemLink = (itemLink and itemLink ~= "" and itemLink) or UNKNOWN,
                count = count,
                moveOrigin = moveOrigin,
                moveDestination = moveDestination,
                year = year,
                month = month,
                day = day,
                hour = hour,
            }

            local key = (transactionType .. name .. (private:GetItemName(itemLink) or UNKNOWN) .. (private:GetItemRank(itemLink) or 0) .. count .. moveOrigin .. moveDestination)
            if entries[key] then
                elementData.isDupe = abs(transactionDate - entries[key]) <= (private.timeInSeconds.hours + private.timeInSeconds.minutes)
            end
            entries[key] = transactionDate

            tinsert(private.db.global.guilds[guildKey].masterScan, elementData)
        end
    end

    for _, transaction in addon:pairs(scan.moneyTransactions) do
        local transactionType, name, amount, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

        local approxDate = private:GetTransactionDate(scanID, year, month, day, hour)
        local mins = tonumber(date("%M", approxDate))
        local transactionDate = approxDate - (mins * private.timeInSeconds.minutes)

        local elementData = {
            transactionID = #private.db.global.guilds[guildKey].masterScan + 1,
            scanID = scanID,
            tabID = MAX_GUILDBANK_TABS + 1,
            transactionDate = transactionDate,

            transactionType = transactionType,
            name = name or UNKNOWN,
            amount = amount,
            year = year,
            month = month,
            day = day,
            hour = hour,
        }

        local key = (transactionType .. name .. amount)
        if entries[key] then
            elementData.isDupe = abs(transactionDate - entries[key]) <= (private.timeInSeconds.hours + private.timeInSeconds.minutes)
        end
        entries[key] = transactionDate

        tinsert(private.db.global.guilds[guildKey].masterScan, elementData)
    end
end
