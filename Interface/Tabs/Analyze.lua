local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local AnalyzeTab
local callbacks, forwardCallbacks, info, mods, sidebarSections, tabs
local AnalyzeScans, DrawGoldContent, DrawItemContent, DrawNameContent, DrawSidebar, DrawSidebarGold, DrawSidebarItems, DrawTabs, GetGuildDataTable, GetItemTable, GetNameTable
local dividerString, divider = "....................................................................................................."
local names = {}

function private:InitializeAnalyzeTab()
    AnalyzeTab = {
        guildKey = private.db.global.preferences.defaultGuild,
        guilds = {},
    }
end

callbacks = {
    selectGuild = {
        OnShow = {
            function(self)
                self:SelectByID(AnalyzeTab.guild or AnalyzeTab.guildKey)
            end,
            true,
        },
    },
    container = {
        OnSizeChanged = {
            function(self)
                AnalyzeTab.tabContainer:DoLayout()
            end,
        },
    },
    selectScans = {
        OnShow = {
            function(self)
                self:SetDisabled(#private.db.global.guilds[AnalyzeTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    removeDupes = {
        OnClick = {
            function(self)
                AnalyzeTab.guilds[AnalyzeTab.guildKey].removeDupes = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(AnalyzeTab.guilds[AnalyzeTab.guildKey].removeDupes, true)
            end,
            true,
        },
    },
    analyze = {
        OnClick = {
            function(self)
                if addon:tcount(AnalyzeTab.guilds[AnalyzeTab.guildKey].scans) == 0 then
                    return
                end
                AnalyzeScans()
            end,
        },
    },
    deposit = {
        OnShow = {
            function(self)
                local deposits = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.deposit
                self:SetText(private:GetDoubleLine(L["Deposits"], deposits > 0 and addon:ColorFontString(deposits, "GREEN") or deposits))
            end,
            true,
        },
    },
    topDeposit = {
        OnShow = {
            function(self)
                local topDeposit = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.topDeposit
                self:SetText(topDeposit and format("%s (%s)", topDeposit.name, addon:ColorFontString(topDeposit.quantity, "GREEN")))
            end,
            true,
        },
    },
    withdraw = {
        OnShow = {
            function(self)
                local withdrawals = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.withdraw
                self:SetText(private:GetDoubleLine(L["Withdrawals"], withdrawals > 0 and addon:ColorFontString(withdrawals, "RED") or withdrawals))
            end,
            true,
        },
    },
    topWithdraw = {
        OnShow = {
            function(self)
                local topWithdraw = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.topWithdraw
                self:SetText(topWithdraw and format("%s (%s)", topWithdraw.name, addon:ColorFontString(topWithdraw.quantity, "RED")))
            end,
            true,
        },
    },
    goldTotal = {
        OnShow = {
            function(self)
                self:SetText(private:GetDoubleLine(L["Total Money"], GetCoinTextureString(AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.total)))
            end,
            true,
        },
    },
    goldNet = {
        OnShow = {
            function(self)
                local net = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.net
                local coinString = GetCoinTextureString(abs(net))
                self:SetText(private:GetDoubleLine(L["Net Gold"], net == 0 and coinString or addon:ColorFontString(coinString, net < 0 and "RED" or net > 0 and "GREEN")))
            end,
            true,
        },
    },
    goldDeposit = {
        OnShow = {
            function(self)
                local deposits = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.deposit
                self:SetText(private:GetDoubleLine(L["Deposits"], deposits > 0 and addon:ColorFontString(GetCoinTextureString(deposits), "GREEN") or GetCoinTextureString(deposits)))
            end,
            true,
        },
    },
    goldDepositSummary = {
        OnShow = {
            function(self)
                local depositSummary = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.depositSummary
                self:SetText(private:GetDoubleLine(L["Deposit Summary"], depositSummary > 0 and addon:ColorFontString(GetCoinTextureString(depositSummary), "GREEN") or GetCoinTextureString(depositSummary)))
            end,
            true,
        },
    },
    goldTopDeposit = {
        OnShow = {
            function(self)
                local topDeposit = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.topDeposit
                self:SetText(topDeposit and format("%s (%s)", topDeposit.name, addon:ColorFontString(GetCoinTextureString(topDeposit.quantity), "GREEN")))
            end,
            true,
        },
    },
    goldRepair = {
        OnShow = {
            function(self)
                local repairs = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.repair
                self:SetText(private:GetDoubleLine(L["Repairs"], repairs > 0 and addon:ColorFontString(GetCoinTextureString(repairs), "RED") or GetCoinTextureString(repairs)))
            end,
            true,
        },
    },
    goldWithdraw = {
        OnShow = {
            function(self)
                local withdrawals = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.withdraw
                self:SetText(private:GetDoubleLine(L["Withdrawals"], withdrawals > 0 and addon:ColorFontString(GetCoinTextureString(withdrawals), "RED") or GetCoinTextureString(withdrawals)))
            end,
            true,
        },
    },
    goldTopWithdraw = {
        OnShow = {
            function(self)
                local topWithdraw = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.topWithdraw
                self:SetText(topWithdraw and format("%s (%s)", topWithdraw.name, addon:ColorFontString(GetCoinTextureString(topWithdraw.quantity), "RED")))
            end,
            true,
        },
    },
    goldBuyTab = {
        OnShow = {
            function(self)
                local buyTab = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.buyTab
                self:SetText(private:GetDoubleLine(L["Buy Tab"], buyTab > 0 and addon:ColorFontString(buyTab, "GREEN") or GetCoinTextureString(buyTab)))
            end,
            true,
        },
    },
    goldWithdrawForTab = {
        OnShow = {
            function(self)
                local withdrawForTab = AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.withdrawForTab
                self:SetText(private:GetDoubleLine(L["Withdraw For Tab"], withdrawForTab > 0 and addon:ColorFontString(withdrawForTab, "RED") or GetCoinTextureString(withdrawForTab)))
            end,
            true,
        },
    },
    tab = {
        OnClick = {
            function(self)
                local tabID = self:GetTabID()
                AnalyzeTab.guilds[AnalyzeTab.guildKey].selectedTab = tabID
                tabs[tabID].onClick(self)
            end,
        },
    },
}

forwardCallbacks = {
    selectScans = {
        OnClear = {
            function(self)
                wipe(AnalyzeTab.guilds[AnalyzeTab.guildKey].scans)
                AnalyzeTab.guilds[AnalyzeTab.guildKey].data = GetGuildDataTable()
                DrawSidebar()
            end,
        },
        OnInfoSet = {
            function(self)
                for scanID, _ in pairs(AnalyzeTab.guilds[AnalyzeTab.guildKey].scans) do
                    self:SelectByID(scanID, true, true)
                end
            end,
        },
    },
}

info = {
    selectGuild = function()
        local info = {}

        private:IterateGuilds(function(guildKey, guildName, guild)
            tinsert(info, {
                id = guildKey,
                text = guildName,
                func = function(dropdown, info)
                    AnalyzeTab.guildKey = guildKey
                    AnalyzeTab.guilds[guildKey] = AnalyzeTab.guilds[guildKey] or {
                        -- selectedTab = 1,-- TODO
                        selectedTab = 3,
                        removeDupes = true,
                        scans = {},
                        data = GetGuildDataTable(),
                    }
                    DrawSidebar()
                end,
            })
        end)

        return info
    end,
    selectScans = function()
        local info = {}

        for scanID, _ in addon:pairs(private.db.global.guilds[AnalyzeTab.guildKey].scans, private.sortDesc) do
            tinsert(info, {
                id = scanID,
                text = date(private.db.global.preferences.dateFormat, scanID),
                func = function(dropdown, info)
                    AnalyzeTab.guilds[AnalyzeTab.guildKey].scans[info.id] = dropdown:GetSelected(info.id) and true or nil
                end,
            })
        end

        return info
    end,
}

mods = {
    buyTab = 1,
    deposit = 1,
    depositSummary = 1,
    repair = -1,
    withdraw = -1,
    withdrawForTab = -1,
}

sidebarSections = {
    {
        header = L["Items"],
        collapsed = false,
        onLoad = function(...)
            return DrawSidebarItems(...)
        end,
    },
    {
        header = L["Gold"],
        collapsed = false,
        onLoad = function(...)
            return DrawSidebarGold(...)
        end,
    },
}

tabs = {
    {
        header = L["Item"],
        onClick = function()
            local tabContent = AnalyzeTab.tabContent
            local content = tabContent.content
            content:ReleaseAll()
            DrawItemContent(content)
            content:MarkDirty()
            tabContent.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
        end,
    },
    {
        header = L["Name"],
        onClick = function()
            local tabContent = AnalyzeTab.tabContent
            local content = tabContent.content
            content:ReleaseAll()
            DrawNameContent(content)
            content:MarkDirty()
            tabContent.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
        end,
    },
    {
        header = L["Gold"],
        onClick = function()
            local tabContent = AnalyzeTab.tabContent
            local content = tabContent.content
            content:ReleaseAll()
            DrawGoldContent(content)
            content:MarkDirty()
            tabContent.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
        end,
    },
}

AnalyzeScans = function(skipDrawSidebar)
    if not AnalyzeTab.guildKey then
        return
    end

    local analyzeInfo = AnalyzeTab.guilds[AnalyzeTab.guildKey]
    local guildInfo = private.db.global.guilds[AnalyzeTab.guildKey]
    analyzeInfo.data = GetGuildDataTable()

    -- Get current gold total
    for scanID, selected in addon:pairs(analyzeInfo.scans, private.sortDesc) do
        if selected then
            local totalMoney = guildInfo.scans[scanID].totalMoney
            if analyzeInfo.data.gold.total == 0 then
                analyzeInfo.data.gold.total = totalMoney
            end
            tinsert(analyzeInfo.data.gold.totals, {
                scanID,
                totalMoney,
            })
            analyzeInfo.data.minX = analyzeInfo.data.minX and min(analyzeInfo.data.minX, scanID) or scanID
            analyzeInfo.data.maxX = analyzeInfo.data.maxX and max(analyzeInfo.data.maxX, scanID) or scanID
            analyzeInfo.data.maxY = analyzeInfo.data.maxY and max(analyzeInfo.data.maxY, totalMoney) or totalMoney
        end
    end

    for transactionID, transaction in addon:pairs(guildInfo.masterScan, private.sortDesc) do
        -- scanID is selected, name is not filtered out, transaction type isn't move (who cares about this in analyze?), transaction is not a dupe or dupes are allowed
        if analyzeInfo.scans[transaction.scanID] and not guildInfo.settings.bankers[transaction.name] and transaction.transactionType ~= "move" and (not analyzeInfo.removeDupes or not transaction.isDupe) then
            -- Initialize name table for specific player
            analyzeInfo.data.names[transaction.name] = analyzeInfo.data.names[transaction.name] or GetNameTable()

            if transaction.tabID == private.moneyTab then
                -- Update running total for gold
                analyzeInfo.data.gold.net = analyzeInfo.data.gold.net + (mods[transaction.transactionType] * transaction.amount)
                -- Update running total for transaction type
                analyzeInfo.data.gold[transaction.transactionType] = analyzeInfo.data.gold[transaction.transactionType] + transaction.amount
                -- Add transaction to transactions table
                analyzeInfo.data.gold[transaction.transactionType .. "s"][transactionID] = addon:CloneTable(transaction)

                -- Update running total for transaction type for specific player
                -- e.g. analyzeInfo.data.names.Nikketa.gold.withdraw = 10
                analyzeInfo.data.names[transaction.name].gold[transaction.transactionType] = analyzeInfo.data.names[transaction.name].gold[transaction.transactionType] + transaction.amount
                -- Add transaction to transactions table for specific player
                -- e.g. analyzeInfo.data.names.Nikketa.gold.withdraws[1] = { ... }
                analyzeInfo.data.names[transaction.name].gold[transaction.transactionType .. "s"][transactionID] = addon:CloneTable(transaction)
            else
                -- Update running total for transaction type
                analyzeInfo.data[transaction.transactionType] = analyzeInfo.data[transaction.transactionType] + transaction.count

                -- Initialize item table for itemLink
                analyzeInfo.data.items[transaction.itemLink] = analyzeInfo.data.items[transaction.itemLink] or GetItemTable()
                -- Update running total for transaction type for specific item
                -- e.g. analyzeInfo.data.items["Phial of Versatility"].withdraw = 10
                analyzeInfo.data.items[transaction.itemLink][transaction.transactionType] = analyzeInfo.data.items[transaction.itemLink][transaction.transactionType] + transaction.count
                -- Add transaction to transactions table for specific item
                -- e.g. analyzeInfo.data.items["Phial of Versatility"].withdraws[1] = { ... }
                analyzeInfo.data.items[transaction.itemLink][transaction.transactionType .. "s"][transactionID] = addon:CloneTable(transaction)

                -- Update running total for transaction type for specific player
                -- e.g. analyzeInfo.data.names.Nikketa.withdraw = 10
                analyzeInfo.data.names[transaction.name][transaction.transactionType] = analyzeInfo.data.names[transaction.name][transaction.transactionType] + transaction.count
                -- Add transaction to transactions table for specific player
                -- e.g. analyzeInfo.data.names.Nikketa.withdraws[1] = { ... }
                analyzeInfo.data.names[transaction.name][transaction.transactionType .. "s"][transactionID] = addon:CloneTable(transaction)
            end
        end
    end

    -- Get top depositers/withdrawers
    for name, info in pairs(analyzeInfo.data.names) do
        -- Set top deposit
        if (not analyzeInfo.data.topDeposit or info.deposit > analyzeInfo.data.topDeposit.quantity) and info.deposit > 0 then
            analyzeInfo.data.topDeposit = { name = name, quantity = info.deposit }
        end
        -- Set top withdraw
        if (not analyzeInfo.data.topWithdraw or info.withdraw > analyzeInfo.data.topWithdraw.quantity) and info.withdraw > 0 then
            analyzeInfo.data.topWithdraw = { name = name, quantity = info.withdraw }
        end

        local goldDeposits = info.gold.buyTab + info.gold.deposit
        local goldWithdrawals = info.gold.repair + info.gold.withdraw + info.gold.withdrawForTab

        -- Update running total for gold for specific player
        analyzeInfo.data.names[name].net = goldDeposits - goldWithdrawals

        -- Set top gold deposit
        if (not analyzeInfo.data.gold.topDeposit or goldDeposits > analyzeInfo.data.gold.topDeposit.quantity) and goldDeposits > 0 then
            analyzeInfo.data.gold.topDeposit = { name = name, quantity = goldDeposits }
        end

        -- Set top gold withdraw
        if (not analyzeInfo.data.gold.topWithdraw or goldWithdrawals > analyzeInfo.data.gold.topWithdraw.quantity) and goldWithdrawals > 0 then
            analyzeInfo.data.gold.topWithdraw = { name = name, quantity = goldWithdrawals }
        end
    end

    if not skipDrawSidebar then
        DrawSidebar()
    end
end

DrawGoldContent = function(content)
    local height = 0
end

DrawItemContent = function(content)
    local height = 0
end

DrawNameContent = function(content)
    local height = 0
end

DrawSidebar = function()
    local sidebar = AnalyzeTab.sidebar
    local content = sidebar.content
    content:ReleaseAll()

    if not AnalyzeTab.guildKey then
        return
    end

    local height = 0

    local analyze = content:Acquire("GuildBankSnapshotsButton")
    analyze:SetPoint("TOPLEFT", 5, -height)
    analyze:SetPoint("RIGHT", -5, 0)
    analyze:SetText(L["Analyze"])
    analyze:SetTooltipInitializer(L["Changes will not be calculated until analyze is re-run"])
    analyze:SetCallbacks(callbacks.analyze)
    height = height + analyze:GetHeight() + 5

    local selectScans = content:Acquire("GuildBankSnapshotsDropdownFrame")
    selectScans:SetPoint("TOPLEFT", 5, -height)
    selectScans:SetPoint("RIGHT", -5, 0)
    selectScans:SetLabel(L["Select Scans"])
    selectScans:SetLabelFont(nil, private:GetInterfaceFlairColor())
    selectScans:Justify("LEFT")
    selectScans:SetStyle({ multiSelect = true, hasClear = true, hasSelectAll = true }) -- TODO select all
    selectScans:SetCallbacks(callbacks.selectScans)
    selectScans:ForwardCallbacks(forwardCallbacks.selectScans)
    selectScans:SetInfo(info.selectScans)
    height = height + selectScans:GetHeight() + 5

    local removeDupes = content:Acquire("GuildBankSnapshotsCheckButton")
    removeDupes:SetPoint("TOPLEFT", 5, -height)
    removeDupes:SetPoint("RIGHT", -5, 0)
    removeDupes:SetText(L["Remove duplicates"] .. "*")
    removeDupes:SetTooltipInitializer(L["Experimental"])
    removeDupes:SetCallbacks(callbacks.removeDupes)
    height = height + removeDupes:GetHeight() + 10

    if addon:tcount(AnalyzeTab.guilds[AnalyzeTab.guildKey].scans) == 0 then
        content:MarkDirty()
        sidebar.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)

        DrawTabs()
        return
    end

    for sectionID, info in addon:pairs(sidebarSections) do
        local header = content:Acquire("GuildBankSnapshotsButton")
        header:SetHeight(20)
        header:SetText(info.header)
        header:SetBackdropColor(private.interface.colors[private:UseClassColor() and "lightClass" or "lightFlair"], private.interface.colors.light)
        header:SetTextColor(private.interface.colors.white:GetRGBA())
        header:SetPoint("TOPLEFT", 0, -height)
        header:SetPoint("RIGHT", 0, 0)
        header:SetCallback("OnClick", function()
            local isCollapsed = info.collapsed
            if isCollapsed then
                sidebarSections[sectionID].collapsed = false
            else
                sidebarSections[sectionID].collapsed = true
            end

            DrawSidebar()
        end)
        height = height + header:GetHeight() + 5

        if not info.collapsed then
            height = info.onLoad(content, height) + 5
        end
    end

    content:MarkDirty()
    sidebar.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)

    DrawTabs()
