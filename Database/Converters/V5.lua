local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

function private:ConvertDatabaseV5(backup)
    if backup.guilds then
        for guildKey, scans in pairs(backup.guilds) do
            local _, guildName, faction, realm = strsplit(":", guildKey)
            guildName = gsub(guildName, "|s", " ")
            faction = faction == "H" and "Horde" or "Alliance"
            realm = gsub(realm, "|s", " ")

            local guildID = format("%s - %s (%s)", guildName, realm, faction)
            private.db.global.guilds[guildID] = private.db.global.guilds[guildID] or addon:CloneTable(private.defaults.guild)
            local db = private.db.global.guilds[guildID]

            db.guildName = guildName
            db.faction = faction
            db.realm = realm

            for scanID, scan in
                addon:pairs(scans, function(a, b)
                    return a > b
                end)
            do
                db.numTabs = db.numTabs == 0 and (addon:tcount(scan) - 1) or db.numTabs
                db.scans[scanID] = { totalMoney = 0, moneyTransactions = {}, tabs = {} }

                for tab, transactions in pairs(scan) do
                    if transactions.tabName ~= "Money" then
                        db.scans[scanID].tabs[tab] = { items = {}, transactions = {} }
                    end
                    for transactionID, transaction in pairs(transactions) do
                        if transactionID == "total" then
                            db.scans[scanID].totalMoney = transaction
                        elseif transactionID == "tabName" then
                            if transaction ~= "Money" then
                                db.tabs[tab] = {
                                    name = transaction,
                                    icon = 134400,
                                }
                            elseif tab ~= MAX_GUILDBANK_TABS + 1 then
                                local name, icon = GetGuildBankTabInfo(tab)
                                db.tabs[tab] = {
                                    name = name,
                                    icon = icon or 134400,
                                }
                            end
                        elseif type(transaction) == "table" then
                            local t = date("*t", time())
                            if (transactions.tabName and transactions.tabName == "Money") or tab == 9 then
                                local transactionTime, name, transactionType, count = unpack(transaction)
                                transactionTime = date("*t", transactionTime)

                                tinsert(db.scans[scanID].moneyTransactions, AceSerializer:Serialize(transactionType, name, count, t.year - transactionTime.year, t.month - transactionTime.month, t.day - transactionTime.day, t.hour - transactionTime.hour))
                            else
                                local transactionTime, name, transactionType, count, itemLink, moveOrigin, moveDestination = unpack(transaction)
                                transactionTime = date("*t", transactionTime)

                                tinsert(db.scans[scanID].tabs[tab].transactions, AceSerializer:Serialize(transactionType, name, itemLink, count, moveOrigin or 0, moveDestination or 0, t.year - transactionTime.year, t.month - transactionTime.month, t.day - transactionTime.day, t.hour - transactionTime.hour))
                            end
                        end
                    end
                end
            end
        end
    end

    if backup.settings then
        private.db.global.settings.scans.review = backup.settings.showFrameAfterScan
        private.db.global.settings.scans.autoScan.enabled = backup.settings.autoScan
        private.db.global.settings.scans.autoScan.review = backup.settings.showFrameAfterAutoScan
        private.db.global.preferences.dateFormat = backup.settings.dateFormat
        private.db.global.preferences.defaultGuild = backup.settings.defaultGuild
        private.db.global.preferences.confirmDeletions = backup.settings.confirmDeletion
        private.db.global.preferences.dateType = backup.settings.approxDates and "approx" or "default"
        private.db.global.preferences.exportDelimiter = backup.settings.exportDelimiter
    end

    private.db.global.backup = nil
end
