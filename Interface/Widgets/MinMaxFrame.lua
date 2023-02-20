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
        end,
    })

    frame.lowerText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.lowerText:SetPoint("TOPLEFT")
    frame.lowerText:SetText("Min")
    frame.lower = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.lower:SetPoint("BOTTOMLEFT")
    frame.lower:SetScript("OnEnterPressed", function(self)
        frame:ValidateValues(self, frame.minValue)
        local upper = frame.upper:GetNumber()
        if self:GetNumber() > upper then
            self:SetText(upper)
        end

        if frame.callback then
            frame.callback(frame, "lower", self:GetNumber())
        end
    end)

    frame.upperText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.upperText:SetPoint("TOPRIGHT")
    frame.upperText:SetText("Max")
    frame.upper = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.upper:SetPoint("BOTTOMRIGHT")
    frame.upper:SetScript("OnEnterPressed", function(self)
        frame:ValidateValues(self, frame.maxValue)
        local lower = frame.lower:GetNumber()
        if self:GetNumber() < lower then
            self:SetText(lower)
        end

        if frame.callback then
            frame.callback(frame, "upper", self:GetNumber())
        end
    end)

    -- Methods
    function frame:SetMaxValue(maxValue)
        frame.upper:SetText(maxValue)
    end

    function frame:SetMinMaxValues(minValue, maxValue, callback)
        self.minValue = minValue
        self.maxValue = maxValue
        self.callback = callback
    end

    function frame:SetMinValue(minValue)
        frame.lower:SetText(minValue)
    end

    function frame:SetValues(minValue, maxValue)
        frame:SetMinValue(minValue)
        frame:SetMaxValue(maxValue)
    end

    function frame:ValidateValues(editBox, default)
        local value = tonumber(editBox:GetText())

        if not value then
            editBox:SetText(default)
        elseif value < frame.minValue then
            editBox:SetText(frame.minValue)
        elseif value > frame.maxValue then
            editBox:SetText(frame.maxValue)
        end

        editBox:ClearFocus()
    end
end
