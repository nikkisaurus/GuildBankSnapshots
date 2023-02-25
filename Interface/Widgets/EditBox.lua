local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsEditBox_OnLoad(editbox)
    editbox = private:MixinWidget(editbox)
    editbox:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)

            self:SetBackdropColor(private.interface.colors.light)
            self:SetHighlightColor(private.interface.colors.lightWhite)

            self:SetFontObject(GameFontHighlightSmall)
            self:SetText("")

            self:SetAutoFocus(false)
            self:SetTextInsets(5, 5, 2, 2)
            self:SetSearchTemplate()
            self:SetDisabled()
        end,

        OnEnter = function(self)
            if self:IsEnabled() then
                self.border:SetColorTexture(self.highlight:GetRGBA())
            end
        end,

        OnEnterPressed = function(self)
            self:ClearFocus()
        end,

        OnEscapePressed = function(self)
            self:ClearFocus()
        end,

        OnLeave = function(self)
            self.border:SetColorTexture(private.interface.colors.black:GetRGBA())
        end,

        OnTextChanged = function(self)
            if self.isSearchBox and self:IsValidText() then
                self.clearButton:Show()
            else
                self.clearButton:Hide()
            end
        end,

        OnRelease = function(self)
            self.isSearchBox = nil
        end,
    })

    -- Textures
    editbox.bg, editbox.border = private:AddBackdrop(editbox)

    editbox.searchIcon = editbox:CreateTexture(nil, "ARTWORK")
    editbox.searchIcon:SetPoint("LEFT", 5, 0)
    editbox.searchIcon:SetTexture(374210)

    editbox.clearButton = CreateFrame("Button", nil, editbox)
    editbox.clearButton:SetPoint("RIGHT", -5, 0)
    editbox.clearButton:SetNormalTexture(374214)
    editbox.clearButton:Hide()

    editbox.clearButton:SetScript("OnClick", function()
        editbox:SetText("")
        if editbox.handlers.OnClear then
            editbox.handlers.OnClear(editbox)
        end
    end)

    -- Methods
    function editbox:IsValidText()
        return private:strcheck(editbox:GetText())
    end

    function editbox:SetDisabled(isDisabled)
        if isDisabled then
            self:SetEnabled()
            self:SetBackdropColor(private.interface.colors.dark)
            self.searchIcon:SetVertexColor(private.interface.colors.dimmedWhite:GetRGBA())
        else
            self:SetEnabled(true)
            self:SetBackdropColor(private.interface.colors.light)
            self.searchIcon:SetVertexColor(private.interface.colors.white:GetRGBA())
        end
    end

    function editbox:SetHighlightColor(color)
        self.highlight = color
    end

    function editbox:SetSearchTemplate(isSearchBox)
        self.isSearchBox = isSearchBox
        if isSearchBox then
            local iconSize = min(12, self:GetHeight())
            self:SetTextInsets(iconSize + 10, iconSize + 10, 2, 2)

            editbox.searchIcon:Show()
            editbox.searchIcon:SetSize(iconSize, iconSize)
            editbox.clearButton:SetSize(iconSize, iconSize)
        else
            self:SetTextInsets(5, 5, 2, 2)

            editbox.searchIcon:Hide()
            editbox.clearButton:Hide()
        end
    end
end

function GuildBankSnapshotsEditBoxFrame_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 40)

            self.label:Justify("LEFT", "MIDDLE")
            self:SetLabelFont(GameFontHighlightSmall, private.interface.colors.white)
            self:SetLabel("")

            self:SetEditboxFont(GameFontHighlightSmall)
            self:SetText("")
        end,

        OnSizeChanged = function(self, width, height)
            self.label:SetSize(width, 20)
            self.editbox:SetSize(width, height - 20)
        end,
    })

    frame.label = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.label:SetPoint("TOPLEFT")

    frame.editbox = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.editbox:SetPoint("BOTTOMLEFT")

    -- Methods
    function frame:IsValidText()
        return self.editbox:IsValidText()
    end

    function frame:SetDisabled(...)
        self.editbox:SetDisabled(...)
    end

    function frame:SetEditboxFont(fontObject)
        self.editbox:SetFontObject(fontObject or GameFontHighlightSmall)
    end

    function frame:SetHighlightColor(...)
        self.editbox:SetHighlightColor(...)
    end

    function frame:SetLabel(text)
        self.label:SetText(text)
    end

    function frame:SetLabelFont(fontObject, color)
        self.label:SetFontObject(fontObject or GameFontHighlightSmall)
        self.label:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:SetSearchTemplate(...)
        self.editbox:SetSearchTemplate(...)
    end

    function frame:SetText(text)
        self.editbox:SetText(text)
    end
end
