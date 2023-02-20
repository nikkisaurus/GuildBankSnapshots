local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsEditBox_OnLoad(editbox)
    editbox = private:MixinWidget(editbox)
    editbox:InitScripts({
        OnAcquire = function(self)
            self:SetSize(100, 20)
            self:SetFontObject(GameFontHighlightSmall)
            self:SetText("")
            self:SetBackdropColor(private.interface.colors.light)
            self:SetAutoFocus(false)
            self:SetTextInsets(5, 5, 2, 2)
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
            self.border:SetColorTexture(private.interface.colors.black:GetRGBA())
        end,

        OnTextChanged = function(self)
            if self.isSearchBox and self:IsValidText() then
                self.clearButton:Show()
            else
                self.clearButton:Hide()
            end
        end,

        OnRelease = function(self)
            self.isSearchBox = nil
        end,
    })

    -- Textures
    editbox.bg, editbox.border = private:AddBackdrop(editbox)

    editbox.searchIcon = editbox:CreateTexture(nil, "ARTWORK")
    editbox.searchIcon:SetPoint("LEFT", 5, 0)
    editbox.searchIcon:SetTexture(374210)
    editbox.searchIcon:Hide()

    editbox.clearButton = CreateFrame("Button", nil, editbox)
    editbox.clearButton:SetPoint("RIGHT", -5, 0)
    editbox.clearButton:SetNormalTexture(374214)
    editbox.clearButton:Hide()

    editbox.clearButton:SetScript("OnClick", function()
        editbox:SetText("")
        if editbox.handlers.OnClear then
            editbox.handlers.OnClear(editbox)
        end
    end)

    -- Methods
    function editbox:IsValidText()
        return private:strcheck(editbox:GetText())
    end

    function editbox:SetSearchTemplate(isSearchBox)
        self.isSearchBox = isSearchBox
        if isSearchBox then
            local iconSize = min(12, self:GetHeight())
            self:SetTextInsets(iconSize + 10, iconSize + 10, 2, 2)

            editbox.searchIcon:Show()
            editbox.searchIcon:SetSize(iconSize, iconSize)
            editbox.clearButton:SetSize(iconSize, iconSize)
        else
            self:SetTextInsets(5, 5, 2, 2)

            editbox.searchIcon:Hide()
            editbox.clearButton:Hide()
        end
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
