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
    dropdown = private:MixinText(dropdown)
    dropdown:InitScripts({
        OnAcquire = function(self)
            self:SetUserData("selected", {})

            self.arrow:SetSize(20, 20)
            self.text:SetHeight(20)
            self:SetButtonHidden(false)
            self:Justify("RIGHT", "MIDDLE")
            self.menu:InitializeStyle()
            self:SetDisabled()
            self:SetBackdropColor(private.interface.colors.dark)
            self.arrow:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
            self:SetText("")

            self:SetSize(150, 20)
        end,

        OnClick = function(self)
            if self:GetUserData("disabled") then
                return
            end
            self:ToggleMenu()
        end,

        OnHide = function(self)
            self.menu:Hide()
        end,

        OnSizeChanged = function(self)
            local height = self:GetHeight()
            self.arrow:SetSize(height, height)
            self.text:SetHeight(height)
        end,
    })

    -- Textures
    dropdown.bg, dropdown.border, dropdown.highlight = private:AddBackdrop(dropdown)

    dropdown.arrow = CreateFrame("Button", nil, dropdown)
    dropdown.arrow = private:MixinText(dropdown.arrow)
    dropdown.arrow:SetPoint("RIGHT", -5)
    dropdown.arrow.text = dropdown.arrow:CreateFontString(nil, "OVERLAY")
    dropdown.arrow.text:SetFontObject(private.interface.fonts.symbolFont)
    dropdown.arrow.text:SetAllPoints(dropdown.arrow)
    dropdown.arrow:SetText("▼")
    dropdown.arrow:SetScript("OnClick", function(self, ...)
        dropdown:Fire("OnClick", ...)
    end)

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
    function dropdown:Clear()
        wipe(self:GetUserData("selected"))
        self:UpdateText()
        if self.handlers.OnClear then
            self.handlers.OnClear(self)
        end
    end

    function dropdown:GetInfo(id)
        assert(self:GetUserData("info"), "GuildBankSnapshotsDropdownButton: info is not initialized")

        if id then
            for _, info in pairs(self:GetInfo()) do
                if info.id == id then
                    return info
                end
            end
        else
            return self:GetUserData("info")()
        end
    end

    function dropdown:GetSelected(searchID)
        for selectedID, enabled in addon:pairs(self:GetUserData("selected")) do
            if selectedID == searchID and enabled then
                return self:GetInfo(selectedID)
            end
        end
    end

    function dropdown:SelectByID(value, skipCallback, forceSelect)
        assert(self:GetUserData("info"), "GuildBankSnapshotsDropdownButton: info is not initialized")

        for _, info in pairs(self:GetInfo()) do
            if info.id == value then
                if self.menu.style.multiSelect then
                    self:GetUserData("selected")[info.id] = forceSelect or not self:GetUserData("selected")[info.id]
                else
                    wipe(self:GetUserData("selected"))
                    self:GetUserData("selected")[info.id] = true
                end
                if not skipCallback then
                    info.func(self, info)
                end
            end
        end

        self:UpdateText()
    end

    function dropdown:SetButtonHidden(setHidden)
        if setHidden then
            dropdown.arrow:Hide()
        else
            dropdown.arrow:Show()
        end
    end

    function dropdown:SetDefaultText(text)
        self:SetUserData("defaultText", text)
        self:UpdateText()
    end

    function dropdown:SetDisabled(isDisabled)
        self:SetUserData("disabled", isDisabled)
        if isDisabled then
            self.arrow:SetTextColor(private.interface.colors[private:UseClassColor() and "dimmedClass" or "dimmedFlair"]:GetRGBA())
        else
            self.arrow:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
        end
        self:SetEnabled(not isDisabled)
    end

    function dropdown:SetInfo(info)
        assert(type(info) == "function", "GuildBankSnapshotsDropdownButton: info must be a callback function")
        self:SetUserData("info", info)

        if self.handlers.OnInfoSet then
            self.handlers.OnInfoSet(self)
        end
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

            if self.handlers.OnMenuClosed then
                self.handlers.OnMenuClosed(self)
            end
        else
            self.menu:Open()
        end
    end

    function dropdown:UpdateText()
        self:SetText(self:GetUserData("defaultText") or "")

        local text
        for selectedID, enabled in addon:pairs(self:GetUserData("selected")) do
            if enabled then
                local info = dropdown:GetInfo(selectedID)

                if info then
                    if not text then
                        text = info.text
                    else
                        text = text .. ", " .. info.text
                    end
                end
            end
        end

        if text then
            self:SetText(text)
        end
    end
end

