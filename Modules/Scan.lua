local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer =LibStub("AceSerializer-3.0")

------------------------------------------------------------

local abs = math.abs
local format = string.format
local tinsert = table.insert

--*------------------------------------------------------------------------

local hours = 60 * 60
local days = hours * 24
local months = days * (365 / 12)
local years = months * 12

------------------------------------------------------------

function addon:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * hours) + (day * days) + (month * months) + (year * years)
    return scanTime - sec
end

--*------------------------------------------------------------------------

function addon:ScanGuildBank()
    self:Print(L["Scanning"].."...")
    self.isScanning = true

    local numTabs = self.db.global.guilds[self:GetGuildID()].numTabs

    for tab = 1, numTabs do
        QueryGuildBankTab(tab)
        QueryGuildBankLog(tab)
    end

    C_Timer.After(.2, function()
        local db = {}

        for tab = 1, numTabs do
            db[tab] = {items = {}, transactions = {}}
            local tabDB = db[tab]

            ------------------------------------------------------------

            for index = 1, GetNumGuildBankTransactions(tab) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = GetGuildBankTransaction(tab, index)
                local itemID = GetItemInfoInstant(itemLink)

                tinsert(tabDB.transactions, AceSerializer:Serialize(transactionType, name, itemID, count, moveOrigin or 0, moveDestination or 0, year, month, day, hour))
            end

            ------------------------------------------------------------

            for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
                local slotItemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)
                if slotItemID then
                    local _, slotItemCount = GetGuildBankItemInfo(tab, slot)
                    tabDB.items[slotItemID] = tabDB.items[slotItemID] and tabDB.items[slotItemID] + slotItemCount or slotItemCount
                end
            end
        end

        self:ValidateScan(db)
    end)
end

------------------------------------------------------------

function addon:ValidateScan(db)
    if not self.isScanning then return end

    local scans = self.db.global.guilds[self:GetGuildID()].scans

    local isValid
    for scanTime, scan in self.pairs(scans, function(a, b) return b < a end) do
        for tab, tabDB in pairs(scan) do
            for k, v in pairs(tabDB.items) do
                if v ~= db[tab].items[k] then
                    isValid = true
                    break
                end
            end
        end
        break
    end

    isValid = isValid or self.tcount(scans) == 0

    if isValid then
        self.db.global.guilds[self:GetGuildID()].scans[time()] = db
    end

    self.isScanning = false
    self:Print(L["Scan finished."], not isValid and L["No changes detected."] or "")
end