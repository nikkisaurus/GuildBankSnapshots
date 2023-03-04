local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*----------[[ Initialize tab ]]----------*--
local AnalyzeTab
local callbacks, forwardCallbacks, info, mods, sidebarSections, tabs
local AnalyzeScans, DrawGoldContent, DrawGraphContent, DrawItemContent, DrawNameContent, DrawSidebar, DrawSidebarGold, DrawSidebarItems, DrawTabs, GetGuildDataTable, GetItemTable, GetNameTable, GetSelectedGuild
local divider

function private:InitializeAnalyzeTab()
    AnalyzeTab = {
        guildKey = private.db.global.preferences.defaultGuild,
        guilds = {},
    }
end

--*----------[[ Data ]]----------*--
callbacks = {
    selectGuild = {
        OnShow = {
            function(self)
                self:SelectByID(AnalyzeTab.guild or AnalyzeTab.guildKey)
                AnalyzeTab.guild = nil
            end,
            true,
        },
    },
    analyze = {
        OnClick = {
            function(self)
                if addon:tcount(GetSelectedGuild().scans) == 0 then
                    return
                end
                AnalyzeScans()
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
                GetSelectedGuild().removeDupes = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(GetSelectedGuild().removeDupes, true)
            end,
            true,
        },
    },
    sectionHeader = {
        OnClick = {
            function(self)
                local info = self:GetUserData("info")
                local sectionID = self:GetUserData("sectionID")
                if info.collapsed then
                    sidebarSections[sectionID].collapsed = false
                else
                    sidebarSections[sectionID].collapsed = true
                end

                DrawSidebar(true)
            end,
        },
    },
    deposit = {
        OnShow = {
            function(self)
                local deposits = GetSelectedGuild().data.deposit
                self:SetText(private:GetDoubleLine(L["Deposits"], deposits > 0 and addon:ColorFontString(deposits, "GREEN") or deposits))
            end,
            true,
        },
    },
    topDeposit = {
        OnShow = {
            function(self)
                local topDeposit = GetSelectedGuild().data.topDeposit
                self:SetText(topDeposit and format("%s (%s)", topDeposit.name, addon:ColorFontString(topDeposit.quantity, "GREEN")))
            end,
            true,
        },
    },
    withdraw = {
        OnShow = {
            function(self)
                local withdrawals = GetSelectedGuild().data.withdraw
                self:SetText(private:GetDoubleLine(L["Withdrawals"], withdrawals > 0 and addon:ColorFontString(withdrawals, "RED") or withdrawals))
            end,
            true,
        },
    },
    topWithdraw = {
        OnShow = {
            function(self)
                local topWithdraw = GetSelectedGuild().data.topWithdraw
                self:SetText(topWithdraw and format("%s (%s)", topWithdraw.name, addon:ColorFontString(topWithdraw.quantity, "RED")))
            end,
            true,
        },
    },
    goldTotal = {
        OnShow = {
            function(self)
                self:SetText(private:GetDoubleLine(L["Total Money"], GetCoinTextureString(GetSelectedGuild().data.gold.total)))
            end,
            true,
        },
    },
    goldNet = {
        OnShow = {
            function(self)
                local net = GetSelectedGuild().data.gold.net
                local coinString = GetCoinTextureString(abs(net))
                self:SetText(private:GetDoubleLine(L["Net Gold"], net == 0 and coinString or addon:ColorFontString(coinString, net < 0 and "RED" or net > 0 and "GREEN")))
            end,
            true,
        },
    },
    goldDeposit = {
        OnShow = {
            function(self)
                local deposits = GetSelectedGuild().data.gold.deposit
                self:SetText(private:GetDoubleLine(L["Deposits"], deposits > 0 and addon:ColorFontString(GetCoinTextureString(deposits), "GREEN") or GetCoinTextureString(deposits)))
            end,
            true,
        },
    },
    goldDepositSummary = {
        OnShow = {
            function(self)
                local depositSummary = GetSelectedGuild().data.gold.depositSummary
                self:SetText(private:GetDoubleLine(L["Deposit Summary"], depositSummary > 0 and addon:ColorFontString(GetCoinTextureString(depositSummary), "GREEN") or GetCoinTextureString(depositSummary)))
            end,
            true,
        },
    },
    goldTopDeposit = {
        OnShow = {
            function(self)
                local topDeposit = GetSelectedGuild().data.gold.topDeposit
                self:SetText(topDeposit and format("%s (%s)", topDeposit.name, addon:ColorFontString(GetCoinTextureString(topDeposit.quantity), "GREEN")))
            end,
            true,
        },
    },
    goldRepair = {
        OnShow = {
            function(self)
                local repairs = GetSelectedGuild().data.gold.repair
                self:SetText(private:GetDoubleLine(L["Repairs"], repairs > 0 and addon:ColorFontString(GetCoinTextureString(repairs), "RED") or GetCoinTextureString(repairs)))
            end,
            true,
        },
    },
    goldWithdraw = {
        OnShow = {
            function(self)
                local withdrawals = GetSelectedGuild().data.gold.withdraw
                self:SetText(private:GetDoubleLine(L["Withdrawals"], withdrawals > 0 and addon:ColorFontString(GetCoinTextureString(withdrawals), "RED") or GetCoinTextureString(withdrawals)))
            end,
            true,
        },
    },
    goldTopWithdraw = {
        OnShow = {
            function(self)
                local topWithdraw = GetSelectedGuild().data.gold.topWithdraw
                self:SetText(topWithdraw and format("%s (%s)", topWithdraw.name, addon:ColorFontString(GetCoinTextureString(topWithdraw.quantity), "RED")))
            end,
            true,
        },
    },
    goldBuyTab = {
        OnShow = {
            function(self)
                local buyTab = GetSelectedGuild().data.gold.buyTab
                self:SetText(private:GetDoubleLine(L["Buy Tab"], buyTab > 0 and addon:ColorFontString(buyTab, "GREEN") or GetCoinTextureString(buyTab)))
            end,
            true,
        },
    },
    goldWithdrawForTab = {
        OnShow = {
            function(self)
                local withdrawForTab = GetSelectedGuild().data.gold.withdrawForTab
                self:SetText(private:GetDoubleLine(L["Withdraw For Tab"], withdrawForTab > 0 and addon:ColorFontString(withdrawForTab, "RED") or GetCoinTextureString(withdrawForTab)))
            end,
            true,
        },
    },
    tab = {
        OnClick = {
            function(self)
                local tabID = self:GetTabID()
                GetSelectedGuild().selectedTab = tabID

                local tabContent = AnalyzeTab.content
                tabContent:ReleaseChildren()
                tabs[tabID].onClick(tabContent)
            end,
        },
    },
    goldDepositPie = {
        OnShow = {
            function(self)
                local data = GetSelectedGuild().data
                local buyTab = (data.gold.buyTab / data.gold.totalDeposit) * 100
                local deposit = (data.gold.deposit / data.gold.totalDeposit) * 100
                local depositSummary = (data.gold.depositSummary / data.gold.totalDeposit) * 100

                if buyTab == 100 then
                    self:CompletePie(L["Buy Tab"], { 0, 0.5, 0, 1 })
                elseif buyTab > 0 then
                    self:AddPie(L["Buy Tab"], buyTab, { 0, 0.5, 0, 1 })
                end

                if deposit == 100 then
                    self:CompletePie(L["Deposit"], { 0, 0.75, 0, 1 })
                elseif deposit > 0 then
                    self:AddPie(L["Deposit"], deposit, { 0, 0.75, 0, 1 })
                end

                if depositSummary == 100 then
                    self:CompletePie(L["Deposit Summary"], { 0, 1, 0, 1 })
                elseif depositSummary > 0 then
                    self:AddPie(L["Deposit Summary"], depositSummary, { 0, 1, 0, 1 })
                end
            end,
            true,
        },
    },
    goldWithdrawPie = {
        OnShow = {
            function(self)
                local data = GetSelectedGuild().data
                local repair = (data.gold.repair / data.gold.totalWithdraw) * 100
                local withdraw = (data.gold.withdraw / data.gold.totalWithdraw) * 100
                local withdrawForTab = (data.gold.withdrawForTab / data.gold.totalWithdraw) * 100

                if repair == 100 then
                    self:CompletePie(L["Repair"], { 0.5, 0, 0, 1 })
                elseif repair > 0 then
                    self:AddPie(L["Repair"], repair, { 0.5, 0, 0, 1 })
                end

                if withdraw == 100 then
                    self:CompletePie(L["Withdraw"], { 0.75, 0, 0, 1 })
                elseif withdraw > 0 then
                    self:AddPie(L["Withdraw"], withdraw, { 0.75, 0, 0, 1 })
                end

                if withdrawForTab == 100 then
                    self:CompletePie(L["Withdraw For Tab"], { 1, 0, 0, 1 })
                elseif withdrawForTab > 0 then
                    self:AddPie(L["Withdraw For Tab"], withdrawForTab, { 1, 0, 0, 1 })
                end
            end,
            true,
        },
    },
}