function GuildBankSnapshotsDropdownFrame_OnLoad(frame)
    frame = private:MixinElementContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self.label:Fire("OnAcquire")
            self.dropdown:Fire("OnAcquire")
            self.dropdown.menu:Fire("OnAcquire")

            self.label:Justify("LEFT", "MIDDLE")

            self:SetLabelFont(GameFontHighlightSmall, private.interface.colors.white)

            self:SetSize(150, 40)
            self:Fire("OnSizeChanged", self:GetWidth(), self:GetHeight())

            self:RegisterCallbacks(self.dropdown)
        end,

        OnSizeChanged = function(self, width, height)
            self.label:SetHeight(20)
            self.label:SetPoint("TOPLEFT")
            self.label:SetPoint("TOPRIGHT")

            self.dropdown:SetHeight(height - 20)
            self.dropdown:SetPoint("BOTTOMLEFT")
            self.dropdown:SetPoint("BOTTOMRIGHT")
        end,
    })

    -- Elements
    frame.label = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.dropdown = frame:Acquire("GuildBankSnapshotsDropdownButton")

    -- Methods
    function frame:GetInfo()
        return self.dropdown:GetInfo()
    end

    function frame:Justify(...)
        self.dropdown:Justify(...)
    end

    function frame:RegisterCallbacks(mainElement)
        self:SetUserData("mainElement", mainElement)

        self.label:SetCallbacks({
            OnEnter = {
                function(label)
                    self:FireScript("OnEnter")
                end,
            },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
        })

        mainElement:SetCallbacks({
            OnEnter = {
                function(label)
                    self:ShowTooltip()
                end,
            },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
        })
    end

    function frame:SelectByID(...)
        self.dropdown:SelectByID(...)
    end

    function frame:SetDefaultText(...)
        self.dropdown:SetDefaultText(...)
    end

    function frame:SetDisabled(...)
        self.dropdown:SetDisabled(...)
    end

    function frame:SetInfo(...)
        self.dropdown:SetInfo(...)
    end

    function frame:SetLabel(text)
        self.label:SetText(text)
    end

    function frame:SetLabelFont(fontObject, color)
        self.label:SetFontObject(fontObject or GameFontHighlightSmall)
        self.label:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:SetStyle(...)
        self.dropdown:SetStyle(...)
    end

    function frame:SetText(...)
        self.dropdown:SetText(...)
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
            self:GetUserData("dropdown"):SelectByID(self:GetUserData("info").id)

            if self:GetUserData("menu").style.multiSelect then
                self:SetChecked()
            else
                self:GetUserData("menu"):Hide()
            end
        end,

        OnEnter = function(self)
            self.highlight:Show()

            if self.text:GetStringWidth() > self.text:GetWidth() then
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    local text = self.text:GetText()
                    GameTooltip:AddLine(text, unpack(private.interface.colors.white))
                end)
            end
        end,

        OnLeave = function(self)
            self.highlight:Hide()
            private:HideTooltip()
        end,
    })

    -- Textures
    button.container = button:CreateTexture(nil, "BACKGROUND")

    button.checkBoxBorder = button:CreateTexture(nil, "BORDER")
    button.checkBoxBorder:SetColorTexture(private.interface.colors.black:GetRGBA())

    button.checkBox = button:CreateTexture(nil, "ARTWORK")
    button.checkBox:SetPoint("TOPLEFT", button.checkBoxBorder, "TOPLEFT", 1, -1)
    button.checkBox:SetPoint("BOTTOMRIGHT", button.checkBoxBorder, "BOTTOMRIGHT", -1, 1)
    button.checkBox:SetColorTexture(private.interface.colors.light:GetRGBA())

    button.checked = button:CreateTexture(nil, "OVERLAY")
    button.checked:SetPoint("TOPLEFT", button.checkBoxBorder, "TOPLEFT", -4, 4)
    button.checked:SetPoint("BOTTOMRIGHT", button.checkBoxBorder, "BOTTOMRIGHT", 4, -4)
    button.checked:SetTexture(130751)
    button.checked:Hide()

    button.highlight = button:CreateTexture(nil, "BACKGROUND")
    button.highlight:SetAllPoints(button)
    button.highlight:Hide()

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

    -- Methods
    function button:SetAnchors()
        local style = self:GetUserData("menu").style
        local leftAligned = style.checkAlignment == "LEFT"
        local xMod = leftAligned and 1 or -1

        if style.hasCheckBox then
            local size = min(self.container:GetHeight(), 12)
            size = size == 0 and 12 or size
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
            self.text:SetPoint(style.checkAlignment, self.container, style.checkAlignment, xMod * style.paddingX, 0)
            self.text:SetPoint(leftAligned and "RIGHT" or "LEFT", self.container, leftAligned and "RIGHT" or "LEFT", -(xMod * style.paddingX), 0)
            self.text:SetPoint("BOTTOM", self.container, "BOTTOM")
        end
    end

    function button:SetChecked()
        local checked = self:GetUserData("dropdown"):GetSelected(self:GetUserData("info").id)
        if checked then
            self.checked:Show()
        else
            self.checked:Hide()
        end
    end

    function button:SetInfo(menu, buttonID, info)
        self:SetUserData("menu", menu)
        self:SetUserData("dropdown", menu.dropdown)
        self:SetUserData("buttonID", buttonID)
        self:SetUserData("info", info)

        button:Update()
    end

    function button:Update()
        if not self:GetUserData("info") then
            return
        end

        self.container:SetPoint("TOPLEFT", self:GetUserData("menu").style.paddingX, -self:GetUserData("menu").style.paddingY)
        self.container:SetPoint("BOTTOMRIGHT", -self:GetUserData("menu").style.paddingX, self:GetUserData("menu").style.paddingY)

        self.highlight:SetColorTexture(self:GetUserData("menu").style.buttonHighlight:GetRGBA())

        self:Justify(self:GetUserData("menu").style.justifyH, self:GetUserData("menu").style.justifyV)
        self:SetText(self:GetUserData("info").text)

        self:SetAnchors()
        self:SetChecked()
    end
