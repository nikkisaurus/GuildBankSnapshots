local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*----------[[ Collection pool ]]----------*--
local function Resetter(_, self)
    if self.Reset then
        self:Reset()
    else
        self:ClearAllPoints()
        self:Hide()
    end
end

local CollectionMixin = {}

function CollectionMixin:InitPools(parent)
    self.pool = CreateFramePoolCollection()
    self.pool:CreatePool("Button", parent or self, "GuildBankSnapshotsButton", Resetter)
    self.pool:CreatePool("Frame", parent or self, "GuildBankSnapshotsCollectionFrame", Resetter)
    self.pool:CreatePool("Button", parent or self, "GuildBankSnapshotsDropdownButton", Resetter)
    self.pool:CreatePool("Button", parent or self, "GuildBankSnapshotsDropdownListButton", Resetter)
    self.pool:CreatePool("Frame", parent or self, "GuildBankSnapshotsFontFrame", Resetter)
    self.pool:CreatePool("Frame", parent or self, "GuildBankSnapshotsListScrollFrame", Resetter)
    self.pool:CreatePool("Frame", parent or self, "GuildBankSnapshotsScrollFrame", Resetter)
    self.pool:CreatePool("EditBox", parent or self, "GuildBankSnapshotsSearchBox", Resetter)
    self.pool:CreatePool("Button", parent or self, "GuildBankSnapshotsTableCell", Resetter)
    self.pool:CreatePool("Button", parent or self, "GuildBankSnapshotsTabButton", Resetter)
end

--*----------[[ Mixins ]]----------*--
local DropdownMenuMixin = {}

