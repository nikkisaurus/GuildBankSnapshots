local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local FiltersMixin = {
    duplicates = {
        value = true,
        func = function(self, elementData)
            -- TODO filter duplicates
        end,
    },

    names = {
        list = {},
        values = {},
        func = function(self, elementData)
            if addon:tcount(self.values) == 0 then
                return
            end

            for _, data in pairs(self.values) do
                if elementData.name == data.text then
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

            for _, data in pairs(self.values) do
                if elementData.transactionType == data.text then
                    return
                end
            end

            return true
        end,
    },
}

local ReviewTab
function private:InitializeReviewTab()
    ReviewTab = {
        guildID = private.db.global.settings.preferences.defaultGuild,
        searchQuery = false,
        searchKeys = { "itemLink", "name", "moveDestinationName", "moveOriginName", "tabName", "transactionType" },
        filters = {},
    }
end

--*----------[[ Data ]]----------*--
local sidebarSections = {
    {
        header = L["Sorting"],
        collapsed = false,
        onLoad = function(content, height)
            for i = 1, 8 do
                local test = content:Acquire("GuildBankSnapshotsFontFrame")
                test:SetPoint("TOPLEFT", 5, -height)
                test:SetPoint("RIGHT", -5, 0)
                test:SetText("Sorting stuff " .. i)
                test:Justify("LEFT")
                test:Show()
                height = height + test:GetHeight()
            end

            return height
        end,
    },
    {
        header = L["Filters"],
        collapsed = false,
        onLoad = function(content, height)
            local duplicates = content:Acquire("GuildBankSnapshotsCheckButton")
            duplicates:SetPoint("TOPLEFT", 5, -height)
            duplicates:SetPoint("RIGHT", -5, 0)

            duplicates:SetText(L["Remove duplicates"] .. "*")
            duplicates:SetCallback("OnClick", function(self)
                ReviewTab.filters[ReviewTab.guildID].duplicates.value = self:GetChecked()
            end)
            duplicates:SetTooltipInitializer(function()
                GameTooltip:AddLine(L["Experimental"])
            end)

            duplicates:SetCheckedState(ReviewTab.filters[ReviewTab.guildID].duplicates.value)

            height = height + duplicates:GetHeight()

            local transactionTypeLabel = content:Acquire("GuildBankSnapshotsFontFrame")
            transactionTypeLabel:SetPoint("TOPLEFT", 5, -height)
            transactionTypeLabel:SetPoint("RIGHT", -5, 0)
            transactionTypeLabel:SetText(L["Transaction Type"])
            transactionTypeLabel:SetFontObject(GameFontNormalSmall)
            transactionTypeLabel:Justify("LEFT")
            transactionTypeLabel:Show()

            height = height + transactionTypeLabel:GetHeight()

            local transactionType = content:Acquire("GuildBankSnapshotsDropdownButton")
            transactionType:SetPoint("TOPLEFT", 5, -height)
            transactionType:SetPoint("RIGHT", -5, 0)
            transactionType:Justify("LEFT")

            transactionType:SetMultiSelect(true)
            transactionType:SetInfo(function()
                local info = {}

                for _, transactionType in addon:pairs({ "buyTab", "deposit", "depositSummary", "repair", "withdraw", "withdrawForTab" }) do
                    tinsert(info, {
                        value = transactionType,
                        text = transactionType,
                        func = function(dropdown, buttonID, elementData)
                            if not dropdown then
                                return
                            end

                            if dropdown.selected[buttonID] then
                                ReviewTab.filters[ReviewTab.guildID].transactionType.values[buttonID] = elementData
                            else
                                ReviewTab.filters[ReviewTab.guildID].transactionType.values[buttonID] = nil
                            end

                            private:LoadTable()
                        end,
                    })
                end

                return info
            end)

            for buttonID, data in pairs(ReviewTab.filters[ReviewTab.guildID].transactionType.values) do
                transactionType:SelectValue(data.value, true)
            end

            height = height + transactionType:GetHeight() + 5

            local nameLabel = content:Acquire("GuildBankSnapshotsFontFrame")
            nameLabel:SetPoint("TOPLEFT", 5, -height)
            nameLabel:SetPoint("RIGHT", -5, 0)
            nameLabel:SetText(L["Name"])
            nameLabel:SetFontObject(GameFontNormalSmall)
            nameLabel:Justify("LEFT")
            nameLabel:Show()

            height = height + nameLabel:GetHeight()

            local name = content:Acquire("GuildBankSnapshotsDropdownButton")
            name:SetPoint("TOPLEFT", 5, -height)
            name:SetPoint("RIGHT", -5, 0)
            name:Justify("LEFT")

            name:SetStyle({
                hasSearch = true,
            })
            name:SetMultiSelect(true)
            name:SetInfo(function()
                local info = {}

                for name, _ in addon:pairs(ReviewTab.filters[ReviewTab.guildID].names.list) do
                    tinsert(info, {
                        value = name,
                        text = name,
                        func = function(dropdown, buttonID, elementData)
                            if not dropdown then
                                return
                            end

                            if dropdown.selected[buttonID] then
                                ReviewTab.filters[ReviewTab.guildID].names.values[buttonID] = elementData
                            else
                                ReviewTab.filters[ReviewTab.guildID].names.values[buttonID] = nil
                            end

                            private:LoadTable()
                        end,
                    })
                end

                return info
            end)

            for buttonID, data in pairs(ReviewTab.filters[ReviewTab.guildID].names.values) do
                name:SelectValue(data.value, true)
            end

            height = height + name:GetHeight() + 5

            return height
        end,
    },
    {
        header = L["Tools"],
        collapsed = false,
        onLoad = function(content, height)
            for i = 1, 1 do
                local test = content:Acquire("GuildBankSnapshotsFontFrame")
                test:SetPoint("TOPLEFT", 5, -height)
                test:SetPoint("RIGHT", -5, 0)
                test:SetText("Tools stuff " .. i)
                test:Justify("LEFT")
                test:Show()
                height = height + test:GetHeight()
            end

            return height
        end,
    },
}

