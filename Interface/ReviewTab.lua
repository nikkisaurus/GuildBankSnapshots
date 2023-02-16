local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

-- [[ Data ]]
--------------
local reviewData = {
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
            return private:GetTabName(data.selected, data.tabID)
        end,
        text = function(data)
            return private:GetTabName(data.selected, data.tabID)
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
                return true
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
            return data.moveOrigin and data.moveOrigin > 0 and private:GetTabName(data.selected, data.moveOrigin) or ""
        end,
        width = 1,
    },
    [8] = {
        header = "Move Destination",
        sortValue = function(data)
            return data.moveDestination or 0
        end,
        text = function(data)
            return data.moveDestination and data.moveDestination > 0 and private:GetTabName(data.selected, data.moveDestination) or ""
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

            return true
        end,
        width = 0.25,
    },
}

function private:LoadReviewTab(content)
    local guildDD = content.frames:Acquire(addonName .. "DropdownButton")
    guildDD:SetPoint("TOPLEFT", 10, -10)
    guildDD:SetSize(200, 20)
    guildDD:SetText(guildDD.selected or L["Select a guild"])
    guildDD.onClick = function()
        if addon:tcount(private.db.global.guilds) > 0 then
            guildDD:ToggleMenu(function()
                local sortKeys = function(a, b)
                    return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
                end

                for guildID, guild in addon:pairs(private.db.global.guilds, sortKeys) do
                    guildDD.menu:AddLine({
                        text = private:GetGuildDisplayName(guildID),
                        checked = function()
                            return guildDD.selected == guildID
                        end,
                        isRadio = true,
                        func = function()
                            guildDD:SetValue(guildID, function(dropdown, guildID)
                                dropdown:SetText(private:GetGuildDisplayName(guildID))
                                private:InitializeDataProvider(guildDD.main, function(provider)
                                    private:LoadTransactions(provider, guildID)
                                end)
                            end)
                        end,
                    })
                end
            end)
        end
    end
    guildDD:SetScript("OnShow", function(self)
        if self.selected then
            private:InitializeDataProvider(self.main, function(provider)
                private:LoadTransactions(provider, self.selected)
            end)
            -- TODO Update scrollbox
        end
    end)

    guildDD:Show()

    local sidebar = content.frames:Acquire(addonName .. "LinearScrollFrame")
    sidebar:SetPoint("TOPLEFT", guildDD, "BOTTOMLEFT", 0, 0)
    sidebar:SetPoint("RIGHT", guildDD, "RIGHT")
    sidebar:SetPoint("BOTTOM", 0, 10)
    private:AddBackdrop(sidebar, "bgColor")
    sidebar:Show()

    -- for i = 1, 1000 do
    --     local test = sidebar.frames:Acquire(addonName .. "FontFrame")
    --     test:SetHeight(20)
    --     test:SetPoint("TOPLEFT", 5, -(20 * (i - 1)))
    --     test:SetPoint("RIGHT", -5, 0)
    --     test:SetText("Testing cows and stuff and things and stuff " .. i)
    --     test:SetJustifyH("LEFT")
    --     test:Show()
    -- end

    -- sidebar.content:MarkDirty()

    local headers = content.frames:Acquire(addonName .. "CollectionFrame")
    headers:SetPoint("TOPLEFT", guildDD, "TOPRIGHT", 5, 0)
    headers:SetPoint("RIGHT", -10, 0)
    headers:SetPoint("BOTTOM", guildDD, "BOTTOM")
    private:AddBackdrop(headers, "bgColor")
    headers:Show()

    local main = content.frames:Acquire(addonName .. "ListScrollFrame")
    main:SetPoint("TOPLEFT", headers, "BOTTOMLEFT")
    main:SetPoint("BOTTOMRIGHT", -10, 10)
    private:AddBackdrop(main, "bgColor")
    guildDD.main = main
    main:Show()

    main.extent = 20
    main.initializer = function(frame, elementData)
        frame.bg = frame.bg or frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints(frame)

        frame.cells = frame.cells or {}
        frame.pool = frame.pool or private:GetPool("Button", frame, addonName .. "ReviewCell")

        -- Methods
        function frame:AcquireCells()
            self:ReleaseCells()

            for dataID, data in addon:pairs(reviewData) do
                cell = self.pool:Acquire()
                cell:SetParent(self)
                self.cells[dataID] = cell
                cell:Show()

                cell:SetSize(self:GetWidth() / addon:tcount(reviewData) * reviewData[dataID].width, self:GetHeight())

                if dataID == 1 then
                    cell:SetPoint("LEFT")
                else
                    cell:SetPoint("LEFT", self.cells[dataID - 1], "RIGHT")
                end

                cell.data = data
                cell.elementData = elementData
                cell:Update()
            end
        end

        function frame:ReleaseCells()
            for dataID, cell in pairs(self.cells) do
                self.pool:Release(cell)
            end
        end

        -- Scripts
        frame:SetScript("OnEnter", function(self)
            private:SetColorTexture(self.bg, "highlightColor")
        end)

        frame:SetScript("OnLeave", function(self)
            self.bg:SetTexture()
        end)

        frame:SetScript("OnSizeChanged", function(self)
            self:AcquireCells()
        end)

        -- Acquire cells
        frame:AcquireCells()
    end
end

function private:LoadTransactions(provider, guildID)
    if not provider or not guildID then
        return
    end

    local AceSerializer = LibStub("AceSerializer-3.0")

    for scanID, scan in pairs(private.db.global.guilds[guildID].scans) do
        for tabID, tab in pairs(scan.tabs) do
            for transactionID, transaction in pairs(tab.transactions) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

                provider:Insert({
                    selected = guildID,
                    scanID = scanID,
                    tabID = tabID,
                    transactionID = transactionID,
                    transactionType = transactionType,
                    name = name,
                    itemLink = itemLink,
                    count = count,
                    moveOrigin = moveOrigin,
                    moveDestination = moveDestination,
                    year = year,
                    month = month,
                    day = day,
                    hour = hour,
                })
            end
        end

        for transactionID, transaction in pairs(scan.moneyTransactions) do
            local transactionType, name, amount, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

            provider:Insert({
                selected = guildID,
                scanID = scanID,
                tabID = MAX_GUILDBANK_TABS + 1,
                transactionID = transactionID,
                transactionType = transactionType,
                name = name,
                amount = amount,
                year = year,
                month = month,
                day = day,
                hour = hour,
            })
        end
    end

    provider:SetSortComparator(function(a, b)
        for i = 1, addon:tcount(private.db.global.settings.preferences.sortHeaders) do
            local id = private.db.global.settings.preferences.sortHeaders[i]
            local sortValue = reviewData[id].sortValue
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
end