------------------------

forwardCallbacks = {
    selectScans = {
        OnClear = {
            function(self)
                wipe(GetSelectedGuild().scans)
                GetSelectedGuild().data = GetGuildDataTable()
                DrawSidebar()
            end,
        },
        OnInfoSet = {
            function(self)
                if AnalyzeTab.scanID then
                    GetSelectedGuild().scans[AnalyzeTab.scanID] = true
                    AnalyzeTab.scanID = nil
                    AnalyzeScans()
                else
                    for scanID, _ in pairs(GetSelectedGuild().scans) do
                        self:SelectByID(scanID, true, true)
                    end
                end
            end,
        },
        OnMenuClosed = {
            function(self)
                AnalyzeScans(true)
            end,
        },
        OnSelectAll = {
            function(self)
                for _, info in pairs(self:GetInfo()) do
                    GetSelectedGuild().scans[info.id] = true
                end
                AnalyzeScans()
            end,
        },
    },
}

------------------------

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
                    GetSelectedGuild().scans[info.id] = dropdown:GetSelected(info.id) and true or nil
                end,
            })
        end

        return info
    end,
}

------------------------

mods = {
    buyTab = 1,
    deposit = 1,
    depositSummary = 1,
    repair = -1,
    withdraw = -1,
    withdrawForTab = -1,
}