function DropdownMenuMixin:DrawButtons()
    self:ReleaseAll()

    local style = self.style
    self:SetHeight(min(#self.info * (style.buttonHeight + style.paddingY), style.maxButtons * (style.buttonHeight + style.paddingY)))

    local listFrame = self:Acquire("GuildBankSnapshotsListScrollFrame")
    listFrame:SetAllPoints(self)

    listFrame.scrollView:Initialize(style.buttonHeight, function(frame, elementData)
        frame.menu = self
        frame.dropdown = frame.menu.dropdown

        frame:SetStyle(style)
        frame:SetElementData(elementData)
    end, "GuildBankSnapshotsDropdownListButton")

    listFrame:SetDataProvider(function(provider)
        provider:InsertTable(self.info)
    end)
end

function DropdownMenuMixin:InitStyle()
    self.style = {
        width = "auto",
        buttonHeight = 20,
        buttonHighlight = CreateColor(1, 0.82, 0, 0.25),
        maxButtons = 10,
        anchor = "TOPLEFT",
        relAnchor = "BOTTOMLEFT",
        xOffset = 0,
        yOffset = 0,
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        paddingX = 3,
        paddingY = 3,
        hasCheckBox = true,
        checkAlignment = "LEFT",
    }
end

function DropdownMenuMixin:SetAnchors()
    self:SetPoint(self.style.anchor, self:GetParent(), self.style.relAnchor, self.style.xOffset, self.style.yOffset)
end

function DropdownMenuMixin:SetMenuWidth()
    self:SetWidth(self.style.width == "auto" and self:GetParent():GetWidth() or self.style.width)
end

-----------------------

local TextMixin = {}

local function TextMixin_Validate(self)
    return assert(self.text, "TextMixin: text has not been initialized")
end

function TextMixin:Justify(justifyH, justifyV)
    TextMixin_Validate(self)
    self.text:SetJustifyH(justifyH or "CENTER")
    self.text:SetJustifyV(justifyV or "MIDDLE")
end

function TextMixin:SetAutoHeight(autoHeight)
    TextMixin_Validate(self)
    self.autoHeight = autoHeight
end

function TextMixin:SetFontObject(fontObject)
    TextMixin_Validate(self)
    self.text:SetFontObject(fontObject or GameFontNormalSmall)
end

function TextMixin:SetPadding(x, y)
    TextMixin_Validate(self)
    self.text:ClearAllPoints()
    self.text:SetPoint("TOPLEFT", self, "TOPLEFT", x, -y)
    self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -x, y)
end

function TextMixin:SetText(text)
    TextMixin_Validate(self)
    self.text:SetText(text or "")
    if self.autoHeight then
        self:SetHeight(self.text:GetStringHeight() + 8)
    end
end

function TextMixin:SetWordWrap(canWordWrap)
    TextMixin_Validate(self)
    self.text:SetWordWrap(canWordWrap or "")
end

-----------------------

local WidgetMixin = {}

function WidgetMixin:Fire(script, ...)
    if script == "OnAcquire" and self.scripts.OnAcquire then
        self.scripts.OnAcquire(self)
    else
        if self.scripts[script] then
            self.scripts[script](self, ...)
        end

        if self.handlers[script] then
            self.handlers[script](self, ...)
        end
    end
end

function WidgetMixin:InitializeScripts()
    for script, callback in pairs(self.scripts) do
        local success, err = pcall(self.SetScript, self, script, callback)
        if success then
            self:SetScript(script, callback)
        end
    end
end

function WidgetMixin:InitScripts(scripts)
    self.handlers = {}
    self.scripts = scripts or {}

    self:InitializeScripts()
end

function WidgetMixin:Reset()
    self:Fire("OnRelease")

    for script, callback in pairs(self.handlers) do
        local success, err = pcall(self.SetScript, self, script, callback)
        if success then
            self:SetScript(script, nil)
        end
    end

    wipe(self.handlers)

    self:ClearAllPoints()
    self:Hide()
end

function WidgetMixin:SetCallback(script, callback, init)
    local success, err = pcall(self.SetScript, self, script, callback)
    assert(success or script == "OnRelease", "WidgetMixin: invalid script")
    assert(type(callback) == "function", callback and "WidgetMixin: callback must be a function" or "WidgetMixin: attempting to create empty callback")

    self.handlers[script] = callback
    local existingScript = self.scripts[script]
    if success then
        self:SetScript(script, function(...)
            if existingScript then
                existingScript(...)
            end

            callback(...)
        end)
    end

    if init then
        callback(self)
    end
end

-----------------------

local ContainerMixin = Mixin({}, WidgetMixin)
ContainerMixin:InitScripts()

function ContainerMixin:Acquire(template, parent)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")

    local object = self.pool:Acquire(template)
    object:Fire("OnAcquire")
    object:SetParent(parent or self)
    object:Show()

    return object
end

function ContainerMixin:EnumerateActive()
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    return self.pool:EnumerateActive()
end

function ContainerMixin:EnumerateActiveByTemplate(template)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    return self.pool:EnumerateActiveByTemplate(template)
end

function ContainerMixin:Release(object)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    self.pool:Release(object)
end

function ContainerMixin:ReleaseAll()
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    self.pool:ReleaseAll()
end

function ContainerMixin:ReleaseAllByTemplate(template)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    self.pool:ReleaseAllByTemplate(template)
end

--*----------[[ Widgets ]]----------*--
local function Button_OnLoad(button)
    button = Mixin(button, WidgetMixin)
    button:InitScripts()
    button:SetNormalFontObject("GameFontNormalSmall")

    -- Textures
    button.border = button:CreateTexture(nil, "BACKGROUND")
    button.border:SetAllPoints(button)
    button.border:SetColorTexture(0, 0, 0, 1)

    button:SetNormalTexture(button:CreateTexture(nil, "ARTWORK"))
    button.bg = button:GetNormalTexture()
    button.bg:SetColorTexture(private.interface.colors.elementColor:GetRGBA())
    button.bg:SetPoint("TOPLEFT", button.border, "TOPLEFT", 1, -1)
    button.bg:SetPoint("BOTTOMRIGHT", button.border, "BOTTOMRIGHT", -1, 1)

    button:SetHighlightTexture(button:CreateTexture(nil, "ARTWORK"))
    button.highlight = button:GetHighlightTexture()
    button.highlight:SetColorTexture(private.interface.colors.highlightColor:GetRGBA())
    button.highlight:SetAllPoints(button.bg)

    -- Scripts
    button.scripts.OnRelease = function()
        button:SetSize(150, 20)
        button:SetNormalFontObject("GameFontNormalSmall")
    end

    button:InitializeScripts()
end

local function CollectionFrame_OnLoad(frame)
    frame = Mixin(frame, ContainerMixin, CollectionMixin)
    frame:InitPools()
end

local function DropdownButton_OnLoad(dropdown)
    dropdown = Mixin(dropdown, TextMixin, WidgetMixin)
    dropdown:InitScripts()

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
    dropdown.arrow:SetPoint("RIGHT", -5)
    dropdown.arrow:SetTexture(136961)
    dropdown.arrow:SetTexCoord(4 / 64, 27 / 64, 8 / 64, 24 / 64)
    dropdown.arrow:SetVertexColor(1, 1, 1, 1)

    -- Text
    dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dropdown.text:SetWordWrap(false)
    dropdown.text:SetPoint("LEFT", 5, 0)
    dropdown.text:SetPoint("RIGHT", dropdown.arrow, "LEFT", -5, 0)

    -- Menu
    dropdown.menu = CreateFrame("Frame", nil, dropdown, "GuildBankSnapshotsCollectionFrame")
    dropdown.menu = Mixin(dropdown.menu, DropdownMenuMixin, ContainerMixin)
    dropdown.menu:InitStyle()
    dropdown.menu:Hide()
    dropdown.menu.dropdown = dropdown
    private:AddBackdrop(dropdown.menu, "insetColor")

    -- Methods
    function dropdown:SelectValue(value)
        if not self.menu.info then
            return
        end

        for _, info in pairs(self.menu.info) do
            if info.value == value then
                self:SetText(info.text)
                info.func()
                return
            end
        end
    end

    function dropdown:SetButtonHidden(setHidden)
        if setHidden then
            dropdown.arrow:Hide()
        else
            dropdown.arrow:Show()
        end
    end

    function dropdown:SetInfo(info)
        if type(info) == "function" then
            info = info()
        end

        self.menu.info = info
    end

    function dropdown:ToggleMenu()
        if self.menu:IsVisible() then
            self.menu:ClearAllPoints()
            self.menu:Hide()
        else
            self.menu:SetAnchors()
            self.menu:SetMenuWidth()
            self.menu:DrawButtons()
            self.menu:Show()
        end
    end

    -- Scripts
    dropdown.scripts.OnClick = function()
        dropdown:ToggleMenu()
    end

    dropdown.scripts.OnRelease = function()
        dropdown:SetButtonHidden(false)
        dropdown:Justify("RIGHT", "MIDDLE")
        dropdown:SetSize(150, 20)
        dropdown.arrow:SetSize(20, 20)
        dropdown.text:SetHeight(20)
        dropdown.menu.info = nil
        dropdown.menu:Hide()
    end

    dropdown.scripts.OnSizeChanged = function()
        local height = dropdown:GetHeight()
        dropdown.arrow:SetSize(height, height)
        dropdown.text:SetHeight(height)
    end

    dropdown:InitializeScripts()
end

local function DropdownListButton_OnLoad(button)
    button = Mixin(button, TextMixin, WidgetMixin)
    button:InitScripts()

    button.checkBox = button:CreateTexture(nil, "ARTWORK")
    button.checkBox:SetTexture(130755)

    button.checked = button:CreateTexture(nil, "OVERLAY")
    button.checked:SetAllPoints(button.checkBox)
    button.checked:SetTexture(130751)
    button.checked:Hide()

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

    -- Textures
    button:SetHighlightTexture(button:CreateTexture(nil, "ARTWORK"))
    button.highlight = button:GetHighlightTexture()
    button.highlight:SetColorTexture(private.interface.colors.emphasizeColor:GetRGBA())
    button.highlight:SetAllPoints(button)

    -- Methods
    function button:SetAnchors()
        local style = self.style
        local leftAligned = style.checkAlignment == "LEFT"
        local xMod = leftAligned and 1 or -1
        local height = self:GetHeight() - (style.paddingX * 2)
        local width = self:GetWidth() - (style.paddingX * (style.hasCheckBox and 3 or 2) - (style.hasCheckBox and height or 0))

        if style.hasCheckBox then
            self.checkBox:SetSize(height, height)
            self.checkBox:SetPoint(style.checkAlignment, self, style.checkAlignment, xMod * style.paddingX, 0)
            self.text:SetPoint(style.checkAlignment, self.checkBox, leftAligned and "RIGHT" or "LEFT", xMod * style.paddingX, 0)
            self.text:SetPoint(leftAligned and "RIGHT" or "LEFT", self, leftAligned and "RIGHT" or "LEFT", -(xMod * style.paddingX), 0)
        else
            self.checkBox:ClearAllPoints()
            self.text:SetSize(width, height)
            self.text:SetPoint(style.checkAlignment, self, style.checkAlignment, xMod * style.paddingX, 0)
            self.text:SetPoint(leftAligned and "RIGHT" or "LEFT", self, leftAligned and "RIGHT" or "LEFT", -(xMod * style.paddingX), 0)
        end
    end

    function button:SetChecked(checked)
        if type(checked) == "function" then
            checked = checked()
        end

        if checked then
            self.checked:Show()
        else
            self.checked:Hide()
        end
    end

    function button:SetElementData(elementData)
        self.elementData = elementData
        self:SetText(elementData.text)
        self:SetChecked(elementData.checked)
        if elementData.func then
            self:SetCallback("OnClick", elementData.func)
        end
    end

    function button:SetStyle(style)
        self.style = style
        self:SetAnchors()
        self:Justify(style.justifyH, style.justifyV)
    end

    -- Scripts
    button.scripts.OnClick = function(self)
        self.menu:Hide()
        self.dropdown:SetText(self.text:GetText())
    end

    button.scripts.OnRelease = function(self)
        self:SetSize(150, 20)
        self:SetFontObject("GameFontHighlightSmall")
        self.style = nil
        self.elementData = nil
    end

    button:InitializeScripts()
end

local function FontFrame_OnLoad(frame)
    frame = Mixin(frame, TextMixin, WidgetMixin)
    frame:InitScripts()
    frame:EnableMouse(true)

    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetJustifyH("LEFT")

    -- Scripts
    frame.scripts.OnEnter = function()
        if frame.text:GetStringWidth() <= frame.text:GetWidth() then
            return
        end

        -- Text is truncated; show full text
        private:InitializeTooltip(frame, "ANCHOR_RIGHT", function(self)
            local text = self.text:GetText()
            GameTooltip:AddLine(text, unpack(private.interface.colors.fontColor))
        end)
    end

    frame.scripts.OnLeave = GenerateClosure(private.HideTooltip, private)

    frame.scripts.OnRelease = function()
        frame:SetHeight(20)
        frame:SetFontObject("GameFontHighlightSmall")
        frame:SetText("")
        frame:SetPadding(0, 0)
        frame:Justify("CENTER", "MIDDLE")
    end

    frame:InitializeScripts()
end

local function ListScrollFrame_OnLoad(frame)
    frame = Mixin(frame, WidgetMixin)
    frame:InitScripts()

    -- DataProvider
    function frame:SetDataProvider(callback)
        assert(type(callback) == "function", callback and "GuildBankSnapshotsListScrollFrame: data provider callback must be a function" or "GuildBankSnapshotsListScrollFrame: attempting to create empty data provider")

        local DataProvider = CreateDataProvider()
        callback(DataProvider)
        self.scrollBox:SetDataProvider(DataProvider)
    end

    -- ScrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -5)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    -- frame.scrollBar:SetFrameLevel(1)

    -- ScrollBox
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WoWScrollBoxList")

    -- ScrollView
    frame.scrollView = CreateScrollBoxListLinearView()

    function frame.scrollView:Initialize(extent, initializer, template)
        if type(extent) == "function" then
            self:SetElementExtentCalculator(extent)
        else
            self:SetElementExtent(extent or 20)
        end

        assert(type(initializer) == "function", "GuildBankSnapshotsListScrollFrame: invalid initializer function")
        self:SetElementInitializer(template or "Frame", initializer)
    end

    function frame.scrollView:Reset()
        self:SetElementExtent(20)
        self:SetElementInitializer("Frame", private.NullFunc)
        frame.scrollBox:SetView(self)
    end

    -- ScrollUtil
    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", frame.scrollBar, "BOTTOMLEFT", -10, -5),
    }

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0),
    }

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar, anchorsWithBar, anchorsWithoutBar)
    ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)

    -- Scripts
    frame.scripts.OnAcquire = function()
        frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
    end

    frame.scripts.OnRelease = function()
        frame.scrollBox:Flush()
        frame.scrollView:Reset()
    end

    frame:InitializeScripts()
