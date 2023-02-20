local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsSlider_OnLoad(slider)
    slider = private:MixinWidget(slider)
    slider:InitScripts({
        OnAcquire = function(self)
            self:SetHeight(10)
            self:SetOrientation("HORIZONTAL")
            self:SetObeyStepOnDrag(true)
            self:SetMinMaxValues(0, 1)
            self:SetValueStep(1)
            self:SetValue(0)
            self:SetDisabled()
        end,
    })

    -- Textures
    slider.bg = slider:CreateTexture(nil, "BACKGROUND")
    slider.bg:SetAllPoints(slider)
    slider.bg:SetColorTexture(private.interface.colors.elementColor:GetRGBA())

    slider.thumb = slider:CreateTexture(nil, "ARTWORK")
    slider.thumb:SetSize(11, 11)
    slider.thumb:SetColorTexture(private.interface.colors.highlightColor:GetRGBA())
    slider:SetThumbTexture(slider.thumb)

    -- -- Methods
    function slider:SetDisabled(isDisabled)
        if isDisabled then
            self:Disable()
            slider.thumb:Hide()
        else
            self:Enable()
            slider.thumb:Show()
        end
    end
end

function GuildBankSnapshotsDualSlider_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnShow = function(self)
            self:SetSize(200, 62)
            self.lowerText:Justify("LEFT", "MIDDLE")
            self.lowerText:SetText(L["Lower"])
            self.upperText:Justify("RIGHT", "MIDDLE")
            self.upperText:SetText(L["Upper"])
        end,

        OnSizeChanged = function(self, width, height)
            height = (height - 22) / 2

            self.lowerText:SetSize(width, height)
            self.lower:SetSize(width, 11)
            self.upper:SetSize(width, 11)
            self.upperText:SetSize(width, height)

            self.lowerText:SetPoint("TOPLEFT")
            self.lower:SetPoint("TOPLEFT", self.lowerText, "BOTTOMLEFT")
            self.upper:SetPoint("BOTTOMRIGHT", self.upperText, "TOPRIGHT")
            self.upperText:SetPoint("BOTTOMRIGHT")
        end,

        OnRelease = function(self)
            self.formatter = nil
        end,
    })

    frame.lowerText = frame:Acquire("GuildBankSnapshotsFontFrame")

    frame.lower = frame:Acquire("GuildBankSnapshotsSlider")
    frame.lower:SetCallback("OnValueChanged", function(self, ...)
        local lower = self:GetValue()
        local upper = frame.upper:GetValue()

        if lower > upper then
            self:SetValue(upper)
        end

        frame.lowerText:SetText(frame.formatter and frame.formatter(self:GetValue()) or self:GetValue())

        if frame.handlers.OnValueChanged then
            frame.handlers.OnValueChanged(frame, "lower", self, ...)
        end
    end)

    frame.upperText = frame:Acquire("GuildBankSnapshotsFontFrame")

    frame.upper = frame:Acquire("GuildBankSnapshotsSlider")
    frame.upper:SetCallback("OnValueChanged", function(self, ...)
        local upper = self:GetValue()
        local lower = frame.lower:GetValue()

        if upper < lower then
            self:SetValue(lower)
        end

        frame.upperText:SetText(frame.formatter and frame.formatter(self:GetValue()) or self:GetValue())

        if frame.handlers.OnValueChanged then
            frame.handlers.OnValueChanged(frame, "upper", self, ...)
        end
    end)

    -- Methods
    function frame:SetDisabled(isDisabled)
        self.lower:SetDisabled(isDisabled)
        self.upper:SetDisabled(isDisabled)
    end

    function frame:SetMaxValue(value)
        self.upper:SetValue(value)
        self.upperText:SetText(self.formatter and self.formatter(value) or value)
    end

    function frame:SetMinMaxValues(minValue, maxValue, stepValue, formatter, setDefault)
        self.lower:SetMinMaxValues(minValue, maxValue)
        self.upper:SetMinMaxValues(minValue, maxValue)

        self.lower:SetObeyStepOnDrag(true)
        self.upper:SetObeyStepOnDrag(true)

        self.upper:SetValueStep(stepValue)
        self.upper:SetValueStep(stepValue)

        self.formatter = formatter

        if setDefault then
            self:SetMinValue(minValue)
            self:SetMaxValue(maxValue)
        end
    end

    function frame:SetMinValue(value)
        self.lower:SetValue(value)
        self.lowerText:SetText(self.formatter and self.formatter(value) or value)
    end
end
