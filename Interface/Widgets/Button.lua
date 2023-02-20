local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsButton_OnLoad(button)
    button = private:MixinWidget(button)

    button:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:SetNormalFontObject("GameFontNormalSmall")
            self:SetBackdropColor(private.interface.colors.dark)
        end,
    })

    -- Textures
    button.bg, button.border, button.highlight = private:AddBackdrop(button, { hasHighlight = true, highlightColor = "lightest" })
    button:SetHighlightTexture(button.highlight)
end
