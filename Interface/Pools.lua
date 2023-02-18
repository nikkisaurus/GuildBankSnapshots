local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local menus = {}

function private:CloseMenus(ignoredMenu)
    for _, menu in pairs(menus) do
        if menu ~= ignoredMenu then
            menu:Hide()
        end
    end
end

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
    self.pool:CreatePool("CheckButton", parent or self, "GuildBankSnapshotsCheckButton", Resetter)
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
    self:SetHeight(min((addon:tcount(self.info) + 1) * style.buttonHeight, (style.maxButtons + 1) * style.buttonHeight))

    local listFrame = self:Acquire("GuildBankSnapshotsListScrollFrame")

    if style.hasSearch then
        local searchBox = self:Acquire("GuildBankSnapshotsSearchBox")
        searchBox:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -5)
        searchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, 0)
        searchBox:SetHeight(20)
        self:SetHeight(self:GetHeight() + 25)

        searchBox:SetCallback("OnTextChanged", function(_, userInput)
            local text = searchBox:GetText()

            if userInput then
                listFrame:SetDataProvider(function(provider)
                    for _, info in pairs(self.info) do
                        if strfind(strupper(info.value), strupper(text)) then
                            provider:Insert(info)
                        end
                    end
                    self:SetHeight(min((provider:GetSize() + 1) * style.buttonHeight, (style.maxButtons + 1) * style.buttonHeight))
                    self:SetHeight(self:GetHeight() + 25)
                end)
            end
        end)

        listFrame:SetPoint("TOP", searchBox, "BOTTOM")
        listFrame:SetPoint("LEFT", self, "LEFT")
        listFrame:SetPoint("BOTTOM", self, "BOTTOM")
    else
        listFrame:SetAllPoints(self)
    end

    listFrame.scrollView:Initialize(style.buttonHeight, function(frame, elementData)
        frame.menu = self
        frame.dropdown = frame.menu.dropdown

        frame:SetStyle(style)
        frame:SetElementData(frame:GetOrderIndex(), elementData)
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
        hasSearch = false,
    }
end

function DropdownMenuMixin:SetAnchors()
    self:SetPoint(self.style.anchor, self.dropdown, self.style.relAnchor, self.style.xOffset, self.style.yOffset)
end

function DropdownMenuMixin:SetMenuWidth()
    self:SetWidth(self.style.width == "auto" and self.dropdown:GetWidth() or self.style.width)
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
    self.text:SetWordWrap(autoHeight)
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

function WidgetMixin:ShowTooltip(anchor, callback)
    assert(type(callback) == "function", "WidgetMixin: ShowTooltip callback must be a function")
    private:InitializeTooltip(self, anchor or "ANCHOR_RIGHT", callback)
end

-----------------------

local ContainerMixin = Mixin({}, WidgetMixin)
ContainerMixin:InitScripts()

function ContainerMixin:Acquire(template, parent)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")

    local object = self.pool:Acquire(template)
    assert(object.Fire, "ContainerMixin: template '" .. template .. "' is not initialized as a widget")
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
    button:InitScripts({
        OnRelease = function()
            button:SetSize(150, 20)
            button:SetNormalFontObject("GameFontNormalSmall")
        end,
    })
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
end

local function CheckButton_OnLoad(button)
    button:EnableMouse(true)
    button = Mixin(button, TextMixin, WidgetMixin)
    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:Justify("LEFT", "TOP")
            button:SetAutoHeight(true)
        end,

        OnClick = function(self, ...)
            self:SetChecked(not self:GetChecked())
        end,

        OnEnter = function(self)
            if self.tooltip then
                self:ShowTooltip(nil, self.tooltip)
            end
        end,

        OnLeave = function(self)
            private:HideTooltip()
        end,
    })

    -- Textures
    button.checkBox = button:CreateTexture(nil, "ARTWORK")
    button.checkBox:SetTexture(130755)
    button.checkBox:SetPoint("TOPLEFT")
    button.checkBox:SetSize(16, 16)

    button.checked = button:CreateTexture(nil, "OVERLAY")
    button.checked:SetAllPoints(button.checkBox)
    button.checked:SetTexture(130751)
    button.checked:Hide()

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("TOPLEFT", button.checkBox, "TOPRIGHT", 2, 0)
    button.text:SetPoint("RIGHT", -2, 0)

    -- Methods
    function button:GetChecked()
        return self.isChecked
    end

    function button:SetChecked(isChecked)
        self.isChecked = isChecked

        if isChecked then
            self.checked:Show()
        else
            self.checked:Hide()
        end
    end

    function button:SetCheckedState(isChecked)
        self.isChecked = isChecked
        self:SetChecked(isChecked)
        self.handlers.OnClick(self)
    end

    function button:SetTooltipInitializer(tooltip)
        self.tooltip = tooltip
    end
end

