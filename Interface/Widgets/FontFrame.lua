local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsFontFrame_OnLoad(frame)
    frame:EnableMouse(true)
    frame = private:MixinText(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:SetAutoHeight(false)
            self:SetFont(GameFontHighlightSmall, private.interface.colors.white)
            self:Justify("CENTER", "MIDDLE")
            self:SetText("")
            self:SetPadding(0, 0)
            self:SetTextColor(1, 1, 1, 1)
            self:SetHeader()
        end,

        OnEnter = function(self)
            -- Show full text if truncated
            if not self.autoHeight and not self:GetUserData("disableTooltip") and self.text:GetStringWidth() > self.text:GetWidth() then
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    local text = self.text:GetText()
                    GameTooltip:AddLine(text, unpack(private.interface.colors.white))
                end)
            end
        end,

        OnLeave = GenerateClosure(private.HideTooltip, private),
    })

    -- Elements
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.header = frame:CreateTexture(nil, "BACKGROUND")

    -- Methods
    function frame:DisableTooltip(isDisabled)
        self:SetUserData("disableTooltip", isDisabled)
    end

    function frame:SetFont(fontObject, color)
        self.text:SetFontObject(fontObject or GameFontHighlightSmall)
        self:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:SetHeader(isHeader, height)
        self:SetUserData("isHeader", isHeader)

        if isHeader then
            self.header:Show()
        else
            self.header:Hide()
        end

        self.header:SetHeight(height or 1)
        self.header:SetPoint("BOTTOMLEFT")
        self.header:SetPoint("BOTTOMRIGHT")
    end

    function frame:SetTextColor(r, g, b, a)
        if r and g and b and a then
            self.text:SetTextColor(r, g, b, a)
            self.header:SetColorTexture(r, g, b, a)
        else
            self.text:SetTextColor(private.interface.colors.white:GetRGBA())
            self.header:SetColorTexture(private.interface.colors.white:GetRGBA())
        end
    end
end

function GuildBankSnapshotsFontLabelFrame_OnLoad(frame)
    frame = private:MixinElementContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self.label:Fire("OnAcquire")
            self.fontFrame:Fire("OnAcquire")

            self.label:Justify("LEFT", "MIDDLE")

            self:SetLabelFont(GameFontHighlightSmall, private.interface.colors.white)

            self:SetSize(150, 40)
            self:Fire("OnSizeChanged", self:GetWidth(), self:GetHeight())

            self:RegisterCallbacks(self.fontFrame)
        end,

        OnSizeChanged = function(self, width, height)
            self.label:SetHeight(20)
            self.label:SetPoint("TOPLEFT")
            self.label:SetPoint("TOPRIGHT")

            self.fontFrame:SetHeight(height - 20)
            self.fontFrame:SetPoint("BOTTOMLEFT")
            self.fontFrame:SetPoint("BOTTOMRIGHT")
        end,
    })

    -- Elements
    frame.label = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.fontFrame = frame:Acquire("GuildBankSnapshotsFontFrame")

    -- Methods
    function frame:Justify(...)
        self.fontFrame:Justify(...)
    end

    function frame:RegisterCallbacks(mainElement)
        self:SetUserData("mainElement", mainElement)

        self.label:SetCallbacks({
            OnEnter = {
                function(label)
                    self:FireScript("OnEnter")
                end,
            },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
        })

        mainElement:SetCallbacks({
            OnEnter = {
                function(label)
                    self:ShowTooltip()
                end,
            },
            OnLeave = { GenerateClosure(private.HideTooltip, private) },
        })
    end

    function frame:SetLabel(text)
        self.label:SetText(text)
    end

    function frame:SetLabelFont(fontObject, color)
        self.label:SetFontObject(fontObject or GameFontHighlightSmall)
        self.label:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:SetText(...)
        self.fontFrame:SetText(...)
    end

    function frame:SetTextColor(...)
        self.fontFrame:SetTextColor(...)
    end
end
