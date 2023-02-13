local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local cols = {
    [1] = {
        header = "Date",
        width = 1,
        des = true,
        text = function(data)
            return date(private.db.global.settings.preferences.dateFormat, private:GetTransactionDate(data.scanID, data.year, data.month, data.day, data.hour))
        end,
        sortValue = function(data)
            return private:GetTransactionDate(data.scanID, data.year, data.month, data.day, data.hour)
        end,
    },
    [2] = {
        header = "Tab",
        width = 1,
        text = function(data)
            return private:GetTabName(private.frame.guildDropdown.selected, data.tabID)
        end,
        sortValue = function(data)
            return private:GetTabName(private.frame.guildDropdown.selected, data.tabID)
        end,
    },
    [3] = {
        header = "Type",
        width = 1,
        text = function(data)
            return data.transactionType
        end,
        sortValue = function(data)
            return data.transactionType
        end,
    },
    [4] = {
        header = "Name",
        width = 1,
        text = function(data)
            return data.name
        end,
        sortValue = function(data)
            return data.name
        end,
    },
    [5] = {
        header = "Item/Amount",
        width = 2.25,
        text = function(data)
            return data.itemLink or GetCoinTextureString(data.amount)
        end,
        icon = function(icon, data)
            if data.itemLink then
                icon:SetPoint("TOPLEFT")
                icon:SetTexture(GetItemIcon(data.itemLink))
                icon:SetSize(12, 12)
                return true
            end
        end,
        tooltip = function(data)
            if data.itemLink then
                GameTooltip:SetHyperlink(data.itemLink)
            else
                GameTooltip:AddLine(GetCoinTextureString(data.amount))
            end
        end,
        sortValue = function(data)
            return data.itemLink or data.amount
        end,
    },
    [6] = {
        header = "Quantity",
        width = 0.5,
        text = function(data)
            return data.count or ""
        end,
        sortValue = function(data)
            return data.count or 0
        end,
    },
    [7] = {
        header = "Move Origin",
        width = 1,
        text = function(data)
            return data.moveOrigin and data.moveOrigin > 0 and private:GetTabName(private.frame.guildDropdown.selected, data.moveOrigin) or ""
        end,
        sortValue = function(data)
            return data.moveOrigin or 0
        end,
    },
    [8] = {
        header = "Move Destination",
        width = 1,
        text = function(data)
            return data.moveDestination and data.moveDestination > 0 and private:GetTabName(private.frame.guildDropdown.selected, data.moveDestination) or ""
        end,
        sortValue = function(data)
            return data.moveDestination or 0
        end,
    },
    [9] = {
        header = "",
        width = 0.25,
        text = function(data)
            return ""
        end,
        icon = function(icon)
            icon:SetPoint("TOP")
            icon:SetTexture(374216)
            icon:SetSize(12, 12)
            return true
        end,
        tooltip = function(data, order)
            GameTooltip:AddLine(format("%s %d", L["Entry"], order))
            GameTooltip:AddDoubleLine(L["Scan Date"], date(private.db.global.settings.preferences.dateFormat, data.scanID))
            GameTooltip:AddDoubleLine(L["Tab ID"], data.tabID)
            GameTooltip:AddDoubleLine(L["Transaction ID"], data.transactionID)
        end,
    },
}

local function ClearTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

