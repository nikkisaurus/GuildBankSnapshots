local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local LibDD = LibStub("LibDropDown")

local dropdownMenus = {}
local pools = {}

function private:GetPool(...)
    local frameTemplate = select(3, ...)
    if not frameTemplate then
        return
    end

    if not pools[frameTemplate] then
        pools[frameTemplate] = CreateFramePool(...)
    end

    return pools[frameTemplate]
end

function private:MixinCollection(frame, parent, ignoreRelease)
    local frameCollection = CreateFramePoolCollection()
    frame.frames = Mixin({}, frameCollection)

    function frame:ReleaseChildren()
        self.frames:ReleaseAll()
    end

    if not ignoreRelease then
        frame:SetScript("OnHide", function(self)
            self:ReleaseChildren()
        end)
    end

    frameCollection:CreatePool("Frame", parent or frame, addonName .. "CollectionFrame")
    frameCollection:CreatePool("Frame", parent or frame, addonName .. "FontFrame")
    frameCollection:CreatePool("Frame", parent or frame, addonName .. "LinearScrollFrame")
    frameCollection:CreatePool("Frame", parent or frame, addonName .. "ListScrollFrame")

    frameCollection:CreatePool("EditBox", parent or frame, addonName .. "SearchBox", function(_, editbox)
        editbox.onEnterPressed = nil
        editbox.onTextChanged = nil
        editbox.clear = nil

        editbox:SetText("")
        editbox:ClearAllPoints()
        editbox:Hide()
    end)

    frameCollection:CreatePool("Button", parent or frame, addonName .. "Button", function(_, button)
        button.onClick = nil

        button:ClearAllPoints()
        button:Hide()
    end)
    frameCollection:CreatePool("Button", parent or frame, addonName .. "DropdownButton", function(_, dropdown)
        LibDD:CloseAll()

        -- Clear userdata
        dropdown.onClick = nil
        dropdown.onShow = nil

        -- Restore defaults
        dropdown:HideButton()
        dropdown:SetJustify()

        dropdown:ClearAllPoints()
        dropdown:Hide()
    end)
end

function GuildBankSnapshotsCollectionFrame_OnLoad(frame)
    private:MixinCollection(frame)
end

function GuildBankSnapshotsFontFrame_OnLoad(frame)
    frame:EnableMouse(true)

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetJustifyH("LEFT")

    -- Methods
    function frame:SetFontObject(fontObject)
        self.text:SetFontObject(fontObject)
    end

    function frame:SetJustifyH(justifyH)
        self.text:SetJustifyH(justifyH)
    end

    function frame:SetPadding(x, y)
        self.text:ClearAllPoints()
        self.text:SetPoint("TOPLEFT", self, "TOPLEFT", x, -y)
        self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -x, y)
    end

    function frame:SetText(text)
        self.text:SetText(text)
    end

    -- Scripts
    frame:SetScript("OnEnter", function(self)
        if self.text:GetStringWidth() > self.text:GetWidth() then
            -- Get truncated text
            private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                GameTooltip:AddLine(self.text:GetText(), 1, 1, 1)
            end, self)
        end
    end)

    frame:SetScript("OnHide", function(self)
        self:SetPadding(0, 0)
    end)

    frame:SetScript("OnLeave", function()
        -- Hide tooltips
        private:ClearTooltip()
    end)

    -- Defaults
    frame:SetPadding(0, 0)
end

function GuildBankSnapshotsLinearScrollFrame_OnLoad(frame)
    -- scrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -5)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    frame.scrollBar:SetFrameLevel(1)

    -- scrollBox
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBox")
    frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)

    -- scrollView
    frame.scrollView = CreateScrollBoxLinearView()
    frame.scrollView:SetPanExtent(50)

    -- Content
    frame.content = CreateFrame("Frame", nil, frame.scrollBox, "ResizeLayoutFrame")
    private:MixinCollection(frame, frame.content)
    frame.content.scrollable = true
    frame.content:SetAllPoints(frame.scrollBox)
    frame.content:Show()

    frame.content:SetScript("OnSizeChanged", function()
        frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
    end)

    -- ScrollUtil
    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 5, -5),
        CreateAnchor("BOTTOMRIGHT", frame.scrollBar, "BOTTOMLEFT", -5, 5),
    }

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 5, -5),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5),
    }

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar, anchorsWithBar, anchorsWithoutBar)
    ScrollUtil.InitScrollBoxWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)
end

