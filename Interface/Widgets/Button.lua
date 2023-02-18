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
    button.border = button:CreateTexture(nil, "BACKGROUND")
    button.border:SetAllPoints(button)
    button.border:SetColorTexture(0, 0, 0, 1)

    button:SetNormalTexture(button:CreateTexture(nil, "ARTWORK"))
    button.bg = button:GetNormalTexture()
    button.bg:SetColorTexture(private.interface.colors.elementColor:GetRGBA())
    button.bg:SetPoint("TOPLEFT", button.border, "TOPLEFT", 1, -1)
    button.bg:SetPoint("BOTTOMRIGHT", button.border, "BOTTOMRIGHT", -1, 1)

    button:SetHighlightTexture(button:CreateTexture(nil, "ARTWORK"))
    button.highlight = button:GetHighlightTexture()
    button.highlight:SetColorTexture(private.interface.colors.highlightColor:GetRGBA())
    button.highlight:SetAllPoints(button.bg)
end
