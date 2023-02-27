local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local alignment = {
    LEFT = { "RIGHT", 1, "RIGHT", -1 },
    TOPLEFT = { "TOPRIGHT", 1, "RIGHT", -1 },
    BOTTOMLEFT = { "BOTTOMRIGHT", 1, "RIGHT", -1 },
    RIGHT = { "LEFT", -1, "LEFT", 1 },
    TOPRIGHT = { "TOPLEFT", -1, "LEFT", 1 },
    BOTTOMRIGHT = { "BOTTOMLEFT", -1, "LEFT", 1 },
}

function GuildBankSnapshotsCheckButton_OnLoad(button)
    button = private:MixinText(button)
    button:InitScripts({
        OnAcquire = function(self)
            self:SetDisabled()
            self:SetSize(150, 20)
            self:SetPadding(5)
            self:SetCheckAlignment("LEFT")
            self:Justify("LEFT", "TOP")
            self:SetAutoHeight(true)
        end,

        OnClick = function(self, ...)
            self:SetChecked(not self:GetChecked())
        end,

        OnEnter = function(self)
            self:ShowTooltip()
        end,

        OnLeave = GenerateClosure(private.HideTooltip, private),

        OnSizeChanged = function(self)
            self:SetAnchors()
        end,
    })

    -- Textures
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

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

    -- Methods
    function button:SetAnchors()
        local size = min(self:GetHeight(), 12)
        size = size == 0 and 12 or size
        local alignment = alignment[self:GetUserData("alignment")]
        self.checkBoxBorder:ClearAllPoints()
        self.checkBoxBorder:SetSize(size, size)
        self.checkBoxBorder:SetPoint(self:GetUserData("alignment"), self, self:GetUserData("alignment"))
        self.text:ClearAllPoints()
        self.text:SetPoint(self:GetUserData("alignment"), self.checkBox, alignment[1], alignment[2] * self:GetUserData("padding"), 0)
        self.text:SetPoint(alignment[3], alignment[4] * self:GetUserData("padding"), 0)
    end

    function button:GetChecked()
        return self.isChecked
    end

    function button:SetCheckAlignment(alignment)
        self:SetUserData("alignment", alignment)
        self:SetAnchors()
    end

    function button:SetCheckedState(isChecked, skipCallback)
        self.isChecked = isChecked
        self:SetChecked(isChecked)
        if not skipCallback then
            self.handlers.OnClick(self)
        end
    end

    function button:SetChecked(isChecked)
        self.isChecked = isChecked

        if isChecked then
            self.checked:Show()
        else
            self.checked:Hide()
        end
    end

    function button:SetDisabled(isDisabled)
        self:SetTextColor(private.interface.colors[isDisabled and "dimmedWhite" or "white"]:GetRGBA())
        self:SetEnabled(not isDisabled)
    end

    function button:SetMinWidth()
        self:SetWidth(self.checkBoxBorder:GetWidth() + self:GetStringWidth() + 20)
    end

    function button:SetPadding(padding)
        self:SetUserData("padding", padding or 0)
    end

    function button:SetText(text, autoWidth)
        self.text:SetText(text)
        if autoWidth then
            self:SetMinWidth()
        end
    end
end
