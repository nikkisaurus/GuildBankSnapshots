local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local red = LibStub("LibAddonUtils-1.0").ChatColors["RED"]
local white = LibStub("LibAddonUtils-1.0").ChatColors["WHITE"]


local function SelectCharacter(options, character)
    if not character then
        -- Clear character
        addon.selectedAnalyzeCharacter = nil
        return
    end

    local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
    local info = {
        deposit = {
            items = {
                -- [itemID] = 0,
            },
            total = 0,
        },
        withdraw = {
            items = {
                -- [itemID] = 0,
            },
            total = 0,
        },
        money = {
            repair = 0,
            withdraw = 0,
            deposit = 0,
            buyTab = 0,
        },
    }

    -- Wipe deposits and withdrawals
    options.options.args.analyze.args.character.args.deposit.args = {}
    options.options.args.analyze.args.character.args.withdraw.args = {}

    local deposits = {}

    -- Scan transactions
    for tab, tabInfo in pairs(scan.tabs) do
        for t, transaction in pairs(tabInfo.transactions) do
            local transactionInfo = addon:GetTransactionInfo(transaction)
            if transactionInfo and (transactionInfo.name and transactionInfo.name == character or not transactionInfo.name and character == "Unknown") then
                -- Update info table
                if info[transactionInfo.transactionType] then
                    info[transactionInfo.transactionType].items[transactionInfo.itemLink] = transactionInfo.count
                    info[transactionInfo.transactionType].total = info[transactionInfo.transactionType].total + transactionInfo.count
                end

                -- Update item lists
                if options.options.args.analyze.args.character.args[transactionInfo.transactionType] then
                    options.options.args.analyze.args.character.args[transactionInfo.transactionType].args[transactionInfo.itemLink] = {
                        name = format("%s x%d", transactionInfo.itemLink, transactionInfo.count),
                        type = "description",
                        width = "full",
                    }
                end

                -- -- Insert itemLinks into sorting table
                -- if transactionInfo.transactionType == "deposit" then
                --     -- tinsert(deposits, transactionInfo.itemLink)
                --     deposits[GetItemInfo(transactionInfo.itemLink)] = info[transactionInfo.transactionType].items[transactionInfo.itemLink]
                -- end
            end
        end
    end

    -- local i = 0
    -- for k, v in addon.pairs(deposits) do
    --     -- print(k, v)
    --     options.options.args.analyze.args.character.args.deposit.args[k] = {
    --         order = i,
    --         name = format("%s x%d", k, v),
    --         type = "description",
    --         width = "full",
    --     }
    --     i = i + 1
    -- end

    -- Scan money
    for _, transaction in pairs(scan.moneyTransactions) do
        local transactionInfo = addon:GetMoneyTransactionInfo(transaction)
        if transactionInfo and (transactionInfo.name and transactionInfo.name == character or not transactionInfo.name and character == "Unknown") then
            info.money[transactionInfo.transactionType] = info.money[transactionInfo.transactionType] + transactionInfo.amount
        end
    end

    addon.selectedAnalyzeCharacter = {character, info}
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end


local function SelectGuild(guildID)
    addon.selectedAnalyzeGuild = guildID
    addon.selectedAnalyzeScan = nil
    addon.selectedAnalyzeCharacter = nil
    return guildID
end


local function SelectScan(scanID)
    addon.selectedAnalyzeScan = scanID
    addon.selectedAnalyzeCharacter = nil
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    return scanID
end