------------------------

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

------------------------

tabs = {
    {
        header = L["Item"],
        onClick = function(tabContent)
            DrawItemContent(tabContent)
        end,
    },
    {
        header = L["Name"],
        onClick = function(tabContent)
            DrawNameContent(tabContent)
        end,
    },
    {
        header = L["Gold"],
        onClick = function(tabContent)
            DrawGoldContent(tabContent)
        end,
    },
    {
        header = L["Graphs"],
        onClick = function(tabContent)
            DrawGraphContent(tabContent)
        end,
    },
}

--*----------[[ Methods ]]----------*--
AnalyzeScans = function(skipDrawSidebar)
    if not AnalyzeTab.guildKey then
        return
    end

    local analyzeInfo = GetSelectedGuild()
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

    analyzeInfo.data.gold.totalDeposit = analyzeInfo.data.gold.deposit + analyzeInfo.data.gold.depositSummary + analyzeInfo.data.gold.buyTab
    analyzeInfo.data.gold.totalWithdraw = analyzeInfo.data.gold.repair + analyzeInfo.data.gold.withdraw + analyzeInfo.data.gold.withdrawForTab

    if not skipDrawSidebar then
        DrawSidebar()
    end
end

------------------------

DrawGoldContent = function(content)
    content:DoLayout()
end

------------------------

DrawGraphContent = function(content)
    local data = GetSelectedGuild().data

    if data.gold.totalDeposit > 0 then
        local goldDepositPie = content:AcquireElement("GuildBankSnapshotsPieGraph")
        goldDepositPie:SetLabel(L["Gold Deposits"])
        goldDepositPie:SetLabelFont(nil, private:GetInterfaceFlairColor())
        goldDepositPie:SetCallbacks(callbacks.goldDepositPie)
        content:AddChild(goldDepositPie)
    end

    if data.gold.totalWithdraw > 0 then
        local goldWithdrawPie = content:AcquireElement("GuildBankSnapshotsPieGraph")
        goldWithdrawPie:SetLabel(L["Gold Withdrawals"])
        goldWithdrawPie:SetLabelFont(nil, private:GetInterfaceFlairColor())
        goldWithdrawPie:SetCallbacks(callbacks.goldWithdrawPie)
        content:AddChild(goldWithdrawPie)
    end

    content:DoLayout()
end

------------------------

DrawItemContent = function(content)
    content:DoLayout()
end

------------------------

DrawNameContent = function(content)
    content:DoLayout()