end

local function ScrollFrame_OnLoad(frame)
    frame = Mixin(frame, WidgetMixin)
    frame:InitScripts()

    -- ScrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -5)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    -- frame.scrollBar:SetFrameLevel(1)

    -- ScrollBox
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBox")

    -- ScrollView
    frame.scrollView = CreateScrollBoxLinearView()
    frame.scrollView:SetPanExtent(50)

    -- Content
    frame.content = CreateFrame("Frame", nil, frame.scrollBox, "ResizeLayoutFrame")
    frame.content = Mixin(frame.content, ContainerMixin, CollectionMixin)
    frame.content:InitPools()
    frame.content:SetAllPoints(frame.scrollBox)
    frame.content.scrollable = true

    frame.content.scripts.OnSizeChanged = function()
        frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
    end

    -- ScrollUtil
    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", frame.scrollBar, "BOTTOMLEFT", -10, -5),
    }

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, 0),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0),
    }

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar, anchorsWithBar, anchorsWithoutBar)
    ScrollUtil.InitScrollBoxWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)
    frame.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)

    -- Scripts
    frame.scripts.OnRelease = function()
        frame.content:ReleaseAll()
    end

    frame:InitializeScripts()
end

local function SearchBox_OnLoad(editbox)
    editbox = Mixin(editbox, WidgetMixin)
    editbox:InitScripts()

    -- Methods
    function editbox:IsValidText()
        return private:strcheck(editbox:GetText())
    end

    -- editbox:SetTextInsets(editbox.searchIcon:GetWidth() + 4, editbox.clearButton:GetWidth() + 4, 2, 2)
