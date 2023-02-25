local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsFontFrame_OnLoad(frame)
    frame:EnableMouse(true)
    frame.text = frame:CreateFontString(nil, "OVERLAY")

    frame = private:MixinText(frame)

    frame:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:SetAutoHeight(false)
            self:SetFontObject("GameFontHighlightSmall")
            self:Justify("CENTER", "MIDDLE")
            self:SetText("")
            self:SetPadding(0, 0)
            self:SetTextColor(1, 1, 1, 1)
        end,

        OnEnter = function(self)
            -- Show full text if truncated
            if not self.autoHeight and not self.disableTooltip and self.text:GetStringWidth() > self.text:GetWidth() then
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    local text = self.text:GetText()
                    GameTooltip:AddLine(text, unpack(private.interface.colors.white))
                end)
            end
        end,

        OnLeave = GenerateClosure(private.HideTooltip, private),

        OnRelease = function(self)
            self.disableTooltip = nil
        end,
    })

    -- Methods
    function frame:DisableTooltip(isDisabled)
        self.disableTooltip = isDisabled
    end
end
