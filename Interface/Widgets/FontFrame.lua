local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function FontFrame_OnLoad(frame)
    frame = private:MixinText(frame)
    frame = private:MixinWidget(frame)
    frame:InitScripts({
        OnEnter = function(self)
            if self.text:GetStringWidth() <= self.text:GetWidth() then
                return
            end

            -- Text is truncated; show full text
            private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                local text = self.text:GetText()
                GameTooltip:AddLine(text, unpack(private.interface.colors.fontColor))
            end)
        end,

        OnLeave = GenerateClosure(private.HideTooltip, private),

        OnRelease = function(self)
            self:SetHeight(20)
            self:SetFontObject("GameFontHighlightSmall")
            self:SetText("")
            self:SetPadding(0, 0)
            self:Justify("CENTER", "MIDDLE")
        end,
    })

    frame:EnableMouse(true)

    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetJustifyH("LEFT")
end

GuildBankSnapshotsFontFrame_OnLoad = FontFrame_OnLoad
