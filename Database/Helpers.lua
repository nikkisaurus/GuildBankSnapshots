local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:CleanupDatabase()
    private:DeleteCorruptedScans()

    -- Delete scans by age
    for guildID, guildInfo in pairs(private.db.global.guilds) do
        for scanID, _ in addon:pairs(guildInfo.scans) do
            local autoCleanupSettings = private.db.global.settings.scans.autoCleanup
            if autoCleanupSettings.age.enabled then
                -- Convert age to seconds
                local age = autoCleanupSettings.age.measure * private.unitsToSeconds[autoCleanupSettings.age.unit]

                -- Delete scans
                if scanID < time() - age then
                    private.db.global.guilds[guildID].scans[scanID] = nil
                end
            end
        end
    end

    -- TODO
    -- -- Clear selected scans that have been deleted
    -- if private.analyze.scan and not private.db.global.guilds[private.analyze.guildID].scans[private.analyze.scan[1]] then
    --     private:SelectAnalyzeScan()
    -- end
    -- if private.review.scan and not private.db.global.guilds[private.review.guildID].scans[private.review.scan] then
    --     private:SelectReviewScan()
    -- end
end

function private:DeleteCorruptedScans(lastScan)
    if not private.db.global.settings.scans.autoCleanup.corrupted then
        return
    end

    local lastScanCorrupted
    for guildID, guildInfo in pairs(private.db.global.guilds) do
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
                private.db.global.guilds[guildID].scans[scanID] = nil
            end
        end
    end

    return lastScanCorrupted
end

function private:UpdateGuildDatabase()
    local guildID, guildName, faction, realm = private:GetGuildID()
    private.db.global.guilds[guildID] = private.db.global.guilds[guildID] or addon:CloneTable(private.defaults.guild)
    local db = private.db.global.guilds[guildID]

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
