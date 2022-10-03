local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
private.analyze = {}

local function ValidateItemNames(info)
    local scan = private.analyze.scan
    if not scan then
        return
    end

    for itemLink, _ in pairs(scan[2].items) do
        if not scan[2].itemNames[itemLink] then
            private:SelectAnalyzeScan(private.analyze.scan[1], info)
            LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
            return true
        end
    end
end

local function SelectCharacter(info, character)
    private.analyze.character = character
    if not character then
        return
    end

    local char = private.analyze.scan[2].characters[character]
    local args = info.options.args.analyze.args.character.args
    local scan = private.analyze.scan[2]

    if not ValidateItemNames(info) then
        -- Update deposits
        wipe(args.deposit.args)

        local i = 1
        for itemLink, count in
            addon.pairs(char.deposit, function(a, b)
                return scan.itemNames[a] < scan.itemNames[b]
            end)
        do
            args.deposit.args[itemLink] = {
                order = i,
                type = "description",
                name = format("%s x%d", itemLink, count),
            }
            i = i + 1
        end

        -- Update withdrawals
        wipe(args.withdraw.args)

        i = 1
        for itemLink, count in
            addon.pairs(char.withdraw, function(a, b)
                return scan.itemNames[a] < scan.itemNames[b]
            end)
        do
            args.withdraw.args[itemLink] = {
                order = i,
                type = "description",
                name = format("%s x%d", itemLink, count),
            }
            i = i + 1
        end
    else
        SelectCharacter(info, character)
    end
end

local function SelectItem(info, itemLink)
    private.analyze.item = itemLink
    if not itemLink then
        return
    end

    local item = private.analyze.scan[2].items[itemLink]
    local args = info.options.args.analyze.args.item.args
    local scan = private.analyze.scan[2]

    -- Update deposits
    wipe(args.deposit.args)

    local i = 1
    for character, count in addon.pairs(item.deposit) do
        args.deposit.args[character] = {
            order = i,
            type = "description",
            name = format("%s: %d", character, count),
        }
        i = i + 1
    end

    -- Update withdrawals
    wipe(args.withdraw.args)

    i = 1
    for character, count in addon.pairs(item.withdraw) do
        args.withdraw.args[character] = {
            order = i,
            type = "description",
            name = format("%s: %d", character, count),
        }
        i = i + 1
    end
end