end

DrawSidebarGold = function(content, height)
    local goldTotal = content:Acquire("GuildBankSnapshotsFontFrame")
    goldTotal:SetPoint("TOPLEFT", 5, -height)
    goldTotal:SetPoint("RIGHT", -5, 0)
    goldTotal:Justify("LEFT")
    goldTotal:SetCallbacks(callbacks.goldTotal)
    height = height + goldTotal:GetHeight()

    local goldNet = content:Acquire("GuildBankSnapshotsFontFrame")
    goldNet:SetPoint("TOPLEFT", 5, -height)
    goldNet:SetPoint("RIGHT", -5, 0)
    goldNet:Justify("LEFT")
    goldNet:SetCallbacks(callbacks.goldNet)
    height = height + goldNet:GetHeight()

    --.....................
    divider = content:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetPoint("TOPLEFT", 5, -height)
    divider:SetPoint("RIGHT", -5, 0)
    divider:SetHeight(5)
    divider:SetText(dividerString)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())
    divider:DisableTooltip(true)
    height = height + divider:GetHeight() + 5
    --.....................

    local goldDeposit = content:Acquire("GuildBankSnapshotsFontFrame")
    goldDeposit:SetPoint("TOPLEFT", 5, -height)
    goldDeposit:SetPoint("RIGHT", -5, 0)
    goldDeposit:Justify("LEFT")
    goldDeposit:SetCallbacks(callbacks.goldDeposit)
    height = height + goldDeposit:GetHeight()

    local goldDepositSummary = content:Acquire("GuildBankSnapshotsFontFrame")
    goldDepositSummary:SetPoint("TOPLEFT", 5, -height)
    goldDepositSummary:SetPoint("RIGHT", -5, 0)
    goldDepositSummary:Justify("LEFT")
    goldDepositSummary:SetCallbacks(callbacks.goldDepositSummary)
    height = height + goldDepositSummary:GetHeight()

    if AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.topDeposit then
        local goldTopDeposit = content:Acquire("GuildBankSnapshotsFontLabelFrame")
        goldTopDeposit:SetPoint("TOPLEFT", 5, -height)
        goldTopDeposit:SetPoint("RIGHT", -5, 0)
        goldTopDeposit:Justify("LEFT")
        goldTopDeposit:SetLabel(L["All-Star"] .. ":")
        goldTopDeposit:SetLabelFont(nil, private:GetInterfaceFlairColor())
        goldTopDeposit:SetCallbacks(callbacks.goldTopDeposit)
        height = height + goldTopDeposit:GetHeight()
    end

    --.....................
    divider = content:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetPoint("TOPLEFT", 5, -height)
    divider:SetPoint("RIGHT", -5, 0)
    divider:SetHeight(5)
    divider:SetText(dividerString)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())
    divider:DisableTooltip(true)
    height = height + divider:GetHeight() + 5
    --.....................

    local goldRepair = content:Acquire("GuildBankSnapshotsFontFrame")
    goldRepair:SetPoint("TOPLEFT", 5, -height)
    goldRepair:SetPoint("RIGHT", -5, 0)
    goldRepair:Justify("LEFT")
    goldRepair:SetCallbacks(callbacks.goldRepair)
    height = height + goldRepair:GetHeight()

    local goldWithdraw = content:Acquire("GuildBankSnapshotsFontFrame")
    goldWithdraw:SetPoint("TOPLEFT", 5, -height)
    goldWithdraw:SetPoint("RIGHT", -5, 0)
    goldWithdraw:Justify("LEFT")
    goldWithdraw:SetCallbacks(callbacks.goldWithdraw)
    height = height + goldWithdraw:GetHeight()

    if AnalyzeTab.guilds[AnalyzeTab.guildKey].data.gold.topWithdraw then
        local goldTopWithdraw = content:Acquire("GuildBankSnapshotsFontLabelFrame")
        goldTopWithdraw:SetPoint("TOPLEFT", 5, -height)
        goldTopWithdraw:SetPoint("RIGHT", -5, 0)
        goldTopWithdraw:Justify("LEFT")
        goldTopWithdraw:SetLabel(L["All-Star"] .. ":")
        goldTopWithdraw:SetLabelFont(nil, private:GetInterfaceFlairColor())
        goldTopWithdraw:SetCallbacks(callbacks.goldTopWithdraw)
        height = height + goldTopWithdraw:GetHeight()
    end

    --.....................
    divider = content:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetPoint("TOPLEFT", 5, -height)
    divider:SetPoint("RIGHT", -5, 0)
    divider:SetHeight(5)
    divider:SetText(dividerString)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())
    divider:DisableTooltip(true)
    height = height + divider:GetHeight() + 5
    --.....................

    local goldBuyTab = content:Acquire("GuildBankSnapshotsFontFrame")
    goldBuyTab:SetPoint("TOPLEFT", 5, -height)
    goldBuyTab:SetPoint("RIGHT", -5, 0)
    goldBuyTab:Justify("LEFT")
    goldBuyTab:SetCallbacks(callbacks.goldBuyTab)
    height = height + goldBuyTab:GetHeight()

    local goldWithdrawForTab = content:Acquire("GuildBankSnapshotsFontFrame")
    goldWithdrawForTab:SetPoint("TOPLEFT", 5, -height)
    goldWithdrawForTab:SetPoint("RIGHT", -5, 0)
    goldWithdrawForTab:Justify("LEFT")
    goldWithdrawForTab:SetCallbacks(callbacks.goldWithdrawForTab)
    height = height + goldWithdrawForTab:GetHeight()

    return height
