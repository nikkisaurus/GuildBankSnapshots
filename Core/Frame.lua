local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local AceSerializer = LibStub("AceSerializer-3.0")

-- [[ Col/Headers ]]
-------------
local cols = {
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
            return private:GetTabName(private.frame.guildDD.selected, data.tabID)
        end,
        text = function(data)
            return private:GetTabName(private.frame.guildDD.selected, data.tabID)
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
        icon = function(icon, data)
            if data.itemLink then
                icon:SetPoint("TOPLEFT")
                icon:SetTexture(GetItemIcon(data.itemLink))
                icon:SetSize(12, 12)
                return true
            end
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
            return data.moveOrigin and data.moveOrigin > 0 and private:GetTabName(private.frame.guildDD.selected, data.moveOrigin) or ""
        end,
        width = 1,
    },
    [8] = {
        header = "Move Destination",
        sortValue = function(data)
            return data.moveDestination or 0
        end,
        text = function(data)
            return data.moveDestination and data.moveDestination > 0 and private:GetTabName(private.frame.guildDD.selected, data.moveDestination) or ""
        end,
        width = 1,
    },
    [9] = {
        header = "Scan ID",
        icon = function(icon)
            icon:SetPoint("TOP")
            icon:SetTexture(374216)
            icon:SetSize(12, 12)
            return true
        end,
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

-- [[ Sorter ]]
---------------
local function CreateSorter()
    local sorter = CreateFrame("Frame", nil, private.frame.sorters, "BackdropTemplate")
    sorter:EnableMouse(true)
    sorter:RegisterForDrag("LeftButton")
    sorter:SetHeight(20)

    -- Textures
    private:AddBackdrop(sorter)

    -- Text
    sorter.orderText = private:CreateFontString(sorter)
    sorter.orderText:SetSize(20, 20)
    sorter.orderText:SetPoint("RIGHT", -4, 0)

    sorter.text = private:CreateFontString(sorter)
    sorter.text:SetHeight(20)
    sorter.text:SetPoint("TOPLEFT", 4, -4)
    sorter.text:SetPoint("RIGHT", sorter.orderText, "LEFT", -4, 0)
    sorter.text:SetPoint("BOTTOM", 0, 4)

    -- Methods
    function sorter:IsDescending()
        if not self.colID then
            return
        end

        return private.db.global.settings.preferences.descendingHeaders[self.colID]
    end

    function sorter:SetColID(sorterID, colID)
        self.sorterID = sorterID
        self.colID = colID
        self:UpdateText()
    end

    function sorter:SetDescending(bool)
        if not self.colID then
            return
        end

        private.db.global.settings.preferences.descendingHeaders[self.colID] = bool
    end

    function sorter:UpdateText(insertSorter)
        if not self.colID then
            self.orderText:SetText("")
            self.text:SetText("")
            return
        end

        local order = self:IsDescending() and "▼" or "▲"
        self.orderText:SetText(order)

        local header = cols[self.colID].header
        self.text:SetText(format("%s%s%s", insertSorter or "", insertSorter and " " or "", header))
    end

    function sorter:UpdateWidth()
        self:SetWidth((self:GetParent():GetWidth() - 10) / addon:tcount(cols))
    end

    -- Scripts
    sorter:SetScript("OnDragStart", function(self)
        private.frame.sorters.dragging = self.sorterID
        self:SetBackdropColor(unpack(private.defaults.gui.emphasizeBgColor))
    end)

    sorter:SetScript("OnDragStop", function(self)
        -- Must reset dragging ID in this script in addition to the receiving sorter in case it isn't dropped on a valid sorter
        -- Need to delay to make sure the ID is still accessible to the receiving sorter
        C_Timer.After(1, function()
            private.frame.sorters.dragging = nil
        end)

        sorter:SetBackdropColor(unpack(private.defaults.gui.darkBgColor))
    end)

    sorter:SetScript("OnEnter", function(self)
        -- Emphasize highlighted text
        self.text:SetTextColor(unpack(private.defaults.gui.emphasizeFontColor))

        -- Add indicator for sorting insertion
        local sorterID = self.sorterID
        local draggingID = private.frame.sorters.dragging

        if draggingID and draggingID ~= sorterID then
            if sorterID < draggingID then
                -- Insert before
                self:UpdateText("<")
            else
                -- Insert after
                self:UpdateText(">")
            end

            -- Highlight frame to indicate where dragged header is moving
            sorter:SetBackdropColor(unpack(private.defaults.gui.highlightBgColor))
        end

        -- Show tooltip if text is truncated
        if not self.colID or self.text:GetWidth() > self.text:GetStringWidth() then
            return
        end

        private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, cols)
            GameTooltip:AddLine(cols[self.colID].header, 1, 1, 1)
        end, self, cols)
    end)

    sorter:SetScript("OnLeave", function(self)
        -- Restore default text color
        sorter.text:SetTextColor(unpack(private.defaults.gui.fontColor))

        -- Remove sorting indicator
        self:UpdateText()
        if self.sorterID ~= private.frame.sorters.dragging then
            -- Don't reset backdrop on dragging frame; this is done in OnDragStop
            self:SetBackdropColor(unpack(private.defaults.gui.darkBgColor))
        end

        -- Hide tooltips
        private:ClearTooltip()
    end)

    sorter:SetScript("OnMouseUp", function(self)
        -- Changes sorting order
        self:SetDescending(not private.db.global.settings.preferences.descendingHeaders[sorter.colID])
        self:UpdateText()
        private.frame.scrollBox.Sort()
    end)

    sorter:SetScript("OnReceiveDrag", function(self)
        local sorterID = self.sorterID
        local draggingID = private.frame.sorters.dragging

        if not draggingID or draggingID == sorterID then
            return
        end

        private.frame.sorters.dragging = nil

        -- Get the colID to be inserted and remove the col from the sorting table
        -- The insert will go before/after by default because of the removed entry
        local colID = private.frame.sorters.children[draggingID].colID
        tremove(private.db.global.settings.preferences.sortHeaders, draggingID)
        tinsert(private.db.global.settings.preferences.sortHeaders, sorterID, colID)

        -- Reset sorters based on new order
        self:GetParent():AcquireSorters()
    end)

    return sorter