function private:InitializeFrame()
    -- [[ Frame ]]
    local frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "SettingsFrameTemplate")
    frame.NineSlice.Text:SetText(L.addonName)
    frame:SetSize(1000, 500)
    frame:SetPoint("CENTER")
    frame:Hide()
    private.frame = frame

    -- Set movable
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Set resizable
    frame:SetResizable(true)
    frame:SetResizeBounds(500, 300, GetScreenWidth() - 400, GetScreenHeight() - 200)

    local resize = CreateFrame("Button", nil, frame)
    resize:SetPoint("BOTTOMRIGHT", -2, 2)
    resize:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
    resize:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
    resize:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
    resize:SetSize(16, 16)
    resize:EnableMouse(true)

    resize:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)

    resize:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    -- [[ Ribbon ]]
    ----------------
    local guildDropdown = LibDD:Create_UIDropDownMenu(addonName .. "GuildDropdown", frame)
    LibDD:UIDropDownMenu_SetWidth(guildDropdown, 150)
    guildDropdown:SetPoint("TOPLEFT", frame.Bg, "TOPLEFT", 10, -10)

    function guildDropdown:SetValue(guildID)
        self.selected = guildID
        LibDD:UIDropDownMenu_SetText(self, private:GetGuildDisplayName(guildID))
        private:LoadTransactions(guildID)
    end

    guildDropdown.info = LibDD:UIDropDownMenu_CreateInfo()
    function guildDropdown:Initialize()
        LibDD:UIDropDownMenu_Initialize(guildDropdown, function(self, level, menuList)
            local info = self.info

            local sortKeys = function(a, b)
                return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
            end

            for guildID, guild in addon:pairs(private.db.global.guilds, sortKeys) do
                info.value = guildID
                info.text = private:GetGuildDisplayName(guildID)
                info.checked = self.selected == guildID
                info.func = function()
                    self:SetValue(guildID)
                end

                LibDD:UIDropDownMenu_AddButton(info)
            end
        end)
    end

    guildDropdown:SetScript("OnShow", function()
        guildDropdown:Initialize()
    end)

    -- Sorting
    frame.sorting = { 1, 2, 4, 3, 5, 6, 7, 8 }

    -- [[ Table ]]
    ---------------------
    local scrollBox = CreateFrame("Frame", nil, frame, "WoWScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

    -- Headers
    frame.headers = {}
    for id, col in addon:pairs(cols) do
        local header = frame.headers[id] or CreateFrame("Button", nil, frame)
        header:SetHeight(20)
        frame.headers[id] = header

        header.debugTex = header.debugTex or header:CreateTexture(nil, "BACKGROUND")
        header.debugTex:SetAllPoints(header)
        header.debugTex:SetColorTexture(fastrandom(), fastrandom(), fastrandom(), 1)
        header.debugTex:Hide()

        header:SetResizable(true)
        header:SetResizeBounds(20, 20)
        header.resize = header.resize or header:CreateTexture(nil, "BACKGROUND")
        header.resize:SetSize(5, header:GetHeight())
        header.resize:SetPoint("RIGHT")
        header.resize:SetColorTexture(0, 0, 0, 0.5)
        header.resize:EnableMouse(true)
        header.resize:SetScript("OnMouseDown", function()
            header:StartSizing("RIGHT")
        end)
        header.resize:SetScript("OnMouseUp", function()
            header:StopMovingOrSizing()
        end)
        header.resize:Hide()

        header.text = header.text or header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header.text:SetPoint("TOPLEFT", 2, -2)
        header.text:SetPoint("BOTTOMRIGHT", -2, 2)
        header.text:SetJustifyH("LEFT")
        header.text:SetJustifyV("BOTTOM")
        header.text:SetText(col.header)

        header:SetScript("OnClick", function()
            local DataProvider = scrollBox:GetDataProvider()
            if DataProvider then
                if col.des then
                    col.des = nil
                else
                    col.des = true
                end

                DataProvider:Sort()
            end
        end)

        function header:DoLayout()
            header:SetPoint("TOP", guildDropdown, "BOTTOM", 0, -10)
            if id == 1 then
                header:SetPoint("LEFT", guildDropdown, "LEFT", 0, 0)
            else
                header:SetPoint("LEFT", frame.headers[id - 1], "RIGHT", 0, 0)
            end
            header:SetWidth((scrollBox.colWidth or 0) * col.width)
        end
    end

    -- Set scrollBox/scrollBar points
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 10)
    scrollBar:SetPoint("TOP", frame.headers[1] or guildDropdown, "BOTTOM", 0, -10)
    scrollBox:SetPoint("TOPLEFT", frame.headers[1] or guildDropdown, "BOTTOMLEFT", 0, -10)
    scrollBox:SetPoint("RIGHT", scrollBar, "LEFT", -10, 0)
    scrollBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)

    -- Create scrollView
    local scrollView = CreateScrollBoxListLinearView()

    scrollView:SetElementExtentCalculator(function()
        return 20
    end)

    scrollView:SetElementInitializer("Frame", function(frame, data)
        frame.bg = frame.bg or frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints(frame)

        frame.cells = frame.cells or {}

        function frame:SetHighlighted(isHighlighted)
            for _, cell in pairs(frame.cells) do
                if isHighlighted then
                    cell.text:SetTextColor(1, 0.82, 0, 1)
                else
                    cell.text:SetTextColor(1, 1, 1, 1)
                end
            end

            if isHighlighted then
                frame.bg:SetColorTexture(0, 0, 0, 0.5)
            else
                frame.bg:SetTexture()
            end
        end

        frame:SetScript("OnEnter", function()
            frame:SetHighlighted(true)
        end)

        frame:SetScript("OnLeave", function()
            frame:SetHighlighted()
        end)

        for id, col in pairs(cols) do
            local cell = frame.cells[id] or CreateFrame("Button", nil, frame)
            frame.cells[id] = cell

            cell.debugTex = cell.debugTex or cell:CreateTexture(nil, "BACKGROUND")
            cell.debugTex:SetAllPoints(cell)
            cell.debugTex:SetColorTexture(fastrandom(), fastrandom(), fastrandom(), 1)
            cell.debugTex:Hide()

            cell.icon = cell.icon or cell:CreateTexture(nil, "ARTWORK")
            cell.icon:ClearAllPoints()
            cell.icon:SetTexture()

            cell.text = cell.text or cell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            cell.text:SetPoint("TOPLEFT", 2, -2)
            cell.text:SetPoint("BOTTOMRIGHT", -2, 2)
            cell.text:SetJustifyH("LEFT")
            cell.text:SetJustifyV("TOP")
            cell.text:SetText(col.text(data))

            if col.icon then
                local success = col.icon(cell.icon, data)
                if success then
                    cell.text:SetPoint("TOPLEFT", cell.icon, "TOPRIGHT", 2, 0)
                end
            end

            function cell:SetPoints()
                cell:SetPoint("TOP")
                if id == 1 then
                    cell:SetPoint("LEFT", 0, 0)
                    cell:SetPoint("RIGHT", frame, "LEFT", scrollBox.colWidth * col.width, 0)
                else
                    cell:SetPoint("LEFT", frame.cells[id - 1], "RIGHT", 0, 0)
                    cell:SetPoint("RIGHT", frame.cells[id - 1], "RIGHT", scrollBox.colWidth * col.width, 0)
                end
                cell:SetPoint("BOTTOM")
            end

            cell:SetScript("OnEnter", function()
                frame:SetHighlighted(true)
                GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
                if col.tooltip then
                    col.tooltip(data, frame:GetOrderIndex())
                else
                    GameTooltip:AddLine(cell.text:GetText())
                end
                GameTooltip:Show()
            end)

            cell:SetScript("OnLeave", function()
                frame:SetHighlighted()
                if col.tooltip then
                    ClearTooltip()
                end
            end)
        end

        function frame:ArrangeCells()
            for _, cell in pairs(frame.cells) do
                cell:SetPoints()
            end
        end

        frame:SetScript("OnSizeChanged", frame.ArrangeCells)
        frame:ArrangeCells()
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

    -- OnSizeChanged scripts
    function frame:ArrangeHeaders()
        for _, header in pairs(frame.headers) do
            header:DoLayout()
        end
    end

    frame:SetScript("OnSizeChanged", frame.ArrangeHeaders)

    scrollBox:SetScript("OnSizeChanged", function(self, width)
        self.width = width
        self.colWidth = width / addon:tcount(cols)
        frame:ArrangeHeaders()

        -- Need this to populate new entries when scrollBox gains height
        scrollBox:Update()
    end)

    -- [[ Post layout ]]
    frame.guildDropdown = guildDropdown
    frame.scrollBox = scrollBox
    scrollBox.scrollBar = scrollBar
    scrollBox.scrollView = scrollView

    -- Select default guild
    -- guildDropdown:SetValue(private.db.global.settings.preferences.defaultGuild)
end

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
        for i = 1, #private.frame.sorting do
            local sortValue = cols[private.frame.sorting[i]].sortValue
            local des = cols[private.frame.sorting[i]].des
            if sortValue(a) > sortValue(b) then
                if des then
                    return true
                else
                    return false
                end
            elseif sortValue(a) < sortValue(b) then
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
