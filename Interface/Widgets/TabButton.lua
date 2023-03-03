local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsTabButton_OnLoad(tab)
    tab = private:MixinText(tab)
    tab:InitScripts({
        OnAcquire = function(self)
            tab:SetSelected()
            self:SetSize(150, 20)
            self:UpdateText()
            self:UpdateWidth()
        end,

        OnClick = function(self)
            self:SetSelected(true)

            -- Unselect other tabs
            for tab, _ in tab:GetUserData("owner"):EnumerateActive() do
                if tab:GetTabID() ~= self:GetUserData("tabID") then
                    tab:SetSelected()
                end
            end
        end,

        OnEnter = function(self)
            self:SetTextColor(private.interface.colors.white:GetRGBA())
        end,

        OnLeave = function(self)
            if not self.isSelected then
                self:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
            end
        end,
    })

    -- Textures
    tab.bg, tab.border = private:AddBackdrop(tab, { bgColor = "dark" })
    tab:SetNormalTexture(tab.bg)

    tab.selected = tab:CreateTexture(nil, "BACKGROUND")
    tab.selected:SetAllPoints(tab.bg)

    -- Text
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tab.text:SetAllPoints(tab)

    -- Methods
    function tab:GetTabID()
        return self:GetUserData("tabID")
    end

    function tab:SetSelected(isSelected)
        self.isSelected = isSelected

        if isSelected then
            self:SetTextColor(private.interface.colors.white:GetRGBA())
        else
            self:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
        end

        self:SetNormalTexture(isSelected and self.selected or self.bg)
        self.selected:SetColorTexture(private.interface.colors[private:UseClassColor() and "lightClass" or "lightFlair"]:GetRGBA())
    end

    function tab:SetTab(owner, tabID, info)
        self:SetUserData("owner", owner)
        self:SetUserData("tabID", tabID)
        self:SetUserData("info", info)
        self:UpdateText()
        self:UpdateWidth()
    end

    function tab:UpdateText()
        self:SetText("")

        if not self:GetUserData("tabID") then
            return
        end

        self:SetText(self:GetUserData("info").header)
    end

    function tab:UpdateWidth()
        self:SetWidth(150)

        if not self:GetUserData("tabID") then
            return
        end

        self:SetWidth(self.text:GetStringWidth() + 20)
    end
end
