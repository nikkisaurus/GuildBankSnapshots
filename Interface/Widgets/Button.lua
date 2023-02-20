local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsButton_OnLoad(button)
    button = private:MixinText(button)

    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:SetNormalFontObject("GameFontHighlightSmall")
            self:SetBackdropColor(private.interface.colors.normal, private.interface.colors.light)
        end,
    })

    -- Textures
    button.bg, button.border, button.highlight = private:AddBackdrop(button, { hasHighlight = true, highlightColor = "lightest" })
    button:SetHighlightTexture(button.highlight)

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetAllPoints(button)
end
