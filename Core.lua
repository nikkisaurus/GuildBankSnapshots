local addon, ns = ...

local db = setmetatable({}, {__index = function(t, k)
    return _G["GuildBankSnapshotsDB"][k]
end})
ns.db = db

local defaultDB = {
    settings = {
        showFrameAfterScan = true,
        autoScan = false,
        showFrameAfterAutoScan = false,
        dateFormat = "%x (%X)",
        defaultGuild = false,
        confirmDeletion = true,
        approxDates = false,
        timeSinceCurrent = false,
    },
    guilds = {},
    database = 3
}

local L = setmetatable({}, {__index = function(t, k)
    local v = tostring(k)
    rawset(t, k, v)
    return v
end})
ns.L = L

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local f = CreateFrame("Frame", addon .. "Frame", UIParent, "BasicFrameTemplate")
f:SetScript("OnEvent", function(self, event, ...)
    return self[event] and self[event](self, event, ...)
end)
f:Hide()
ns.f = f

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GUILDBANKFRAME_OPENED")
f:RegisterEvent("GUILDBANKFRAME_CLOSED")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

SLASH_GUILDBANKSNAPSHOTS1 = "/gbs"

function SlashCmdList.GUILDBANKSNAPSHOTS(msg)
    if msg == "scan" then
        f:ScanBank()
    elseif msg == "debug db" then
        GuildBankSnapshotsDB = defaultDB
    else
        f:CreateFrame()
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:count(tbl)
    local counter = 0
    for k, v in pairs(tbl) do
        counter = counter + 1
    end

    return counter
end

function f:round(number, decimals)
    return tonumber((("%%.%df"):format(decimals)):format(number))
end

f.pairsByKeys = function(_, t, f)
    local a = {}

    for n in pairs(t) do
        table.insert(a, n)
    end

    table.sort(a, f)

    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end

    return iter
end

function f:print(msg)
    print(string.format("|cff00ff00%s:|r %s", addon, msg))
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local debug = false
function f:ADDON_LOADED(event, loadedAddon, ...)
    if loadedAddon == addon then
        GuildBankSnapshotsDB = GuildBankSnapshotsDB or defaultDB

        if GuildBankSnapshotsDB.Database and GuildBankSnapshotsDB.Database == 2 then
            local backup = GuildBankSnapshotsDB
            GuildBankSnapshotsDB = defaultDB
            GuildBankSnapshotsDB.Backup = backup -- backup database in case any errors are not caught in testing, data is not lost; can delete after a while

            GuildBankSnapshotsDB.settings.autoScan = backup.Settings.AutoScan
            GuildBankSnapshotsDB.settings.showFrameAfterAutoScan = backup.Settings.ShowOnAuto
            GuildBankSnapshotsDB.settings.showFrameAfterScan = backup.Settings.ShowOnScan

            for realm, realmTable in pairs(backup.Transactions) do
                for faction, factionTable in pairs(realmTable) do
                    for guild, guildTable in pairs(factionTable) do
                        local guildID = string.gsub(string.format("G:%s:%s:%s", guild, faction, realm), "%s+", "|s")
                        GuildBankSnapshotsDB.guilds[guildID] = {}

                        for snapshot, snapshotTable in pairs(guildTable) do
                            local month, day, year, hour, min, sec = snapshot:match("(%d+)%/(%d+)%/(%d+)%s(%d+):(%d+):(%d+)")

                            local snapshotID = time({
                                  month = month,
                                  day = day,
                                  year = year,
                                  hour = hour,
                                  min = min,
                                  sec = sec,
                            })

                            GuildBankSnapshotsDB.guilds[guildID][snapshotID] = {}

                            local i = 1

                            for tabNum, tabTable in pairs(snapshotTable.Transactions) do
                                if type(tabTable) == "table" then
                                    for transID, v in pairs(tabTable) do
                                        if type(v) == "table" then
                                            GuildBankSnapshotsDB.guilds[guildID][snapshotID][i] = GuildBankSnapshotsDB.guilds[guildID][snapshotID][i] or {}
                                            GuildBankSnapshotsDB.guilds[guildID][snapshotID][i].tabName = tabTable.Name
                                            local approxTime =  time(f:GetDate(date("*t", snapshotID), v[8], v[9], v[10], v[11]))
                                            v[6] = v[1] == "move" and v[6][2] or nil
                                            v[7] = v[1] == "move" and v[7][2] or nil
                                            tinsert(GuildBankSnapshotsDB.guilds[guildID][snapshotID][i], {approxTime, v[2], v[1], v[5], v[3], v[6], v[7], v[4] ~= "" and v[4] or nil})
                                        end
                                    end
                                end

                                i = i + 1
                            end

                            GuildBankSnapshotsDB.guilds[guildID][snapshotID][i] = {}
                            GuildBankSnapshotsDB.guilds[guildID][snapshotID][i].tabName = L["Money"]

                            for transID, v in pairs(snapshotTable.Money) do
                                 if type(v) == "table" then
                                    local approxTime =  time(f:GetDate(date("*t", snapshotID), v[8], v[9], v[10], v[11]))
                                    tinsert(GuildBankSnapshotsDB.guilds[guildID][snapshotID][i], {approxTime, v[2], v[1], v[3]})
                                 end
                            end

                            GuildBankSnapshotsDB.guilds[guildID][snapshotID][i].total = snapshotTable.MoneyTotal
                        end -- snapshot
                    end -- guild
                end -- faction
            end -- realm
        end

        if debug then
            f:CreateFrame()
        end
    end