end

DrawSidebarItems = function(content, height)
    local deposit = content:Acquire("GuildBankSnapshotsFontFrame")
    deposit:SetPoint("TOPLEFT", 5, -height)
    deposit:SetPoint("RIGHT", -5, 0)
    deposit:Justify("LEFT")
    deposit:SetCallbacks(callbacks.deposit)
    height = height + deposit:GetHeight()

    if AnalyzeTab.guilds[AnalyzeTab.guildKey].data.topDeposit then
        local topDeposit = content:Acquire("GuildBankSnapshotsFontLabelFrame")
        topDeposit:SetPoint("TOPLEFT", 5, -height)
        topDeposit:SetPoint("RIGHT", -5, 0)
        topDeposit:Justify("LEFT")
        topDeposit:SetLabel(L["All-Star"] .. ":")
        topDeposit:SetLabelFont(nil, private:GetInterfaceFlairColor())
        topDeposit:SetCallbacks(callbacks.topDeposit)
        height = height + topDeposit:GetHeight()
    end

    --.....................
    divider = content:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetPoint("TOPLEFT", 5, -height)
    divider:SetPoint("RIGHT", -5, 0)
    divider:SetHeight(5)
    divider:SetText(dividerString)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())
    divider:DisableTooltip(true)
    height = height + divider:GetHeight() + 5
    --.....................

    local withdraw = content:Acquire("GuildBankSnapshotsFontFrame")
    withdraw:SetPoint("TOPLEFT", 5, -height)
    withdraw:SetPoint("RIGHT", -5, 0)
    withdraw:Justify("LEFT")
    withdraw:SetCallbacks(callbacks.withdraw)
    height = height + withdraw:GetHeight()

    if AnalyzeTab.guilds[AnalyzeTab.guildKey].data.topWithdraw then
        local topWithdraw = content:Acquire("GuildBankSnapshotsFontLabelFrame")
        topWithdraw:SetPoint("TOPLEFT", 5, -height)
        topWithdraw:SetPoint("RIGHT", -5, 0)
        topWithdraw:Justify("LEFT")
        topWithdraw:SetLabel(L["All-Star"] .. ":")
        topWithdraw:SetLabelFont(nil, private:GetInterfaceFlairColor())
        topWithdraw:SetCallbacks(callbacks.topWithdraw)
        height = height + topWithdraw:GetHeight()
    end

    return height
