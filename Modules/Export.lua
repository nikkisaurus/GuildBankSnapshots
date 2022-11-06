local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

private.selectedScans = {}

local function CancelExport(copyBox, start, cancel, selectAll, deselectAll, scrollFrame)
    private.pendingExport = nil

    local guild = private.db.global.guilds[private.selectedExportGuild]
    local numScans = addon.tcount(guild.scans)
    local numSelected = addon.tcount(private.selectedScans)

    copyBox:SetDisabled(true)
    copyBox:SetLabel("")
    copyBox.parent:DoLayout()
    start:SetDisabled()
    cancel:SetDisabled(true)
    selectAll:SetDisabled(numScans == 0 or numScans == numSelected)
    deselectAll:SetDisabled(numScans == 0 or numSelected == 0)
    for _, child in pairs(scrollFrame.children) do
        child:SetDisabled()
    end
end

local function StartExport(copyBox, start, cancel, selectAll, deselectAll, scrollFrame)
    private.pendingExport = true

    start:SetDisabled(true)
    cancel:SetDisabled()
    selectAll:SetDisabled(true)
    deselectAll:SetDisabled(true)
    for _, child in pairs(scrollFrame.children) do
        child:SetDisabled(true)
    end

    local i = 1
    local msg = ""
    addon.tpairs(
        private.selectedScans,
        function(scans, scanID)
            if not private.pendingExport then
                return
            end

            -- Update labels
            copyBox:SetLabel(format("%s (%d%%)", L["Processing"], (i / addon.tcount(scans)) * 100))
            if i == 1 then
                copyBox.parent:DoLayout()
            end

            if private.db.global.guilds[private.selectedExportGuild].scans[scanID] then
                local guild = private.db.global.guilds[private.selectedExportGuild]
                local guildName = private:GetGuildDisplayName(private.selectedExportGuild)
                local scanDate = date(private.db.global.settings.preferences.dateFormat, scanID)

                -- Scan item transactions
                for tab, tabInfo in pairs(private.db.global.guilds[private.selectedExportGuild].scans[scanID].tabs) do
                    if not private.pendingExport then
                        return
                    end
                    for _, transaction in pairs(tabInfo.transactions) do
                        if not private.pendingExport then
                            return
                        end

                        local transactionInfo = private:GetTransactionInfo(transaction)

                        -- transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour
                        local line = {}
                        tinsert(line, guildName)
                        tinsert(line, scanDate)
                        tinsert(line, guild.tabs[tab].name)
                        tinsert(line, transactionInfo.transactionType)
                        tinsert(line, transactionInfo.name or "")
                        tinsert(line, transactionInfo.itemLink)
                        tinsert(line, transactionInfo.count)
                        tinsert(line, guild.tabs[transactionInfo.moveOrigin] and guild.tabs[transactionInfo.moveOrigin].name or "")
                        tinsert(line, guild.tabs[transactionInfo.moveDestination] and guild.tabs[transactionInfo.moveDestination].name or "")
                        tinsert(line, date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(scanID, transactionInfo.year, transactionInfo.month, transactionInfo.day, transactionInfo.hour)))
                        tinsert(line, private:GetTransactionLabel(scanID, transaction))
                        line = table.concat(line, private.db.global.settings.preferences.exportDelimiter)

                        msg = format("%s%s\n", msg, line)
                    end
                end

                -- Scan money transactions
                for _, transaction in pairs(private.db.global.guilds[private.selectedExportGuild].scans[scanID].moneyTransactions) do
                    if not private.pendingExport then
                        return
                    end

                    local transactionInfo = private:GetMoneyTransactionInfo(transaction)

                    -- transactionType, name, amount, year, month, day, hour
                    local line = {}
                    tinsert(line, guildName)
                    tinsert(line, scanDate)
                    tinsert(line, L["Money"])
                    tinsert(line, transactionInfo.transactionType)
                    tinsert(line, transactionInfo.name or "")
                    tinsert(line, "")
                    tinsert(line, GetCoinText(transactionInfo.amount, " "))
                    tinsert(line, "")
                    tinsert(line, "")
                    tinsert(line, date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(scanID, transactionInfo.year, transactionInfo.month, transactionInfo.day, transactionInfo.hour)))
                    tinsert(line, private:GetMoneyTransactionLabel(scanID, transaction))
                    line = table.concat(line, private.db.global.settings.preferences.exportDelimiter)

                    msg = format("%s%s\n", msg, line)
                end
            end

            if i == addon.tcount(private.selectedScans) then
                CancelExport(copyBox, start, cancel, selectAll, deselectAll, scrollFrame)
                copyBox:SetDisabled()

                local header = table.concat({
                    "guildName",
                    "snapshotDate",
                    "tabName",
                    "transactionType",
                    "name",
                    "itemName",
                    "itemMoneyCount",
                    "moveTabName1",
                    "moveTabName2",
                    "transactionDate",
                    "transactionLine",
                }, private.db.global.settings.preferences.exportDelimiter)
                copyBox:SetText(format("%s\n%s", header, msg))
            else
                i = i + 1
            end
        end,
        0.001,
        nil,
        nil,
        function(a, b)
            return b < a
        end
    )
