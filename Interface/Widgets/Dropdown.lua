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
local DropdownMenuMixin = {}
local DropdownMenuStyle = {
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
    multiSelect = false,
}

function DropdownMenuMixin:DrawButtons()
    local style = self.style
    self:ReleaseAll()

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
                local provider = listFrame:SetDataProvider(function(provider)
                    for _, info in pairs(self.info) do
                        if strfind(strupper(info.value), strupper(text)) then
                            provider:Insert(info)
                        end
                    end
                end)

                self:SetHeight(min((provider:GetSize() + 1) * style.buttonHeight, (style.maxButtons + 1) * style.buttonHeight) + 25)
            end
        end)

        searchBox:SetCallback("OnClear", function(...)
            local provider = listFrame:SetDataProvider(function(provider)
                provider:InsertTable(self.info)
            end)
            self:SetHeight(min((provider:GetSize() + 1) * style.buttonHeight, (style.maxButtons + 1) * style.buttonHeight) + 25)
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

    local provider = listFrame:SetDataProvider(function(provider)
        provider:InsertTable(self.info)
    end)
    self:SetHeight(min((provider:GetSize() + 1) * style.buttonHeight, (style.maxButtons + 1) * style.buttonHeight))
end

function DropdownMenuMixin:InitStyle()
    self.style = addon:CloneTable(DropdownMenuStyle)
end

function DropdownMenuMixin:SetAnchors()
    self:SetPoint(self.style.anchor, self.dropdown, self.style.relAnchor, self.style.xOffset, self.style.yOffset)
end

function DropdownMenuMixin:SetMenuWidth()
    self:SetWidth(self.style.width == "auto" and self.dropdown:GetWidth() or self.style.width)
end

local function DropdownButton_OnLoad(dropdown)
    dropdown = private:MixinText(dropdown)
    dropdown = private:MixinWidget(dropdown)
    dropdown:InitScripts({
        OnAcquire = function(self)
            self:SetButtonHidden(false)
            self:Justify("RIGHT", "MIDDLE")
            self:SetText("")
            self:SetSize(150, 20)
            self.arrow:SetSize(20, 20)
            self.text:SetHeight(20)
            self.menu:InitStyle()
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
    dropdown.menu = Mixin(CreateFrame("Frame", nil, UIParent, "GuildBankSnapshotsContainer"), DropdownMenuMixin)
    dropdown.menu = private:MixinContainer(dropdown.menu)
    tinsert(menus, dropdown.menu)
    dropdown.menu.dropdown = dropdown
    dropdown.menu:SetFrameLevel(1000)
    dropdown.menu:Hide()
    private:AddBackdrop(dropdown.menu, "insetColor")

    dropdown.selected = {}

    -- Methods
    function dropdown:SelectValue(value, callback)
        if not self.menu.info then
            return
        end

        for infoID, info in pairs(self.menu.info) do
            if info.value == value then
                if self.menu.style.multiSelect then
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
    button = private:MixinText(button)
    button = private:MixinWidget(button)
    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:SetFontObject("GameFontHighlightSmall")
        end,

        OnClick = function(self)
            self.dropdown:SelectValue(self.elementData.value, true)

            if self.menu.style.multiSelect then
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

        local checked = self.menu.style.multiSelect and self.dropdown.selected[self.id] or self.elementData.checked

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

GuildBankSnapshotsDropdownButton_OnLoad = DropdownButton_OnLoad
GuildBankSnapshotsDropdownListButton_OnLoad = DropdownListButton_OnLoad
