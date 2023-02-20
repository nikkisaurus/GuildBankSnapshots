local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsEditBox_OnLoad(editbox)
    editbox = private:MixinWidget(editbox)
    editbox:InitScripts({
        OnAcquire = function(self)
            self:SetText("")
        end,

        OnEnter = function(self)
            self.border:SetColorTexture(1, 1, 1, 0.75)
        end,

        OnEnterPressed = function(self)
            self:ClearFocus()
        end,

        OnEscapePressed = function(self)
            self:ClearFocus()
        end,

        OnLeave = function(self)
            self.border:SetColorTexture(private.interface.colors.borderColor:GetRGBA())
        end,

        OnRelease = function(self)
            self.isSearchBox = nil
        end,
    })

    editbox.bg, editbox.border = private:AddBackdrop(editbox, { bgColor = "highlightColor" })
    editbox:SetAutoFocus(false)

    -- Methods
    function editbox:IsValidText()
        return private:strcheck(editbox:GetText())
    end

    function editbox:SetSearchTemplate(isSearchBox)
        self.isSearchBox = isSearchBox
    end
end

-- function GuildBankSnapshotsEditBox_OnLoad(editbox)
--     editbox = private:MixinWidget(editbox)

--     editbox:InitScripts({
--         OnAcquire = function(self)
--             self:SetText("")
--         end,

--         OnEnterPressed = function(self)
--             self:ClearFocus()
--         end,
--     })

--     -- editbox.clearButton:HookScript("OnClick", function()
--     --     if editbox.handlers.OnClear then
--     --         editbox.handlers.OnClear(editbox)
--     --     end
--     -- end)

--     -- editbox:SetTextInsets(editbox.searchIcon:GetWidth() + 4, editbox.clearButton:GetWidth() + 4, 2, 2)
-- end
