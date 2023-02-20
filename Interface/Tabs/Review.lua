local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local dividerString, divider = ".................................................................."

--*----------[[ Initialize tab ]]----------*--
local ReviewTab
local GetFilters, DrawTableHeaders, IsFiltered, IsQueryMatch, LoadRow, LoadSideBar, LoadSidebarFilters, LoadSidebarSorters, LoadSidebarTools, LoadTable

function private:InitializeReviewTab()
    ReviewTab = {
        guildID = private.db.global.settings.preferences.defaultGuild,
        searchKeys = { "itemLink", "name", "moveDestinationName", "moveOriginName", "tabName", "transactionType" },
        guilds = {},
        entriesPerFrame = 50,
        maxEntries = 25000,
    }
end

--*----------[[ Data ]]----------*--
local sidebarSections = {
    {
        header = L["Sorting"],
        collapsed = true,
        onLoad = function(...)
            return LoadSidebarSorters(...)
        end,
    },
    {
        header = L["Filters"],
        collapsed = false,
        onLoad = function(...)
            return LoadSidebarFilters(...)
        end,
    },
    {
        header = L["Tools"],
        collapsed = true,
        onLoad = function(...)
            return LoadSidebarTools(...)
        end,
    },
}

local tableCols = {
    [1] = {
        header = L["Date"],
        sortValue = function(data)
            return data.transactionDate
        end,
        text = function(data)
            return date(private.db.global.settings.preferences.dateFormat, data.transactionDate)
        end,
        width = 1,
    },
    [2] = {
        header = L["Tab"],
        sortValue = function(data)
            return private:GetTabName(ReviewTab.guildID, data.tabID)
        end,
        text = function(data)
            return private:GetTabName(ReviewTab.guildID, data.tabID)
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
            return data.moveOrigin and data.moveOrigin > 0 and private:GetTabName(ReviewTab.guildID, data.moveOrigin) or ""
        end,
        width = 1,
    },
    [8] = {
        header = L["Move Destination"],
        sortValue = function(data)
            return data.moveDestination or 0
        end,
        text = function(data)
            return data.moveDestination and data.moveDestination > 0 and private:GetTabName(ReviewTab.guildID, data.moveDestination) or ""
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
            GameTooltip:AddDoubleLine(L["Scan Date"], date(private.db.global.settings.preferences.dateFormat, data.scanID), nil, nil, nil, 1, 1, 1)
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
        duplicates = {
            value = true,
            func = function(self, elementData)
                -- TODO filter duplicates
            end,
        },

        itemNames = {
            list = {},
            values = {},
            func = function(self, elementData)
                if not elementData.itemLink then
                    return true
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
    for filterID, filter in pairs(ReviewTab.guilds[ReviewTab.guildID].filters) do
        if filter.func(filter, elementData) then
            return true
        end
    end

    return
end

IsQueryMatch = function(elementData)
    if not ReviewTab.guilds[ReviewTab.guildID].searchQuery then
        return true
    end

    for _, key in pairs(ReviewTab.searchKeys) do
        local found = elementData[key] and strfind(strupper(elementData[key]), strupper(ReviewTab.guilds[ReviewTab.guildID].searchQuery))
        if found then
            return true
        end
    end
end

LoadRow = function(row, elementData)
    row.bg = row.bg or row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)

    row:SetCallback("OnEnter", function(self)
        private:SetColorTexture(self.bg, "lightest")
    end)

    row:SetCallback("OnLeave", function(self)
        self.bg:SetTexture()
    end)

    row.cells = row.cells or {}
    row:SetCallback("OnSizeChanged", function(self)
        row:ReleaseAll()

        local width = 0

        for colID, col in addon:pairs(tableCols) do
            local cell = row:Acquire("GuildBankSnapshotsTableCell")
            cell:SetPadding(4, 4)
            row.cells[colID] = cell

            cell:SetText(col.text(elementData))
            cell:SetSize(self:GetWidth() / addon:tcount(tableCols) * tableCols[colID].width, self:GetHeight())
            cell:SetPoint("LEFT", width, 0)
            width = width + cell:GetWidth()

            cell:SetData(col, elementData, row:GetOrderIndex())
        end
    end, true)
end

LoadSidebar = function()
    local sidebar = ReviewTab.sidebar
    local content = sidebar.content
    content:ReleaseAll()

    if not ReviewTab.guildID then
        return
    end

    local height = 0

    local searchBox = content:Acquire("GuildBankSnapshotsEditBox")
    searchBox:SetSearchTemplate(true)
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOPLEFT", 5, -height)
    searchBox:SetPoint("TOPRIGHT", -5, -height)

    searchBox:SetCallback("OnEnterPressed", function(self)
        ReviewTab.guilds[ReviewTab.guildID].searchQuery = self:IsValidText() and self:GetText()
        LoadTable()
    end)

    searchBox:SetCallback("OnClear", function()
        ReviewTab.guilds[ReviewTab.guildID].searchQuery = nil
        LoadTable()
    end)

    if ReviewTab.guilds[ReviewTab.guildID].searchQuery then
        searchBox:SetText(ReviewTab.guilds[ReviewTab.guildID].searchQuery)
    end

    height = height + searchBox:GetHeight() + 5

    for sectionID, info in addon:pairs(sidebarSections) do
        local header = content:Acquire("GuildBankSnapshotsButton")
        header:SetHeight(20)
        header:SetText(info.header)
        header:SetBackdropColor(private.interface.colors[private:UseClassColor() and "lightClass" or "lightFlair"], private.interface.colors.light)
        header:SetTextColor(private.interface.colors.white:GetRGBA())

        header:SetPoint("TOPLEFT", 0, -height)
        header:SetPoint("RIGHT", 0, 0)

        height = height + header:GetHeight() + 5

        if not info.collapsed then
            height = info.onLoad(content, height) + 5
        end

        header:SetCallback("OnClick", function()
            local isCollapsed = info.collapsed
            if isCollapsed then
                sidebarSections[sectionID].collapsed = false
            else
                sidebarSections[sectionID].collapsed = true
            end

            LoadSidebar()
        end)
    end

    content:MarkDirty()
    sidebar.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
end

LoadSidebarFilters = function(content, height)
    local transactionTypeLabel = content:Acquire("GuildBankSnapshotsFontFrame")
    transactionTypeLabel:SetPoint("TOPLEFT", 5, -height)
    transactionTypeLabel:SetPoint("RIGHT", -5, 0)
    transactionTypeLabel:SetText(L["Type"])
    transactionTypeLabel:Justify("LEFT")

    height = height + transactionTypeLabel:GetHeight()

    local transactionType = content:Acquire("GuildBankSnapshotsDropdownButton")
    transactionType:SetPoint("TOPLEFT", 5, -height)
    transactionType:SetPoint("RIGHT", -5, 0)
    transactionType:Justify("LEFT")

    transactionType:SetStyle({ multiSelect = true, hasClear = true })
    transactionType:SetInfo(function()
        local info = {}

        for _, transactionType in addon:pairs({ "buyTab", "deposit", "depositSummary", "move", "repair", "withdraw", "withdrawForTab" }) do
            tinsert(info, {
                id = transactionType,
                text = transactionType,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildID].filters.transactionType.values[transactionType] = dropdown:GetSelected(transactionType) and true or nil
                    LoadTable()
                end,
            })
        end

        return info
    end)

    transactionType:SetCallback("OnClear", function()
        wipe(ReviewTab.guilds[ReviewTab.guildID].filters.transactionType.values)
        LoadTable()
    end)

    transactionType:SetCallback("OnShow", function(self)
        for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildID].filters.transactionType.values) do
            self:SelectByID(value)
        end

        self:SetDisabled(#private.db.global.guilds[ReviewTab.guildID].masterScan == 0)
    end, true)

    height = height + transactionType:GetHeight() + 5

    -----------------------

    divider = content:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetPoint("TOPLEFT", 5, -height)
    divider:SetPoint("RIGHT", -5, 0)
    divider:SetHeight(5)
    divider:SetText(dividerString)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())

    height = height + divider:GetHeight() + 5

    -----------------------

    local nameLabel = content:Acquire("GuildBankSnapshotsFontFrame")
    nameLabel:SetPoint("TOPLEFT", 5, -height)
    nameLabel:SetPoint("RIGHT", -5, 0)
    nameLabel:SetText(L["Name"])
    nameLabel:Justify("LEFT")

    height = height + nameLabel:GetHeight()

    local name = content:Acquire("GuildBankSnapshotsDropdownButton")
    name:SetPoint("TOPLEFT", 5, -height)
    name:SetPoint("RIGHT", -5, 0)
    name:Justify("LEFT")

    name:SetStyle({ multiSelect = true, hasSearch = true, hasClear = true })
    name:SetInfo(function()
        local info = {}

        for name, _ in addon:pairs(ReviewTab.guilds[ReviewTab.guildID].filters.names.list) do
            tinsert(info, {
                id = name,
                text = name,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildID].filters.names.values[name] = dropdown:GetSelected(name) and true or nil
                    LoadTable()
                end,
            })
        end

        return info
    end)

    name:SetCallback("OnClear", function()
        wipe(ReviewTab.guilds[ReviewTab.guildID].filters.names.values)
        LoadTable()
    end)

    name:SetCallback("OnShow", function(self)
        for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildID].filters.names.values) do
            self:SelectByID(value)
        end

        self:SetDisabled(#private.db.global.guilds[ReviewTab.guildID].masterScan == 0)
    end, true)

    height = height + name:GetHeight() + 5

    -----------------------

    divider = content:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetPoint("TOPLEFT", 5, -height)
    divider:SetPoint("RIGHT", -5, 0)
    divider:SetHeight(5)
    divider:SetText(dividerString)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())

    height = height + divider:GetHeight() + 5

    -----------------------

    local itemNameLabel = content:Acquire("GuildBankSnapshotsFontFrame")
    itemNameLabel:SetPoint("TOPLEFT", 5, -height)
    itemNameLabel:SetPoint("RIGHT", -5, 0)
    itemNameLabel:SetText(L["Item"])
    itemNameLabel:Justify("LEFT")

    height = height + itemNameLabel:GetHeight()

    local itemName = content:Acquire("GuildBankSnapshotsDropdownButton")
    itemName:SetPoint("TOPLEFT", 5, -height)
    itemName:SetPoint("RIGHT", -5, 0)
    itemName:Justify("LEFT")

    itemName:SetStyle({ height = "auto", multiSelect = true, hasSearch = true, hasClear = true })
    itemName:SetInfo(function()
        local info = {}

        for itemName, _ in addon:pairs(ReviewTab.guilds[ReviewTab.guildID].filters.itemNames.list) do
            tinsert(info, {
                id = itemName,
                text = itemName,
                func = function(dropdown)
                    ReviewTab.guilds[ReviewTab.guildID].filters.itemNames.values[itemName] = dropdown:GetSelected(itemName) and true or nil
                    LoadTable()
                end,
            })
        end

        return info
    end)

    itemName:SetCallback("OnClear", function()
        wipe(ReviewTab.guilds[ReviewTab.guildID].filters.itemNames.values)
        LoadTable()
    end)

    itemName:SetCallback("OnShow", function(self)
        for value, _ in pairs(ReviewTab.guilds[ReviewTab.guildID].filters.itemNames.values) do
            self:SelectByID(value)
        end

        self:SetDisabled(#private.db.global.guilds[ReviewTab.guildID].masterScan == 0)
    end, true)

    height = height + itemName:GetHeight() + 5

    -----------------------

    divider = content:Acquire("GuildBankSnapshotsFontFrame")
    divider:SetPoint("TOPLEFT", 5, -height)
    divider:SetPoint("RIGHT", -5, 0)
    divider:SetHeight(5)
    divider:SetText(dividerString)
    divider:SetTextColor(private.interface.colors.dimmedWhite:GetRGBA())

    height = height + divider:GetHeight() + 5

    -----------------------

    local rankLabel = content:Acquire("GuildBankSnapshotsFontFrame")
    rankLabel:SetPoint("TOPLEFT", 5, -height)
    rankLabel:SetPoint("RIGHT", -5, 0)
    rankLabel:SetText(L["Item Rank"])
    rankLabel:Justify("LEFT")

    height = height + rankLabel:GetHeight()

    local rank = content:Acquire("GuildBankSnapshotsMinMaxFrame")
    rank:SetPoint("TOPLEFT", 5, -height)
    rank:SetPoint("RIGHT", -5, 0)
    rank:SetMinMaxValues(0, 5, function(self, range, value)
        print(range, value)
    end)

    height = height + rank:GetHeight() + 5

    return height
end

LoadSidebarSorters = function(content, height)
    local enableMultiSort = content:Acquire("GuildBankSnapshotsCheckButton")
    enableMultiSort:SetPoint("TOPLEFT", 5, -height)
    enableMultiSort:SetPoint("RIGHT", -5, 0)

    enableMultiSort:SetText(L["Enable multi-sorting"] .. "*")
    enableMultiSort:SetCallback("OnClick", function(self)
        ReviewTab.guilds[ReviewTab.guildID].multiSort = self:GetChecked()
        LoadTable()
    end)
    enableMultiSort:SetTooltipInitializer(function()
        GameTooltip:AddLine(L["Not recommended for large tables as it may cause the game to freeze for extended periods of time"])
    end)

    enableMultiSort:SetCheckedState(ReviewTab.guilds[ReviewTab.guildID].multiSort)

    height = height + enableMultiSort:GetHeight()

    for sortID, colID in addon:pairs(private.db.global.settings.preferences.sortHeaders) do
        local sorter = content:Acquire("GuildBankSnapshotsTableSorter")
        sorter:SetPoint("TOPLEFT", 5, -height)
        sorter:SetPoint("RIGHT", -5, 0)
        sorter:SetText(tableCols[colID].header)
        sorter:SetSorterData(sortID, addon:tcount(tableCols), function()
            LoadTable()
            LoadSidebar()
        end)

        height = height + sorter:GetHeight() + 2
    end

    return height
end

LoadSidebarTools = function(content, height)
    local tblSize = #private.db.global.guilds[ReviewTab.guildID].masterScan

    local numEntries = content:Acquire("GuildBankSnapshotsFontFrame")
    numEntries:SetPoint("TOPLEFT", 5, -height)
    numEntries:SetPoint("RIGHT", -5, 0)
    numEntries:SetAutoHeight(true)
    numEntries:SetText(format("%s: %s", L["Number of entries"], addon:iformat(tblSize, 1)))
    numEntries:Justify("LEFT")

    height = height + numEntries:GetHeight()

    if tblSize > 5000 then
        local largeTableWarning = content:Acquire("GuildBankSnapshotsFontFrame")
        largeTableWarning:SetPoint("TOPLEFT", 5, -height)
        largeTableWarning:SetPoint("RIGHT", -5, 0)
        largeTableWarning:SetAutoHeight(true)
        largeTableWarning:SetText("*" .. L["Due to this table's large size, reviewing may cause performance issues and possibly Lua errors. It is recommended that you reduce the table size using the cleanup feature. Optionally, you may export the data before purging."])
        largeTableWarning:SetTextColor(1, 0, 0, 1)
        largeTableWarning:Justify("LEFT")

        height = height + largeTableWarning:GetHeight()
    end

    return height
end

LoadTable = function()
    tableContainer = ReviewTab.tableContainer
    if not ReviewTab.guildID then
        tableContainer.scrollBox:Flush()
        return
    end

    tableContainer.scrollView:Initialize(20, LoadRow, "GuildBankSnapshotsContainer")
    local provider = tableContainer:SetDataProvider(function(provider)
        local masterScan = private.db.global.guilds[ReviewTab.guildID].masterScan
        local validEntries = 0

        for transactionID, transaction in ipairs(masterScan) do
            local elementData = transaction.info
            elementData.transactionDate = private:GetTransactionDate(elementData.scanID, elementData.year, elementData.month, elementData.day, elementData.hour)
            elementData.transactionID = transaction.transactionID
            elementData.scanID = transaction.scanID

            -- Filter defaults
            -- tinsert(ReviewTab.guilds[ReviewTab.guildID].filters.transactionDate.list, elementData.transactionDate)
            ReviewTab.guilds[ReviewTab.guildID].filters.names.list[elementData.name] = true
            if elementData.itemLink then
                ReviewTab.guilds[ReviewTab.guildID].filters.itemNames.list[private:GetItemName(elementData.itemLink)] = true
            end

            -- Insert into provider
            if IsQueryMatch(elementData) and not IsFiltered(elementData) then
                validEntries = validEntries + 1
                elementData.entryID = validEntries
                provider:Insert(elementData)

                if validEntries >= ReviewTab.maxEntries then
                    addon:Printf(L["The results of this query exceed the maximum allowed entries (%s); loading has stopped and review data is incomplete. To prevent this error, please limit the query through filters or reduce the size of the table using the cleanup feature (optionally, you may first export the table for use in Excel)."], addon:iformat(ReviewTab.maxEntries, 1))
                    break
                end
            end
        end

        provider:SetSortComparator(function(a, b)
            for sortID, id in ipairs(private.db.global.settings.preferences.sortHeaders) do
                if not ReviewTab.guilds[ReviewTab.guildID].multiSort and sortID > 1 then
                    break
                end

                local sortValue = tableCols[id].sortValue
                local des = private.db.global.settings.preferences.descendingHeaders[id]

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

    return provider:GetSize()
end

------------------------

function private:LoadReviewTab(content)
    local guildDropdown = content:Acquire("GuildBankSnapshotsDropdownButton")
    guildDropdown:SetPoint("TOPLEFT", 10, -10)
    guildDropdown:SetSize(200, 20)
    guildDropdown:SetText(L["Select a guild"])
    guildDropdown:SetBackdropColor(private.interface.colors.darker)
    ReviewTab.guildDropdown = guildDropdown

    guildDropdown:SetInfo(function()
        local info = {}

        local sortKeys = function(a, b)
            return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
        end

        for guildID, guild in addon:pairs(private.db.global.guilds, sortKeys) do
            local text = private:GetGuildDisplayName(guildID)
            tinsert(info, {
                id = guildID,
                text = text,
                isRadio = true,
                func = function()
                    ReviewTab.guildID = guildID
                    ReviewTab.guilds[guildID] = ReviewTab.guilds[guildID] or {
                        searchQuery = false,
                        filters = GetFilters(),
                        multiSort = #private.db.global.guilds[guildID].masterScan < 5000,
                    }
                    LoadTable()
                    LoadSidebar()
                end,
            })
        end

        return info
    end)

    -- Have to set guildDropdown OnShow callback after all main elements are drawn to populate sidebar and tableContainer

    local sidebar = content:Acquire("GuildBankSnapshotsScrollFrame")
    sidebar:SetWidth(guildDropdown:GetWidth())
    sidebar:SetPoint("TOPLEFT", guildDropdown, "BOTTOMLEFT")
    sidebar:SetPoint("BOTTOM", 0, 10)
    sidebar.bg, sidebar.border = private:AddBackdrop(sidebar, { bgColor = "darker" })
    ReviewTab.sidebar = sidebar

    local tableContainer = content:Acquire("GuildBankSnapshotsListScrollFrame")
    tableContainer:SetPoint("TOPLEFT", sidebar, "TOPRIGHT")
    tableContainer:SetPoint("BOTTOMRIGHT", -10, 10)
    tableContainer.bg, tableContainer.border = private:AddBackdrop(tableContainer, { bgColor = "dark" })
    ReviewTab.tableContainer = tableContainer

    local tableHeaders = content:Acquire("GuildBankSnapshotsContainer")
    tableHeaders:SetPoint("TOP", guildDropdown, "TOP")
    tableHeaders:SetPoint("LEFT", tableContainer.scrollBox, "LEFT")
    tableHeaders:SetPoint("RIGHT", tableContainer.scrollBox, "RIGHT")
    tableHeaders:SetPoint("BOTTOM", tableContainer, "TOP")
    tableHeaders.bg, tableHeaders.border = private:AddBackdrop(tableHeaders, { bgColor = "darker" })
    ReviewTab.tableHeaders = ReviewTab.tableHeaders

    tableHeaders:SetCallback("OnSizeChanged", function()
        DrawTableHeaders(tableHeaders)
    end, true)

    -- It's now safe to initialize the dropdown
    guildDropdown:SetCallback("OnShow", function()
        if ReviewTab.guildID then
            guildDropdown:SelectByID(ReviewTab.guildID)
        end
    end, true)
end