function private:GetAnalyzeOptions()
    local options = {
        selectGuild = {
            order = 1,
            type = "select",
            style = "dropdown",
            name = L["Guild"],
            width = "full",
            disabled = function()
                return addon.tcount(private.db.global.guilds) == 0
            end,
            get = function()
                return private.analyze.guild or private:SelectAnalyzeGuild(private.db.global.settings.preferences.defaultGuild)
            end,
            set = function(_, guildID)
                private:SelectAnalyzeGuild(guildID)
            end,
            values = function()
                local guilds = {}

                for guildID, guildInfo in addon.pairs(private.db.global.guilds) do
                    guilds[guildID] = private:GetGuildDisplayName(guildID)
                end

                return guilds
            end,
        },
        selectScan = {
            order = 2,
            type = "select",
            style = "dropdown",
            name = L["Scan"],
            width = "full",
            disabled = function()
                return not private.analyze.guild or addon.tcount(private.db.global.guilds[private.analyze.guild].scans) == 0
            end,
            get = function()
                return private.analyze.scan and private.analyze.scan[1]
            end,
            set = function(info, scanID)
                private:SelectAnalyzeScan(scanID, info)
            end,
            values = function()
                if not private.analyze.guild then
                    return {}
                end

                local scans = {}

                for scanID, _ in pairs(private.db.global.guilds[private.analyze.guild].scans) do
                    scans[scanID] = date(private.db.global.settings.preferences.dateFormat, scanID)
                end

                return scans
            end,
            sorting = function()
                if not private.analyze.guild then
                    return {}
                end

                local scans = {}

                for scanID, _ in
                    addon.pairs(private.db.global.guilds[private.analyze.guild].scans, function(a, b)
                        return b < a
                    end)
                do
                    tinsert(scans, scanID)
                end

                return scans
            end,
        },
        character = {
            order = 3,
            type = "group",
            childGroups = "tab",
            name = L["Character"],
            disabled = function()
                return not private.analyze.scan
            end,
            args = {
                selectCharacter = {
                    order = 1,
                    type = "select",
                    style = "dropdown",
                    name = L["Character"],
                    width = "full",
                    get = function()
                        return private.analyze.character
                    end,
                    set = function(info, character)
                        SelectCharacter(info, character)
                    end,
                    disabled = function(info)
                        return addon.tcount(info.option.values()) == 0
                    end,
                    values = function()
                        if not private.analyze.scan then
                            return {}
                        end

                        local characters = {}

                        for character, _ in addon.pairs(private.analyze.scan[2].characters) do
                            characters[character] = character
                        end

                        return characters
                    end,
                },
                summary = {
                    order = 2,
                    type = "group",
                    inline = true,
                    name = L["Summary"],
                    hidden = function()
                        return not private.analyze.character
                    end,
                    args = {
                        deposits = {
                            order = 1,
                            type = "description",
                            width = "full",
                            name = function()
                                if not private.analyze.character then
                                    return ""
                                end

                                local character = private.analyze.scan[2].characters[private.analyze.character]
                                local total = 0

                                -- Get total count of items
                                for _, count in pairs(character.deposit) do
                                    total = total + count
                                end

                                return format("%s: %d (%d)", L["Deposits"], addon.tcount(character.deposit), total)
                            end,
                        },
                        withdrawals = {
                            order = 2,
                            type = "description",
                            width = "full",
                            name = function()
                                if not private.analyze.character then
                                    return ""
                                end

                                local character = private.analyze.scan[2].characters[private.analyze.character]
                                local total = 0

                                -- Get total count of items
                                for _, count in pairs(character.withdraw) do
                                    total = total + count
                                end

                                return format("%s: %d (%d)", L["Withdrawals"], addon.tcount(character.withdraw), total)
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
                                if not private.analyze.character then
                                    return ""
                                end

                                local character = private.analyze.scan[2].characters[private.analyze.character]

                                return format("%s: %s", L["Deposits"], GetCoinTextureString(character.money.deposit + character.money.buyTab))
                            end,
                        },
                        moneyWithdrawals = {
                            order = 5,
                            type = "description",
                            width = "full",
                            name = function()
                                if not private.analyze.character then
                                    return ""
                                end

                                local character = private.analyze.scan[2].characters[private.analyze.character]

                                return format("%s: %s", L["Withdrawals"], GetCoinTextureString(character.money.withdraw))
                            end,
                        },
                        moneyRepairs = {
                            order = 6,
                            type = "description",
                            width = "full",
                            name = function()
                                if not private.analyze.character then
                                    return ""
                                end

                                local character = private.analyze.scan[2].characters[private.analyze.character]

                                return format("%s: %s", L["Repairs"], GetCoinTextureString(character.money.repair))
                            end,
                        },
                        netMoney = {
                            order = 7,
                            type = "description",
                            width = "full",
                            name = function()
                                if not private.analyze.character then
                                    return ""
                                end

                                local character = private.analyze.scan[2].characters[private.analyze.character]
                                local count = character.money.deposit + character.money.buyTab - character.money.withdraw - character.money.repair
                                local red = LibStub("LibAddonUtils-1.0").ChatColors["RED"]
                                local white = LibStub("LibAddonUtils-1.0").ChatColors["WHITE"]

                                return format("%s: %s%s|r", L["Net"], count < 0 and red or white, GetCoinTextureString(math.abs(count)))
                            end,
                        },
                    },
                },
                deposit = {
                    order = 3,
                    type = "group",
                    name = L["Deposits"],
                    hidden = function()
                        return not private.analyze.character
                    end,
                    disabled = function()
                        local character = private.analyze.scan[2].characters[private.analyze.character]
                        return not private.analyze.character or addon.tcount(character.deposit) == 0
                    end,
                    args = {},
                },
                withdraw = {
                    order = 4,
                    type = "group",
                    name = L["Withdrawals"],
                    hidden = function()
                        return not private.analyze.character
                    end,
                    disabled = function()
                        local character = private.analyze.scan[2].characters[private.analyze.character]
                        return not private.analyze.character or addon.tcount(character.withdraw) == 0
                    end,
                    args = {},
                },
            },
        },
        item = {
            order = 4,
            type = "group",
            childGroups = "tab",
            name = L["Item"],
            disabled = function()
                return not private.analyze.scan
            end,
            args = {
                selectItem = {
                    order = 1,
                    type = "select",
                    style = "dropdown",
                    name = L["Select Item"],
                    width = "full",
                    disabled = function(info)
                        return addon.tcount(info.option.values()) == 0
                    end,
                    get = function()
                        return private.analyze.item
                    end,
                    set = function(info, itemLink)
                        SelectItem(info, itemLink)
                    end,
                    values = function()
                        if not private.analyze.scan then
                            return {}
                        end

                        local items = {}

                        for itemLink, _ in addon.pairs(private.analyze.scan[2].items) do
                            items[itemLink] = itemLink
                        end

                        return items
                    end,
                    sorting = function(info)
                        if not private.analyze.scan then
                            return {}
                        end

                        local scan = private.analyze.scan[2]
                        local items = {}

                        if not ValidateItemNames(info) then
                            for itemLink, _ in
                                addon.pairs(scan.items, function(a, b)
                                    return scan.itemNames[a] < scan.itemNames[b]
                                end)
                            do
                                tinsert(items, itemLink)
                            end

                            return items
                        end
                    end,
                },
                summary = {
                    order = 2,
                    type = "group",
                    inline = true,
                    name = L["Summary"],
                    hidden = function()
                        return not private.analyze.item
                    end,
                    args = {
                        currentTotal = {
                            order = 1,
                            type = "description",
                            name = function()
                                if not private.analyze.item then
                                    return ""
                                end
                                local total = 0
                                for _, tabInfo in pairs(private.db.global.guilds[private.analyze.guild].scans[private.analyze.scan[1]].tabs) do
                                    for itemID, count in pairs(tabInfo.items) do
                                        if itemID == (GetItemInfoInstant(private.analyze.item)) then
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
                                if not private.analyze.item then
                                    return ""
                                end

                                local count = 0

                                for _, amount in pairs(private.analyze.scan[2].items[private.analyze.item].deposit) do
                                    count = count + amount
                                end

                                return format("%s: %d", L["Deposits"], count)
                            end,
                        },
                        withdraw = {
                            order = 2,
                            type = "description",
                            name = function()
                                if not private.analyze.item then
                                    return ""
                                end

                                local count = 0

                                for _, amount in pairs(private.analyze.scan[2].items[private.analyze.item].withdraw) do
                                    count = count + amount
                                end

                                return format("%s: %d", L["Withdrawals"], count)
                            end,
                        },
                    },
                },
                deposit = {
                    order = 3,
                    type = "group",
                    name = L["Deposits"],
                    hidden = function()
                        return not private.analyze.item
                    end,
                    disabled = function()
                        local item = private.analyze.scan[2].items[private.analyze.item]
                        return not private.analyze.item or addon.tcount(item.deposit) == 0
                    end,
                    args = {},
                },
                withdraw = {
                    order = 4,
                    type = "group",
                    name = L["Withdrawals"],
                    hidden = function()
                        return not private.analyze.item
                    end,
                    disabled = function()
                        local item = private.analyze.scan[2].items[private.analyze.item]
                        return not private.analyze.item or addon.tcount(item.withdraw) == 0
                    end,
                    args = {},
                },
            },
        },
        money = {
            order = 5,
            type = "group",
            childGroups = "tab",
            name = L["Money"],
            disabled = function()
                return not private.analyze.scan
            end,
            args = {
                summary = {
                    order = 2,
                    type = "group",
                    inline = true,
                    name = L["Summary"],
                    args = {
                        currentTotal = {
                            order = 1,
                            type = "description",
                            name = function()
                                if not private.analyze.scan then
                                    return ""
                                end
                                return format("%s: %s", L["Current Total"], GetCoinTextureString(private.db.global.guilds[private.analyze.guild].scans[private.analyze.scan[1]].totalMoney))
                            end,
                        },
                        deposit = {
                            order = 2,
                            type = "description",
                            name = function()
                                if not private.analyze.scan then
                                    return ""
                                end

                                local total = 0
                                for transactionType, amount in pairs(private.analyze.scan[2].money) do
                                    if transactionType == "buyTab" or transactionType == "deposit" then
                                        total = total + amount
                                    end
                                end

                                return format("%s: %s", L["Deposits"], GetCoinTextureString(total))
                            end,
                        },
                        withdraw = {
                            order = 3,
                            type = "description",
                            name = function()
                                if not private.analyze.scan then
                                    return ""
                                end

                                local total = 0
                                for transactionType, amount in pairs(private.analyze.scan[2].money) do
                                    if transactionType == "withdraw" then
                                        total = total + amount
                                    end
                                end

                                return format("%s: %s", L["Withdrawals"], GetCoinTextureString(total))
                            end,
                        },
                        repair = {
                            order = 4,
                            type = "description",
                            name = function()
                                if not private.analyze.scan then
                                    return ""
                                end

                                local total = 0
                                for transactionType, amount in pairs(private.analyze.scan[2].money) do
                                    if transactionType == "repair" then
                                        total = total + amount
                                    end
                                end

                                return format("%s: %s", L["Repairs"], GetCoinTextureString(total))
                            end,
                        },
                    },
                },
                deposit = {
                    order = 2,
                    type = "group",
                    name = L["Deposits"],
                    hidden = function()
                        return not private.analyze.scan
                    end,
                    disabled = function()
                        return not private.analyze.scan or (private.analyze.scan[2].money.deposit + private.analyze.scan[2].money.buyTab) == 0
                    end,
                    args = {},
                },
                withdraw = {
                    order = 3,
                    type = "group",
                    name = L["Withdrawals"],
                    hidden = function()
                        return not private.analyze.scan
                    end,
                    disabled = function()
                        return not private.analyze.scan or private.analyze.scan[2].money.withdraw == 0
                    end,
                    args = {},
                },
                repair = {
                    order = 4,
                    type = "group",
                    name = L["Repairs"],
                    hidden = function()
                        return not private.analyze.scan
                    end,
                    disabled = function()
                        return not private.analyze.scan or private.analyze.scan[2].money.repair == 0
                    end,
                    args = {},
                },
            },
        },
    }

    return options
