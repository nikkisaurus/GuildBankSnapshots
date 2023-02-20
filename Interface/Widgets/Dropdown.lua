local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*----------[[ Menus ]]----------*--
local menus = {}

function private:CloseMenus(ignoredMenu)
    for _, menu in pairs(menus) do
        if menu ~= ignoredMenu then
            menu:Close()
        end
    end
end

--*----------[[ Widgets ]]----------*--
function GuildBankSnapshotsDropdownButton_OnLoad(dropdown)
    dropdown.selected = {}
    dropdown = private:MixinText(dropdown)

    dropdown:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self.arrow:SetSize(20, 20)
            self.text:SetHeight(20)
            self:SetButtonHidden(false)
            self:Justify("RIGHT", "MIDDLE")
            self:SetText("")
            self.menu:InitializeStyle()
            self:SetEnabled(true)
        end,

        OnClick = function(self)
            self:ToggleMenu()
        end,

        OnHide = function(self)
            self.menu:Hide()
        end,

        OnRelease = function(self)
            self.info = nil
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
    dropdown.menu = CreateFrame("Frame", nil, UIParent, "GuildBankSnapshotsDropdownMenu")
    dropdown.menu:Hide()
    dropdown.menu.dropdown = dropdown
    tinsert(menus, dropdown.menu)

    -- Methods
    function dropdown:GetInfo(id)
        assert(self.info, "GuildBankSnapshotsDropdownButton: info is not initialized")

        if id then
            for _, info in pairs(self:GetInfo()) do
                if info.id == id then
                    return info
                end
            end
        else
            return self.info()
        end
    end

    function dropdown:GetSelected(searchID)
        for selectedID, enabled in addon:pairs(self.selected) do
            if selectedID == searchID and enabled then
                return self:GetInfo(selectedID)
            end
        end
    end

    function dropdown:SelectByID(value)
        assert(self.info, "GuildBankSnapshotsDropdownButton: info is not initialized")

        for _, info in pairs(self:GetInfo()) do
            if info.id == value then
                if self.menu.style.multiSelect then
                    self.selected[info.id] = not self.selected[info.id]
                else
                    wipe(self.selected)
                    self.selected[info.id] = true
                end
                self:UpdateText()
                info.func(self)
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

    function dropdown:SetDisabled(isDisabled)
        self.arrow:SetVertexColor(1, 1, 1, isDisabled and 0.25 or 1)
        self:SetEnabled(not isDisabled)
    end

    function dropdown:SetInfo(info)
        assert(type(info) == "function", "GuildBankSnapshotsDropdownButton: info must be a callback function")
        self.info = info
    end

    function dropdown:SetStyle(style)
        for k, v in pairs(style) do
            self.menu.style[k] = v
        end
    end

    function dropdown:ToggleMenu()
        private:CloseMenus(self.menu)

        if self.menu:IsVisible() then
            self.menu:Close()
        else
            self.menu:Open()
        end
    end

    function dropdown:UpdateText()
        self:SetText("")

        local text
        for selectedID, enabled in addon:pairs(self.selected) do
            if enabled then
                local info = dropdown:GetInfo(selectedID)

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

