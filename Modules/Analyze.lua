local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
private.analyze = {}

function private:GetAnalyzeOptions()
    local options = {}

    for guildKey, guild in addon.pairs(private.db.global.guilds) do
        options[guildKey] = {
            type = "group",
            name = private:GetGuildDisplayName(guildKey),
            args = {},
        }

        local i = 0
        for scanID, scan in
            addon.pairs(guild.scans, function(a, b)
                return a > b
            end)
        do
            i = i + 1
            options[guildKey].args[tostring(scanID)] = {
                order = i,
                type = "group",
                name = date(private.db.global.settings.preferences.dateFormat, scanID),
                childGroups = "tab",
                args = {
                    character = {
                        order = 1,
                        type = "group",
                        childGroups = "select",
                        name = L["Character"],
                        args = {},
                    },
                    item = {
                        order = 2,
                        type = "group",
                        childGroups = "select",
                        name = L["Item"],
                        args = {},
                    },
                    money = {
                        order = 3,
                        type = "group",
                        childGroups = "tab",
                        name = L["Money"],
                        args = {
                            summary = {
                                order = 1,
                                type = "group",
                                inline = true,
                                name = L["Summary"],
                                args = {
                                    currentTotal = {
                                        order = 1,
                                        type = "description",
                                        name = function()
                                            return format("%s: %s", L["Current Total"], GetCoinTextureString(scan.totalMoney))
                                        end,
                                    },
                                },
                            },
                        },
                    },
                },
            }

            -- Initialize info
            local scanInfo = {
                items = {},
                itemNames = {},
                characters = {},
                money = {
                    buyTab = 0,
                    repair = 0,
                    deposit = 0,
                    withdraw = 0,
                },
            }

            -- Scan transactions
            for _, tabInfo in pairs(scan.tabs) do
                for _, transaction in pairs(tabInfo.transactions) do
                    local transactionInfo = private:GetTransactionInfo(transaction)
                    transactionInfo.name = transactionInfo.name or L["Unknown"]

                    if transactionInfo then
                        -- Initialize item table
                        scanInfo.items[transactionInfo.itemLink] = scanInfo.items[transactionInfo.itemLink] or {
                            withdraw = {},
                            deposit = {},
                            move = {},
                        }

                        local item = scanInfo.items[transactionInfo.itemLink]

                        -- Update item values
                        item[transactionInfo.transactionType][transactionInfo.name] = transactionInfo.count + (item[transactionInfo.transactionType][transactionInfo.name] or 0)
                        addon.CacheItem(transactionInfo.itemLink, function(itemID, info, itemLink)
                            info.itemNames[itemLink] = (GetItemInfo(itemLink))
                        end, scanInfo, transactionInfo.itemLink)

                        -- Initialize character table
                        scanInfo.characters[transactionInfo.name] = scanInfo.characters[transactionInfo.name] or {
                            withdraw = {},
                            deposit = {},
                            move = {},
                            money = {
                                buyTab = 0,
                                repair = 0,
                                deposit = 0,
                                withdraw = 0,
                            },
                        }

                        local character = scanInfo.characters[transactionInfo.name]

                        -- Update character values
                        character[transactionInfo.transactionType][transactionInfo.itemLink] = transactionInfo.count + (character[transactionInfo.transactionType][transactionInfo.itemLink] or 0)
                    end
                end
            end

            -- Character
            for character, charInfo in pairs(scanInfo.characters) do
                options[guildKey].args[tostring(scanID)].args.character.args[character] = {
                    type = "group",
                    name = character,
                    childGroups = "tab",
                    args = {
                        summary = {
                            order = 1,
                            type = "group",
                            inline = true,
                            name = L["Summary"],
                            args = {
                                deposits = {
                                    order = 1,
                                    type = "description",
                                    width = "full",
                                    name = function()
                                        local total = 0

                                        -- Get total count of items
                                        for _, count in pairs(charInfo.deposit) do
                                            total = total + count
                                        end

                                        return format("%s: %d (%d)", L["Deposits"], addon.tcount(charInfo.deposit), total)
                                    end,
                                },
                                withdrawals = {
                                    order = 2,
                                    type = "description",
                                    width = "full",
                                    name = function()
                                        local total = 0

                                        -- Get total count of items
                                        for _, count in pairs(charInfo.withdraw) do
                                            total = total + count
                                        end

                                        return format("%s: %d (%d)", L["Withdrawals"], addon.tcount(charInfo.withdraw), total)
                                    end,
                                },
                                moneyHeader = {
                                    order = 3,
                                    type = "header",
                                    width = "full",
                                    name = L["Money"],
                                },
                                moneyDeposits = {
                                    order = 4,
                                    type = "description",
                                    width = "full",
                                    name = function()
                                        return format("%s: %s", L["Deposits"], GetCoinTextureString(charInfo.money.deposit + charInfo.money.buyTab))
                                    end,
                                },
                                moneyWithdrawals = {
                                    order = 5,
                                    type = "description",
                                    width = "full",
                                    name = function()
                                        return format("%s: %s", L["Withdrawals"], GetCoinTextureString(charInfo.money.withdraw))
                                    end,
                                },
                                moneyRepairs = {
                                    order = 6,
                                    type = "description",
                                    width = "full",
                                    name = function()
                                        return format("%s: %s", L["Repairs"], GetCoinTextureString(charInfo.money.repair))
                                    end,
                                },
                                netMoney = {
                                    order = 7,
                                    type = "description",
                                    width = "full",
                                    name = function()
                                        local count = charInfo.money.deposit + charInfo.money.buyTab - charInfo.money.withdraw - charInfo.money.repair
                                        local red = LibStub("LibAddonUtils-1.0").ChatColors["RED"]
                                        local white = LibStub("LibAddonUtils-1.0").ChatColors["WHITE"]

                                        return format("%s: %s%s|r", L["Net"], count < 0 and red or white, GetCoinTextureString(math.abs(count)))
                                    end,
                                },
                            },
                        },
                        deposit = {
                            order = 2,
                            type = "group",
                            name = L["Deposits"],
                            disabled = function()
                                return addon.tcount(charInfo.deposit) == 0
                            end,
                            args = {},
                        },
                        withdraw = {
                            order = 3,
                            type = "group",
                            name = L["Withdrawals"],
                            disabled = function()
                                return addon.tcount(charInfo.withdraw) == 0
                            end,
                            args = {},
                        },
                    },
                }

                local x = 0
                for itemLink, count in
                    addon.pairs(scanInfo.characters[character].deposit, function(a, b)
                        local _, _, itemA = strfind(select(3, strfind(a, "|H(.+)|h")), "%[(.+)%]")
                        local _, _, itemB = strfind(select(3, strfind(b, "|H(.+)|h")), "%[(.+)%]")

                        return itemA < itemB
                    end)
                do
                    x = x + 1
                    options[guildKey].args[tostring(scanID)].args.character.args[character].args.deposit.args[itemLink] = {
                        order = x,
                        type = "description",
                        dialogControl = "GuildBankSnapshotsTransaction",
                        name = format("%s x%d", itemLink, count),
                    }
                end

                x = 0
                for itemLink, count in
                    addon.pairs(scanInfo.characters[character].withdraw, function(a, b)
                        local _, _, itemA = strfind(select(3, strfind(a, "|H(.+)|h")), "%[(.+)%]")
                        local _, _, itemB = strfind(select(3, strfind(b, "|H(.+)|h")), "%[(.+)%]")

                        return itemA < itemB
                    end)
                do
                    x = x + 1
                    options[guildKey].args[tostring(scanID)].args.character.args[character].args.withdraw.args[itemLink] = {
                        order = x,
                        type = "description",
                        dialogControl = "GuildBankSnapshotsTransaction",
                        name = format("%s x%d", itemLink, count),
                    }
                end
            end

            -- Item
            local x = 0
            for itemLink, _ in
                addon.pairs(scanInfo.items, function(a, b)
                    local _, _, itemA = strfind(select(3, strfind(a, "|H(.+)|h")), "%[(.+)%]")
                    local _, _, itemB = strfind(select(3, strfind(b, "|H(.+)|h")), "%[(.+)%]")

                    return itemA < itemB
                end)
            do
                x = x + 1
                options[guildKey].args[tostring(scanID)].args.item.args[itemLink] = {
                    order = x,
                    type = "group",
                    childGroups = "tab",
                    name = itemLink,
                    args = {
                        summary = {
                            order = 1,
                            type = "group",
                            inline = true,
                            name = L["Summary"],
                            args = {
                                currentTotal = {
                                    order = 1,
                                    type = "description",
                                    name = function()
                                        local total = 0
                                        for _, tabInfo in pairs(scan.tabs) do
                                            for itemID, count in pairs(tabInfo.items) do
                                                if itemID == (GetItemInfoInstant(itemLink)) then
                                                    total = total + count
                                                end
                                            end
                                        end
                                        return format("%s: %d", L["Current Total"], total)
                                    end,
                                },
                                deposit = {
                                    order = 2,
                                    type = "description",
                                    name = function()
                                        local count = 0

                                        for _, amount in pairs(scanInfo.items[itemLink].deposit) do
                                            count = count + amount
                                        end

                                        return format("%s: %d", L["Deposits"], count)
                                    end,
                                },
                                withdraw = {
                                    order = 2,
                                    type = "description",
                                    name = function()
                                        local count = 0

                                        for _, amount in pairs(scanInfo.items[itemLink].withdraw) do
                                            count = count + amount
                                        end

                                        return format("%s: %d", L["Withdrawals"], count)
                                    end,
                                },
                            },
                        },
                        deposit = {
                            order = 2,
                            type = "group",
                            name = L["Deposits"],
                            disabled = function()
                                return addon.tcount(scanInfo.items[itemLink].deposit) == 0
                            end,
                            args = {},
                        },
                        withdraw = {
                            order = 3,
                            type = "group",
                            name = L["Withdrawals"],
                            disabled = function()
                                return addon.tcount(scanInfo.items[itemLink].withdraw) == 0
                            end,
                            args = {},
                        },
                    },
                }

                for character, count in addon.pairs(scanInfo.items[itemLink].deposit) do
                    options[guildKey].args[tostring(scanID)].args.item.args[itemLink].args.deposit.args[character] = {
                        type = "description",
                        name = format("%s x%d", character, count),
                    }
                end

                for character, count in addon.pairs(scanInfo.items[itemLink].withdraw) do
                    options[guildKey].args[tostring(scanID)].args.item.args[itemLink].args.withdraw.args[character] = {
                        type = "description",
                        name = format("%s x%d", character, count),
                    }
                end
            end

            -- Money
            options[guildKey].args[tostring(scanID)].args.money.args.summary.args.deposit = {
                order = 2,
                type = "description",
                name = function()
                    local total = 0
                    for transactionType, amount in pairs(scanInfo.money) do
                        if transactionType == "buyTab" or transactionType == "deposit" then
                            total = total + amount
                        end
                    end

                    return format("%s: %s", L["Deposits"], GetCoinTextureString(total))
                end,
            }

            options[guildKey].args[tostring(scanID)].args.money.args.summary.args.withdraw = {
                order = 3,
                type = "description",
                name = function()
                    local total = 0
                    for transactionType, amount in pairs(scanInfo.money) do
                        if transactionType == "withdraw" then
                            total = total + amount
                        end
                    end

                    return format("%s: %s", L["Withdrawals"], GetCoinTextureString(total))
                end,
            }

            options[guildKey].args[tostring(scanID)].args.money.args.summary.args.repair = {
                order = 4,
                type = "description",
                name = function()
                    local total = 0
                    for transactionType, amount in pairs(scanInfo.money) do
                        if transactionType == "repair" then
                            total = total + amount
                        end
                    end

                    return format("%s: %s", L["Repairs"], GetCoinTextureString(total))
                end,
            }

            options[guildKey].args[tostring(scanID)].args.money.args.deposit = {
                order = 2,
                type = "group",
                name = L["Deposits"],
                disabled = function()
                    return (scanInfo.money.deposit + scanInfo.money.buyTab) == 0
                end,
                args = {},
            }
            options[guildKey].args[tostring(scanID)].args.money.args.withdraw = {
                order = 2,
                type = "group",
                name = L["Withdrawals"],
                disabled = function()
                    return scanInfo.money.withdraw == 0
                end,
                args = {},
            }
            options[guildKey].args[tostring(scanID)].args.money.args.repair = {
                order = 2,
                type = "group",
                name = L["Repairs"],
                disabled = function()
                    return scanInfo.money.repair == 0
                end,
                args = {},
            }

            -- Scan money
            for _, transaction in pairs(scan.moneyTransactions) do
                local transactionInfo = private:GetMoneyTransactionInfo(transaction)
                transactionInfo.name = transactionInfo.name or L["Unknown"]

                if transactionInfo then
                    -- Update money values
                    scanInfo.money[transactionInfo.transactionType] = (scanInfo.money[transactionInfo.transactionType] or 0) + transactionInfo.amount

                    -- Initialize character table
                    scanInfo.characters[transactionInfo.name] = scanInfo.characters[transactionInfo.name] or {
                        withdraw = {},
                        deposit = {},
                        move = {},
                        money = {
                            buyTab = 0,
                            repair = 0,
                            deposit = 0,
                            withdraw = 0,
                        },
                    }

                    local character = scanInfo.characters[transactionInfo.name]

                    -- Update character values
                    character.money[transactionInfo.transactionType] = (character.money[transactionInfo.transactionType] or 0) + transactionInfo.amount

                    -- Update money list
                    if transactionInfo.transactionType ~= "depositSummary" then -- Implement deposit summary in analyze
                        options[guildKey].args[tostring(scanID)].args.money.args[(transactionInfo.transactionType == "buyTab" and "deposit") or (transactionInfo.transactionType == "withdrawForTab" and "withdraw") or transactionInfo.transactionType].args[transactionInfo.name] = {
                            type = "description",
                            name = format("%s: %s", transactionInfo.name, GetCoinTextureString(character.money[transactionInfo.transactionType])),
                        }
                    end
                end
            end
        end
    end

    return options
end