function GuildBankSnapshotsListScrollFrame_OnLoad(frame)
    -- scrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -5)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    frame.scrollBar:SetFrameLevel(1)

    -- scrollBox
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WoWScrollBoxList")
    frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)

    -- scrollView
    frame.scrollView = CreateScrollBoxListLinearView()
    frame.scrollView:SetElementExtentCalculator(function()
        return frame.extent or 20
    end)
    frame.scrollView:SetElementInitializer("Frame", function(element, data)
        if frame.initializer then
            frame.initializer(element, data)
        end
    end)

    -- Content
    frame.content = CreateFrame("Frame", nil, frame.scrollBox, "ResizeLayoutFrame")
    private:MixinCollection(frame, frame.content)
    frame.content.scrollable = true
    frame.content:SetAllPoints(frame.scrollBox)
    frame.content:Show()

    frame.content:SetScript("OnSizeChanged", function()
        frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
    end)

    -- ScrollUtil
    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 5, -5),
        CreateAnchor("BOTTOMRIGHT", frame.scrollBar, "BOTTOMLEFT", -5, 5),
    }

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 5, -5),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5),
    }

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar, anchorsWithBar, anchorsWithoutBar)
    ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)

    -- Methods and scripts
    function frame:SetDataProvider(callback)
        local DataProvider = CreateDataProvider()

        callback(DataProvider)

        self.scrollBox:SetDataProvider(DataProvider)
    end

    frame:SetScript("OnHide", function(self)
        self.extent = nil
        self.initializer = nil
        self.scrollBox:Flush()
    end)
end

function GuildBankSnapshotsSearchBox_OnLoad(editbox)
    editbox:SetTextInsets(editbox.searchIcon:GetWidth() + 4, editbox.clearButton:GetWidth() + 4, 2, 2)

    editbox:HookScript("OnEnterPressed", function(self)
        if self.onEnterPressed then
            self.onEnterPressed(self)
        end
    end)

    editbox:HookScript("OnTextChanged", function(self)
        if self.onTextChanged then
            self.onTextChanged(self)
        end
    end)

    editbox.clearButton:HookScript("OnClick", function()
        if editbox.clear then
            editbox.clear(editbox)
        end
    end)

    -- function SearchBoxTemplate_OnEditFocusLost(self)
    --     if ( self:GetText() == "" ) then
    --         self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
    --         self.clearButton:Hide();
    --     end
    -- end

    -- function SearchBoxTemplate_OnEditFocusGained(self)
    --     self.searchIcon:SetVertexColor(1.0, 1.0, 1.0);
    --     self.clearButton:Show();
    -- end

    -- function SearchBoxTemplate_OnTextChanged(self)
    --     if ( not self:HasFocus() and self:GetText() == "" ) then
    --         self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
    --         self.clearButton:Hide();
    --     else
    --         self.searchIcon:SetVertexColor(1.0, 1.0, 1.0);
    --         self.clearButton:Show();
    --     end
    --     InputBoxInstructions_OnTextChanged(self);
    -- end
end

function GuildBankSnapshotsButton_OnLoad(button)
    button:SetSize(150, 20)

    -- Textures
    button.border = button:CreateTexture(nil, "BACKGROUND")
    button.border:SetAllPoints(button)
    button.border:SetColorTexture(0, 0, 0, 1)

    button:SetNormalTexture(button:CreateTexture(nil, "ARTWORK"))
    button.bg = button:GetNormalTexture()
    button.bg:SetColorTexture(0.1, 0.1, 0.1, 1)
    button.bg:SetPoint("TOPLEFT", button.border, "TOPLEFT", 1, -1)
    button.bg:SetPoint("BOTTOMRIGHT", button.border, "BOTTOMRIGHT", -1, 1)

    button:SetHighlightTexture(button:CreateTexture(nil, "ARTWORK"))
    button.highlight = button:GetHighlightTexture()
    button.highlight:SetColorTexture(0.2, 0.2, 0.2, 1)
    button.highlight:SetAllPoints(button.bg)

    -- Text
    button:SetNormalFontObject("GameFontNormal")

    -- Scripts
    button:SetScript("OnClick", function(self)
        if self.onClick then
            self.onClick(self)
        end
    end)
end