end

local function SelectGuild(guildGroup, _, guildKey)
    if private.selectedExportGuild ~= guildKey then
        wipe(private.selectedScans)
    end
    private.selectedExportGuild = guildKey
    guildGroup:ReleaseChildren()

    local guild = private.db.global.guilds[guildKey]
    if not guild then
        return
    end
    local numScans = addon.tcount(guild.scans)
    local numSelected = addon.tcount(private.selectedScans)

    local copyBox = AceGUI:Create("EditBox")
    copyBox:SetLabel("")
    copyBox:SetFullWidth(true)
    copyBox:DisableButton(true)
    copyBox:SetDisabled(true)
    guildGroup:AddChild(copyBox)

    local selectAll = AceGUI:Create("Button")
    selectAll:SetText(L["Select All"])
    selectAll:SetDisabled(numScans == 0 or numScans == numSelected)
    selectAll:SetCallback("OnClick", function()
        for scanID, _ in pairs(guild.scans) do
            private.selectedScans[scanID] = true
        end
        SelectGuild(guildGroup, _, guildKey)
    end)
    guildGroup:AddChild(selectAll)

    local deselectAll = AceGUI:Create("Button")
    deselectAll:SetText(L["Deselect All"])
    deselectAll:SetDisabled(numScans == 0 or numSelected == 0)
    deselectAll:SetCallback("OnClick", function()
        wipe(private.selectedScans)
        SelectGuild(guildGroup, _, guildKey)
    end)
    guildGroup:AddChild(deselectAll)

    local cancel, scrollFrame
    local start = AceGUI:Create("Button")
    start:SetText(START)
    start:SetDisabled(private.pendingExport or numSelected == 0)
    start:SetCallback("OnClick", function(start)
        StartExport(copyBox, start, cancel, selectAll, deselectAll, scrollFrame)
    end)
    guildGroup:AddChild(start)

    cancel = AceGUI:Create("Button")
    cancel:SetText(CANCEL)
    cancel:SetDisabled(not private.pendingExport)
    cancel:SetCallback("OnClick", function()
        CancelExport(copyBox, start, cancel, selectAll, deselectAll, scrollFrame)
    end)
    guildGroup:AddChild(cancel)

    local scansGroup = AceGUI:Create("InlineGroup")
    scansGroup:SetTitle(L["Scans"])
    scansGroup:SetLayout("Fill")
    scansGroup:SetFullWidth(true)
    scansGroup:SetFullHeight(true)
    guildGroup:AddChild(scansGroup)

    scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scansGroup:AddChild(scrollFrame)

    for scanID, scan in
        addon.pairs(guild.scans, function(a, b)
            return a > b
        end)
    do
        local check = AceGUI:Create("CheckBox")
        check:SetLabel(date(private.db.global.settings.preferences.dateFormat, scanID))
        check:SetCallback("OnValueChanged", function(_, _, value)
            if private.pendingExport then
                return
            end

            private.selectedScans[scanID] = value and true or nil

            local numScans = addon.tcount(guild.scans)
            local numSelected = addon.tcount(private.selectedScans)
            selectAll:SetDisabled(numScans == 0 or numScans == numSelected)
            deselectAll:SetDisabled(numScans == 0 or numSelected == 0)
            start:SetDisabled(numSelected == 0)
            copyBox:SetText("")
            copyBox:SetDisabled(true)
        end)
        check:SetValue(private.selectedScans[scanID])
        scrollFrame:AddChild(check)
    end
end

function private:GetExportOptions(content)
    content:SetLayout("Fill")

    local guildGroup = AceGUI:Create("DropdownGroup")
    guildGroup:SetLayout("Flow")
    guildGroup:SetGroupList(private:GetGuildList())
    guildGroup:SetCallback("OnGroupSelected", SelectGuild)
    content:AddChild(guildGroup)
    guildGroup:SetGroup(private.selectedExportGuild or private.db.global.settings.preferences.defaultGuild)
    private.frame:SetUserData("guildGroup", guildGroup)
end
