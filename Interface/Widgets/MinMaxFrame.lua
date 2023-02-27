local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsMinMaxFrame_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self.lowerText:Fire("OnAcquire")
            self.lower:Fire("OnAcquire")
            self.upperText:Fire("OnAcquire")
            self.upper:Fire("OnAcquire")

            self.lowerText:Justify("LEFT", "MIDDLE")
            self.upperText:Justify("LEFT", "MIDDLE")

            self:SetLabelFont(GameFontHighlightSmall, private.interface.colors.white)
            self:HideLabels()
            self:SetLabels()

            self:SetSize(100, 40)
            self:Fire("OnSizeChanged", self:GetWidth(), self:GetHeight())

            self:RegisterCallbacks()
        end,

        OnSizeChanged = function(self, width, height)
            width = width - 5
            self.lowerText:SetSize(width / 2, height - 20)
            self.lowerText:SetPoint("TOPLEFT")

            self.lower:SetSize(width / 2, height - (self:GetUserData("hideLabels") and 0 or 20))
            self.lower:SetPoint("BOTTOMLEFT")

            self.upperText:SetSize(width / 2, height - 20)
            self.upperText:SetPoint("TOPRIGHT")

            self.upper:SetSize(width / 2, height - (self:GetUserData("hideLabels") and 0 or 20))
            self.upper:SetPoint("BOTTOMRIGHT")
        end,
    })

    -- Elements
    frame.lowerText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.lower = frame:Acquire("GuildBankSnapshotsEditBox")
    frame.upperText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.upper = frame:Acquire("GuildBankSnapshotsEditBox")

    -- Methods
    function frame:HideLabels(isHidden)
        self:SetUserData("hideLabels", isHidden)

        if isHidden then
            self.lowerText:Hide()
            self.upperText:Hide()
            self:SetHeight(self:GetHeight() - 20)
        else
            self.lowerText:Show()
            self.upperText:Show()
        end
    end

    function frame:RegisterCallbacks()
        self.lower:SetCallbacks({
            OnEnterPressed = {
                function(lower)
                    lower:ClearFocus()

                    local text = lower:GetText()
                    if self:GetUserData("reverseFormatter") then
                        text = self:GetUserData("reverseFormatter")(text) or tonumber(text)
                    end
                    text = tonumber(text)

                    local upper = self:GetUserData("upperValue")
                    if text > upper then
                        self:SetMinValue(upper)
                    elseif text > self:GetUserData("maxValue") then
                        self:SetMinValue(self:GetUserData("maxValue"))
                    elseif text < self:GetUserData("minValue") then
                        self:SetMinValue(self:GetUserData("minValue"))
                    else
                        self:SetMinValue(text)
                    end

                    if self:GetUserData("callback") then
                        self:GetUserData("callback")(self, "lower", lower:GetText())
                    end
                end,
            },
        })

        self.upper:SetCallbacks({
            OnEnterPressed = {
                function(upper)
                    upper:ClearFocus()

                    local text = upper:GetText()
                    if self:GetUserData("reverseFormatter") then
                        text = self:GetUserData("reverseFormatter")(text) or tonumber(text)
                    end
                    text = tonumber(text)

                    local lower = self:GetUserData("lowerValue")
                    if text < lower then
                        self:SetMaxValue(lower)
                    elseif text < self:GetUserData("minValue") then
                        self:SetMaxValue(self:GetUserData("minValue"))
                    elseif text > self:GetUserData("maxValue") then
                        self:SetMaxValue(self:GetUserData("maxValue"))
                    else
                        self:SetMaxValue(text)
                    end

                    if self:GetUserData("callback") then
                        self:GetUserData("callback")(self, "upper", upper:GetText())
                    end
                end,
            },
        })
    end

    function frame:SetDisabled(isDisabled)
        self.lower:SetDisabled(isDisabled)
        self.upper:SetDisabled(isDisabled)
    end

    function frame:SetLabelFont(fontObject, color)
        self.lowerText:SetFontObject(fontObject or GameFontHighlightSmall)
        self.lowerText:SetTextColor((color and color or private.interface.colors.white):GetRGBA())

        self.upperText:SetFontObject(fontObject or GameFontHighlightSmall)
        self.upperText:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:SetMaxValue(maxValue)
        self:SetUserData("upperValue", tonumber(maxValue))
        self.upper:SetText(self:GetUserData("formatter") and self:GetUserData("formatter")(maxValue) or maxValue)
    end

    function frame:SetMinMaxValues(minValue, maxValue, callback, formatter, reverseFormatter)
        self:SetUserData("minValue", minValue)
        self:SetUserData("maxValue", maxValue)
        self:SetUserData("callback", callback)
        self:SetUserData("formatter", formatter)
        self:SetUserData("reverseFormatter", reverseFormatter)
    end

    function frame:SetMinValue(minValue)
        self:SetUserData("lowerValue", tonumber(minValue))
        self.lower:SetText(self:GetUserData("formatter") and self:GetUserData("formatter")(minValue) or minValue)
    end

    function frame:SetLabels(lower, upper)
        self.lowerText:SetText(lower or L["Min"])
        self.upperText:SetText(upper or L["Max"])
    end

    function frame:SetValues(minValue, maxValue)
        self:SetMinValue(minValue)
        self:SetMaxValue(maxValue)
    end

    function frame:ValidateValues(editBox, value, default)
        value = tonumber(value)
        if not value then
            return true
        elseif value < self:GetUserData("minValue") then
            self:SetMinValue(self:GetUserData("minValue"))
        elseif value > self:GetUserData("maxValue") then
            self:SetMaxValue(self:GetUserData("maxValue"))
        end
    end
end
