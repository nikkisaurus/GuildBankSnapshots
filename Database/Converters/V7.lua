local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

local entries = {}
function private:ConvertDatabaseV7()
    -- Update masterScan
    if private.db.global and private.db.global.guilds then
        for guildKey, guildInfo in pairs(private.db.global.guilds) do
            private.db.global.guilds[guildKey].masterScan = {}
            private.db.global.guilds[guildKey].filters = {}

            if guildInfo.scans then
                for scanID, scan in addon:pairs(guildInfo.scans) do
                    for tabID, tab in addon:pairs(scan.tabs) do
                        for _, transaction in addon:pairs(tab.transactions) do
                            local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

                            local approxDate = private:GetTransactionDate(scanID, year, month, day, hour)
                            local mins = tonumber(date("%M", approxDate))
                            local transactionDate = approxDate - (mins * private.timeInSeconds.minute)

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
                                elementData.isDupe = abs(transactionDate - entries[key]) <= (private.timeInSeconds.hour + private.timeInSeconds.minute)
                            end
                            entries[key] = transactionDate

                            tinsert(private.db.global.guilds[guildKey].masterScan, elementData)
                        end
                    end

                    for _, transaction in addon:pairs(scan.moneyTransactions) do
                        local transactionType, name, amount, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

                        local approxDate = private:GetTransactionDate(scanID, year, month, day, hour)
                        local mins = tonumber(date("%M", approxDate))
                        local transactionDate = approxDate - (mins * private.timeInSeconds.minute)

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
                            elementData.isDupe = abs(transactionDate - entries[key]) <= (private.timeInSeconds.hour + private.timeInSeconds.minute)
                        end
                        entries[key] = transactionDate

                        tinsert(private.db.global.guilds[guildKey].masterScan, elementData)
                    end
                end

                private.db.global.guilds[guildKey].scans = nil
            end
        end
    end
end
