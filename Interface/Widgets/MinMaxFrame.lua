local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsMinMaxFrame_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self:SetSize(100, 40)
            self.lowerText:Justify("LEFT", "MIDDLE")
            self.upperText:Justify("LEFT", "MIDDLE")
            self:SetLabels()
            self:HideLabels()
        end,

        OnSizeChanged = function(self, width, height)
            width = width - 5
            self.lowerText:SetSize(width / 2, height - 20)
            self.lower:SetSize(width / 2, height - (self.hideLabels and 0 or 20))
            self.upperText:SetSize(width / 2, height - 20)
            self.upper:SetSize(width / 2, height - (self.hideLabels and 0 or 20))
        end,

        OnRelease = function(self)
            self.minValue = nil
            self.maxValue = nil
            self.callback = nil
            self.formatter = nil
            self.reverseFormatter = nil
            self.lower.value = nil
            self.upper.value = nil
        end,
    })

    frame.lowerText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.lowerText:SetPoint("TOPLEFT")
    frame.lowerText:SetText(L["Min"])

    frame.lower = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.lower:SetPoint("BOTTOMLEFT")

    frame.upperText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.upperText:SetPoint("TOPRIGHT")
    frame.upperText:SetText(L["Max"])

    frame.upper = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.upper:SetPoint("BOTTOMRIGHT")

    -- Methods
    function frame:HideLabels(isHidden)
        self.hideLabels = isHidden

        if isHidden then
            self.lowerText:Hide()
            self.upperText:Hide()
            self:SetHeight(self:GetHeight() - 20)
        else
            self.lowerText:Show()
            self.upperText:Show()
        end
    end

    function frame:SetDisabled(isDisabled)
        self.lower:SetDisabled(isDisabled)
        self.upper:SetDisabled(isDisabled)
    end

    function frame:SetMaxValue(maxValue)
        self.upper.value = tonumber(maxValue)
        self.upper:SetText(self.formatter and self.formatter(maxValue) or maxValue)
    end

    function frame:SetMinMaxValues(minValue, maxValue, callback, formatter, reverseFormatter)
        self.minValue = minValue
        self.maxValue = maxValue
        self.callback = callback
        self.formatter = formatter
        self.reverseFormatter = reverseFormatter
    end

    function frame:SetMinValue(minValue)
        self.lower.value = tonumber(minValue)
        self.lower:SetText(self.formatter and self.formatter(minValue) or minValue)
    end

    function frame:SetLabels(lower, upper)
        self.lowerText:SetText(lower or L["Min"])
        self.upperText:SetText(lower or L["Max"])
    end

    function frame:SetValues(minValue, maxValue)
        self:SetMinValue(minValue)
        self:SetMaxValue(maxValue)
    end

    function frame:ValidateValues(editBox, value, default)
        value = tonumber(value)
        if not value then
            return true
        elseif value < self.minValue then
            self:SetMinValue(self.minValue)
        elseif value > self.maxValue then
            self:SetMaxValue(self.maxValue)
        end
    end

    -- Scripts
    frame.lower:SetCallback("OnEnterPressed", function(self)
        self:ClearFocus()

        local text = self:GetText()
        if frame.reverseFormatter then
            text = frame.reverseFormatter(text) or tonumber(text)
        end
        text = tonumber(text)

        local upper = frame.upper.value
        if text > upper then
            frame:SetMinValue(upper)
        elseif text > frame.maxValue then
            frame:SetMinValue(frame.maxValue)
        elseif text < frame.minValue then
            frame:SetMinValue(frame.minValue)
        else
            frame:SetMinValue(text)
        end

        if frame.callback then
            frame.callback(frame, "lower", self:GetText())
        end
    end)

    frame.upper:SetCallback("OnEnterPressed", function(self)
        self:ClearFocus()

        local text = self:GetText()
        if frame.reverseFormatter then
            text = frame.reverseFormatter(text) or tonumber(text)
        end
        text = tonumber(text)

        local lower = frame.lower.value
        if text < lower then
            frame:SetMaxValue(lower)
        elseif text < frame.minValue then
            frame:SetMaxValue(frame.minValue)
        elseif text > frame.maxValue then
            frame:SetMaxValue(frame.maxValue)
        else
            frame:SetMaxValue(text)
        end

        if frame.callback then
            frame.callback(frame, "upper", self:GetText())
        end
    end)
end
