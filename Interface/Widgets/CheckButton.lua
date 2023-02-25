local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsCheckButton_OnLoad(button)
    button:EnableMouse(true)
    button = private:MixinText(button)

    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:Justify("LEFT", "TOP")
            self:SetAutoHeight(true)
            self:SetDisabled()
            self:SetAnchors()
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
        self.checkBoxBorder:SetSize(size, size)
        self.checkBoxBorder:SetPoint("TOPLEFT", self, "TOPLEFT")
        self.text:SetPoint("TOPLEFT", self.checkBox, "TOPRIGHT", 5, 0)
        self.text:SetPoint("RIGHT", -5, 0)
    end

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
