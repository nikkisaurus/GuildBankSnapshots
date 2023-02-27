local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsSlider_OnLoad(slider)
    slider = private:MixinWidget(slider)
    slider:InitScripts({
        OnAcquire = function(self)
            self:SetDisabled()
            self:SetBackdropColor(private.interface.colors.dark)
            self:SetOrientation("HORIZONTAL")
            self:SetObeyStepOnDrag(true)
            self:SetMinMaxValues(0, 1)
            self:SetValueStep(0.1)
            self:SetValue(0)
            self:SetSize(150, 10)
        end,
    })

    -- Textures
    slider.bg = slider:CreateTexture(nil, "BACKGROUND")
    slider.bg:SetAllPoints(slider)

    slider.thumb = slider:CreateTexture(nil, "ARTWORK")
    slider.thumb:SetSize(11, 11)
    slider.thumb:SetColorTexture(private.interface.colors.light:GetRGBA())
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

-- function GuildBankSnapshotsDualSlider_OnLoad(frame)
--     frame = private:MixinContainer(frame)
--     frame:InitScripts({
--         OnShow = function(self)
--             self:SetSize(150, 62)
--             self.lowerText:Justify("LEFT", "MIDDLE")
--             self.lowerText:SetText(L["Lower"])
--             self.upperText:Justify("RIGHT", "MIDDLE")
--             self.upperText:SetText(L["Upper"])
--         end,

--         OnSizeChanged = function(self, width, height)
--             height = (height - 22) / 2

--             self.lowerText:SetSize(width, height)
--             self.lower:SetSize(width, 11)
--             self.upper:SetSize(width, 11)
--             self.upperText:SetSize(width, height)

--             self.lowerText:SetPoint("TOPLEFT")
--             self.lower:SetPoint("TOPLEFT", self.lowerText, "BOTTOMLEFT")
--             self.upper:SetPoint("BOTTOMRIGHT", self.upperText, "TOPRIGHT")
--             self.upperText:SetPoint("BOTTOMRIGHT")
--         end,

--         OnRelease = function(self)
--             self.formatter = nil
--         end,
--     })

--     frame.lowerText = frame:Acquire("GuildBankSnapshotsFontFrame")

--     frame.lower = frame:Acquire("GuildBankSnapshotsSlider")
--     frame.lower:SetCallback("OnValueChanged", function(self, ...)
--         local lower = self:GetValue()
--         local upper = frame.upper:GetValue()

--         if lower > upper then
--             self:SetValue(upper)
--         end

--         frame.lowerText:SetText(frame.formatter and frame.formatter(self:GetValue()) or self:GetValue())

--         if frame.handlers.OnValueChanged then
--             frame.handlers.OnValueChanged(frame, "lower", self, ...)
--         end
--     end)

--     frame.upperText = frame:Acquire("GuildBankSnapshotsFontFrame")

--     frame.upper = frame:Acquire("GuildBankSnapshotsSlider")
--     frame.upper:SetCallback("OnValueChanged", function(self, ...)
--         local upper = self:GetValue()
--         local lower = frame.lower:GetValue()

--         if upper < lower then
--             self:SetValue(lower)
--         end

--         frame.upperText:SetText(frame.formatter and frame.formatter(self:GetValue()) or self:GetValue())

--         if frame.handlers.OnValueChanged then
--             frame.handlers.OnValueChanged(frame, "upper", self, ...)
--         end
--     end)

--     -- Methods
--     function frame:SetDisabled(isDisabled)
--         self.lower:SetDisabled(isDisabled)
--         self.upper:SetDisabled(isDisabled)
--     end

--     function frame:SetMaxValue(value)
--         self.upper:SetValue(value)
--         self.upperText:SetText(self.formatter and self.formatter(value) or value)
--     end

--     function frame:SetMinMaxValues(minValue, maxValue, stepValue, formatter, setDefault)
--         self.lower:SetMinMaxValues(minValue, maxValue)
--         self.upper:SetMinMaxValues(minValue, maxValue)

--         self.lower:SetObeyStepOnDrag(true)
--         self.upper:SetObeyStepOnDrag(true)

--         self.upper:SetValueStep(stepValue)
--         self.upper:SetValueStep(stepValue)

--         self.formatter = formatter

--         if setDefault then
--             self:SetMinValue(minValue)
--             self:SetMaxValue(maxValue)
--         end
--     end

--     function frame:SetMinValue(value)
--         self.lower:SetValue(value)
--         self.lowerText:SetText(self.formatter and self.formatter(value) or value)
--     end
-- end

local function GuildBankSnapshotsSliderFrame_OnEnter(self, ...)
    local script = self.slider:GetScript("OnEnter")
    if script then
        script(self.slider, ...)
    end

    -- self:ShowTooltip() is already called in slider's OnEnter
end

