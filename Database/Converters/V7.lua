local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:ConvertDatabaseV7()
    -- Update masterScan
    if private.db.global and private.db.global.guilds then
        for guildKey, guildInfo in pairs(private.db.global.guilds) do
            private.db.global.guilds[guildKey].masterScan = {}
            private.db.global.guilds[guildKey].filters = {}

            for scanID, scan in pairs(guildInfo.scans) do
                for tabID, tab in pairs(scan.tabs) do
                    for _, transaction in pairs(tab.transactions) do
                        local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = select(2, LibStub("AceSerializer-3.0"):Deserialize(transaction))

                        tinsert(private.db.global.guilds[guildKey].masterScan, {
                            transactionID = #private.db.global.guilds[guildKey].masterScan + 1,
                            scanID = scanID,
                            tabID = tabID,
                            transactionDate = private:GetTransactionDate(scanID, year, month, day, hour),

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
                        })
                    end
                end

                for _, transaction in pairs(scan.moneyTransactions) do
                    local transactionType, name, amount, year, month, day, hour = select(2, LibStub("AceSerializer-3.0"):Deserialize(transaction))

                    tinsert(private.db.global.guilds[guildKey].masterScan, {
                        transactionID = #private.db.global.guilds[guildKey].masterScan + 1,
                        scanID = scanID,
                        tabID = MAX_GUILDBANK_TABS + 1,
                        transactionDate = private:GetTransactionDate(scanID, year, month, day, hour),

                        transactionType = transactionType,
                        name = name or UNKNOWN,
                        amount = amount,
                        year = year,
                        month = month,
                        day = day,
                        hour = hour,
                    })
                end
            end
        end
    end
end

-- ["scanID"] = 1674193374,
-- ["tabID"] = 1,
-- ["info"] = {
--     ["scanID"] = 1674193374,
--     ["moveOrigin"] = 0,
--     ["hour"] = 17,
--     ["day"] = 12,
--     ["month"] = 0,
--     ["approxDate"] = 1673095374,
--     ["itemLink"] = "|cff0070dd|Hitem:184479::::::::53:104:::::::::|h[Shrouded Cloth Bag]|h|r",
--     ["moveDestination"] = 0,
--     ["isDupe"] = true,
--     ["transactionType"] = "deposit",
--     ["entryID"] = 1,
--     ["count"] = 1,
--     ["tabID"] = 1,
--     ["transactionDate"] = 1673095374,
--     ["year"] = 0,
--     ["name"] = "Kairra",
--     ["transactionID"] = 1,
-- },
-- ["label"] = "|cffffd100Kairra|r deposited |cff0070dd|Hitem:184479::::::::53:104:::::::::|h[Shrouded Cloth Bag]|h|r",
-- ["transaction"] = "^1^Sdeposit^SKairra^S|cff0070dd|Hitem:184479::::::::53:104:::::::::|h[Shrouded~`Cloth~`Bag]|h|r^N1^N0^N0^N0^N0^N12^N17^^",
-- ["transactionID"] = 1,

-- local elementData = transaction.info
-- elementData.transactionDate = private:GetTransactionDate(elementData.scanID, elementData.year, elementData.month, elementData.day, elementData.hour)
-- elementData.transactionID = transaction.transactionID
-- elementData.scanID = transaction.scanID
