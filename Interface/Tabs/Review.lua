local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*----------[[ Initialize tab ]]----------*--
local ReviewTab
local callbacks, forwardCallbacks, info, otherCallbacks, sidebarSections, tableCols
local DrawRow, DrawSidebar, DrawSidebarFilters, DrawSidebarInfo, DrawSidebarSorters, DrawSidebarTools, DrawTableHeaders, GetFilters, IsFiltered, IsQueryMatch, LoadTable
local dividerString, divider = ".................................................................."

function private:InitializeReviewTab()
    ReviewTab = {
        guildKey = private.db.global.preferences.defaultGuild,
        searchKeys = { "itemLink", "name", "moveDestinationName", "moveOriginName", "tabName", "transactionType" },
        guilds = {},
        entriesPerFrame = 50,
        warningMax = 10000,
        maxEntries = 25000,
    }
end

--*----------[[ Data ]]----------*--
callbacks = {
    selectGuild = {
        OnShow = {
            function(self)
                self:SelectByID(ReviewTab.guild or ReviewTab.guildKey)
            end,
            true,
        },
    },
    tableHeaders = {
        OnSizeChanged = {
            function(self)
                DrawTableHeaders(self)
            end,
            true,
        },
    },
    row = {
        OnEnter = {
            function(self)
                private:SetColorTexture(self.bg, "lightest")
            end,
        },
        OnLeave = {
            function(self)
                self.bg:SetTexture()
            end,
        },
        OnSizeChanged = {
            function(self)
                self:ReleaseAll()

                local width = 0

                for colID, col in addon:pairs(tableCols) do
                    local cell = self:Acquire("GuildBankSnapshotsTableCell")
                    cell:SetPadding(4, 4)
                    self.cells[colID] = cell

                    cell:SetText(col.text(self:GetElementData()))
                    cell:SetSize(self:GetWidth() / addon:tcount(tableCols) * tableCols[colID].width, self:GetHeight())
                    cell:SetPoint("LEFT", width, 0)
                    width = width + cell:GetWidth()

                    cell:SetData(col, self:GetElementData(), self:GetOrderIndex())
                end
            end,
            true,
        },
    },
    searchBox = {
        OnClear = {
            function(self)
                ReviewTab.guilds[ReviewTab.guildKey].searchQuery = nil
                LoadTable()
            end,
        },
        OnEnterPressed = {
            function(self)
                ReviewTab.guilds[ReviewTab.guildKey].searchQuery = self:IsValidText() and self:GetText()
                LoadTable()
            end,
        },
        OnShow = {
            function(self)
                if ReviewTab.guilds[ReviewTab.guildKey].searchQuery then
                    self:SetText(ReviewTab.guilds[ReviewTab.guildKey].searchQuery)
                end

                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    enableMultiSort = {
        OnClick = {
            function(self)
                ReviewTab.guilds[ReviewTab.guildKey].multiSort = self:GetChecked()
                LoadTable(true)
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(ReviewTab.guilds[ReviewTab.guildKey].multiSort, true)
            end,
            true,
        },
    },
    duplicates = {
        OnClick = {
            function(self)
                ReviewTab.guilds[ReviewTab.guildKey].filters.duplicates.value = self:GetChecked()
                LoadTable()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(ReviewTab.guilds[ReviewTab.guildKey].filters.duplicates.value, true)
            end,
            true,
        },
    },
    filterLoadouts = {
        OnShow = {
            function(self)
                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0 or #self:GetInfo() == 0)
            end,
            true,
        },
    },
    clearFilters = {
        OnClick = {
            function()
                ReviewTab.guilds[ReviewTab.guildKey].filters = GetFilters()
                LoadTable()
            end,
        },
    },
    scanDate = {
        OnShow = {
            function(self)
                for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.scanDates.values) do
                    self:SelectByID(value, true, true)
                end

                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    transactionDate = {
        OnShow = {
            function(self)
                for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.transactionDates.values) do
                    self:SelectByID(value, true, true)
                end

                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    tabName = {
        OnShow = {
            function(self)
                for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.tabs.values) do
                    self:SelectByID(value, true, true)
                end

                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    transactionType = {
        OnShow = {
            function(self)
                for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.transactionType.values) do
                    self:SelectByID(value, true, true)
                end

                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    name = {
        OnShow = {
            function(self)
                for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.names.values) do
                    self:SelectByID(value, true, true)
                end

                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    itemName = {
        OnShow = {
            function(self)
                for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.itemNames.values) do
                    self:SelectByID(value, true, true)
                end

                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    rank = {
        OnShow = {
            function(self)
                self:SetValues(ReviewTab.guilds[ReviewTab.guildKey].filters.rank.minValue, ReviewTab.guilds[ReviewTab.guildKey].filters.rank.maxValue)
                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    itemLevel = {
        OnShow = {
            function(self)
                self:SetValues(ReviewTab.guilds[ReviewTab.guildKey].filters.itemLevels.minValue, ReviewTab.guilds[ReviewTab.guildKey].filters.itemLevels.maxValue)
                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
    amount = {
        OnShow = {
            function(self)
                self:SetValues(ReviewTab.guilds[ReviewTab.guildKey].filters.amounts.minValue, ReviewTab.guilds[ReviewTab.guildKey].filters.amounts.maxValue)
                self:SetDisabled(#private.db.global.guilds[ReviewTab.guildKey].masterScan == 0)
            end,
            true,
        },
    },
}

forwardCallbacks = {
    saveFilterLoadout = {
        OnEnterPressed = {
            function(self)
                local loadoutID = self:GetText()

                if private.db.global.guilds[ReviewTab.guildKey].filters[loadoutID] then
                    addon:Printf(L["Filter loadout '%s' already exists for %s. Please supply a unique loadout name. Note: existing loadouts can be managed from the Settings tab."], loadoutID, private:GetGuildDisplayName(ReviewTab.guildKey))
                    return
                elseif not self:IsValidText() then
                    addon:Print(L["Please supply a valid loadout name."])
                    return
                end

                private.db.global.guilds[ReviewTab.guildKey].filters[loadoutID] = addon:CloneTable(ReviewTab.guilds[ReviewTab.guildKey].filters)
                DrawSidebar()
            end,
        },
    },
    scanDate = {
        OnClear = {
            function()
                wipe(ReviewTab.guilds[ReviewTab.guildKey].filters.scanDates.values)
                LoadTable(true)
            end,
        },
    },
    transactionDate = {
        OnClear = {
            function()
                wipe(ReviewTab.guilds[ReviewTab.guildKey].filters.transactionDates.values)
                LoadTable(true)
            end,
        },
    },
    tabName = {
        OnClear = {
            function()
                wipe(ReviewTab.guilds[ReviewTab.guildKey].filters.tabs.values)
                LoadTable(true)
            end,
        },
    },
    transactionType = {
        OnClear = {
            function()
                wipe(ReviewTab.guilds[ReviewTab.guildKey].filters.transactionType.values)
                LoadTable(true)
            end,
        },
    },
    name = {
        OnClear = {
            function()
                wipe(ReviewTab.guilds[ReviewTab.guildKey].filters.names.values)
                LoadTable(true)
            end,
        },
    },
    itemName = {
        OnClear = {
            function()
                wipe(ReviewTab.guilds[ReviewTab.guildKey].filters.itemNames.values)
                LoadTable(true)
            end,
        },
    },
    deleteScan = {
        OnClear = {
            function(self)
                self:SetText("")
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
                    ReviewTab.guildKey = guildKey
                    ReviewTab.guilds[guildKey] = ReviewTab.guilds[guildKey] or {
                        searchQuery = false,
                        filters = GetFilters(),
                        multiSort = #private.db.global.guilds[guildKey].masterScan < ReviewTab.warningMax,
                    }
                    LoadTable()
                    DrawSidebar()
                end,
            })
        end)

        return info
    end,
    filterLoadouts = function()
        local info = {}

        for loadoutID, loadout in addon:pairs(private.db.global.guilds[ReviewTab.guildKey].filters) do
            tinsert(info, {
                id = loadoutID,
                text = loadoutID,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildKey].filters = addon:CloneTable(loadout)
                    dropdown:Clear()
                    LoadTable()
                end,
            })
        end

        return info
    end,
    scanDate = function()
        local info = {}

        for scanDate, _ in addon:pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.scanDates.list, private.sortDesc) do
            tinsert(info, {
                id = scanDate,
                text = date(private.db.global.preferences.dateFormat, scanDate),
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildKey].filters.scanDates.values[scanDate] = dropdown:GetSelected(scanDate) and true or nil
                    LoadTable(true)
                end,
            })
        end

        return info
    end,
    transactionDate = function()
        local info = {}

        for scanDate, _ in addon:pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.transactionDates.list, private.sortDesc) do
            tinsert(info, {
                id = scanDate,
                text = date(private.db.global.preferences.dateFormat, scanDate),
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildKey].filters.transactionDates.values[scanDate] = dropdown:GetSelected(scanDate) and true or nil
                    LoadTable(true)
                end,
            })
        end

        return info
    end,
    tabName = function()
        local info = {}

        for tabName, _ in addon:pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.tabs.list) do
            tinsert(info, {
                id = tabName,
                text = tabName,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildKey].filters.tabs.values[tabName] = dropdown:GetSelected(tabName) and true or nil
                    LoadTable(true)
                end,
            })
        end

        return info
    end,
    transactionType = function()
        local info = {}

        for _, transactionType in addon:pairs({ "buyTab", "deposit", "depositSummary", "move", "repair", "withdraw", "withdrawForTab" }) do
            tinsert(info, {
                id = transactionType,
                text = transactionType,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildKey].filters.transactionType.values[transactionType] = dropdown:GetSelected(transactionType) and true or nil
                    LoadTable(true)
                end,
            })
        end

        return info
    end,
    name = function()
        local info = {}

        for name, _ in addon:pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.names.list) do
            tinsert(info, {
                id = name,
                text = name,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildKey].filters.names.values[name] = dropdown:GetSelected(name) and true or nil
                    LoadTable(true)
                end,
            })
        end

        return info
    end,
    itemName = function()
        local info = {}

        for itemName, _ in addon:pairs(ReviewTab.guilds[ReviewTab.guildKey].filters.itemNames.list) do
            tinsert(info, {
                id = itemName,
                text = itemName,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildKey].filters.itemNames.values[itemName] = dropdown:GetSelected(itemName) and true or nil
                    LoadTable(true)
                end,
            })
        end

        return info
    end,
    deleteScan = function()
        local info = {}

        for scanID, _ in addon:pairs(private.db.global.guilds[ReviewTab.guildKey].scans, private.sortDesc) do
            tinsert(info, {
                id = scanID,
                text = date(private.db.global.preferences.dateFormat, scanID),
                func = function(dropdown, info)
                    local function onAccept(ReviewTab, dropdown, info)
                        private:DeleteScan(ReviewTab.guildKey, info.id)
                        dropdown:Clear()
                        LoadTable()
                    end

                    local function onCancel(dropdown)
                        dropdown:Clear()
                    end

                    private:ShowConfirmationDialog(format(L["Are you sure you want to delete the scan '%s'? This action is irreversible."], date(private.db.global.preferences.dateFormat, scanID)), onAccept, onCancel, { ReviewTab, dropdown, info }, { dropdown })
                end,
            })
        end

        return info
    end,
}

otherCallbacks = {
    sorter = {
        callback = function()
            LoadTable()
        end,
        dCallback = function()
            LoadTable()
        end,
    },
    rank = {
        callback = function(self, range, value)
            ReviewTab.guilds[ReviewTab.guildKey].filters.rank[range == "lower" and "minValue" or range == "upper" and "maxValue"] = tonumber(value)
            LoadTable(true)
        end,
    },
    itemLevel = {
        callback = function(self, range, value)
            ReviewTab.guilds[ReviewTab.guildKey].filters.itemLevels[range == "lower" and "minValue" or range == "upper" and "maxValue"] = tonumber(value)
            LoadTable(true)
        end,
    },
    amount = {
        callback = function(self, range, value)
            ReviewTab.guilds[ReviewTab.guildKey].filters.amounts[range == "lower" and "minValue" or range == "upper" and "maxValue"] = self[range].value

            LoadTable(true)
        end,
        formatter = function(value)
            return GetCoinTextureString(value)
        end,
        reverseFormatter = function(value)
            local gold = strmatch(value, "(%d+)g")
            local silver = strmatch(value, "(%d+)s")
            local copper = strmatch(value, "(%d+)c")

            return ((tonumber(gold) or 0) * COPPER_PER_GOLD) + ((tonumber(silver) or 0) * COPPER_PER_SILVER) + (tonumber(copper) or 0)
        end,
    },
}

sidebarSections = {
    {
        header = L["Info"],
        collapsed = false,
        onLoad = function(...)
            return DrawSidebarInfo(...)
        end,
    },
    {
        header = L["Sorting"],
        collapsed = true,
        onLoad = function(...)
            return DrawSidebarSorters(...)
        end,
    },
    {
        header = L["Filters"],
        collapsed = true,
        onLoad = function(...)
            return DrawSidebarFilters(...)
        end,
    },
    {
        header = L["Tools"],
        collapsed = true,
        onLoad = function(...)
            return DrawSidebarTools(...)
        end,
    },
}

tableCols = {
    [1] = {
        header = L["Date"],
        sortValue = function(data)
            return data.transactionDate
        end,
        text = function(data)
            return date(private.db.global.preferences.dateFormat, data.transactionDate)
        end,
        width = 1,
    },
    [2] = {
        header = L["Tab"],
        sortValue = function(data)
            return private:GetTabName(ReviewTab.guildKey, data.tabID)
        end,
        text = function(data)
            return private:GetTabName(ReviewTab.guildKey, data.tabID)
        end,
        width = 1,
    },
    [3] = {
        header = L["Type"],
        sortValue = function(data)
            return data.transactionType
        end,
        text = function(data)
            return data.transactionType
        end,
        width = 1,
    },
    [4] = {
        header = L["Name"],
        sortValue = function(data)
            return data.name
        end,
        text = function(data)
            return data.name
        end,
        width = 1,
    },
    [5] = {
        header = L["Item/Amount"],
        icon = function(data)
            return data.itemLink and GetItemIcon(data.itemLink)
        end,
        sortValue = function(data)
            return data.itemLink and private:GetItemName(data.itemLink) or data.amount
        end,
        text = function(data)
            return data.itemLink or GetCoinTextureString(data.amount)
        end,
        tooltip = function(data)
            if data.itemLink then
                GameTooltip:SetHyperlink(data.itemLink)
            end
        end,
        width = 2.25,
    },
    [6] = {
        header = L["Quantity"],
        sortValue = function(data)
            return data.count or 0
        end,
        text = function(data)
            return data.count or ""
        end,
        width = 0.5,
    },
    [7] = {
        header = L["Move Origin"],
        sortValue = function(data)
            return data.moveOrigin or 0
        end,
        text = function(data)
            return data.moveOrigin and data.moveOrigin > 0 and private:GetTabName(ReviewTab.guildKey, data.moveOrigin) or ""
        end,
        width = 1,
    },
    [8] = {
        header = L["Move Destination"],
        sortValue = function(data)
            return data.moveDestination or 0
        end,
        text = function(data)
            return data.moveDestination and data.moveDestination > 0 and private:GetTabName(ReviewTab.guildKey, data.moveDestination) or ""
        end,
        width = 1,
    },
    [9] = {
        header = L["Scan Date"],
        icon = 374216,
        sortValue = function(data)
            return data.scanID
        end,
        text = function(data)
            return ""
        end,
        tooltip = function(data, order)
            GameTooltip:AddDoubleLine(L["Line"], order, nil, nil, nil, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Entry"], data.entryID, nil, nil, nil, 1, 1, 1)
            GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
            GameTooltip:AddDoubleLine(L["Transaction ID"], data.transactionID, nil, nil, nil, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Scan Date"], date(private.db.global.preferences.dateFormat, data.scanID), nil, nil, nil, 1, 1, 1)
            GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
            GameTooltip:AddDoubleLine(L["Tab ID"], data.tabID, nil, nil, nil, 1, 1, 1)
            if data.moveOrigin and data.moveOrigin > 0 then
                GameTooltip:AddDoubleLine(L["Move Origin ID"], data.moveOrigin, nil, nil, nil, 1, 1, 1)
            end
            if data.moveDestination and data.moveDestination > 0 then
                GameTooltip:AddDoubleLine(L["Move Destination ID"], data.moveDestination, nil, nil, nil, 1, 1, 1)
            end
        end,
        width = 0.25,
    },
}

--*----------[[ Methods ]]----------*--
DrawRow = function(row, elementData)
    row.cells = row.cells or {}
    row.bg = row.bg or row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row:SetCallbacks(callbacks.row)
end

DrawSidebar = function()
    local sidebar = ReviewTab.sidebar
    local content = sidebar.content
    content:ReleaseAll()

    if not ReviewTab.guildKey then
        return
    end

    local height = 0

    local searchBox = content:Acquire("GuildBankSnapshotsEditBox")
    searchBox:SetSearchTemplate(true)
    searchBox:SetPoint("TOPLEFT", 5, -height)
    searchBox:SetPoint("TOPRIGHT", -5, -height)
    searchBox:SetCallbacks(callbacks.searchBox)
    height = height + searchBox:GetHeight() + 5

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
end

DrawSidebarFilters = function(content, height)
    local duplicates = content:Acquire("GuildBankSnapshotsCheckButton")
    duplicates:SetPoint("TOPLEFT", 5, -height)
    duplicates:SetPoint("RIGHT", -5, 0)
    duplicates:SetText(L["Remove duplicates"] .. "*")
    duplicates:SetTooltipInitializer(L["Experimental"])
    duplicates:SetCallbacks(callbacks.duplicates)
    height = height + duplicates:GetHeight()

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

    local filterLoadouts = content:Acquire("GuildBankSnapshotsDropdownFrame")
    filterLoadouts:SetPoint("TOPLEFT", 5, -height)
    filterLoadouts:SetPoint("RIGHT", -5, 0)
    filterLoadouts:SetLabel(L["Filter Loadouts"])
    filterLoadouts:SetLabelFont(nil, private:GetInterfaceFlairColor())
    filterLoadouts:Justify("LEFT")
    filterLoadouts:SetStyle({ hasCheckBox = false, hasSearch = true })
    filterLoadouts:SetInfo(info.filterLoadouts)
    filterLoadouts:SetCallbacks(callbacks.filterLoadouts)
    height = height + filterLoadouts:GetHeight() + 5

    local saveFilterLoadout = content:Acquire("GuildBankSnapshotsEditBoxFrame")
    saveFilterLoadout:SetPoint("TOPLEFT", 5, -height)
    saveFilterLoadout:SetPoint("RIGHT", -5, 0)
    saveFilterLoadout:SetLabel(L["Save Filter Loadout"])
    saveFilterLoadout:SetLabelFont(nil, private:GetInterfaceFlairColor())
    saveFilterLoadout:ForwardCallbacks(forwardCallbacks.saveFilterLoadout)
    height = height + saveFilterLoadout:GetHeight() + 5

    local clearFilters = content:Acquire("GuildBankSnapshotsButton")
    clearFilters:SetPoint("TOPLEFT", 5, -height)
    clearFilters:SetPoint("RIGHT", -5, 0)
    clearFilters:SetText(L["Clear Filters"])
    clearFilters:SetFont(nil, private:GetInterfaceFlairColor())
    clearFilters:SetCallbacks(callbacks.clearFilters)
    height = height + clearFilters:GetHeight() + 5

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

    local scanDate = content:Acquire("GuildBankSnapshotsDropdownFrame")
    scanDate:SetPoint("TOPLEFT", 5, -height)
    scanDate:SetPoint("RIGHT", -5, 0)
    scanDate:SetLabel(L["Scan Date"])
    scanDate:SetLabelFont(nil, private:GetInterfaceFlairColor())
    scanDate:Justify("LEFT")
    scanDate:SetStyle({ multiSelect = true, hasClear = true })
    scanDate:SetInfo(info.scanDate)
    scanDate:ForwardCallbacks(forwardCallbacks.scanDate)
    scanDate:SetCallbacks(callbacks.scanDate)
    height = height + scanDate:GetHeight() + 5

    local transactionDate = content:Acquire("GuildBankSnapshotsDropdownFrame")
    transactionDate:SetPoint("TOPLEFT", 5, -height)
    transactionDate:SetPoint("RIGHT", -5, 0)
    transactionDate:SetLabel(L["Transaction Date"])
    transactionDate:SetLabelFont(nil, private:GetInterfaceFlairColor())
    transactionDate:Justify("LEFT")
    transactionDate:SetStyle({ multiSelect = true, hasClear = true })
    transactionDate:SetInfo(info.transactionDate)
    transactionDate:ForwardCallbacks(forwardCallbacks.transactionDate)
    transactionDate:SetCallbacks(callbacks.transactionDate)
    height = height + transactionDate:GetHeight() + 5

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

    local tabName = content:Acquire("GuildBankSnapshotsDropdownFrame")
    tabName:SetPoint("TOPLEFT", 5, -height)
    tabName:SetPoint("RIGHT", -5, 0)
    tabName:SetLabel(L["Tab"])
    tabName:SetLabelFont(nil, private:GetInterfaceFlairColor())
    tabName:Justify("LEFT")
    tabName:SetStyle({ multiSelect = true, hasClear = true })
    tabName:SetInfo(info.tabName)
    tabName:ForwardCallbacks(forwardCallbacks.tabName)
    tabName:SetCallbacks(callbacks.tabName)
    height = height + tabName:GetHeight() + 5

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

    local transactionType = content:Acquire("GuildBankSnapshotsDropdownFrame")
    transactionType:SetPoint("TOPLEFT", 5, -height)
    transactionType:SetPoint("RIGHT", -5, 0)
    transactionType:SetLabel(L["Type"])
    transactionType:SetLabelFont(nil, private:GetInterfaceFlairColor())
    transactionType:Justify("LEFT")
    transactionType:SetStyle({ multiSelect = true, hasClear = true })
    transactionType:SetInfo(info.transactionType)
    transactionType:SetCallbacks(callbacks.transactionType)
    transactionType:ForwardCallbacks(forwardCallbacks.transactionType)

    height = height + transactionType:GetHeight() + 5

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

    local name = content:Acquire("GuildBankSnapshotsDropdownFrame")
    name:SetPoint("TOPLEFT", 5, -height)
    name:SetPoint("RIGHT", -5, 0)
    name:SetLabel(L["Name"])
    name:SetLabelFont(nil, private:GetInterfaceFlairColor())
    name:Justify("LEFT")
    name:SetStyle({ multiSelect = true, hasSearch = true, hasClear = true })
    name:SetInfo(info.name)
    name:ForwardCallbacks(forwardCallbacks.name)
    name:SetCallbacks(callbacks.name)
    height = height + name:GetHeight() + 5

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

    local itemName = content:Acquire("GuildBankSnapshotsDropdownFrame")
    itemName:SetPoint("TOPLEFT", 5, -height)
    itemName:SetPoint("RIGHT", -5, 0)
    itemName:SetLabel(L["Item"])
    itemName:SetLabelFont(nil, private:GetInterfaceFlairColor())
    itemName:Justify("LEFT")
    itemName:SetStyle({ height = "auto", multiSelect = true, hasSearch = true, hasClear = true })
    itemName:SetCallbacks(callbacks.itemName)
    itemName:ForwardCallbacks(forwardCallbacks.itemName)
    itemName:SetInfo(info.itemName)
    height = height + itemName:GetHeight() + 5

    local rank = content:Acquire("GuildBankSnapshotsMinMaxFrame")
    rank:SetPoint("TOPLEFT", 5, -height)
    rank:SetPoint("RIGHT", -5, 0)
    rank:SetLabels(L["Item Rank"], "")
    rank:SetLabelFont(nil, private:GetInterfaceFlairColor())
    rank:SetMinMaxValues(0, 5, otherCallbacks.rank.callback)
    rank:SetCallbacks(callbacks.rank)
    height = height + rank:GetHeight() + 5

    local itemLevel = content:Acquire("GuildBankSnapshotsMinMaxFrame")
    itemLevel:SetPoint("TOPLEFT", 5, -height)
    itemLevel:SetPoint("RIGHT", -5, 0)
    itemLevel:SetLabels(L["Item Level"], "")
    itemLevel:SetLabelFont(nil, private:GetInterfaceFlairColor())
    itemLevel:SetMinMaxValues(0, 418, otherCallbacks.itemLevel.callback)
    itemLevel:SetCallbacks(callbacks.itemLevel)
    height = height + itemLevel:GetHeight() + 5

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

    local amount = content:Acquire("GuildBankSnapshotsMinMaxFrame")
    amount:SetPoint("TOPLEFT", 5, -height)
    amount:SetPoint("RIGHT", -5, 0)
    amount:SetLabels(L["Amount"], "")
    amount:SetLabelFont(nil, private:GetInterfaceFlairColor())
    amount:SetMinMaxValues(0, 10000000000, otherCallbacks.amount.callback, otherCallbacks.amount.formatter, otherCallbacks.amount.reverseFormatter)
    amount:SetCallbacks(callbacks.amount)
    height = height + amount:GetHeight() + 5

    return height
end

DrawSidebarInfo = function(content, height)
    local tblSize = ReviewTab.tableContainer.scrollBox:GetDataProvider():GetSize() or 0

    local numTransactions = content:Acquire("GuildBankSnapshotsFontFrame")
    numTransactions:SetPoint("TOPLEFT", 5, -height)
    numTransactions:SetPoint("RIGHT", -5, 0)
    numTransactions:SetAutoHeight(true)
    numTransactions:SetText(format("%s: %s", L["Number of transactions"], addon:iformat(#private.db.global.guilds[ReviewTab.guildKey].masterScan, 1)))
    numTransactions:Justify("LEFT")
    height = height + numTransactions:GetHeight()

    local numEntries = content:Acquire("GuildBankSnapshotsFontFrame")
    numEntries:SetPoint("TOPLEFT", 5, -height)
    numEntries:SetPoint("RIGHT", -5, 0)
    numEntries:SetAutoHeight(true)
    numEntries:SetText(format("%s: %s", L["Number of entries"], addon:iformat(tblSize, 1)))
    numEntries:Justify("LEFT")
    ReviewTab.numEntries = ReviewTab.numEntries
    height = height + numEntries:GetHeight()

    if tblSize > ReviewTab.warningMax then
        local largeTableWarning = content:Acquire("GuildBankSnapshotsFontFrame")
        largeTableWarning:SetPoint("TOPLEFT", 5, -height)
        largeTableWarning:SetPoint("RIGHT", -5, 0)
        largeTableWarning:SetAutoHeight(true)
        largetTableWarning:SetText("*" .. L["Due to the large quantity of results in this query, performance issues may occur. You can reduce the size of your resluts by limiting the query through filters or reducing the size of the master table using the cleanup feature (optionally, you may first export the table for use in Excel)."])
        largeTableWarning:SetTextColor(1, 0, 0, 1)
        largeTableWarning:Justify("LEFT")
        height = height + largeTableWarning:GetHeight()
    end

    return height
end

DrawSidebarSorters = function(content, height)
    local enableMultiSort = content:Acquire("GuildBankSnapshotsCheckButton")
    enableMultiSort:SetPoint("TOPLEFT", 5, -height)
    enableMultiSort:SetPoint("RIGHT", -5, 0)
    enableMultiSort:SetText(L["Enable multi-sorting"] .. "*")
    enableMultiSort:SetTooltipInitializer(L["Not recommended for large tables as it may cause the game to freeze for extended periods of time"])
    enableMultiSort:SetCallbacks(callbacks.enableMultiSort)
    height = height + enableMultiSort:GetHeight()

    for sortID, colID in addon:pairs(private.db.global.preferences.sortHeaders) do
        local sorter = content:Acquire("GuildBankSnapshotsTableSorter")
        sorter:SetPoint("TOPLEFT", 5, -height)
        sorter:SetPoint("RIGHT", -5, 0)
        sorter:SetText(tableCols[colID].header)
        sorter:SetSorterData(sortID, colID, addon:tcount(tableCols), otherCallbacks.sorter.callback, otherCallbacks.sorter.dCallback)
        height = height + sorter:GetHeight() + 2
    end

    return height
end

DrawSidebarTools = function(content, height)
    local deleteScan = content:Acquire("GuildBankSnapshotsDropdownFrame")
    deleteScan:SetPoint("TOPLEFT", 5, -height)
    deleteScan:SetPoint("RIGHT", -5, 0)
    deleteScan:SetLabel(L["Delete Scan"])
    deleteScan:SetLabelFont(nil, private:GetInterfaceFlairColor())
    deleteScan:Justify("LEFT")
    deleteScan:SetStyle({ hasCheckBox = false })
    deleteScan:SetInfo(info.deleteScan)
    deleteScan:ForwardCallbacks(forwardCallbacks.deleteScan)
    height = height + deleteScan:GetHeight() + 5

    return height
end

DrawTableHeaders = function(self)
    self:ReleaseAll()

    local width = 0
    for colID, col in addon:pairs(tableCols) do
        local header = self:Acquire("GuildBankSnapshotsFontFrame")
        header:SetPadding(4, 4)
        header:SetText(col.header)
        header:SetSize(self:GetWidth() / addon:tcount(tableCols) * col.width, self:GetHeight())
        header:SetPoint("LEFT", width, 0)
        width = width + header:GetWidth()
    end
end

GetFilters = function()
    return {
        amounts = {
            minValue = 0,
            maxValue = 10000000000,
            func = function(self, elementData)
                if not elementData.amount then
                    return self.minValue > 0
                end

                if elementData.amount >= self.minValue and elementData.amount <= self.maxValue then
                    return
                end

                return true
            end,
        },
        duplicates = {
            value = true,
            func = function(self, elementData)
                if not self.value then
                    return
                end

                return elementData.isDupe
            end,
        },
        itemLevels = {
            list = {},
            minValue = 0,
            maxValue = 418,
            func = function(self, elementData)
                local itemLink = elementData.itemLink
                local iLvl = itemLink and self.list[itemLink]

                if self.minValue == 0 and (not itemLink or not iLvl) then
                    return
                end

                if iLvl and iLvl >= self.minValue and iLvl <= self.maxValue then
                    return
                end

                return true
            end,
        },
        itemNames = {
            list = {},
            values = {},
            func = function(self, elementData)
                if not elementData.itemLink then
                    return addon:tcount(self.values) > 0
                end

                if addon:tcount(self.values) == 0 then
                    return
                end

                for itemName, _ in pairs(self.values) do
                    if itemName == private:GetItemName(elementData.itemLink) then
                        return
                    end
                end

                return true
            end,
        },
        names = {
            list = {},
            values = {},
            func = function(self, elementData)
                if addon:tcount(self.values) == 0 then
                    return
                end

                for name, _ in pairs(self.values) do
                    if name == elementData.name then
                        return
                    end
                end

                return true
            end,
        },
        rank = {
            minValue = 0,
            maxValue = 5,
            func = function(self, elementData)
                if not elementData.itemLink then
                    return self.minValue > 0
                end

                local tier = private:GetItemRank(elementData.itemLink)
                if tier >= self.minValue and tier <= self.maxValue then
                    return
                end

                return true
            end,
        },
        scanDates = {
            list = {},
            values = {},
            func = function(self, elementData)
                if addon:tcount(self.values) == 0 then
                    return
                end

                for scanDate, _ in pairs(self.values) do
                    if scanDate == elementData.scanID then
                        return
                    end
                end

                return true
            end,
        },
        tabs = {
            list = {},
            values = {},
            func = function(self, elementData)
                if addon:tcount(self.values) == 0 then
                    return
                end

                for _, key in pairs({ "tabID", "moveOrigin", "moveDestination" }) do
                    for tabName, _ in pairs(self.values) do
                        if tabName == private:GetTabName(ReviewTab.guildKey, elementData[key]) then
                            return
                        end
                    end
                end

                return true
            end,
        },
        transactionDates = {
            list = {},
            values = {},
            func = function(self, elementData)
                if addon:tcount(self.values) == 0 then
                    return
                end

                for transactionDate, _ in pairs(self.values) do
                    if transactionDate == elementData.transactionDate then
                        return
                    end
                end

                return true
            end,
        },
        transactionType = {
            values = {},
            func = function(self, elementData)
                if addon:tcount(self.values) == 0 then
                    return
                end

                for transactionType, _ in pairs(self.values) do
                    if transactionType == elementData.transactionType then
                        return
                    end
                end

                return true
            end,
        },
    }
end

IsFiltered = function(elementData)
    for filterID, filter in pairs(ReviewTab.guilds[ReviewTab.guildKey].filters) do
        if not filter.func then
            local defaultFilter = GetFilters()
            filter.func = defaultFilter[filterID].func
        end

        if filter.func(filter, elementData) then
            return true
        end
    end

    return
end

IsQueryMatch = function(elementData)
    if not ReviewTab.guilds[ReviewTab.guildKey].searchQuery then
        return true
    end

    for _, key in pairs(ReviewTab.searchKeys) do
        local found = elementData[key] and strfind(strupper(elementData[key]), strupper(ReviewTab.guilds[ReviewTab.guildKey].searchQuery))
        if found then
            return true
        end
    end
end

LoadTable = function(skipDrawSidebar)
    tableContainer = ReviewTab.tableContainer

    if not ReviewTab.guildKey then
        tableContainer.scrollBox:Flush()
        return
    end

    tableContainer.scrollView:Initialize(20, DrawRow, "GuildBankSnapshotsContainer")

    local provider = tableContainer:SetDataProvider(function(provider)
        local masterScan = private.db.global.guilds[ReviewTab.guildKey].masterScan
        local validEntries = 0

        for transactionID, elementData in ipairs(masterScan) do
            -- Filter defaults
            ReviewTab.guilds[ReviewTab.guildKey].filters.scanDates.list[elementData.scanID] = true
            ReviewTab.guilds[ReviewTab.guildKey].filters.transactionDates.list[elementData.transactionDate] = true
            ReviewTab.guilds[ReviewTab.guildKey].filters.names.list[elementData.name] = true
            ReviewTab.guilds[ReviewTab.guildKey].filters.tabs.list[private:GetTabName(ReviewTab.guildKey, elementData.tabID)] = true
            if elementData.itemLink then
                addon:CacheItem(elementData.itemLink, function(success, itemID, callback)
                    if success then
                        local _, itemLink, _, _, _, itemType = GetItemInfo(itemID)
                        if itemType == "Armor" or itemType == "Weapon" then
                            local iLvl = GetDetailedItemLevelInfo(itemID)
                            callback(itemLink, iLvl)
                        end
                    end
                end, {
                    function(itemLink, itemLevel)
                        ReviewTab.guilds[ReviewTab.guildKey].filters.itemLevels.list[itemLink] = itemLevel
                    end,
                })
                ReviewTab.guilds[ReviewTab.guildKey].filters.itemNames.list[private:GetItemName(elementData.itemLink)] = true
            end

            -- Insert into provider
            if IsQueryMatch(elementData) and not IsFiltered(elementData) then
                validEntries = validEntries + 1
                elementData.entryID = validEntries
                provider:Insert(elementData)

                if validEntries >= ReviewTab.maxEntries then
                    addon:Printf(L["The results of this query exceed the maximum allowed entries (%s); loading has stopped and review data is incomplete. To prevent this error, please limit the query through filters or reduce the size of the master table using the cleanup feature (optionally, you may first export the table for use in Excel)."], addon:iformat(ReviewTab.maxEntries, 1))
                    break
                end
            end
        end

        provider:SetSortComparator(function(a, b)
            for sortID, id in ipairs(private.db.global.preferences.sortHeaders) do
                if not ReviewTab.guilds[ReviewTab.guildKey].multiSort and sortID > 1 then
                    break
                end

                local sortValue = tableCols[id].sortValue
                local des = private.db.global.preferences.descendingHeaders[id]

                local sortA = sortValue(a)
                local sortB = sortValue(b)

                if type(sortA) ~= type(sortB) then
                    sortA = tostring(sortA)
                    sortB = tostring(sortB)
                end

                if sortA > sortB then
                    if des then
                        return true
                    else
                        return false
                    end
                elseif sortA < sortB then
                    if des then
                        return false
                    else
                        return true
                    end
                end
            end
        end)
    end)

    if not skipDrawSidebar then
        DrawSidebar()
    end

    return provider:GetSize()
end

------------------------

function private:LoadReviewTab(content, guildKey)
    ReviewTab.guild = guildKey

    local selectGuild = content:Acquire("GuildBankSnapshotsDropdownButton")
    selectGuild:SetPoint("TOPLEFT", 10, -10)
    selectGuild:SetSize(250, 20)
    selectGuild:SetText(L["Select a guild"])
    selectGuild:SetBackdropColor(private.interface.colors.darker)
    selectGuild:SetInfo(info.selectGuild)
    ReviewTab.selectGuild = selectGuild

    local sidebar = content:Acquire("GuildBankSnapshotsScrollFrame")
    sidebar.bg, sidebar.border = private:AddBackdrop(sidebar, { bgColor = "darker" })
    sidebar:SetWidth(selectGuild:GetWidth())
    sidebar:SetPoint("TOPLEFT", selectGuild, "BOTTOMLEFT")
    sidebar:SetPoint("BOTTOM", 0, 10)
    ReviewTab.sidebar = sidebar

    local tableContainer = content:Acquire("GuildBankSnapshotsListScrollFrame")
    tableContainer.bg, tableContainer.border = private:AddBackdrop(tableContainer, { bgColor = "dark" })
    tableContainer:SetPoint("TOPLEFT", sidebar, "TOPRIGHT")
    tableContainer:SetPoint("BOTTOMRIGHT", -10, 10)
    ReviewTab.tableContainer = tableContainer

    local tableHeaders = content:Acquire("GuildBankSnapshotsContainer")
    tableHeaders.bg, tableHeaders.border = private:AddBackdrop(tableHeaders, { bgColor = "darker" })
    tableHeaders:SetPoint("TOP", selectGuild, "TOP")
    tableHeaders:SetPoint("LEFT", tableContainer.scrollBox, "LEFT")
    tableHeaders:SetPoint("RIGHT", tableContainer.scrollBox, "RIGHT")
    tableHeaders:SetPoint("BOTTOM", tableContainer, "TOP")
    tableHeaders:SetCallbacks(callbacks.tableHeaders)
    ReviewTab.tableHeaders = ReviewTab.tableHeaders

    -- These callbacks need all elements acquired before being initialized
    selectGuild:SetCallbacks(callbacks.selectGuild)
end