function GuildBankSnapshotsSliderFrame_OnLoad(frame)
    frame = private:MixinElementContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self.label:Fire("OnAcquire")
            self.slider:Fire("OnAcquire")
            self.lowerText:Fire("OnAcquire")
            self.upperText:Fire("OnAcquire")
            self.editbox:Fire("OnAcquire")

            self.label:Justify("LEFT", "MIDDLE")
            self.lowerText:Justify("LEFT", "MIDDLE")
            self.upperText:Justify("RIGHT", "MIDDLE")

            self:SetLabelFont(GameFontHighlightSmall, private.interface.colors.white)
            self:SetMinMaxLabels(L["Min"], L["Max"])

            self:SetSize(150, 40)
            self:Fire("OnSizeChanged", self:GetWidth(), self:GetHeight())

            self:RegisterCallbacks(self.slider)
        end,

        OnSizeChanged = function(self, width, height)
            self.label:SetWidth(20)
            self.slider:SetWidth(height - 40)

            self.lowerText:SetSize(width / 3, 20)
            self.lowerText:SetPoint("BOTTOMLEFT")
            self.lowerText:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", width / 3, 0)

            self.upperText:SetSize(width / 3, 20)
            self.upperText:SetPoint("BOTTOMRIGHT")
            self.upperText:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -width / 3, 0)

            self.editbox:SetSize(width / 3, 16)
            self.editbox:SetPoint("BOTTOMLEFT", self.lowerText, "BOTTOMRIGHT", 0, 2)
            self.editbox:SetPoint("BOTTOMRIGHT", self.upperText, "BOTTOMLEFT", 0, 2)
        end,

        OnRelease = function(self)
            self.numDecimals = nil
            self.userInput = nil
        end,
    })

    -- Elements
    frame.label = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.label:SetPoint("TOPLEFT")
    frame.label:SetPoint("TOPRIGHT")

    frame.slider = frame:Acquire("GuildBankSnapshotsSlider")
    frame.slider:SetPoint("LEFT")
    frame.slider:SetPoint("RIGHT")

    frame.lowerText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.upperText = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.editbox = frame:Acquire("GuildBankSnapshotsEditBox")

    -- Methods
    function frame:ForwardCallback(script, callback, init)
        assert(script ~= "OnValueChanged", "GuildBankSnapshotsSliderFrame: Please register callback for 'OnSliderValueChanged' instead of forwarding slider callback 'OnValueChanged'")
        self.slider:SetCallback(script, callback, init)
    end

    function frame:RegisterCallbacks(mainElement)
        self:SetUserData("mainElement", mainElement)

        self.label:SetCallbacks({
            OnEnter = { GenerateClosure(GuildBankSnapshotsSliderFrame_OnEnter, self) },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
        })

        mainElement:SetCallbacks({
            OnEnter = {
                function(slider)
                    self:ShowTooltip()
                end,
            },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
            OnValueChanged = {
                function(slider, value, userInput)
                    if self.numDecimals then
                        value = addon:round(value, self.numDecimals)
                    end
                    self.editbox:SetText(value)

                    if userInput or self.userInput then
                        self.userInput = nil
                        if self.handlers.OnSliderValueChanged then
                            -- We don't need to pass userInput/true to the handler because it will only be called on userInput
                            self.handlers.OnSliderValueChanged(slider, value)
                        end
                    end
                end,
            },
        })

        self.lowerText:SetCallbacks({
            OnEnter = { GenerateClosure(GuildBankSnapshotsSliderFrame_OnEnter, self) },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
        })

        self.upperText:SetCallbacks({
            OnEnter = { GenerateClosure(GuildBankSnapshotsSliderFrame_OnEnter, self) },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
        })

        self.editbox:SetCallbacks({
            OnEnter = { GenerateClosure(GuildBankSnapshotsSliderFrame_OnEnter, self) },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
            OnEnterPressed = {
                function(editbox, ...)
                    local value = editbox:GetNumber()
                    self.userInput = true
                    self.slider:SetValue(value)
                end,
            },
        })
    end

    function frame:SetBackdropColor(...)
        self.slider:SetBackdropColor(...)
    end

    function frame:SetLabel(text)
        self.label:SetText(text)
    end

    function frame:SetLabelFont(fontObject, color)
        self.label:SetFontObject(fontObject or GameFontHighlightSmall)
        self.label:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:SetMinMaxValues(minValue, maxValue, stepValue, numDecimals)
        self.slider:SetMinMaxValues(minValue, maxValue)
        self.slider:SetObeyStepOnDrag(false)
        self.slider:SetValueStep(stepValue)
        self.numDecimals = numDecimals
        self:SetMinMaxLabels(minValue, maxValue)
    end

    function frame:SetMinMaxLabels(lowerText, upperText)
        frame.lowerText:SetText(lowerText)
        frame.upperText:SetText(upperText)
    end

    function frame:SetValue(value)
        self.slider:SetValue(value)
        self.editbox:SetText(value)
    end

    function frame:SetValueStep(...)
        self.slider:SetValueStep(...)
    end
end