function addon:GetAnalyzeOptions()
    local options = {
        selectGuild = {
            order = 1,
            type = "select",
            style = "dropdown",
            name = L["Guild"],
            width = "full",
            get = function()
                return addon.selectedAnalyzeGuild or SelectGuild(addon.db.global.settings.defaultGuild)
            end,
            set = function(_, guildID)
                SelectGuild(guildID)
            end,
            disabled = function()
                return addon.tcount(addon.db.global.guilds) == 0
            end,
            values = function()
                local guilds = {}

                for guildID, guildInfo in addon.pairs(addon.db.global.guilds) do
                    guilds[guildID] = guildInfo.guildName
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
            get = function()
                return addon.selectedAnalyzeScan
            end,
            set = function(_, scanID)
                SelectScan(scanID)
            end,
            disabled = function()
                return not addon.selectedAnalyzeGuild or addon.tcount(addon.db.global.guilds[addon.selectedAnalyzeGuild].scans) == 0
            end,
            values = function()
                if not addon.selectedAnalyzeGuild then return {} end

                local scans = {}

                for scanID, _ in pairs(addon.db.global.guilds[addon.selectedAnalyzeGuild].scans) do
                    scans[scanID] = date(addon.db.global.settings.dateFormat, scanID)
                end

                return scans
            end,
            sorting = function()
                if not addon.selectedAnalyzeGuild then return {} end

                local scans = {}

                for scanID, _ in addon.pairs(addon.db.global.guilds[addon.selectedAnalyzeGuild].scans, function(a, b) return b < a end) do
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
                return not addon.selectedAnalyzeScan
            end,
            args = {
                selectCharacter = {
                    order = 1,
                    type = "select",
                    style = "dropdown",
                    name = L["Character"],
                    width = "full",
                    get = function()
                        return addon.selectedAnalyzeCharacter and addon.selectedAnalyzeCharacter[1]
                    end,
                    set = function(info, character)
                        SelectCharacter(info, character)
                    end,
                    disabled = function()
                        if not addon.selectedAnalyzeScan then return {} end

                        local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                        local characters = {}

                        for _, tabInfo in pairs(scan.tabs) do
                            for transactionID, transactionInfo in pairs(tabInfo.transactions) do
                               local info = addon:GetTransactionInfo(transactionInfo)
                               if info then
                                   characters[info.name or "Unknown"] = info.name or L["Unknown"]
                               end
                            end
                        end

                        for transactionID, transactionInfo in pairs(scan.moneyTransactions) do
                           local info = addon:GetTransactionInfo(transactionInfo)
                           if info then
                               characters[info.name or "Unknown"] = info.name or L["Unknown"]
                           end
                        end

                        return addon.tcount(characters) == 0
                    end,
                    values = function()
                        if not addon.selectedAnalyzeScan then return {} end

                        local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                        local characters = {}

                        for _, tabInfo in pairs(scan.tabs) do
                            for transactionID, transactionInfo in pairs(tabInfo.transactions) do
                               local info = addon:GetTransactionInfo(transactionInfo)
                               if info then
                                   characters[info.name or "Unknown"] = info.name or L["Unknown"]
                               end
                            end
                        end

                        for transactionID, transactionInfo in pairs(scan.moneyTransactions) do
                           local info = addon:GetTransactionInfo(transactionInfo)
                           if info then
                               characters[info.name or "Unknown"] = info.name or L["Unknown"]
                           end
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
                        return not addon.selectedAnalyzeCharacter
                    end,
                    args = {
                        deposits = {
                            order = 1,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then
                                    return ""
                                else
                                    return format("%s: %d (%d)", L["Deposits"], addon.tcount(addon.selectedAnalyzeCharacter[2].deposit.items), addon.selectedAnalyzeCharacter[2].deposit.total)
                                end
                            end,
                        },
                        withdrawals = {
                            order = 2,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then
                                    return ""
                                else
                                    return format("%s: %d (%d)", L["Withdrawals"], addon.tcount(addon.selectedAnalyzeCharacter[2].withdraw.items), addon.selectedAnalyzeCharacter[2].withdraw.total)
                                end
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
                                if not addon.selectedAnalyzeCharacter then
                                    return ""
                                else
                                    return format("%s: %s", L["Deposits"], GetCoinTextureString(addon.selectedAnalyzeCharacter[2].money.deposit + addon.selectedAnalyzeCharacter[2].money.buyTab))
                                end
                            end,
                        },
                        moneyWithdrawals = {
                            order = 5,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then
                                    return ""
                                else
                                    return format("%s: %s", L["Withdrawals"], GetCoinTextureString(addon.selectedAnalyzeCharacter[2].money.withdraw))
                                end
                            end,
                        },
                        moneyRepairs = {
                            order = 6,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then
                                    return ""
                                else
                                    return format("%s: %s", L["Repairs"], GetCoinTextureString(addon.selectedAnalyzeCharacter[2].money.repair))
                                end
                            end,
                        },
                        netMoney = {
                            order = 7,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then
                                    return ""
                                else
                                    local count = addon.selectedAnalyzeCharacter[2].money.deposit + addon.selectedAnalyzeCharacter[2].money.buyTab - addon.selectedAnalyzeCharacter[2].money.withdraw - addon.selectedAnalyzeCharacter[2].money.repair
                                    return format("%s: %s%s|r", L["Net"], count < 0 and red or white, GetCoinTextureString(math.abs(count)))
                                end

                            end,
                        },
                    },
                },
                deposit = {
                    order = 3,
                    type = "group",
                    name = L["Deposits"],
                    disabled = function()
                        return not addon.selectedAnalyzeCharacter
                    end,
                    args = {},
                },
                withdraw = {
                    order = 4,
                    type = "group",
                    name = L["Withdrawals"],
                    disabled = function()
                        return not addon.selectedAnalyzeCharacter
                    end,
                    args = {

                    },
                },
            },
        },
        item = {
            order = 4,
            type = "group",
            name = L["Item"],
            disabled = function()
                return not addon.selectedAnalyzeScan
            end,
            args = {

            },
        },
        tab = {
            order = 5,
            type = "group",
            name = L["Tab"],
            disabled = function()
                return not addon.selectedAnalyzeScan
            end,
            args = {

            },
        },
    }

    return options
end
