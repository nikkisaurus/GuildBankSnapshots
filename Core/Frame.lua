local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local cols = {
    [1] = {
        header = "Date",
        width = 1,
        text = function(data)
            return date(private.db.global.settings.preferences.dateFormat, data.scanID)
        end,
    },
    [2] = {
        header = "Tab",
        width = 1,
        text = function(data)
            return private:GetTabName(private.frame.guildDropdown.selected, data.tabID)
        end,
    },
    [3] = {
        header = "Type",
        width = 1,
        text = function(data)
            return data.transactionType
        end,
    },
    [4] = {
        header = "Name",
        width = 1,
        text = function(data)
            return data.name
        end,
    },
    [5] = {
        header = "Item",
        width = 1.5,
        text = function(data)
            return data.itemLink
        end,
        icon = function(tex, data)
            tex:SetPoint("TOPLEFT")
            tex:SetTexture(GetItemIcon(data.itemLink))
            tex:SetSize(12, 12)
        end,
        tooltip = function(data)
            GameTooltip:SetHyperlink(data.itemLink)
        end,
    },
    [6] = {
        header = "Quantity",
        width = 1,
        text = function(data)
            return data.count
        end,
    },
    [7] = {
        header = "Comments",
        width = 1,
        text = function(data)
            return ""
        end,
    },
    [8] = {
        header = "",
        width = 0.25,
        text = function(data)
            return ""
        end,
        icon = function(tex)
            tex:SetPoint("TOP")
            tex:SetTexture(374216)
            tex:SetSize(12, 12)
        end,
        tooltip = function(data)
            GameTooltip:AddDoubleLine("Scan Date", date(private.db.global.settings.preferences.dateFormat, data.scanID))
            GameTooltip:AddDoubleLine("Tab", data.tabID)
            GameTooltip:AddDoubleLine("Transaction ID", data.transactionID)
        end,
    },
}

local function ClearTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

local function CreateRow(row, data)
    -- [[ Background ]]
    if not row.bg then
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
    end

    row.bgAlpha = mod(row:GetOrderIndex(), 2) == 0 and 0.75 or 0.5
    row.bg:SetColorTexture(0, 0, 0, row.bgAlpha)

    -- [[ Create cells ]]
    row.cells = row.cells or {}

    for id, col in addon:pairs(cols) do
        local cell = row.cells[id] or CreateFrame("Button", nil, row)
        row.cells[id] = cell

        -- Set points
        if id == 1 then
            cell:SetPoint("TOPLEFT")
        else
            cell:SetPoint("TOPLEFT", row.cells[id - 1], "TOPRIGHT", 0, 0)
        end

        -- Set width
        function cell:DoLayout()
            cell:SetWidth(private.frame.scrollBox.colWidth * col.width)
            cell:SetHeight(cell.text:GetStringHeight())
        end

        -- Update text
        cell:SetPushedTextOffset(0, 0)
        cell.text = cell.text or cell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cell.text:SetPoint("LEFT")
        cell.text:SetPoint("RIGHT")
        cell.text:SetJustifyH("LEFT")
        cell.text:SetJustifyV("TOP")
        cell.text:SetText(col.text(data))

        -- Icon
        cell.icon = cell.icon or cell:CreateTexture(nil, "BACKGROUND")
        cell.icon:SetTexture()
        if col.icon then
            col.icon(cell.icon, data)
            cell.text:SetPoint("LEFT", cell.icon, "RIGHT", 1, 0)
        end

        -- Tooltips
        cell:SetScript("OnEnter", function(self)
            row.bg:SetColorTexture(1, 1, 1, 0.25)
            if col.tooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                col.tooltip(data)
                GameTooltip:Show()
            end
        end)

        cell:SetScript("OnLeave", function()
            row.bg:SetColorTexture(0, 0, 0, row.bgAlpha)
            if col.tooltip then
                ClearTooltip()
            end
        end)

        -- Hyperlinks
        cell:SetHyperlinksEnabled(true)
        cell:SetScript("OnHyperlinkClick", function(self, link, text, button)
            SetItemRef(link, text, button, self)
        end)
        cell:SetScript("OnHyperLinkEnter", function(self, link)
            row.bg:SetColorTexture(1, 1, 1, 0.25)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end)
        cell:SetScript("OnHyperLinkLeave", function()
            row.bg:SetColorTexture(0, 0, 0, row.bgAlpha)
            if col.tooltip then
                ClearTooltip()
            end
        end)

        -- Initialize width
        cell:DoLayout()
    end

    -- Update cells OnSizeChanged
    row:SetScript("OnSizeChanged", function(self)
        for _, cell in pairs(self.cells) do
            cell:DoLayout()
        end
    end)
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

    -- [[ Table ]]
    ---------------------
    -- Headers
    frame.headers = {}
    for id, col in addon:pairs(cols) do
        local header = frame.headers[id] or frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.headers[id] = header
        header:SetJustifyH("LEFT")
        header:SetText(col.header)
        if id == 1 then
            header:SetPoint("TOPLEFT", guildDropdown, "BOTTOMLEFT", 0, -10) -- ! Change anchor here when elements are added
        else
            header:SetPoint("LEFT", frame.headers[id - 1], "RIGHT", 0, 0)
        end

        function header:DoLayout()
            local contentWidth = frame:GetWidth() - 68
            local colWidth = (contentWidth / addon:tcount(cols)) * col.width
            header:SetWidth(colWidth)
        end
    end

    -- Create scrollBox
    local scrollBox = CreateFrame("Frame", nil, frame, "WoWScrollBoxList")
    scrollBox:SetScript("OnSizeChanged", function(self, width)
        self.colWidth = width / addon:tcount(cols)
    end)

    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

    -- Set scrollBox/scrollBar points
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 10)
    scrollBar:SetPoint("TOP", frame.headers[1] or guildDropdown, "BOTTOM", 0, -10)
    scrollBox:SetPoint("TOPLEFT", frame.headers[1] or guildDropdown, "BOTTOMLEFT", 0, -10)
    scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -10, 0)

    -- Create scrollView
    local scrollView = CreateScrollBoxListLinearView()
    local extentCalcFrame = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scrollView:SetElementExtent(20)
    -- scrollView:SetElementExtentCalculator(function(dataIndex, elementData)
    --     local height = 0
    --     for _, col in pairs(cols) do
    --         extentCalcFrame:SetWidth(scrollBox.colWidth * col.width)
    --         extentCalcFrame:SetText(col.text(elementData))
    --         height = max(height, extentCalcFrame:GetStringHeight())
    --     end

    --     print("Updating height", height)

    --     return height
    -- end)
    scrollView:SetElementInitializer("Frame", CreateRow)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

    -- [[ Post layout ]]
    frame.guildDropdown = guildDropdown
    frame.scrollBox = scrollBox
    scrollBox.scrollBar = scrollBar
    scrollBox.scrollView = scrollView

    frame:SetScript("OnSizeChanged", function(self, width)
        for _, header in pairs(frame.headers) do
            header:DoLayout()
        end
    end)

    -- Select default guild
    guildDropdown:SetValue(private.db.global.settings.preferences.defaultGuild)
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
    end

    scrollBox:SetDataProvider(DataProvider)
end