end

DrawTabs = function()
    local tabContainer = AnalyzeTab.tabContainer
    tabContainer:ReleaseChildren()

    if not AnalyzeTab.guildKey or addon:tcount(AnalyzeTab.guilds[AnalyzeTab.guildKey].scans) == 0 then
        return
    end

    for tabID, info in addon:pairs(tabs) do
        local tab = tabContainer:Acquire("GuildBankSnapshotsTabButton")
        tab:SetTab(tabContainer, tabID, info)
        tab:SetCallbacks(callbacks.tab)
        if tabID == AnalyzeTab.guilds[AnalyzeTab.guildKey].selectedTab then
            tab:Fire("OnClick")
        end
        tabContainer:AddChild(tab)
    end
    tabContainer:DoLayout()
end

GetGuildDataTable = function()
    return {
        deposit = 0,
        topDeposit = false,
        topWithdraw = false,
        withdraw = 0,

        gold = {
            net = 0,
            topDeposit = false,
            topWithdraw = false,
            total = 0,

            buyTab = 0,
            deposit = 0,
            depositSummary = 0,
            repair = 0,
            withdraw = 0,
            withdrawForTab = 0,

            buyTabs = {},
            deposits = {},
            depositSummarys = {},
            repairs = {},
            withdrawForTabs = {},
            withdraws = {},

            totals = {},
        },
        items = {},
        names = {},
    }