local buttons = {}
function GuildBankSnapshotsDropdownListButton_OnLoad(button)
    button = private:MixinText(button)

    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:SetFontObject("GameFontHighlightSmall")
        end,

        OnClick = function(self)
            self.dropdown:SelectByID(self.info.id)

            if self.menu.style.multiSelect then
                self:SetChecked()
            else
                self.menu:Hide()
            end
        end,

        OnEnter = function(self)
            if self.text:GetStringWidth() > self.text:GetWidth() then
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    local text = self.text:GetText()
                    GameTooltip:AddLine(text, unpack(private.interface.colors.fontColor))
                end)
            end
        end,

        OnLeave = GenerateClosure(private.HideTooltip, private),

        OnRelease = function(self)
            self.menu = nil
            self.dropdown = nil
            self.buttonID = nil
            self.info = nil
        end,
    })

    -- Textures
    button.container = button:CreateTexture(nil, "BACKGROUND")

    button.checkBoxBorder = button:CreateTexture(nil, "ARTWORK")
    button.checkBoxBorder:SetColorTexture(0, 0, 0, 1)

    button.checkBox = button:CreateTexture(nil, "ARTWORK")
    button.checkBox:SetPoint("TOPLEFT", button.checkBoxBorder, "TOPLEFT", 1, -1)
    button.checkBox:SetPoint("BOTTOMRIGHT", button.checkBoxBorder, "BOTTOMRIGHT", -1, 1)
    button.checkBox:SetColorTexture(private.interface.colors.bgColor:GetRGBA())

    button.checked = button:CreateTexture(nil, "OVERLAY")
    button.checked:SetPoint("TOPLEFT", button.checkBoxBorder, "TOPLEFT", -4, 4)
    button.checked:SetPoint("BOTTOMRIGHT", button.checkBoxBorder, "BOTTOMRIGHT", 4, -4)
    button.checked:SetTexture(130751)
    button.checked:Hide()

    button.highlight = button:CreateTexture(nil, "ARTWORK")
    button.highlight:SetAllPoints(button)
    button:SetHighlightTexture(button.highlight)
    button:GetHighlightTexture():SetColorTexture(private.interface.colors.emphasizeColor:GetRGBA())

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

    -- Methods
    function button:SetAnchors()
        local style = self.menu.style
        local leftAligned = style.checkAlignment == "LEFT"
        local xMod = leftAligned and 1 or -1

        if style.hasCheckBox then
            local size = min(self.container:GetHeight(), 12)
            self.checkBoxBorder:SetSize(size, size)
            self.checkBoxBorder:SetPoint("TOP", self.container, "TOP")
            self.checkBoxBorder:SetPoint(style.checkAlignment, self.container, style.checkAlignment)
            self.text:SetPoint("TOP", self.checkBoxBorder, "TOP")
            self.text:SetPoint(style.checkAlignment, self.checkBoxBorder, leftAligned and "RIGHT" or "LEFT", xMod * style.paddingX, 0)
            self.text:SetPoint(leftAligned and "RIGHT" or "LEFT", self, leftAligned and "RIGHT" or "LEFT", -(xMod * style.paddingX), 0)
            self.text:SetPoint("BOTTOM", self.container, "BOTTOM")
        else
            self.checkBoxBorder:ClearAllPoints()
            self.text:SetPoint("TOP", self.container, "TOP")
            self.text:SetPoint(style.checkAlignment, self.container, style.checkAlignment)
            self.text:SetPoint(leftAligned and "RIGHT" or "LEFT", self.container, leftAligned and "RIGHT" or "LEFT")
            self.text:SetPoint("BOTTOM", self.container, "BOTTOM")
        end
    end

    function button:SetChecked()
        local checked = self.dropdown:GetSelected(self.info.id)
        if checked then
            self.checked:Show()
        else
            self.checked:Hide()
        end
    end

    function button:SetInfo(menu, buttonID, info)
        self.menu = menu
        self.dropdown = menu.dropdown
        self.buttonID = buttonID
        self.info = info

        button:Update()
    end

    function button:Update()
        if not self.info then
            return
        end

        self.container:SetPoint("TOPLEFT", self.menu.style.paddingX, -self.menu.style.paddingY)
        self.container:SetPoint("BOTTOMRIGHT", -self.menu.style.paddingX, self.menu.style.paddingY)

        self:GetHighlightTexture():SetColorTexture(self.menu.style.buttonHighlight:GetRGBA())

        self:Justify(self.menu.style.justifyH, self.menu.style.justifyV)
        self:SetText(self.info.text)

        self:SetAnchors()
        self:SetChecked()
    end
end

