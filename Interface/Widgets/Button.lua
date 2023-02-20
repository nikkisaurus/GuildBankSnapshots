local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsButton_OnLoad(button)
    button = private:MixinWidget(button)

    button:InitScripts({
        OnRelease = function()
            button:SetSize(150, 20)
            button:SetNormalFontObject("GameFontNormalSmall")
        end,
    })
    button:SetNormalFontObject("GameFontNormalSmall")

    -- Textures
    button.bg, button.border, button.highlight = private:AddBackdrop(button, { bgColor = "elementColor", hasHighlight = true, highlightColor = "elementHighlightColor" })
    button:SetHighlightTexture(button.highlight)
end