end

local function TabButton_OnLoad(tab)
    tab = Mixin(tab, WidgetMixin)
    tab:InitScripts({
        OnAcquire = function(self)
            tab:SetSelected()
            self:SetSize(150, 20)
            self:UpdateText()
            self:UpdateWidth()
        end,

        OnClick = function(self)
            self:SetSelected(true)

            -- Unselect other tabs
            for tab, _ in private.frame.tabContainer:EnumerateActive() do
                if tab:GetTabID() ~= self.tabID then
                    tab:SetSelected()
                end
            end
        end,

        OnRelease = function(self)
            self.tabID = nil
            self.info = nil
        end,
    })

    -- Textures
    tab.border = tab:CreateTexture(nil, "BACKGROUND")
    tab.border:SetColorTexture(private.interface.colors.borderColor:GetRGBA())
    tab.border:SetAllPoints(tab)

    tab.normal = tab:CreateTexture(nil, "BACKGROUND")
    tab.normal:SetColorTexture(private.interface.colors.elementColor:GetRGBA())
    tab.normal:SetPoint("TOPLEFT", tab.border, "TOPLEFT", 1, -1)
    tab.normal:SetPoint("BOTTOMRIGHT", tab.border, "BOTTOMRIGHT", -1, 1)

    tab.selected = tab:CreateTexture(nil, "BACKGROUND")
    tab.selected:SetColorTexture(private.interface.colors.insetColor:GetRGBA())
    tab.selected:SetAllPoints(tab.normal)

    tab.highlight = tab:CreateTexture(nil, "BACKGROUND")
    tab.highlight:SetColorTexture(private.interface.colors.highlightColor:GetRGBA())
    tab.highlight:SetAllPoints(tab.normal)

    tab:SetNormalTexture(tab.normal)
    tab:SetHighlightTexture(tab.highlight)

    -- Text
    tab:SetText("")
    tab:SetNormalFontObject(GameFontNormal)
    tab:SetHighlightFontObject(GameFontHighlight)
    tab:SetPushedTextOffset(0, 0)

    -- Methods
    function tab:GetTabID()
        return self.tabID
    end

    function tab:SetSelected(isSelected)
        if isSelected then
            tab:SetNormalTexture(tab.selected)
        else
            tab:SetNormalTexture(tab.normal)
        end
    end

    function tab:SetTab(tabID, info)
        self.tabID = tabID
        self.info = info
        self:UpdateText()
        self:UpdateWidth()
    end

    function tab:UpdateText()
        tab:SetText("")

        if not self.tabID then
            return
        end

        tab:SetText(self.info.header)
    end

    function tab:UpdateWidth()
        self:SetWidth(150)

        if not self.tabID then
            return
        end

        self:SetWidth(self:GetTextWidth() + 20)
    end