local tableCols = {
    [1] = {
        header = "Date",
        sortValue = function(data)
            return private:GetTransactionDate(data.scanID, data.year, data.month, data.day, data.hour)
        end,
        text = function(data)
            return date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(data.scanID, data.year, data.month, data.day, data.hour))
        end,
        width = 1,
    },
    [2] = {
        header = "Tab",
        sortValue = function(data)
            return private:GetTabName(ReviewTab.guildID, data.tabID)
        end,
        text = function(data)
            return private:GetTabName(ReviewTab.guildID, data.tabID)
        end,
        width = 1,
    },
    [3] = {
        header = "Type",
        sortValue = function(data)
            return data.transactionType
        end,
        text = function(data)
            return data.transactionType
        end,
        width = 1,
    },
    [4] = {
        header = "Name",
        sortValue = function(data)
            return data.name
        end,
        text = function(data)
            return data.name
        end,
        width = 1,
    },
    [5] = {
        header = "Item/Amount",
        icon = function(data)
            return data.itemLink and GetItemIcon(data.itemLink)
        end,
        sortValue = function(data)
            local itemString = select(3, strfind(data.itemLink or "", "|H(.+)|h"))
            local itemName = select(3, strfind(itemString or "", "%[(.+)%]"))
            return itemName or data.amount
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
        header = "Quantity",
        sortValue = function(data)
            return data.count or 0
        end,
        text = function(data)
            return data.count or ""
        end,
        width = 0.5,
    },
    [7] = {
        header = "Move Origin",
        sortValue = function(data)
            return data.moveOrigin or 0
        end,
        text = function(data)
            return data.moveOrigin and data.moveOrigin > 0 and private:GetTabName(ReviewTab.guildID, data.moveOrigin) or ""
        end,
        width = 1,
    },
    [8] = {
        header = "Move Destination",
        sortValue = function(data)
            return data.moveDestination or 0
        end,
        text = function(data)
            return data.moveDestination and data.moveDestination > 0 and private:GetTabName(ReviewTab.guildID, data.moveDestination) or ""
        end,
        width = 1,
    },
    [9] = {
        header = "Scan ID",
        icon = 374216,
        sortValue = function(data)
            return data.scanID
        end,
        text = function(data)
            return ""
        end,
        tooltip = function(data, order)
            GameTooltip:AddLine(format("%s %d", L["Entry"], order))
            GameTooltip:AddDoubleLine(L["Scan Date"], date(private.db.global.settings.preferences.dateFormat, data.scanID), nil, nil, nil, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Tab ID"], data.tabID, nil, nil, nil, 1, 1, 1)
            GameTooltip:AddDoubleLine(L["Transaction ID"], data.transactionID, nil, nil, nil, 1, 1, 1)

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

--*----------[[ Local functions ]]----------*--
local function DrawTableHeaders(self)
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

local function IsFiltered(elementData)
    for filterID, filter in pairs(ReviewTab.filters[ReviewTab.guildID]) do
        if filter.func(filter, elementData) then
            return true
        end
    end

    return
end

local function IsQueryMatch(elementData)
    if not ReviewTab.searchQuery then
        return true
    end

    for _, key in pairs(ReviewTab.searchKeys) do
        local found = elementData[key] and strfind(strupper(elementData[key]), strupper(ReviewTab.searchQuery))
        if found then
            return true
        end
    end
end

local function LoadRow(row, elementData)
    row.bg = row.bg or row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)

    row:SetCallback("OnEnter", function(self)
        private:SetColorTexture(self.bg, "highlightColor")
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

--*----------[[ Methods ]]----------*--
function private:LoadReviewTab(content)
    local guildDropdown = content:Acquire("GuildBankSnapshotsDropdownButton")
    guildDropdown:SetPoint("TOPLEFT", 10, -10)
    guildDropdown:SetSize(200, 20)
    guildDropdown:SetText(L["Select a guild"])
    ReviewTab.guildDropdown = guildDropdown

    guildDropdown:SetInfo(function()
        local info = {}

        local sortKeys = function(a, b)
            return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
        end

        for guildID, guild in addon:pairs(private.db.global.guilds, sortKeys) do
            local text = private:GetGuildDisplayName(guildID)
            tinsert(info, {
                value = guildID,
                text = text,
                isRadio = true,
                checked = function()
                    return guildID == ReviewTab.guildID
                end,
                func = function()
                    ReviewTab.guildID = guildID
                    ReviewTab.filters[guildID] = ReviewTab.filters[guildID] or addon:CloneTable(FiltersMixin)
                    private:LoadTable()
                    private:LoadSidebar()
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
    private:AddBackdrop(sidebar, "bgColor")
    ReviewTab.sidebar = sidebar

    local tableContainer = content:Acquire("GuildBankSnapshotsListScrollFrame")
    tableContainer:SetPoint("TOPLEFT", sidebar, "TOPRIGHT")
    tableContainer:SetPoint("BOTTOMRIGHT", -10, 10)
    private:AddBackdrop(tableContainer.scrollBox)
    ReviewTab.tableContainer = tableContainer

    local tableHeaders = content:Acquire("GuildBankSnapshotsCollectionFrame")
    tableHeaders:SetPoint("BOTTOMLEFT", tableContainer.scrollBox, "TOPLEFT")
    tableHeaders:SetPoint("RIGHT", tableContainer.scrollBox, "RIGHT")
    tableHeaders:SetPoint("TOP", guildDropdown, "TOP")
    private:AddBackdrop(tableHeaders)
    ReviewTab.tableHeaders = ReviewTab.tableHeaders

    tableHeaders:SetCallback("OnSizeChanged", function()
        DrawTableHeaders(tableHeaders)
    end, true)

    -- It's now safe to initialize the dropdown
    guildDropdown:SetCallback("OnShow", function()
        if ReviewTab.guildID then
            guildDropdown:SelectValue(ReviewTab.guildID, true)
        end
    end, true)
end

function private:LoadSidebar()
    local sidebar = ReviewTab.sidebar
    local content = sidebar.content
    content:ReleaseAll()

    local height = 0

    local searchBox = content:Acquire("GuildBankSnapshotsSearchBox")
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOPLEFT", 10, -height)
    searchBox:SetPoint("TOPRIGHT", -5, -height)

    searchBox:SetCallback("OnTextChanged", function(self, userInput)
        local text = self:GetText()

        if userInput then
            ReviewTab.searchQuery = self:IsValidText() and text
            private:LoadTable()
        end
    end)

    if ReviewTab.searchQuery then
        searchBox:SetText(ReviewTab.searchQuery)
    end

    height = height + searchBox:GetHeight() + 10

    for sectionID, info in addon:pairs(sidebarSections) do
        local header = content:Acquire("GuildBankSnapshotsButton")
        header:SetHeight(20)
        header:SetText(info.header)

        header:SetPoint("TOPLEFT", 5, -height)
        header:SetPoint("RIGHT", -5, 0)

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

            private:LoadSidebar()
        end)
    end

    content:MarkDirty()
    sidebar.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
end

function private:LoadTable()
    tableContainer = ReviewTab.tableContainer
    tableContainer.scrollView:Initialize(20, LoadRow, "GuildBankSnapshotsCollectionFrame")
    tableContainer:SetDataProvider(function(provider)
        local masterScan = private.db.global.guilds[ReviewTab.guildID].masterScan
        for transactionID, transaction in ipairs(masterScan) do
            local elementData = transaction.info
            elementData.scanID = transaction.scanID

            ReviewTab.filters[ReviewTab.guildID].names.list[elementData.name] = true

            if IsQueryMatch(elementData) and not IsFiltered(elementData) then
                provider:Insert(elementData)
            end
        end

        -- provider:SetSortComparator(function(a, b)
        --     for i = 1, addon:tcount(private.db.global.settings.preferences.sortHeaders) do
        --         local id = private.db.global.settings.preferences.sortHeaders[i]
        --         local sortValue = tableCols[id].sortValue
        --         local des = private.db.global.settings.preferences.descendingHeaders[id]

        --         local sortA = sortValue(a)
        --         local sortB = sortValue(b)

        --         if type(sortA) ~= type(sortB) then
        --             sortA = tostring(sortA)
        --             sortB = tostring(sortB)
        --         end

        --         if sortA > sortB then
        --             if des then
        --                 return true
        --             else
        --                 return false
        --             end
        --         elseif sortA < sortB then
        --             if des then
        --                 return false
        --             else
        --                 return true
        --             end
        --         end
        --     end
        -- end)

        print(provider:GetSize())
    end)
end