end

function f:GUILDBANKFRAME_OPENED(event, ...)
    ns.BankOpen = true
    for i = 1, MAX_GUILDBANK_TABS + 1 do
        QueryGuildBankLog(i)

        if i == MAX_GUILDBANK_TABS + 1 and db.settings.autoScan then
            local scannedToday

            local guildID = f:GetGuildID()
            if db.guilds[guildID] then
                for k, v in pairs(db.guilds[guildID]) do
                    if k > time() - 86400 then
                        scannedToday = true
                    end
                end
            end

            if not scannedToday then
                C_Timer.After(1.5, function()
                    f:ScanBank(true)
                end)
            end
        end
    end
end

function f:GUILDBANKFRAME_CLOSED(event, ...)
    ns.BankOpen = false
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:GetGuildID()
   local guildID =  string.gsub(string.format("G:%s:%s:%s", GetGuildInfo("player"), strsub(UnitFactionGroup("player"), 1, 1), GetRealmName()), "%s+", "|s")
   return guildID
end

function f:GetDate(dateTable, year, month, day, hour, minute, second)
   local dTable = {
      year = dateTable.year - (year or 0),
      month = dateTable.month - (month or 0),
      day = dateTable.day - (day or 0),
      hour = dateTable.hour - (hour or 0),
      min = dateTable.min - (minute or 0),
      sec = dateTable.sec - (second or 0),
      wday = dateTable.wday,
      yday = dateTable.yday,
      isdst = dateTable.isdst
   }
   return dTable, date(db.settings.dateFormat, time(dTable))
end

function f:GetElapsedTime(t, T)
    local elapsed = (T or time()) - t
    local format = elapsed

    if  elapsed < 3600 then
        format = L["< an hour"]
    elseif elapsed < 86400 then
        format = string.format(L["%d hour%s"], f:round(elapsed / 3600, 0), f:round(elapsed / 3600, 0) > 1 and "s" or "")
    elseif elapsed < 2678400 then
        format = string.format(L["%d day%s"], f:round(elapsed / 86400, 0), f:round(elapsed / 86400, 0) > 1 and "s" or "")
    elseif elapsed < 29462400 then
        format = string.format(L["%d month%s"], f:round(elapsed / 2678400, 0), f:round(elapsed / 2678400, 0) > 1 and "s" or "")
    elseif elapsed < 31536000 then
        format = L["1 year"]
    else
        format = L["over a year"]
    end

    return format
end

function f:GetFormattedDate(t)
    return date(db.settings.dateFormat, t)
end

function f:GetFormattedGuildName(guildID)
    local _, guildName, faction, realm = string.split(":", string.gsub(guildID, "|s", " "), 4)
    return string.format("%s-%s [%s]", guildName, realm, faction)
end

