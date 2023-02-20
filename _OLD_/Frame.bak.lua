-- [[ Col/Headers ]]
-------------

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
        self:SetBackdropColor(private.interface.colors.dimmedClass:GetRGBA())
    end)

    sorter:SetScript("OnDragStop", function(self)
        -- Must reset dragging ID in this script in addition to the receiving sorter in case it isn't dropped on a valid sorter
        -- Need to delay to make sure the ID is still accessible to the receiving sorter
        C_Timer.After(1, function()
            private.frame.sorters.dragging = nil
        end)

        sorter:SetBackdropColor(private.interface.colors.bgColorDark:GetRGBA())
    end)

    sorter:SetScript("OnEnter", function(self)
        -- Emphasize highlighted text
        self.text:SetFontObject(private.interface.fonts.emphasizedFont)

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
            sorter:SetBackdropColor(private.interface.colors.highlightColor:GetRGBA())
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
        sorter.text:SetFontObject(private.interface.fonts.normalFont)

        -- Remove sorting indicator
        self:UpdateText()
        if self.sorterID ~= private.frame.sorters.dragging then
            -- Don't reset backdrop on dragging frame; this is done in OnDragStop
            self:SetBackdropColor(private.interface.colors.bgColorDark:GetRGBA())
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
    sorter:SetBackdropColor(private.interface.colors.bgColorDark:GetRGBA())
    sorter:Hide()
end

local Sorter = CreateObjectPool(CreateSorter, ResetSorter)

self.bg = self.bg or private:AddBackdropTexture(self)
self.cells = self.cells or {}

-- Methods
function self:AcquireCells()
    for _, cell in pairs(self.cells) do
        Cell:Release(cell)
    end

    for colID, col in addon:pairs(reviewData) do
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

function self:ArrangeCells()
    for _, cell in pairs(self.cells) do
        cell:UpdateSize()
    end
end

function self:SetHighlighted(isHighlighted)
    for _, cell in pairs(self.cells) do
        if isHighlighted then
            cell.text:SetFontObject(private.interface.fonts.emphasizedFont)
        else
            cell.text:SetFontObject(private.interface.fonts.normalFont)
        end
    end

    if isHighlighted then
        self.bg:SetColorTexture(private.interface.colors.highlightColor:GetRGBA())
    else
        self.bg:SetColorTexture(private.interface.colors.bgColorDark:GetRGBA())
    end
end

-- Scripts
self:SetScript("OnEnter", function(self)
    self:SetHighlighted(true)
end)

self:SetScript("OnLeave", function(self)
    self:SetHighlighted()
    private:ClearTooltip()
end)

self:SetScript("OnSizeChanged", self.ArrangeCells)
self:AcquireCells()
-- -- [[ Cell ]]
-- local function CreateCell()
--     local cell = CreateFrame("Frame")

--     -- Textures
--     cell.icon = cell:CreateTexture(nil, "ARTWORK")
--     cell.icon:SetTexture()
--     cell.icon:ClearAllPoints()

--     -- Text
--     cell.text = private:CreateFontString(cell, nil, "TOP")
--     cell.text:SetPoint("TOPLEFT", 2, -2)
--     cell.text:SetPoint("BOTTOMRIGHT", -2, 2)

--     -- Methods
--     function cell:SetColID(frame, data, colID)
--         self:SetParent(frame)
--         self.data = data
--         self.colID = colID
--         self:UpdateIcon()
--         self:UpdateText()
--     end

--     function cell:UpdateIcon()
--         self.icon:SetTexture()
--         self.icon:ClearAllPoints()
--         self.text:SetPoint("TOPLEFT", 2, -2)

--         if not self.colID then
--             return
--         end

--         local icon = reviewData[self.colID].icon

--         if not icon then
--             return
--         end

--         local success = icon(self.icon, self.data)
--         if success then
--             self.text:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
--         end
--     end

--     function cell:UpdateText()
--         self.text:SetText("")

--         if not self.colID then
--             return
--         end

--         self.text:SetText(reviewData[self.colID].text(self.data))
--     end

--     function cell:UpdateSize()
--         self:SetSize((private.frame.scrollBox.colWidth or 1) * reviewData[self.colID].width, self:GetParent():GetHeight())
--     end

--     -- Scripts
--     cell:SetScript("OnEnter", function(self)
--         self:GetParent():SetHighlighted(true)

--         if not self.colID then
--             return
--         end

--         private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, reviewData)
--             local tooltip = reviewData[self.colID].tooltip

--             if tooltip then
--                 local success = tooltip(self.data, self:GetParent():GetOrderIndex())

--                 if success then
--                     -- All tooltips should return true to prevent them from being auto-cleared; or I could probably just return for all?
--                     return
--                 end
--             end

--             if self.text:GetWidth() < self.text:GetStringWidth() then
--                 GameTooltip:AddLine(self.text:GetText(), 1, 1, 1)
--             else
--                 -- Hide tooltip if not truncated
--                 private:ClearTooltip()
--             end
--         end, self, reviewData)
--     end)