function GuildBankSnapshotsDropdownMenu_OnLoad(menu)
    menu = private:MixinContainer(menu)
    menu:SetFrameLevel(1000)
    private:AddBackdrop(menu, "insetColor")

    -- Methods
    function menu:Close()
        self:ClearAllPoints()
        self:Hide()
    end

    function menu:InitializeListFrame()
        self:ReleaseAll()

        local listFrame = self:Acquire("GuildBankSnapshotsListScrollFrame")

        local searchBox = self:Acquire("GuildBankSnapshotsSearchBox")
        searchBox:SetHeight(20)
        if self.style.hasSearch then
            searchBox:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -5)
            searchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, 0)
            self:SetHeight(self:GetHeight() + 30)
        end

        searchBox:SetCallback("OnTextChanged", function(_, userInput)
            local text = searchBox:GetText()

            if userInput then
                listFrame:SetDataProvider(function(provider)
                    for _, info in pairs(self.dropdown:GetInfo()) do
                        if strfind(strupper(info.id), strupper(text)) then
                            provider:Insert(info)
                        end
                    end
                end)
            end
        end)

        searchBox:SetCallback("OnClear", function(...)
            listFrame:SetDataProvider(function(provider)
                provider:InsertTable(self.dropdown:GetInfo())
            end)
        end)

        local clearButton = self:Acquire("GuildBankSnapshotsButton")
        clearButton:SetText(L["Clear"])
        clearButton:SetHeight(20)
        if self.style.hasClear then
            if self.style.hasSearch then
                clearButton:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -5, -5)
                clearButton:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", 5, 0)
            else
                clearButton:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -5)
                clearButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -5, 0)
            end
            self:SetHeight(self:GetHeight() + 30)
        end

        clearButton:SetCallback("OnClick", function()
            self:Close()
            wipe(self.dropdown.selected)
            self.dropdown:UpdateText()
            if self.dropdown.handlers.OnClear then
                self.dropdown.handlers.OnClear(self.dropdown)
            end
        end)

        if self.style.hasClear or self.style.hasSearch then
            listFrame:SetPoint("TOP", self.style.hasClear and clearButton or self.style.hasSearch and searchBox, "BOTTOM", 0, -5)
            listFrame:SetPoint("LEFT", self, "LEFT")
            listFrame:SetPoint("BOTTOM", self, "BOTTOM")
        else
            listFrame:SetAllPoints(self)
        end

        listFrame.scrollView:Initialize(self.style.buttonHeight, function(frame, elementData)
            frame:SetInfo(self, frame:GetOrderIndex(), elementData)
        end, "GuildBankSnapshotsDropdownListButton")
        listFrame:SetDataProvider(function(provider)
            provider:InsertTable(self.dropdown:GetInfo())
            self:SetHeight(min(self:GetHeight() + ((provider:GetSize() + 1) * self.style.buttonHeight), self.style.maxHeight))
        end)
    end

    function menu:InitializeStyle()
        self.style = {
            width = "auto",
            buttonHeight = 20,
            buttonHighlight = CreateColor(1, 0.82, 0, 0.25),
            maxHeight = 200,
            anchor = "TOPLEFT",
            relAnchor = "BOTTOMLEFT",
            xOffset = 0,
            yOffset = 0,
            justifyH = "LEFT",
            justifyV = "TOP",
            paddingX = 3,
            paddingY = 3,
            hasCheckBox = true,
            checkAlignment = "LEFT",
            hasSearch = false,
            multiSelect = false,
            hasClear = false,
        }
    end

    function menu:Open()
        self:SetHeight(0)
        self:SetMenuWidth()
        self:SetAnchors()
        self:InitializeListFrame()
        self:Show()
    end

    function menu:SetAnchors()
        self:SetPoint(self.style.anchor, self.dropdown, self.style.relAnchor, self.style.xOffset, self.style.yOffset)
    end

    function menu:SetMenuWidth()
        self:SetWidth(self.style.width == "auto" and self.dropdown:GetWidth() or self.style.width)
    end
end