local function CollectionFrame_OnLoad(frame)
    frame = Mixin(frame, ContainerMixin, CollectionMixin)
    frame:InitPools()
end

local function DropdownButton_OnLoad(dropdown)
    dropdown = Mixin(dropdown, TextMixin, WidgetMixin)
    dropdown:InitScripts({
        OnAcquire = function(self)
            self:SetButtonHidden(false)
            self:Justify("RIGHT", "MIDDLE")
            self:SetText("")
            self:SetSize(150, 20)
            self.arrow:SetSize(20, 20)
            self.text:SetHeight(20)
        end,

        OnClick = function(self)
            self:ToggleMenu()
        end,

        OnHide = function(self)
            self.menu:Hide()
        end,

        OnRelease = function(self)
            self.menu.info = nil
            wipe(self.selected)
        end,

        OnSizeChanged = function(self)
            local height = self:GetHeight()
            self.arrow:SetSize(height, height)
            self.text:SetHeight(height)
        end,
    })

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
    dropdown.menu = Mixin(CreateFrame("Frame", nil, UIParent, "GuildBankSnapshotsCollectionFrame"), DropdownMenuMixin, ContainerMixin)
    tinsert(menus, dropdown.menu)
    dropdown.menu.dropdown = dropdown
    dropdown.menu:InitStyle()
    dropdown.menu:SetFrameLevel(1000)
    dropdown.menu:Hide()
    private:AddBackdrop(dropdown.menu, "insetColor")

    dropdown.selected = {}

    -- Methods
    function dropdown:IsMultiSelect()
        return self.isMulti
    end

    function dropdown:SelectValue(value, callback)
        if not self.menu.info then
            return
        end

        for infoID, info in pairs(self.menu.info) do
            if info.value == value then
                if self:IsMultiSelect() then
                    self.selected[infoID] = not self.selected[infoID]
                    self:UpdateMultiText()
                else
                    self:SetText(info.text)
                end
                if callback then
                    info.func()
                end
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

    function dropdown:SetMultiSelect(isMulti)
        self.isMulti = isMulti
    end

    function dropdown:SetStyle(style)
        for k, v in pairs(style) do
            self.menu.style[k] = v
        end
    end

    function dropdown:ToggleMenu()
        private:CloseMenus(self.menu)

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

    function dropdown:UpdateMultiText()
        if not self.menu.info then
            return
        end

        local text
        for infoID, enabled in addon:pairs(self.selected) do
            if enabled then
                local info = self.menu.info[infoID]
                if not text then
                    text = info.text
                else
                    text = text .. ", " .. info.text
                end
            end
        end

        self:SetText(text)
    end
end

local function DropdownListButton_OnLoad(button)
    button = Mixin(button, TextMixin, WidgetMixin)
    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:SetFontObject("GameFontHighlightSmall")
        end,

        OnClick = function(self)
            self.dropdown:SelectValue(self.elementData.value, true)

            if self.dropdown:IsMultiSelect() then
                self:SetChecked()
            else
                self.menu:Hide()
            end
        end,

        OnRelease = function(self)
            self.style = nil
            self.elementData = nil
        end,
    })

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

    function button:SetChecked()
        if not self.id then
            return
        end

        local checked = self.dropdown:IsMultiSelect() and self.dropdown.selected[self.id] or self.elementData.checked

        if type(checked) == "function" then
            checked = checked()
        end

        if checked then
            self.checked:Show()
        else
            self.checked:Hide()
        end
    end

    function button:SetElementData(id, elementData)
        self.id = id
        self.elementData = elementData
        self:SetText(elementData.text)
        self:SetChecked()
        if elementData.func then
            self:SetCallback("OnClick", function()
                elementData.func(self.dropdown, id, elementData)
            end)
        end
    end

    function button:SetStyle(style)
        self.style = style
        self:SetAnchors()
        self:Justify(style.justifyH, style.justifyV)
    end
end

local function FontFrame_OnLoad(frame)
    frame = Mixin(frame, TextMixin, WidgetMixin)
    frame:InitScripts({
        OnEnter = function(self)
            if self.text:GetStringWidth() <= self.text:GetWidth() then
                return
            end

            -- Text is truncated; show full text
            private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                local text = self.text:GetText()
                GameTooltip:AddLine(text, unpack(private.interface.colors.fontColor))
            end)
        end,

        OnLeave = GenerateClosure(private.HideTooltip, private),

        OnRelease = function(self)
            self:SetHeight(20)
            self:SetFontObject("GameFontHighlightSmall")
            self:SetText("")
            self:SetPadding(0, 0)
            self:Justify("CENTER", "MIDDLE")
        end,
    })

    frame:EnableMouse(true)

    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetJustifyH("LEFT")
end