end

local function ResetSorter(__, sorter)
    sorter.sorterID = nil
    sorter.colID = nil
    sorter:Hide()
end

local Sorter = CreateObjectPool(CreateSorter, ResetSorter)

-- [[ Header ]]
---------------
local function CreateHeader()
    local header = CreateFrame("Frame", nil, private.frame, "BackdropTemplate")
    header:EnableMouse(true)
    header:SetHeight(20)

    -- Textures
    private:AddBackdrop(header, true)

    -- Text
    header.text = private:CreateFontString(header, nil, "BOTTOM")
    header.text:SetPoint("TOPLEFT", 4, -4)
    header.text:SetPoint("BOTTOMRIGHT", -4, 4)

    -- Methods
    function header:SetColID(colID)
        self.colID = colID
        self:UpdateText()
    end

    function header:UpdateText(insertSorter)
        if not self.colID then
            self.text:SetText("")
            return
        end

        self.text:SetText(cols[self.colID].header)
    end

    function header:UpdateWidth()
        header:SetWidth((private.frame.scrollBox.colWidth or 1) * cols[self.colID].width)
    end

    -- Scripts
    header:SetScript("OnEnter", function(self)
        -- Show tooltip if text is truncated
        if not self.colID or self.text:GetWidth() > self.text:GetStringWidth() then
            return
        end

        private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, cols)
            GameTooltip:AddLine(cols[self.colID].header, 1, 1, 1)
        end, self, cols)
    end)

    header:SetScript("OnLeave", function()
        -- Hide tooltips
        private:ClearTooltip()
    end)

    return header
end

local function ResetHeader(_, header)
    header.colID = nil
    header:Hide()
end

local Header = CreateObjectPool(CreateHeader, ResetHeader)

-- [[ Cell ]]
local function CreateCell()
    local cell = CreateFrame("Frame")

    -- Textures
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetTexture()
    cell.icon:ClearAllPoints()

    -- Text
    cell.text = private:CreateFontString(cell, nil, "TOP")
    cell.text:SetPoint("TOPLEFT", 2, -2)
    cell.text:SetPoint("BOTTOMRIGHT", -2, 2)

    -- Methods
    function cell:SetColID(frame, data, colID)
        self:SetParent(frame)
        self.data = data
        self.colID = colID
        self:UpdateIcon()
        self:UpdateText()
    end

    function cell:UpdateIcon()
        self.icon:SetTexture()
        self.icon:ClearAllPoints()
        self.text:SetPoint("TOPLEFT", 2, -2)

        if not self.colID then
            return
        end

        local icon = cols[self.colID].icon

        if not icon then
            return
        end

        local success = icon(self.icon, self.data)
        if success then
            self.text:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
        end
    end

    function cell:UpdateText()
        self.text:SetText("")

        if not self.colID then
            return
        end

        self.text:SetText(cols[self.colID].text(self.data))
    end

    function cell:UpdateSize()
        self:SetSize((private.frame.scrollBox.colWidth or 1) * cols[self.colID].width, self:GetParent():GetHeight())
    end

    -- Scripts
    cell:SetScript("OnEnter", function(self)
        self:GetParent():SetHighlighted(true)

        if not self.colID then
            return
        end

        private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, cols)
            local tooltip = cols[self.colID].tooltip

            if tooltip then
                local success = tooltip(self.data, self:GetParent():GetOrderIndex())

                if success then
                    -- All tooltips should return true to prevent them from being auto-cleared; or I could probably just return for all?
                    return
                end
            end

            if self.text:GetWidth() < self.text:GetStringWidth() then
                GameTooltip:AddLine(self.text:GetText(), 1, 1, 1)
            else
                -- Hide tooltip if not truncated
                private:ClearTooltip()
            end
        end, self, cols)
    end)

    cell:SetScript("OnLeave", function(self)
        self:GetParent():SetHighlighted()

        -- Hide tooltips
        private:ClearTooltip()
    end)

    return cell
