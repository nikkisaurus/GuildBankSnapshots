local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local relPoint = {
    LEFT = { "RIGHT", "RIGHT", 1, -1 },
    TOPLEFT = { "TOPRIGHT", "RIGHT", 1, -1 },
    BOTTOMLEFT = { "BOTTOMRIGHT", "RIGHT", 1, -1 },
    RIGHT = { "LEFT", "LEFT", -1, 1 },
    TOPRIGHT = { "TOPLEFT", "LEFT", -1, 1 },
    BOTTOMRIGHT = { "BOTTOMLEFT", "LEFT", -1, 1 },
}

function GuildBankSnapshotsCheckButton_OnLoad(button)
    button:EnableMouse(true)
    button = private:MixinText(button)

    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:Justify("LEFT", "TOP")
            self:SetAutoHeight(true)
            self:SetDisabled()
            self:SetCheckAlignment("TOPLEFT")
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

        OnSizeChanged = function(self)
            self:SetAnchors()
        end,

        OnRelease = function(self)
            self.alignment = nil
            self.width = nil
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
        local alignment = relPoint[self.alignment]
        self.checkBoxBorder:ClearAllPoints()
        self.checkBoxBorder:SetSize(size, size)
        self.checkBoxBorder:SetPoint(self.alignment, self, self.alignment)
        self.text:ClearAllPoints()
        self.text:SetPoint(self.alignment, self.checkBox, alignment[1], alignment[3] * 5, 0)
        self.text:SetPoint(alignment[2], alignment[4] * 5, 0)
    end

    function button:GetChecked()
        return self.isChecked
    end

    function button:GetMinWidth()
        return self.checkBoxBorder:GetWidth() + self:GetStringWidth() + 20
    end

    function button:SetChecked(isChecked)
        self.isChecked = isChecked

        if isChecked then
            self.checked:Show()
        else
            self.checked:Hide()
        end
    end

    function button:SetCheckAlignment(alignment)
        self.alignment = alignment
        self:SetAnchors()
    end

    function button:SetCheckedState(isChecked, skipCallback)
        self.isChecked = isChecked
        self:SetChecked(isChecked)
        if not skipCallback then
            self.handlers.OnClick(self)
        end
    end

    function button:SetDisabled(isDisabled)
        self:SetTextColor(private.interface.colors[isDisabled and "dimmedWhite" or "white"]:GetRGBA())
        self:SetEnabled(not isDisabled)
    end

    function button:SetTooltipInitializer(tooltip)
        self.tooltip = tooltip
    end
end