local function ListScrollFrame_OnLoad(frame)
    frame = Mixin(frame, WidgetMixin)
    frame:InitScripts({
        OnAcquire = function(self)
            self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
        end,

        OnRelease = function(self)
            self.scrollBox:Flush()
            self.scrollView:Reset()
        end,
    })

    -- ScrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 0)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
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
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, -10),
        CreateAnchor("BOTTOMRIGHT", frame.scrollBar, "BOTTOMLEFT", -5, 10),
    }

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, -10),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 10),
    }

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar, anchorsWithBar, anchorsWithoutBar)
    ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)

    -- Methods
    function frame:SetDataProvider(callback)
        assert(type(callback) == "function", callback and "GuildBankSnapshotsListScrollFrame: data provider callback must be a function" or "GuildBankSnapshotsListScrollFrame: attempting to create empty data provider")

        local DataProvider = CreateDataProvider()
        callback(DataProvider)
        self.scrollBox:SetDataProvider(DataProvider)
    end
end

local function ScrollFrame_OnLoad(frame)
    frame = Mixin(frame, WidgetMixin)
    frame:InitScripts({
        OnSizeChanged = function(self)
            self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
        end,

        OnRelease = function(self)
            self.content:ReleaseAll()
        end,
    })

    -- ScrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 0)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    -- frame.scrollBar:SetFrameLevel(1)

    -- ScrollBox
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBox")

    -- ScrollView
    frame.scrollView = CreateScrollBoxLinearView()
    frame.scrollView:SetPanExtent(50)

    -- Content
    frame.content = Mixin(CreateFrame("Frame", nil, frame.scrollBox, "ResizeLayoutFrame"), ContainerMixin, CollectionMixin)
    frame.content.scrollable = true
    frame.content:InitPools()
    frame.content:SetAllPoints(frame.scrollBox)

    -- ScrollUtil
    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, -10),
        CreateAnchor("BOTTOMRIGHT", frame.scrollBar, "BOTTOMLEFT", -5, 10),
    }

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, -10),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 10),
    }

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar, anchorsWithBar, anchorsWithoutBar)
    ScrollUtil.InitScrollBoxWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)
end

local function SearchBox_OnLoad(editbox)
    editbox = Mixin(editbox, WidgetMixin)
    editbox:InitScripts()

    -- editbox:SetTextInsets(editbox.searchIcon:GetWidth() + 4, editbox.clearButton:GetWidth() + 4, 2, 2)

    -- Methods
    function editbox:IsValidText()
        return private:strcheck(editbox:GetText())
    end
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
    cell:InitScripts({
        -- Scripts
        OnEnter = function(self, ...)
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
        end,

        OnLeave = function(self, ...)
            -- Disable row highlight
            local parent = self:GetParent()
            parent:GetScript("OnLeave")(parent, ...)
            -- Unhighlight text
            self.text:SetFontObject(GameFontHighlightSmall)
            -- Hide tooltips
            private:ClearTooltip()
        end,

        OnRelease = function(self)
            self:SetHeight(20)
            self:SetFontObject("GameFontHighlightSmall")
            self:SetText("")
            self:SetPadding(0, 0)
            self:Justify("LEFT", "TOP")
            self.data = nil
            self.elementData = nil
            self.entryID = nil
        end,
    })

    cell:SetHeight(20)

    -- Textures
    cell.icon = cell:CreateTexture(nil, "BACKGROUND")
    cell.icon:SetScript("OnEnter", GenerateClosure(cell.GetScript, cell, "OnEnter"))
    cell.icon:SetScript("OnLeave", GenerateClosure(cell.GetScript, cell, "OnLeave"))

    -- Text
    cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cell:Justify("LEFT", "TOP")
    cell.text:SetWordWrap(false)

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

    function cell:SetData(data, elementData, entryID)
        self.data = data
        self.elementData = elementData
        self.entryID = entryID
        self:SetAnchors()
    end

    function cell:SetPadding(paddingX, paddingY)
        self.paddingX = paddingX
        self.paddingY = paddingY
    end
end

-----------------------

GuildBankSnapshotsButton_OnLoad = Button_OnLoad
GuildBankSnapshotsCheckButton_OnLoad = CheckButton_OnLoad
GuildBankSnapshotsCollectionFrame_OnLoad = CollectionFrame_OnLoad
GuildBankSnapshotsDropdownButton_OnLoad = DropdownButton_OnLoad
GuildBankSnapshotsDropdownListButton_OnLoad = DropdownListButton_OnLoad
GuildBankSnapshotsFontFrame_OnLoad = FontFrame_OnLoad
GuildBankSnapshotsListScrollFrame_OnLoad = ListScrollFrame_OnLoad
GuildBankSnapshotsScrollFrame_OnLoad = ScrollFrame_OnLoad
GuildBankSnapshotsSearchBox_OnLoad = SearchBox_OnLoad
GuildBankSnapshotsTabButton_OnLoad = TabButton_OnLoad
GuildBankSnapshotsTableCell_OnLoad = TableCell_OnLoad
