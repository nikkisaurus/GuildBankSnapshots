local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local red = LibStub("LibAddonUtils-1.0").ChatColors["RED"]
local white = LibStub("LibAddonUtils-1.0").ChatColors["WHITE"]


local function SelectCharacter(character)
    addon.selectedAnalyzeCharacter = character
    return character
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
                        return addon.selectedAnalyzeCharacter
                    end,
                    set = function(_, character)
                        SelectCharacter(character)
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
                                if not addon.selectedAnalyzeCharacter then return "" end
        
                                local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                                local count = 0
        
                                for _, tabInfo in pairs(scan.tabs) do
                                    for transactionID, transactionInfo in pairs(tabInfo.transactions) do
                                        local info = addon:GetTransactionInfo(transactionInfo)
                                        if info and (info.name and info.name == addon.selectedAnalyzeCharacter or not info.name and addon.selectedAnalyzeCharacter == "Unknown") then
                                            if info.transactionType == "deposit" then
                                                count = count + 1
                                            end
                                        end
                                    end
                                end
        
                                return format("%s: %d", L["Deposits"], count)
                            end,
                        },
                        withdrawals = {
                            order = 2,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then return "" end
        
                                local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                                local count = 0
        
                                for _, tabInfo in pairs(scan.tabs) do
                                    for transactionID, transactionInfo in pairs(tabInfo.transactions) do
                                        local info = addon:GetTransactionInfo(transactionInfo)
                                        if info and (info.name and info.name == addon.selectedAnalyzeCharacter or not info.name and addon.selectedAnalyzeCharacter == "Unknown") then
                                            if info.transactionType == "withdraw" then
                                                count = count + 1
                                            end
                                        end
                                    end
                                end
        
                                return format("%s: %d", L["Withdrawals"], count)
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
                                if not addon.selectedAnalyzeCharacter then return "" end
        
                                local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                                local count = 0
        
                                for transactionID, transactionInfo in pairs(scan.moneyTransactions) do
                                    local info = addon:GetMoneyTransactionInfo(transactionInfo)
                                    if info and (info.name and info.name == addon.selectedAnalyzeCharacter or not info.name and addon.selectedAnalyzeCharacter == "Unknown") then
                                        if info.transactionType == "deposit" or info.transactionType == "buyTab" then
                                            count = count + (info.amount or 0)
                                        end
                                    end
                                end
        
                                return format("%s: %s", L["Deposits"], GetCoinTextureString(count))
                            end,
                        },
                        moneyWithdrawals = {
                            order = 5,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then return "" end
        
                                local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                                local count = 0
        
                                for transactionID, transactionInfo in pairs(scan.moneyTransactions) do
                                    local info = addon:GetMoneyTransactionInfo(transactionInfo)
                                    if info and (info.name and info.name == addon.selectedAnalyzeCharacter or not info.name and addon.selectedAnalyzeCharacter == "Unknown") then
                                        if info.transactionType == "withdraw" then
                                            count = count + (info.amount or 0)
                                        end
                                    end
                                end
        
                                return format("%s: %s", L["Withdrawals"], GetCoinTextureString(count))
                            end,
                        },
                        moneyRepairs = {
                            order = 6,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then return "" end
        
                                local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                                local count = 0
        
                                for transactionID, transactionInfo in pairs(scan.moneyTransactions) do
                                    local info = addon:GetMoneyTransactionInfo(transactionInfo)
                                    if info and (info.name and info.name == addon.selectedAnalyzeCharacter or not info.name and addon.selectedAnalyzeCharacter == "Unknown") then
                                        if info.transactionType == "repair" then
                                            count = count + (info.amount or 0)
                                        end
                                    end
                                end
        
                                return format("%s: %s", L["Repairs"], GetCoinTextureString(count))
                            end,
                        },
                        netMoney = {
                            order = 7,
                            type = "description",
                            width = "full",
                            name = function()
                                if not addon.selectedAnalyzeCharacter then return "" end
        
                                local scan = addon.db.global.guilds[addon.selectedAnalyzeGuild].scans[addon.selectedAnalyzeScan]
                                local count = 0
        
                                for transactionID, transactionInfo in pairs(scan.moneyTransactions) do
                                    local info = addon:GetMoneyTransactionInfo(transactionInfo)
                                    if info and (info.name and info.name == addon.selectedAnalyzeCharacter or not info.name and addon.selectedAnalyzeCharacter == "Unknown") then
                                        if info.transactionType == "repair" or info.transactionType == "withdraw" then
                                            count = count - (info.amount or 0)
                                        elseif info.transactionType == "deposit" then
                                            count = count + (info.amount or 0)
                                        end
                                    end
                                end

                                return format("%s: %s%s|r", L["Net"], count < 0 and red or white, GetCoinTextureString(math.abs(count)))
                            end,
                        },
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