local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local cols = {
    [1] = {
        header = "",
        width = 0.25,
    },
    [2] = {
        header = "Date",
        width = 1,
    },
    [3] = {
        header = "Tab",
        width = 1,
    },
    [4] = {
        header = "Type",
        width = 1,
    },
    [5] = {
        header = "Name",
        width = 1,
    },
    [6] = {
        header = "Item",
        width = 2,
    },
    [7] = {
        header = "Quantity",
        width = 1,
    },
    [8] = {
        header = "Comments",
        width = 1,
    },
}

local function CreateRow(row, data)
    if not row.Bg then
        row.Bg = row:CreateTexture(nil, "BACKGROUND")
        row.Bg:SetAllPoints(row)
    end

    local hasBg = mod(row:GetOrderIndex(), 2) == 0
    row.Bg:SetColorTexture(0, 0, 0, hasBg and 0.75 or 0.5)

    row.cells = row.cells or {}

    for id, col in addon:pairs(cols) do
        local cell = row.cells[id] or row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.cells[id] = cell
        cell:SetJustifyH("LEFT")
        cell:SetText(col.header)
        if id == 1 then
            cell:SetPoint("LEFT", 0, 0)
        else
            cell:SetPoint("LEFT", row.cells[id - 1], "RIGHT", 0, 0)
        end

        cell:SetWidth((row:GetWidth() / addon:tcount(cols)) * col.width)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(cell)
        bg:SetColorTexture(fastrandom(), fastrandom(), fastrandom(), 1)
    end

    -- Create columns
    -- local width = 0
    -- for i = 1, addon:tcount(cols) do
    --     local colWidth = (frame:GetWidth() / addon:tcount(cols)) * cols[i].width
    --     local text = frame["text" .. i] or frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    --     text:SetWidth(colWidth)
    --     text:SetPoint("LEFT", width, 0)
    --     text:SetJustifyH("LEFT")
    --     width = width + colWidth
    --     frame["text" .. i] = text
    -- end

    -- -- transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour
    -- frame.text1:SetText(date(private.db.global.settings.preferences.dateFormat, data.scanID))
    -- frame.text2:SetText(data.tabID)
    -- frame.text3:SetText(data.transactionType)
    -- frame.text4:SetText(data.name)
    -- frame.text5:SetText(data.itemLink)
    -- frame.text6:SetText(data.count)
    -- frame.text7:SetText()
    -- frame.text8:SetText()
    -- -- if not frame.text then
    -- --     frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- --     frame.text:SetAllPoints(frame)
    -- --     frame.text:SetJustifyH("LEFT")
    -- -- end

    -- frame:SetScript("OnEnter", function()
    --     GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    --     GameTooltip:AddDoubleLine("Scan Date", date(private.db.global.settings.preferences.dateFormat, data.scanID))
    --     GameTooltip:AddDoubleLine("Tab", data.tabID)
    --     GameTooltip:AddDoubleLine("Transaction ID", data.transactionID)
    --     GameTooltip:Show()
    -- end)
    -- frame:SetScript("OnLeave", function()
    --     GameTooltip:ClearLines()
    --     GameTooltip:Hide()
    -- end)
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

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Set resizable
    frame:SetResizable(true)
    frame:SetResizeBounds(500, 300, GetScreenWidth() - 400, GetScreenHeight() - 200)

    local resize = CreateFrame("Button", nil, frame)
    resize:EnableMouse(true)
    resize:SetPoint("BOTTOMRIGHT", -2, 2)
    resize:SetSize(16, 16)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    resize:SetScript("OnMouseDown", function(self)
        frame:StartSizing("BOTTOMRIGHT")
    end)

    resize:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        -- private:LoadTransactions(frame.guildDropdown.selected)
    end)

    -- [[ Ribbon ]]
    ----------------
    -- Select guild
    local guildDropdown = LibDD:Create_UIDropDownMenu("MyDropDownMenu", frame)
    LibDD:UIDropDownMenu_SetWidth(guildDropdown, 150)
    guildDropdown:SetPoint("TOPLEFT", frame.Bg, "TOPLEFT", 10, -10)
    -- frame.guildDropdown = guildDropdown

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

    frame:SetScript("OnSizeChanged", function(self, width)
        for _, header in pairs(frame.headers) do
            header:DoLayout()
        end

        frame.scrollView:Rebuild()
        -- self.scrollBox:SetDataProvider(self.scrollBox:GetDataProvider())
    end)

    -- Create scrollBox
    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    local scrollBox = CreateFrame("ScrollFrame", nil, frame, "WoWScrollBoxList")
    frame.scrollBox = scrollBox
    scrollBox.scrollBar = scrollBar

    -- Set points
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 10)
    scrollBar:SetPoint("TOP", frame.headers[1] or guildDropdown, "BOTTOM", 0, -10)
    scrollBox:SetPoint("TOPLEFT", frame.headers[1] or guildDropdown, "BOTTOMLEFT", 0, -10)
    scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -10, 0)

    -- View
    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(20)
    scrollView:SetElementInitializer("Frame", CreateRow)
    frame.scrollView = scrollView
    ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, scrollView)

    -- [[ Post layout ]]
    guildDropdown:SetValue(private.db.global.settings.preferences.defaultGuild)
end

function private:LoadTransactions(guildID)
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
    -- for i = 1, 100000 do
    --     DataProvider:Insert({
    --         id = i,
    --         text = "Line " .. i,
    --         color = CreateColor(fastrandom(), 0, 0, 1),
    --     })
    -- end

    -- DataProvider:SetSortComparator(function(a, b)
    --     return a.id > b.id
    -- end)

    private.frame.scrollBox:SetDataProvider(DataProvider)
end