function GuildBankSnapshotsDropdownButton_OnLoad(dropdown)
    dropdown:SetSize(150, 20)

    -- Textures
    dropdown.border = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.border:SetAllPoints(dropdown)
    dropdown.border:SetColorTexture(0, 0, 0, 1)

    dropdown:SetNormalTexture(dropdown:CreateTexture(nil, "ARTWORK"))
    dropdown.bg = dropdown:GetNormalTexture()
    dropdown.bg:SetColorTexture(0.1, 0.1, 0.1, 1)
    dropdown.bg:SetPoint("TOPLEFT", dropdown.border, "TOPLEFT", 1, -1)
    dropdown.bg:SetPoint("BOTTOMRIGHT", dropdown.border, "BOTTOMRIGHT", -1, 1)

    dropdown:SetHighlightTexture(dropdown:CreateTexture(nil, "ARTWORK"))
    dropdown.highlight = dropdown:GetHighlightTexture()
    dropdown.highlight:SetColorTexture(0.2, 0.2, 0.2, 1)
    dropdown.highlight:SetAllPoints(dropdown.bg)

    dropdown.arrow = dropdown:CreateTexture(nil, "ARTWORK", nil, 7)
    dropdown.arrow:SetSize(20, 20)
    dropdown.arrow:SetPoint("RIGHT", -5)
    dropdown.arrow:SetTexture(136961)
    dropdown.arrow:SetTexCoord(4 / 64, 27 / 64, 8 / 64, 24 / 64)
    dropdown.arrow:SetVertexColor(1, 1, 1, 1)

    -- Text
    dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dropdown.text:SetHeight(20)
    dropdown.text:SetJustifyH("RIGHT")
    dropdown.text:SetWordWrap(false)
    dropdown.text:SetPoint("LEFT", 5, 0)
    dropdown.text:SetPoint("RIGHT", dropdown.arrow, "LEFT", -5, 0)

    -- Menu
    dropdown.menu = LibDD:NewMenu(dropdown, addonName .. "DropdownMenu" .. (#dropdownMenus + 1))
    dropdown.menu:SetAnchor("TOP", dropdown, "BOTTOM", 0, -10)
    dropdown.menu:SetStyle(addonName)
    dropdown.menu:SetCheckAlignment("LEFT")
    dropdown.menu.dropdown = dropdown
    tinsert(dropdownMenus, dropdown.menu)

    -- Methods
    function dropdown:HideButton(hide)
        if hide then
            dropdown.arrow:Hide()
        else
            dropdown.arrow:Show()
        end
    end

    function dropdown:SetJustify(h, v)
        self.text:SetJustifyH(h or "RIGHT")
        self.text:SetJustifyV(v or "MIDDLE")
    end

    function dropdown:SetText(text)
        self.text:SetText(text)
    end

    function dropdown:SetValue(value, callback)
        self.selected = value
        if type(callback) == "function" then
            callback(self, value)
        end
    end

    function dropdown:ToggleMenu(callback)
        if type(callback) ~= "function" then
            return
        end

        self.menu:ClearLines()
        callback()
        self.menu:Toggle()
    end

    -- Scripts
    dropdown:SetScript("OnClick", function(self)
        if self.onClick then
            self.onClick(self)
        end
    end)

    dropdown:SetScript("OnShow", function(self)
        if self.onShow then
            self.onShow(self)
        end
    end)
end

function GuildBankSnapshotsReviewCell_OnLoad(cell)
    -- Textures
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetSize(12, 12)

    -- Text
    cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cell.text:SetJustifyH("LEFT")
    cell.text:SetJustifyV("TOP")

    function cell:Reset()
        self.icon:SetTexture()
        self.icon:ClearAllPoints()
        self.text:SetText("")
        self.text:ClearAllPoints()
    end

    function cell:Update()
        self:Reset()

        local data = self.data
        if data then
            self.text:SetText(data.text(self.elementData))
            self.text:SetPoint("TOPLEFT")
            self.text:SetPoint("BOTTOMRIGHT")

            if data.icon then
                local icon = data.icon
                if type(data.icon) == "function" then
                    icon = data.icon(self.elementData)
                end

                if icon then
                    self.icon:SetTexture(icon)
                    self.icon:SetPoint("TOPLEFT")
                    self.text:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
                end
            end
        end
    end

    -- Scripts
    cell:SetScript("OnEnter", function(self, ...)
        -- Enable row highlight
        local parent = self:GetParent()
        parent:GetScript("OnEnter")(parent, ...)

        -- Highlight text
        cell.text:SetFontObject(GameFontNormal)

        local data = self.data
        if not data then
            return
        end

        -- Show tooltips
        if data.tooltip then
            private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, data)
                GameTooltip:AddLine(data.tooltip(self.elementData), 1, 1, 1)
            end, self, data)
        elseif cell.text:GetStringWidth() > cell:GetWidth() then
            -- Get truncated text
            private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, data)
                GameTooltip:AddLine(data.text(self.elementData), 1, 1, 1)
            end, self, data)
        end
    end)

    cell:SetScript("OnHide", function(self)
        self.data = nil
        self.elementData = nil
        self:Update()
        self.text:SetFontObject(GameFontHighlight)
    end)

    cell:SetScript("OnLeave", function(self, ...)
        -- Disable row highlight
        local parent = self:GetParent()
        parent:GetScript("OnLeave")(parent, ...)

        -- Unhighlight text
        cell.text:SetFontObject(GameFontHighlight)

        -- Hide tooltips
        private:ClearTooltip()
    end)
end