function f:GetMoneyString(str)
    if not str then
        return 0
    end
    str = tonumber(str)
    local g = floor(abs(str/10000))
    local s = floor(abs(mod(str/100, 100)))
    local c = floor(abs(mod(str, 100)))

    return string.format("%dg %ds %dc", g, s, c)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:FormatLine(data, logType)
    local line

    local type = data[3]
    local name = data[2]

    if not name then
        name = UNKNOWN or "Unknown"
    end

    name = (NORMAL_FONT_COLOR_CODE or "|cffffd200") .. name .. (FONT_COLOR_CODE_CLOSE or "|r")

    if logType == "money" then
        local money
        local amount = data[4]

        money = GetDenominationsFromCopper(amount)

        if type == "deposit" then
            line = format(GUILDBANK_DEPOSIT_MONEY_FORMAT or "%s deposited %s", name, money)
        elseif type == "withdraw" then
            line = format(GUILDBANK_WITHDRAW_MONEY_FORMAT or "%s |cffff2020withdrew|r %s", name, money)
        elseif type == "repair" then
            line = format(GUILDBANK_REPAIR_MONEY_FORMAT or "%s withdrew %s for repairs", name, money)
        elseif type == "withdrawForTab" then
            line = format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT or "%s withdrew %s to purchase a guild bank tab", name, money)
        elseif type == "buyTab" then
            if amount > 0 then
                line = format(GUILDBANK_BUYTAB_MONEY_FORMAT or "%s purchased a guild bank tab for %s", name, money)
            else
                line = format(GUILDBANK_UNLOCKTAB_FORMAT or "%s unlocked a guild bank tab with a Guild Vault Voucher.", name)
            end
        elseif type == "depositSummary" then
            line = format(GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT or "A total of %s was deposited last week from Guild Perk: Cash Flow ", money)
        end

        if not line then
            return
        end
    elseif logType == "item" then
        local itemLink = data[5]
        local count = data[4]
        local tab1 = data[6]
        local tab2 = data[7]

        if type == "deposit" then
            line = format(GUILDBANK_DEPOSIT_FORMAT or "%s deposited %s", name, itemLink)
            if count > 1 then
                line = line .. format(GUILDBANK_LOG_QUANTITY or " x %d", count)
            end
        elseif type == "withdraw" then
            line = format(GUILDBANK_WITHDRAW_FORMAT or "%s |cffff2020withdrew|r %s", name, itemLink)
            if count > 1 then
                line = line .. format(GUILDBANK_LOG_QUANTITY or " x %d", count)
            end
        elseif type == "move" then
            line = format(GUILDBANK_MOVE_FORMAT or "%s moved %s x %d from %s to %s", name, itemLink, count, tab1, tab2)
        end

        if not line then
            return
        end
    end

    line = line .. (GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   ") .. (db.settings.approxDates and date("at approx. %I %p on %x", data[1]):gsub(" 0", " ") or string.format("( %s ago )", f:GetElapsedTime(data[1], not db.settings.timeSinceCurrent and f.snapshot)))
    return line
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:ScanBank(auto)
    if not ns.BankOpen then
        f:print(L["Please open your guild bank frame and try again."])
        return
    end

    f:print("Scanning guild bank...")

    local guildID = f:GetGuildID()
    if not db.guilds[guildID] then
        db.guilds[guildID] = {}
    end

    local snapshotID = time()
    db.guilds[guildID][snapshotID] = {}
    local snapshotTable = db.guilds[guildID][snapshotID]

    for tab = 1, GetNumGuildBankTabs() do
       QueryGuildBankLog(tab)
       C_Timer.After(0.5, function()
            snapshotTable[tab] = {}

             local numTransactions = GetNumGuildBankTransactions(tab)
             snapshotTable[tab]["tabName"] = select(1, GetGuildBankTabInfo(tab))
             for i = numTransactions, 1, -1 do
                local type, name, itemLink, count, tab1, tab2, year, month, day, hour = GetGuildBankTransaction(tab, i)
                tab1 = tab1 and select(1, GetGuildBankTabInfo(tab1))
                tab2 = tab2 and select(1, GetGuildBankTabInfo(tab2))

                local approxTime =  time(f:GetDate(date("*t", time()), year, month, day, hour))
                local _, _, _, itemLevel, _, itemType = GetItemInfo(itemLink)

                tinsert(snapshotTable[tab], {approxTime, name, type, count, itemLink, tab1, tab2,  (itemType == "Armor" or itemType == "Weapon") and itemLevel})
             end

             if tab == GetNumGuildBankTabs() then
                QueryGuildBankLog(tab + 1)
                C_Timer.After(0.5, function()
                    snapshotTable[tab + 1] = {}

                    local numTransactions = GetNumGuildBankMoneyTransactions()
                    snapshotTable[tab + 1]["tabName"] = L["Money"]
                    snapshotTable[tab + 1]["total"] = GetGuildBankMoney()

                    for i = numTransactions, 1, -1 do
                        local type, name, amount, year, month, day, hour = GetGuildBankMoneyTransaction(i)
                        local approxTime =  time(f:GetDate(date("*t", time()), year, month, day, hour))
                        tinsert(snapshotTable[tab + 1], {approxTime, name, type, amount})
                    end

                    if (auto and db.settings.showFrameAfterAutoScan) or (not auto and db.settings.showFrameAfterScan) then
                        local tabButton = _G[string.format("%sSnapshotsTabBTN", addon)]
                        if not tabButton then
                            f:CreateFrame()
                        else
                            tabButton:Click()
                        end
                        f:UpdateFrame(guildID, snapshotID, 1, nil, nil, f.exportGuild, f.exportText)
                        f:Show()
                    elseif f.guild and f.guild == guildID then
                        f:LoadSnapshotsList(guildID, f.snapshotScrollFrame.ScrollContent)
                    end

                    f:print("Scan finished.")
                end)
             end
       end)
    end
end