end

local function ResetCell(_, cell)
    cell.data = nil
    cell.colID = nil
    cell:Hide()
end

local Cell = CreateObjectPool(CreateCell, ResetCell)

-- [[ Frame ]]
--------------
local function InitializeGuildDropdown(self, level, menuList)
    local info = self.info

    local sortKeys = function(a, b)
        return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
    end

    for guildID, guild in addon:pairs(private.db.global.guilds, sortKeys) do
        info.value = guildID
        info.text = private:GetGuildDisplayName(guildID)
        info.checked = self.selected == guildID
        info.func = function()
            self:SetValue(self, guildID)
        end

        self:AddButton()
    end
end

local function SetGuildDropdown(self, guildID)
    self.selected = guildID
    self:SetText(private:GetGuildDisplayName(guildID))
    private:LoadTransactions(guildID)
end

local function CreateScrollView(frame, data)
    frame.bg = frame.bg or private:AddBackdropTexture(frame)
    frame.cells = frame.cells or {}

    -- Methods
    function frame:AcquireCells()
        for _, cell in pairs(self.cells) do
            Cell:Release(cell)
        end

        for colID, col in addon:pairs(cols) do
            local cell = Cell:Acquire()
            cell:SetColID(self, data, colID)
            cell:Show()

            self.cells[colID] = cell

            if colID == 1 then
                cell:SetPoint("LEFT", self, "LEFT")
            else
                cell:SetPoint("LEFT", self.cells[colID - 1], "RIGHT")
            end
        end

        self:ArrangeCells()
    end

    function frame:ArrangeCells()
        for _, cell in pairs(self.cells) do
            cell:UpdateSize()
        end
    end

    function frame:SetHighlighted(isHighlighted)
        for _, cell in pairs(self.cells) do
            if isHighlighted then
                cell.text:SetTextColor(unpack(private.defaults.gui.emphasizeFontColor))
            else
                cell.text:SetTextColor(unpack(private.defaults.gui.fontColor))
            end
        end

        if isHighlighted then
            self.bg:SetColorTexture(unpack(private.defaults.gui.bgColor))
        else
            self.bg:SetColorTexture(unpack(private.defaults.gui.darkBgColor))
        end
    end

    -- Scripts
    frame:SetScript("OnEnter", function(self)
        self:SetHighlighted(true)
    end)

    frame:SetScript("OnLeave", function(self)
        self:SetHighlighted()
        private:ClearTooltip()
    end)

    frame:SetScript("OnSizeChanged", frame.ArrangeCells)
    frame:AcquireCells()
end