end

local function TableCell_OnLoad(cell)
    cell = Mixin(cell, TextMixin, WidgetMixin)
    cell:InitScripts()
    cell:SetHeight(20)

    -- Textures
    cell.icon = cell:CreateTexture(nil, "BACKGROUND")

    -- Text
    cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cell.text:SetWordWrap(false)
    cell:Justify("LEFT", "TOP")

    -- Methods
    function cell:SetAnchors()
        self.icon:SetTexture()
        self.icon:ClearAllPoints()
        local iconSize = min(self:GetWidth() - self.paddingX, 12)
        self.icon:SetSize(iconSize, iconSize)

        self.text:ClearAllPoints()

        local icon = self.data.icon
        if type(icon) == "function" then
            icon = self.data.icon(self.elementData)
        end

        if icon then
            self.icon:SetTexture(icon)
            self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", self.paddingX, -self.paddingY)
            self.text:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
        else
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.paddingX, -self.paddingY)
        end
        self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.paddingX, self.paddingY)
    end

    function cell:SetData(data, elementData)
        self.data = data
        self.elementData = elementData
        self:SetAnchors()
    end

    function cell:SetPadding(paddingX, paddingY)
        self.paddingX = paddingX
        self.paddingY = paddingY
    end

    -- Scripts
    cell.scripts.OnEnter = function(self, ...)
        -- Enable row highlight
        local parent = self:GetParent()
        parent:GetScript("OnEnter")(parent, ...)
        -- Highlight text
        self.text:SetFontObject(GameFontNormalSmall)

        -- Show tooltips
        if not self.data then
            return
        end

        if self.data.tooltip then
            private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                local line = self.data.tooltip(self.elementData, self.entryID)

                if line then
                    GameTooltip:AddLine(line, 1, 1, 1)
                elseif self.text:GetStringWidth() > self:GetWidth() then
                    GameTooltip:AddLine(self.data.text(self.elementData), 1, 1, 1)
                end
            end, self)
        elseif self.text:GetStringWidth() > self:GetWidth() then
            -- Get truncated text
            private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                GameTooltip:AddLine(self.data.text(self.elementData), 1, 1, 1)
            end, self)
        end
    end

    cell.scripts.OnLeave = function(self, ...)
        -- Disable row highlight
        local parent = self:GetParent()
        parent:GetScript("OnLeave")(parent, ...)
        -- Unhighlight text
        self.text:SetFontObject(GameFontHighlightSmall)
        -- Hide tooltips
        private:ClearTooltip()
    end

    cell.scripts.OnRelease = function(self)
        self:SetHeight(20)
        self:SetFontObject("GameFontHighlightSmall")
        self:SetText("")
        self:SetPadding(0, 0)
        self:Justify("LEFT", "TOP")
        self.data = nil
        self.elementData = nil
    end

    cell:InitializeScripts()

    cell.icon:SetScript("OnEnter", function(self, ...)
        local parent = self:GetParent()
        parent:GetScript("OnEnter")(parent, ...)
    end)

    cell.icon:SetScript("OnLeave", function(self, ...)
        local parent = self:GetParent()
        parent:GetScript("OnLeave")(parent, ...)
    end)
end

-----------------------

GuildBankSnapshotsButton_OnLoad = Button_OnLoad
GuildBankSnapshotsCollectionFrame_OnLoad = CollectionFrame_OnLoad
GuildBankSnapshotsDropdownButton_OnLoad = DropdownButton_OnLoad
GuildBankSnapshotsDropdownListButton_OnLoad = DropdownListButton_OnLoad
GuildBankSnapshotsFontFrame_OnLoad = FontFrame_OnLoad
GuildBankSnapshotsListScrollFrame_OnLoad = ListScrollFrame_OnLoad
GuildBankSnapshotsScrollFrame_OnLoad = ScrollFrame_OnLoad
GuildBankSnapshotsSearchBox_OnLoad = SearchBox_OnLoad
GuildBankSnapshotsTabButton_OnLoad = TabButton_OnLoad
GuildBankSnapshotsTableCell_OnLoad = TableCell_OnLoad