end

GetItemTable = function()
    return {
        deposit = 0,
        withdraw = 0,

        deposits = {},
        withdraws = {},
    }
end

GetNameTable = function()
    return {
        deposit = 0,
        withdraw = 0,

        deposits = {},
        gold = {
            net = 0,

            buyTab = 0,
            deposit = 0,
            depositSummary = 0,
            repair = 0,
            withdraw = 0,
            withdrawForTab = 0,

            buyTabs = {},
            deposits = {},
            depositSummarys = {},
            repairs = {},
            withdrawForTabs = {},
            withdraws = {},
        },
        withdraws = {},
    }
end

function private:LoadAnalyzeTab(content, guildKey)
    AnalyzeTab.guild = guildKey

    local selectGuild = content:Acquire("GuildBankSnapshotsDropdownButton")
    selectGuild:SetPoint("TOPLEFT", 10, -10)
    selectGuild:SetSize(250, 20)
    selectGuild:SetDefaultText(L["Select a guild"])
    selectGuild:SetBackdropColor(private.interface.colors.darker)
    selectGuild:SetInfo(info.selectGuild)
    AnalyzeTab.selectGuild = selectGuild

    local sidebar = content:Acquire("GuildBankSnapshotsScrollFrame")
    sidebar.bg, sidebar.border = private:AddBackdrop(sidebar, { bgColor = "darker" })
    sidebar:SetWidth(selectGuild:GetWidth())
    sidebar:SetPoint("TOPLEFT", selectGuild, "BOTTOMLEFT")
    sidebar:SetPoint("BOTTOM", 0, 10)
    AnalyzeTab.sidebar = sidebar

    local container = content:Acquire("GuildBankSnapshotsContainer")
    container.bg, container.border = private:AddBackdrop(container, { bgColor = "darker" })
    container:SetPoint("TOPLEFT", selectGuild, "TOPRIGHT")
    container:SetPoint("BOTTOMRIGHT", -10, 10)
    container:SetCallbacks(callbacks.container)
    AnalyzeTab.container = container

    local tabContainer = container:Acquire("GuildBankSnapshotsGroup")
    tabContainer:SetHeight(20)
    tabContainer:SetPoint("TOPLEFT")
    tabContainer:SetPoint("RIGHT")
    tabContainer:SetReverse(true)
    AnalyzeTab.tabContainer = tabContainer

    local tabContent = container:Acquire("GuildBankSnapshotsScrollFrame")
    tabContent:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT")
    tabContent:SetPoint("BOTTOMRIGHT")
    tabContent.bg, tabContent.border = private:AddBackdrop(tabContent, { bgColor = "dark" })
    AnalyzeTab.tabContent = tabContent

    selectGuild:SetCallbacks(callbacks.selectGuild)
end