end

function GuildBankSnapshotsDropdownMenu_OnLoad(menu)
    menu = private:MixinContainer(menu)
    menu:SetFrameLevel(1000)
    menu:InitScripts({
        OnAcquire = function(self)
            self:InitializeStyle()
        end,

        OnRelease = function(self)
            self:ReleaseAll()
        end,
    })

    -- Textures
    menu.bg, menu.border = private:AddBackdrop(menu, { bgColor = "dark" })

    -- Methods
    function menu:Close()
        self:ClearAllPoints()
        self:Hide()
    end

    function menu:InitializeListFrame()
        self:ReleaseAll()
        self:SetHeight(self:GetHeight() + 2) -- to account for border

        local listFrame = self:Acquire("GuildBankSnapshotsListScrollFrame")

        local searchBox = self:Acquire("GuildBankSnapshotsEditBox")
        searchBox.bg:SetColorTexture(private.interface.colors.lightest:GetRGBA())
        searchBox:SetSearchTemplate(true)
        searchBox:SetHeight(20)
        searchBox:Hide()
        if self.style.hasSearch then
            searchBox:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -5)
            searchBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -5, 0)
            self:SetHeight(self:GetHeight() + 30)
            searchBox:Show()
        end

        searchBox:SetCallback("OnTextChanged", function(_, userInput)
            local text = searchBox:GetText()

            if userInput then
                local provider = listFrame:SetDataProvider(function(provider)
                    for _, info in pairs(self.dropdown:GetInfo()) do
                        if strfind(strupper(info.id), strupper(text)) then
                            provider:Insert(info)
                        end
                    end
                    self:SetHeight(min(((provider:GetSize() + 1) * self.style.buttonHeight) + (self.style.hasSearch and 30 or 0) + (self.style.hasClear and 30 or 0) + 2, self.style.maxHeight))
                end)
            end
        end)

        searchBox:SetCallback("OnClear", function(...)
            listFrame:SetDataProvider(function(provider)
                provider:InsertTable(self.dropdown:GetInfo())
                self:SetHeight(min(((provider:GetSize() + 1) * self.style.buttonHeight) + (self.style.hasSearch and 30 or 0) + (self.style.hasClear and 30 or 0) + 2, self.style.maxHeight))
            end)
        end)

        local clearButton = self:Acquire("GuildBankSnapshotsButton")
        clearButton:SetText(L["Clear"])
        clearButton:SetHeight(20)
        clearButton:Hide()
        if self.style.hasClear then
            clearButton:Show()
            if self.style.hasSearch then
                clearButton:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -5)
                clearButton:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", 0, 0)
            else
                clearButton:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -5)
                clearButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -5, 0)
            end
            self:SetHeight(self:GetHeight() + 30)
        end

        clearButton:SetCallback("OnClick", function()
            self:Close()
            self.dropdown:Clear()
        end)

        if self.style.hasClear or self.style.hasSearch then
            listFrame:SetPoint("TOP", self.style.hasClear and clearButton or self.style.hasSearch and searchBox, "BOTTOM", 0, -5)
            listFrame:SetPoint("LEFT", self.bg, "LEFT")
            listFrame:SetPoint("BOTTOM", self.bg, "BOTTOM")
        else
            listFrame:SetPoint("TOPLEFT", self.bg, "TOPLEFT")
            listFrame:SetPoint("BOTTOMRIGHT", self.bg, "BOTTOMRIGHT")
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
            buttonHighlight = private.interface.colors[private:UseClassColor() and "dimmedClass" or "dimmedFlair"],
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
            hasSelectAll = false,
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