end

------------------------

DrawSidebar = function(skipDrawTabs)
    private:dprint("AnalyzeTab > DrawSidebar()")

    local sidebar = AnalyzeTab.sidebar
    sidebar:ReleaseChildren()

    local removeDupes = sidebar:AcquireElement("GuildBankSnapshotsCheckButton")
    removeDupes:SetFullWidth()
    removeDupes:SetText(L["Remove duplicates"] .. "*")
    removeDupes:SetTooltipInitializer(L["Experimental"])
    removeDupes:SetCallbacks(callbacks.removeDupes)
    sidebar:AddChild(removeDupes)

    local selectScans = sidebar:AcquireElement("GuildBankSnapshotsDropdownFrame")
    selectScans:SetWidth(160)
    selectScans:SetLabel(L["Select Scans"])
    selectScans:SetLabelFont(nil, private:GetInterfaceFlairColor())
    selectScans:Justify("LEFT")
    selectScans:SetStyle({ multiSelect = true, hasClear = true, hasSelectAll = true })
    selectScans:ForwardCallbacks(forwardCallbacks.selectScans)
    selectScans:SetInfo(info.selectScans)
    selectScans:SetCallbacks(callbacks.selectScans)
    sidebar:AddChild(selectScans)

    local analyze = sidebar:AcquireElement("GuildBankSnapshotsButton")
    analyze:SetUserData("yOffset", -(selectScans:GetHeight() / 2))
    analyze:SetWidth(50)
    analyze:SetText(L["Analyze"])
    analyze:SetTooltipInitializer(L["Changes will not be calculated until analyze is re-run"])
    analyze:SetCallbacks(callbacks.analyze)
    sidebar:AddChild(analyze)

    if addon:tcount(GetSelectedGuild().scans) == 0 then
        sidebar:DoLayout()
        AnalyzeTab.tabContainer:ReleaseChildren()
        AnalyzeTab.content:ReleaseChildren()
        return
    end

    for sectionID, info in addon:pairs(sidebarSections) do
        local header = sidebar:AcquireElement("GuildBankSnapshotsButton")
        header:SetFullWidth()
        header:SetUserData("sectionID", sectionID)
        header:SetUserData("info", info)
        header:SetBackdropColor(private.interface.colors[private:UseClassColor() and "lightClass" or "lightFlair"], private.interface.colors.light)
        header:SetText(info.header)
        header:SetTextColor(private.interface.colors.white:GetRGBA())
        header:SetCallbacks(callbacks.sectionHeader)
        sidebar:AddChild(header)

        if not info.collapsed then
            local section = sidebar:AcquireElement("GuildBankSnapshotsGroup")
            section:SetFullWidth()
            section:SetHeight(1)
            -- section:SetUserData("yOffset", -10) -- TODO: Fix yOffset in Group:DoLayout()
            section.bg, section.border = private:AddBackdrop(section, { bgColor = "dark" })
            section:SetPadding(4, 2)
            section:SetSpacing(2)
            sidebar:AddChild(section)

            info.onLoad(section)
        end
    end

    sidebar:DoLayout()

    if not skipDrawTabs then
        DrawTabs()
    end
end

------------------------