function private:InitializeFrame()
    local frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "SettingsFrameTemplate")
    frame.NineSlice.Text:SetFont(unpack(private.defaults.gui.fontLarge))
    frame.NineSlice.Text:SetText(L.addonName)
    frame:SetSize(1000, 500)
    frame:SetPoint("CENTER")
    frame:Hide()

    private:SetFrameSizing(frame, 500, 300, GetScreenWidth() - 400, GetScreenHeight() - 200)
    private:AddSpecialFrame(frame)
    private.frame = frame

    -- [[ Ribbon ]]
    ----------------
    -- Guild dropdown
    frame.guildDD = private:CreateDropdown(frame, addonName .. "GuildDropdown", SetGuildDropdown, InitializeGuildDropdown)
    frame.guildDD:SetDropdownWidth(200)
    frame.guildDD:SetPoint("TOPLEFT", frame.Bg, "TOPLEFT", 10, -10)
    frame.guildDD:SetScript("OnShow", function(self)
        self:Initialize()
    end)

    -- Sorters
    frame.sorters = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.sorters:SetHeight(30)
    frame.sorters.children = {}

    frame.sorters.text = private:CreateFontString(frame.sorters)
    frame.sorters.text:SetText(L["Sort By Header"])
    frame.sorters.text:SetTextColor(unpack(private.defaults.gui.emphasizeFontColor))

    frame.sorters.text:SetPoint("TOPLEFT", frame.guildDD, "BOTTOMLEFT", 0, -10)
    frame.sorters:SetPoint("TOPLEFT", frame.sorters.text, "BOTTOMLEFT", 0, -2)
    frame.sorters:SetPoint("RIGHT", -10, 0)

    -- [[ Table ]]
    --------------
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WoWScrollBoxList")
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollView = CreateScrollBoxListLinearView()

    -- Headers
    frame.headers = {}
    for colID, col in addon:pairs(cols) do
        local header = Header:Acquire()
        header:SetColID(colID)
        header:Show()

        frame.headers[colID] = header

        header:SetPoint("TOP", frame.sorters, "BOTTOM", 0, -10)
        if colID == 1 then
            header:SetPoint("LEFT", frame.sorters, "LEFT")
        else
            header:SetPoint("LEFT", frame.headers[colID - 1], "RIGHT")
        end
    end

    -- Set scrollBox/scrollBar points
    frame.scrollBar:SetPoint("BOTTOMRIGHT", -10, 10)
    frame.scrollBar:SetPoint("TOP", frame.headers[1], "BOTTOM", 0, -10)
    frame.scrollBox:SetPoint("TOPLEFT", frame.headers[1], "BOTTOMLEFT")
    frame.scrollBox:SetPoint("RIGHT", frame.scrollBar, "LEFT", -10, 0)
    frame.scrollBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)

    -- Create view
    frame.scrollView:SetElementExtent(20)
    frame.scrollView:SetElementInitializer("Frame", CreateScrollView)
    ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)

    -- Methods
    function frame.sorters:AcquireSorters()
        -- Release children
        for _, child in pairs(frame.sorters.children) do
            Sorter:Release(child)
        end

        for sorterID = 1, addon:tcount(cols) do
            local sorter = Sorter:Acquire()
            sorter:SetColID(sorterID, private.db.global.settings.preferences.sortHeaders[sorterID])
            sorter:Show()

            frame.sorters.children[sorterID] = sorter

            if sorterID == 1 then
                sorter:SetPoint("LEFT", frame.sorters, "LEFT", 5, 0)
            else
                sorter:SetPoint("LEFT", frame.sorters.children[sorterID - 1], "RIGHT")
            end
        end

        frame.scrollBox:Sort()
    end

    function frame:UpdateHeaders()
        for _, sorter in pairs(frame.sorters.children) do
            sorter:UpdateWidth()
        end

        for _, header in pairs(frame.headers) do
            header:UpdateWidth()
        end
    end

    function frame.scrollBox:Sort()
        local DataProvider = frame.scrollBox:GetDataProvider()
        if DataProvider then
            DataProvider:Sort()
        end
    end

    -- Scripts
    frame.scrollBox:SetScript("OnSizeChanged", function(self, width)
        self.width = width
        self.colWidth = width / addon:tcount(cols)
        frame:UpdateHeaders()

        -- Need this to populate new entries when scrollBox gains height
        frame.scrollBox:Update()
    end)

    -- [[ Post layout ]]
    frame.sorters:AcquireSorters()
    frame:UpdateHeaders()
    frame.guildDD:SetValue(frame.guildDD, private.db.global.settings.preferences.defaultGuild)
end

function private:LoadFrame()
    private.frame:Show()
end

-- [[ Data Provider ]]
----------------------
function private:LoadTransactions(guildID)
    local scrollBox = private.frame.scrollBox

    -- Clear transactions if no guildID is provided
    if not guildID then
        scrollBox:Flush()
        return
    end

    local DataProvider = CreateDataProvider()

    for scanID, scan in pairs(private.db.global.guilds[guildID].scans) do
        for tabID, tab in pairs(scan.tabs) do
            for transactionID, transaction in pairs(tab.transactions) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

                DataProvider:Insert({
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

            DataProvider:Insert({
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

    DataProvider:SetSortComparator(function(a, b)
        for i = 1, addon:tcount(private.db.global.settings.preferences.sortHeaders) do
            local id = private.db.global.settings.preferences.sortHeaders[i]
            local sortValue = cols[id].sortValue
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

    scrollBox:SetDataProvider(DataProvider)
end