--     cell:SetScript("OnLeave", function(self)
--         self:GetParent():SetHighlighted()

--         -- Hide tooltips
--         private:ClearTooltip()
--     end)

--     return cell
-- end

-- local function ResetCell(_, cell)
--     cell.data = nil
--     cell.colID = nil
--     cell:Hide()
-- end

-- local Cell = CreateObjectPool(CreateCell, ResetCell)
-- [[ Header ]]
---------------
local function CreateHeader()
    local header = CreateFrame("Frame", nil, private.frame, "BackdropTemplate")
    header:EnableMouse(true)
    header:SetHeight(20)

    -- Textures
    private:AddBackdrop(header, "bgColorLight")

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

local function CreateScrollView(frame, data) end

-- ScrollUtil.InitScrollBoxWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)

-- -- Sorters
-- frame.sorters = CreateFrame("Frame", nil, frame, "BackdropTemplate")
-- frame.sorters:SetHeight(30)
-- frame.sorters.children = {}

-- frame.sorters.text = private:CreateFontString(frame.sorters)
-- frame.sorters.text:SetText(L["Sort By Header"])
-- frame.sorters.text:SetFontObject(private.interface.fonts.emphasizedFont)

-- frame.sorters.text:SetPoint("TOPLEFT", frame.guildDD, "BOTTOMLEFT", 0, -10)
-- frame.sorters:SetPoint("TOPLEFT", frame.sorters.text, "BOTTOMLEFT", 0, -2)
-- frame.sorters:SetPoint("RIGHT", -10, 0)

-- -- [[ Table ]]
-- --------------
-- frame.scrollBox = CreateFrame("Frame", nil, frame, "WoWScrollBoxList")
-- frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
-- frame.scrollView = CreateScrollBoxListLinearView()

-- -- Headers
-- frame.headers = {}
-- for colID, col in addon:pairs(cols) do
--     local header = Header:Acquire()
--     header:SetColID(colID)
--     header:Show()

--     frame.headers[colID] = header

--     header:SetPoint("TOP", frame.sorters, "BOTTOM", 0, -10)
--     if colID == 1 then
--         header:SetPoint("LEFT", frame.sorters, "LEFT")
--     else
--         header:SetPoint("LEFT", frame.headers[colID - 1], "RIGHT")
--     end
-- end

-- -- Set scrollBox/scrollBar points
-- frame.scrollBar:SetPoint("BOTTOMRIGHT", -10, 10)
-- frame.scrollBar:SetPoint("TOP", frame.headers[1], "BOTTOM", 0, -10)
-- frame.scrollBox:SetPoint("TOPLEFT", frame.headers[1], "BOTTOMLEFT")
-- frame.scrollBox:SetPoint("RIGHT", frame.scrollBar, "LEFT", -10, 0)
-- frame.scrollBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)

-- -- Create view
-- frame.scrollView:SetElementExtent(20)
-- frame.scrollView:SetElementInitializer("Frame", CreateScrollView)
-- ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)

-- -- Methods
-- function frame.sorters:AcquireSorters()
--     -- Release children
--     for _, child in pairs(frame.sorters.children) do
--         Sorter:Release(child)
--     end

--     for sorterID = 1, addon:tcount(cols) do
--         local sorter = Sorter:Acquire()
--         sorter:SetColID(sorterID, private.db.global.settings.preferences.sortHeaders[sorterID])
--         sorter:Show()

--         frame.sorters.children[sorterID] = sorter

--         if sorterID == 1 then
--             sorter:SetPoint("LEFT", frame.sorters, "LEFT", 5, 0)
--         else
--             sorter:SetPoint("LEFT", frame.sorters.children[sorterID - 1], "RIGHT")
--         end
--     end

--     frame.scrollBox:Sort()
-- end

-- function frame:UpdateHeaders()
--     for _, sorter in pairs(frame.sorters.children) do
--         sorter:UpdateWidth()
--     end

--     for _, header in pairs(frame.headers) do
--         header:UpdateWidth()
--     end
-- end

-- function frame.scrollBox:Sort()
--     local DataProvider = frame.scrollBox:GetDataProvider()
--     if DataProvider then
--         DataProvider:Sort()
--     end
-- end
-- frame.scrollBox:SetScript("OnSizeChanged", function(self, width)
--     self.width = width
--     self.colWidth = width / addon:tcount(cols)
--     frame:UpdateHeaders()

--     -- Need this to populate new entries when scrollBox gains height
--     frame.scrollBox:Update()
-- end)

-- -- [[ Post layout ]]
-- frame.sorters:AcquireSorters()
-- frame:UpdateHeaders()
-- frame.guildDD:SetValue(frame.guildDD, private.db.global.settings.preferences.defaultGuild)