end

function private:SelectAnalyzeGuild(guildID)
    private.analyze.guild = guildID
    private.analyze.scan = nil
    private.analyze.character = nil
    private.analyze.item = nil
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    return guildID
end

function private:SelectAnalyzeScan(scanID, options)
    private.analyze.character = nil
    private.analyze.item = nil

    local scan = private.db.global.guilds[private.analyze.guild].scans[scanID]
    options = options and options.options or private.options

    -- Initialize info
    local info = {
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
                info.items[transactionInfo.itemLink] = info.items[transactionInfo.itemLink] or {
                    withdraw = {},
                    deposit = {},
                    move = {},
                }

                local item = info.items[transactionInfo.itemLink]

                -- Update item values
                item[transactionInfo.transactionType][transactionInfo.name] = transactionInfo.count + (item[transactionInfo.transactionType][transactionInfo.name] or 0)
                addon.CacheItem(transactionInfo.itemLink, function(itemID, info, itemLink)
                    info.itemNames[itemLink] = (GetItemInfo(itemLink))
                end, info, transactionInfo.itemLink)

                -- Initialize character table
                info.characters[transactionInfo.name] = info.characters[transactionInfo.name] or {
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

                local character = info.characters[transactionInfo.name]

                -- Update character values
                character[transactionInfo.transactionType][transactionInfo.itemLink] = transactionInfo.count + (character[transactionInfo.transactionType][transactionInfo.itemLink] or 0)
            end
        end
    end

    -- Get item names
    for _, tabInfo in pairs(scan.tabs) do
        for itemID, count in pairs(tabInfo.items) do
            addon.CacheItem(itemID, function(itemID, info, count)
                local itemName, itemLink = GetItemInfo(itemID)
                info.itemNames[itemLink] = itemName
            end, info, count)
        end
    end

    -- Clear money lists
    local args = options.args.analyze.args.money.args
    wipe(args.deposit.args)
    wipe(args.withdraw.args)
    wipe(args.repair.args)

    -- Scan money
    for _, transaction in pairs(scan.moneyTransactions) do
        local transactionInfo = private:GetMoneyTransactionInfo(transaction)
        transactionInfo.name = transactionInfo.name or L["Unknown"]

        if transactionInfo then
            -- Update money values
            info.money[transactionInfo.transactionType] = (info.money[transactionInfo.transactionType] or 0) + transactionInfo.amount

            -- Initialize character table
            info.characters[transactionInfo.name] = info.characters[transactionInfo.name] or {
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

            local character = info.characters[transactionInfo.name]

            -- Update character values
            character.money[transactionInfo.transactionType] = (character.money[transactionInfo.transactionType] or 0) + transactionInfo.amount

            -- Update money list
            if transactionInfo.transactionType ~= "depositSummary" then -- Implement deposit summary in analyze
                args[(transactionInfo.transactionType == "buyTab" and "deposit") or (transactionInfo.transactionType == "withdrawForTab" and "withdraw") or transactionInfo.transactionType].args[transactionInfo.name] = {
                    type = "description",
                    name = format("%s: %s", transactionInfo.name, GetCoinTextureString(character.money[transactionInfo.transactionType])),
                }
            end
        end
    end

    private.analyze.scan = { scanID, info }
end
