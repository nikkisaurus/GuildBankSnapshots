local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local cols = {
    [1] = {
        header = "",
        width = 0.25,
        text = function(data)
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

            return ""
        end,
    },
    [2] = {
        header = "Date",
        width = 1,
        text = function(data)
            return date(private.db.global.settings.preferences.dateFormat, data.scanID)
        end,
    },
    [3] = {
        header = "Tab",
        width = 1,
        text = function(data)
            return data.tabID
        end,
    },
    [4] = {
        header = "Type",
        width = 1,
        text = function(data)
            return data.transactionType
        end,
    },
    [5] = {
        header = "Name",
        width = 1,
        text = function(data)
            return data.name
        end,
    },
    [6] = {
        header = "Item",
        width = 2,
        text = function(data)
            return data.itemLink
        end,
    },
    [7] = {
        header = "Quantity",
        width = 1,
        text = function(data)
            return data.count
        end,
    },
    [8] = {
        header = "Comments",
        width = 1,
        text = function(data)
            return ""
        end,
    },
}

local function CreateRow(row, data)
    -- Background
    if not row.Bg then
        row.Bg = row:CreateTexture(nil, "BACKGROUND")
        row.Bg:SetAllPoints(row)
    end

    local isEvenRow = mod(row:GetOrderIndex(), 2) == 0
    row.Bg:SetColorTexture(0, 0, 0, isEvenRow and 0.75 or 0.5)

    -- Create cells
    row.cells = row.cells or {}

    for id, col in addon:pairs(cols) do
        local cell = row.cells[id] or row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.cells[id] = cell

        -- Update text
        cell:SetJustifyH("LEFT")
        cell:SetText(col.text(data))

        -- Set points
        if id == 1 then
            cell:SetPoint("TOPLEFT")
        else
            cell:SetPoint("TOPLEFT", row.cells[id - 1], "TOPRIGHT", 0, 0)
        end

        -- Set width
        function cell:DoLayout()
            cell:SetWidth(private.frame.scrollBox.colWidth * col.width)
        end

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

    frame:SetScript("OnSizeChanged", function(self, width)
        for _, header in pairs(frame.headers) do
            header:DoLayout()
        end
    end)

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
    scrollView:SetElementExtentCalculator(function(dataIndex, elementData)
        local height = 0
        for _, col in pairs(cols) do
            extentCalcFrame:SetWidth(scrollBox.colWidth * col.width)
            extentCalcFrame:SetText(col.text(elementData))
            height = max(height, extentCalcFrame:GetStringHeight())
        end

        print("Updating height", height)

        return height
    end)
    scrollView:SetElementInitializer("Frame", CreateRow)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

    -- [[ Post layout ]]
    frame.scrollBox = scrollBox
    scrollBox.scrollBar = scrollBar
    scrollBox.scrollView = scrollView

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