DrawSidebarGold = function(section)
    local goldTotal = section:Acquire("GuildBankSnapshotsFontFrame")
    goldTotal:SetFullWidth()
    goldTotal:Justify("LEFT")
    goldTotal:SetCallbacks(callbacks.goldTotal)
    section:AddChild(goldTotal)

    local goldNet = section:Acquire("GuildBankSnapshotsFontFrame")
    goldNet:SetFullWidth()
    goldNet:Justify("LEFT")
    goldNet:SetCallbacks(callbacks.goldNet)
    section:AddChild(goldNet)

    --.....................
    divider = section:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetFullWidth()
    divider:SetHeight(5)
    divider:SetText(private.interface.divider)
    divider:SetFont(nil, private.interface.colors.dimmedWhite)
    divider:DisableTooltip(true)
    section:AddChild(divider)
    --.....................

    local goldDeposit = section:Acquire("GuildBankSnapshotsFontFrame")
    goldDeposit:SetFullWidth()
    goldDeposit:Justify("LEFT")
    goldDeposit:SetCallbacks(callbacks.goldDeposit)
    section:AddChild(goldDeposit)

    local goldDepositSummary = section:Acquire("GuildBankSnapshotsFontFrame")
    goldDepositSummary:SetFullWidth()
    goldDepositSummary:Justify("LEFT")
    goldDepositSummary:SetCallbacks(callbacks.goldDepositSummary)
    section:AddChild(goldDepositSummary)

    if GetSelectedGuild().data.gold.topDeposit then
        local goldTopDeposit = section:Acquire("GuildBankSnapshotsFontLabelFrame")
        goldTopDeposit:SetFullWidth()
        goldTopDeposit:Justify("LEFT")
        goldTopDeposit:SetLabel(L["All-Star"] .. ":")
        goldTopDeposit:SetLabelFont(nil, private:GetInterfaceFlairColor())
        goldTopDeposit:SetCallbacks(callbacks.goldTopDeposit)
        section:AddChild(goldTopDeposit)
    end

    --.....................
    divider = section:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetFullWidth()
    divider:SetHeight(5)
    divider:SetText(private.interface.divider)
    divider:SetFont(nil, private.interface.colors.dimmedWhite)
    divider:DisableTooltip(true)
    section:AddChild(divider)
    --.....................

    local goldRepair = section:Acquire("GuildBankSnapshotsFontFrame")
    goldRepair:SetFullWidth()
    goldRepair:Justify("LEFT")
    goldRepair:SetCallbacks(callbacks.goldRepair)
    section:AddChild(goldRepair)

    local goldWithdraw = section:Acquire("GuildBankSnapshotsFontFrame")
    goldWithdraw:SetFullWidth()
    goldWithdraw:Justify("LEFT")
    goldWithdraw:SetCallbacks(callbacks.goldWithdraw)
    section:AddChild(goldWithdraw)

    if GetSelectedGuild().data.gold.topWithdraw then
        local goldTopWithdraw = section:Acquire("GuildBankSnapshotsFontLabelFrame")
        goldTopWithdraw:SetFullWidth()
        goldTopWithdraw:Justify("LEFT")
        goldTopWithdraw:SetLabel(L["All-Star"] .. ":")
        goldTopWithdraw:SetLabelFont(nil, private:GetInterfaceFlairColor())
        goldTopWithdraw:SetCallbacks(callbacks.goldTopWithdraw)
        section:AddChild(goldTopWithdraw)
    end

    --.....................
    divider = section:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetFullWidth()
    divider:SetHeight(5)
    divider:SetText(private.interface.divider)
    divider:SetFont(nil, private.interface.colors.dimmedWhite)
    divider:DisableTooltip(true)
    section:AddChild(divider)
    --.....................

    local goldBuyTab = section:Acquire("GuildBankSnapshotsFontFrame")
    goldBuyTab:SetFullWidth()
    goldBuyTab:Justify("LEFT")
    goldBuyTab:SetCallbacks(callbacks.goldBuyTab)
    section:AddChild(goldBuyTab)

    local goldWithdrawForTab = section:Acquire("GuildBankSnapshotsFontFrame")
    goldWithdrawForTab:SetFullWidth()
    goldWithdrawForTab:Justify("LEFT")
    goldWithdrawForTab:SetCallbacks(callbacks.goldWithdrawForTab)
    section:AddChild(goldWithdrawForTab)

    -- return height
    section:DoLayout()
end

------------------------

DrawSidebarItems = function(section)
    local deposit = section:Acquire("GuildBankSnapshotsFontFrame")
    deposit:SetFullWidth()
    deposit:Justify("LEFT")
    deposit:SetCallbacks(callbacks.deposit)
    section:AddChild(deposit)

    if GetSelectedGuild().data.topDeposit then
        local topDeposit = section:Acquire("GuildBankSnapshotsFontLabelFrame")
        topDeposit:SetFullWidth()
        topDeposit:Justify("LEFT")
        topDeposit:SetLabel(L["All-Star"] .. ":")
        topDeposit:SetLabelFont(nil, private:GetInterfaceFlairColor())
        topDeposit:SetCallbacks(callbacks.topDeposit)
        section:AddChild(topDeposit)
    end

    --.....................
    divider = section:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetFullWidth()
    divider:SetHeight(5)
    divider:SetText(private.interface.divider)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())
    divider:DisableTooltip(true)
    section:AddChild(divider)
    --.....................

    local withdraw = section:Acquire("GuildBankSnapshotsFontFrame")
    withdraw:SetFullWidth()
    withdraw:Justify("LEFT")
    withdraw:SetCallbacks(callbacks.withdraw)
    section:AddChild(withdraw)

    if GetSelectedGuild().data.topWithdraw then
        local topWithdraw = section:Acquire("GuildBankSnapshotsFontLabelFrame")
        topWithdraw:SetFullWidth()
        topWithdraw:Justify("LEFT")
        topWithdraw:SetLabel(L["All-Star"] .. ":")
        topWithdraw:SetLabelFont(nil, private:GetInterfaceFlairColor())
        topWithdraw:SetCallbacks(callbacks.topWithdraw)
        section:AddChild(topWithdraw)
    end

    section:DoLayout()
