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
            print("CLICK")
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
        size = size == 0 and 12 or size
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

function GuildBankSnapshotsCheckButtonFrame_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 40)

            self.label:Justify("LEFT", "MIDDLE")
            self:SetLabelFont(GameFontHighlightSmall, private.interface.colors.white)
            self:SetLabel("")
        end,

        -- OnSizeChanged = function(self, width, height)
        --     self.label:SetSize(width, 20)
        --     self.checkButton:SetHeight(height - 20)
        -- end,

        OnRelease = function(self)
            self.width = nil
            self.autoWidth = nil
        end,
    })

    frame.label = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.label:SetPoint("TOPLEFT")
    frame.label:SetPoint("TOPRIGHT")

    frame.checkButton = frame:Acquire("GuildBankSnapshotsCheckButton")
    frame.checkButton:SetPoint("BOTTOMLEFT")
    frame.checkButton:SetPoint("BOTTOMRIGHT")

    -- Methods
    function frame:ForwardCallback(...)
        self.checkButton:SetCallback(...)
    end

    function frame:GetMinWidth()
        return self.checkButton:GetMinWidth()
    end

    function frame:SetAutoWidth(autoWidth)
        self.autoWidth = autoWidth
    end

    function frame:SetLabel(text)
        self.label:SetText(text)
    end

    function frame:SetLabelFont(fontObject, color)
        self.label:SetFontObject(fontObject or GameFontHighlightSmall)
        self.label:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:SetText(...)
        self.checkButton:SetText(...)
        if self.autoWidth then
            self.checkButton:SetWidth(self:GetMinWidth())
        end
    end
end
