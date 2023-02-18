local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsCheckButton_OnLoad(button)
    button:EnableMouse(true)
    button = private:MixinText(button)
    button = private:MixinWidget(button)

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