end

------------------------

DrawTabs = function()
    local tabContainer = AnalyzeTab.tabContainer
    tabContainer:ReleaseChildren()

    if not AnalyzeTab.guildKey or addon:tcount(GetSelectedGuild().scans) == 0 then
        return
    end

    for tabID, info in addon:pairs(tabs) do
        local tab = tabContainer:Acquire("GuildBankSnapshotsTabButton")
        tab:SetTab(tabContainer, tabID, info)
        tab:SetCallbacks(callbacks.tab)
        if tabID == GetSelectedGuild().selectedTab then
            tab:Fire("OnClick")
        end
        tabContainer:AddChild(tab)
    end
    tabContainer:DoLayout()
end

------------------------

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
            totalDeposit = 0,
            totalWithdraw = 0,

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

------------------------

GetItemTable = function()
    return {
        deposit = 0,
        withdraw = 0,

        deposits = {},
        withdraws = {},
    }
end

------------------------

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

------------------------

GetSelectedGuild = function()
    local guild = AnalyzeTab.guild or AnalyzeTab.guildKey
    return guild and AnalyzeTab.guilds[guild]
end

------------------------

function private:LoadAnalyzeTab(content, guildKey, scanID)
    AnalyzeTab.guild = guildKey
    AnalyzeTab.scanID = scanID

    local selectGuild = content:Acquire("GuildBankSnapshotsDropdownButton")
    selectGuild:SetPoint("TOPLEFT", 10, -10)
    selectGuild:SetSize(250, 20)
    selectGuild:SetBackdropColor(private.interface.colors.darker)
    selectGuild:SetDefaultText(L["Select a guild"])
    selectGuild:SetInfo(info.selectGuild)
    AnalyzeTab.selectGuild = selectGuild

    local sidebar = content:Acquire("GuildBankSnapshotsScrollingGroup")
    sidebar:SetPoint("TOPLEFT", selectGuild, "BOTTOMLEFT")
    sidebar:SetPoint("BOTTOM", 0, 10)
    sidebar:SetSize(selectGuild:GetWidth(), sidebar:GetHeight())
    sidebar:SetBackdropColor(private.interface.colors.darker)
    sidebar:SetPadding(5, 5)
    sidebar:SetSpacing(5)
    private:RegisterResizeCallback(sidebar, "analyzeSidebar")
    AnalyzeTab.sidebar = sidebar

    local tabContainer = content:Acquire("GuildBankSnapshotsGroup")
    tabContainer:SetPoint("TOPLEFT", selectGuild, "TOPRIGHT")
    tabContainer:SetPoint("RIGHT", -10, 0)
    tabContainer:SetHeight(20)
    tabContainer.bg, tabContainer.border = private:AddBackdrop(tabContainer, { bgColor = "darker" })
    tabContainer:SetReverse(true)
    private:RegisterResizeCallback(tabContainer, "analyzeTabContainer")
    AnalyzeTab.tabContainer = tabContainer

    local content = content:Acquire("GuildBankSnapshotsScrollingGroup")
    content:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT")
    content:SetPoint("BOTTOMRIGHT", -10, 10)
    content:SetSize(selectGuild:GetWidth(), content:GetHeight())
    content:SetBackdropColor(private.interface.colors.dark)
    content:SetPadding(5, 5)
    content:SetSpacing(5)
    private:RegisterResizeCallback(content, "analyzeContent")
    AnalyzeTab.content = content

    selectGuild:SetCallbacks(callbacks.selectGuild)
end
