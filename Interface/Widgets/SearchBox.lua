local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsSearchBox_OnLoad(editbox)
    editbox = private:MixinWidget(editbox)

    editbox:InitScripts({
        OnAcquire = function(self)
            self:SetText("")
        end,

        OnEnterPressed = function(self)
            self:ClearFocus()
        end,
    })

    editbox.clearButton:HookScript("OnClick", function()
        if editbox.handlers.OnClear then
            editbox.handlers.OnClear(editbox)
        end
    end)

    -- editbox:SetTextInsets(editbox.searchIcon:GetWidth() + 4, editbox.clearButton:GetWidth() + 4, 2, 2)

    -- Methods
    function editbox:IsValidText()
        return private:strcheck(editbox:GetText())
    end
end
