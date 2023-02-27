local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local pendingRemoval = {}
function private:CleanupDatabase(guild)
    private:DeleteCorruptedScans()

    -- Delete scans by age
    for guildKey, guildInfo in pairs(private.db.global.guilds) do
        if not guild or guildKey == guild then
            local autoCleanupSettings = guildInfo.settings.autoCleanup

            if autoCleanupSettings.age.enabled then
                -- Convert age to seconds
                local age = autoCleanupSettings.age.measure * private.timeInSeconds[autoCleanupSettings.age.unit]
                local ageLimit = time() - age

                for scanID, _ in addon:pairs(guildInfo.scans) do
                    -- Delete scans
                    if scanID < ageLimit then
                        private.db.global.guilds[guildKey].scans[scanID] = nil
                    end
                end

                wipe(pendingRemoval)
                for id, info in addon:pairs(guildInfo.masterScan) do
                    if info and info.scanID < ageLimit then
                        pendingRemoval[id] = true
                    end
                end

                for id, _ in addon:pairs(pendingRemoval, private.sortDesc) do
                    tremove(private.db.global.guilds[guildKey].masterScan, id)
                end
            end
        end
    end
end

function private:DeleteCorruptedScans(lastScan)
    local lastScanCorrupted
    for guildKey, guildInfo in pairs(private.db.global.guilds) do
        if guildInfo.settings.autoCleanup.corrupted then
            for scanID, scan in addon:pairs(guildInfo.scans) do
                local empty = 0
                local corruptItems

                -- Count empty transactions
                for i = 1, guildInfo.numTabs or MAX_GUILDBANK_TABS do
                    local tabInfo = scan.tabs[i]
                    -- Can't guarantee all corrupt logs will be cleaned up because we can't know that if either items or transactions are empty that it's corrupt rather than a new bank
                    if not tabInfo or (addon:tcount(tabInfo.items) == 0 and addon:tcount(tabInfo.transactions) == 0) then
                        empty = empty + 1
                    else
                        for _, transaction in pairs(tabInfo.transactions) do
                            local info = private:GetTransactionInfo(transaction)
                            if not info.name then
                                info.name = UNKNOWN
                            end

                            -- Delete corrupted scans with missing itemLink info
                            if not info.itemLink or info.itemLink == "" or info.itemLink == UNKNOWN then
                                corruptItems = true
                                break
                            end
                        end
                    end
                end

                -- Count empty money transactions
                if addon:tcount(scan.moneyTransactions) == 0 then
                    empty = empty + 1
                else
                    for _, transaction in pairs(scan.moneyTransactions) do
                        local info = private:GetMoneyTransactionInfo(transaction)
                        if not info.name then
                            info.name = UNKNOWN
                        end
                    end
                end

                -- Delete corrupt scan
                if corruptItems or empty == (guildInfo.numTabs or MAX_GUILDBANK_TABS) + 1 or (scan.totalMoney == 0 and addon:tcount(scan.tabs) == 0 and addon:tcount(scan.moneyTransactions) == 0) or addon:tcount(scan.tabs) ~= (guildInfo.numTabs or MAX_GUILDBANK_TABS) then
                    lastScanCorrupted = scanID == lastScan
                    private.db.global.guilds[guildKey].scans[scanID] = nil

                    -- Remove transactions from masterScan
                    wipe(pendingRemoval)
                    for id, info in addon:pairs(guildInfo.masterScan) do
                        if info and info.scanID == scanID then
                            pendingRemoval[id] = true
                        end
                    end

                    for id, _ in addon:pairs(pendingRemoval, private.sortDesc) do
                        print(scanID, id)
                        tremove(private.db.global.guilds[guildKey].masterScan, id)
                    end
                end
            end
        end
    end

    return lastScanCorrupted
end

function private:UpdateGuildDatabase()
    local guildKey, guildName, faction, realm = private:GetguildKey()
    private.db.global.guilds[guildKey] = private.db.global.guilds[guildKey] or addon:CloneTable(private.defaults.guild)
    local db = private.db.global.guilds[guildKey]

    db.guildName = guildName
    db.faction = faction
    db.realm = realm
    db.masterScan = db.masterScan or {}
    db.scans = db.scans or {}

    local numTabs = GetNumGuildBankTabs()
    db.numTabs = numTabs

    for tab = 1, numTabs do
        local name, icon = GetGuildBankTabInfo(tab)
        db.tabs[tab] = {
            name = name,
            icon = icon,
        }
    end
end
