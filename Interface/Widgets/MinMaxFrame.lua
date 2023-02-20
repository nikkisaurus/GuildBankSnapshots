local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsMinMaxFrame_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            frame:SetSize(100, 40)
        end,

        OnSizeChanged = function(self, width, height)
            -- width = width - 5
            -- frame.lowerText:SetSize(width / 2, height - 20)
            -- frame.lower:SetSize(width / 2, height - 20)
            -- frame.upperText:SetSize(width / 2, height - 20)
            -- frame.upper:SetSize(width / 2, height - 20)
        end,
    })

    -- frame.lowerText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    -- frame.lowerText:SetPoint("TOPLEFT")
    -- frame.lowerText:SetText("Min")
    -- frame.lower = frame:Acquire("GuildBankSnapshotsEditBox")
    -- -- private:AddBackdrop(frame.lower, "insetColor")
    -- -- frame.lower:SetAutoFocus(false)
    -- frame.lower:SetPoint("BOTTOMLEFT")

    -- frame.upperText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    -- frame.upperText:SetPoint("TOPRIGHT")
    -- frame.upperText:SetText("Max")
    -- frame.upper = frame:Acquire("GuildBankSnapshotsEditBox")
    -- -- private:AddBackdrop(frame.upper, "insetColor")
    -- -- frame.upper:SetAutoFocus(false)
    -- frame.upper:SetPoint("BOTTOMRIGHT")
end
