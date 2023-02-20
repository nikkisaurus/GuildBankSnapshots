local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsMinMaxFrame_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            frame:SetSize(100, 40)
            frame.lowerText:Justify("LEFT", "MIDDLE")
            frame.upperText:Justify("LEFT", "MIDDLE")
        end,

        OnSizeChanged = function(self, width, height)
            width = width - 5
            frame.lowerText:SetSize(width / 2, height - 20)
            frame.lower:SetSize(width / 2, height - 20)
            frame.upperText:SetSize(width / 2, height - 20)
            frame.upper:SetSize(width / 2, height - 20)
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
    frame.lowerText:SetText("Min")
    frame.lower = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.lower:SetPoint("BOTTOMLEFT")
    frame.lower:SetScript("OnEnterPressed", function(self)
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

    frame.upperText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.upperText:SetPoint("TOPRIGHT")
    frame.upperText:SetText("Max")
    frame.upper = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.upper:SetPoint("BOTTOMRIGHT")
    frame.upper:SetScript("OnEnterPressed", function(self)
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

    -- Methods
    function frame:SetDisabled(isDisabled)
        frame.lower:SetDisabled(isDisabled)
        frame.upper:SetDisabled(isDisabled)
    end

    function frame:SetMaxValue(maxValue)
        frame.upper.value = tonumber(maxValue)
        frame.upper:SetText(self.formatter and self.formatter(maxValue) or maxValue)
    end

    function frame:SetMinMaxValues(minValue, maxValue, callback, formatter, reverseFormatter)
        self.minValue = minValue
        self.maxValue = maxValue
        self.callback = callback
        self.formatter = formatter
        self.reverseFormatter = reverseFormatter
    end

    function frame:SetMinValue(minValue)
        frame.lower.value = tonumber(minValue)
        frame.lower:SetText(self.formatter and self.formatter(minValue) or minValue)
    end

    function frame:SetValues(minValue, maxValue)
        frame:SetMinValue(minValue)
        frame:SetMaxValue(maxValue)
    end

    function frame:ValidateValues(editBox, value, default)
        value = tonumber(value)
        if not value then
            return true
        elseif value < frame.minValue then
            frame:SetMinValue(frame.minValue)
        elseif value > frame.maxValue then
            frame:SetMaxValue(frame.maxValue)
        end
    end
end
