local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function FontFrame_OnLoad(frame)
    frame:EnableMouse(true)
    frame.text = frame:CreateFontString(nil, "OVERLAY")

    frame = private:MixinText(frame)
    frame = private:MixinWidget(frame)

    frame:InitScripts({
        OnAcquire = function(self)
            self:SetHeight(20)
            self:SetAutoHeight(false)
            self:SetFontObject("GameFontHighlightSmall")
            self:Justify("CENTER", "MIDDLE")
            self:SetText("")
            self:SetPadding(0, 0)
        end,

        OnEnter = function(self)
            -- Show full text if truncated
            if self.text:GetStringWidth() > self.text:GetWidth() then
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    local text = self.text:GetText()
                    GameTooltip:AddLine(text, unpack(private.interface.colors.fontColor))
                end)
            end
        end,

        OnLeave = GenerateClosure(private.HideTooltip, private),
    })
end

GuildBankSnapshotsFontFrame_OnLoad = FontFrame_OnLoad