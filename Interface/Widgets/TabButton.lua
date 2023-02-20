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

        OnEnter = function(self)
            self:SetTextColor(private.interface.colors.white:GetRGBA())
        end,

        OnClick = function(self)
            self:SetSelected(true)

            -- Unselect other tabs
            for tab, _ in private.frame.tabContainer:EnumerateActive() do
                if tab:GetTabID() ~= self.tabID then
                    tab:SetSelected()
                end
            end
        end,

        OnLeave = function(self)
            if not self.isSelected then
                self:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
            end
        end,

        OnRelease = function(self)
            self.tabID = nil
            self.info = nil
        end,
    })

    -- Textures
    tab.bg, tab.border = private:AddBackdrop(tab, { bgColor = "dark" })
    tab:SetNormalTexture(tab.bg)

    tab.selected = tab:CreateTexture(nil, "BACKGROUND")
    tab.selected:SetColorTexture(private.interface.colors[private:UseClassColor() and "lightClass" or "lightFlair"]:GetRGBA())
    tab.selected:SetAllPoints(tab.bg)

    -- Text
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tab.text:SetAllPoints(tab)
    -- tab:SetPushedTextOffset(0, 0)

    -- Methods
    function tab:GetTabID()
        return self.tabID
    end

    function tab:SetSelected(isSelected)
        self.isSelected = isSelected

        if isSelected then
            self:SetTextColor(private.interface.colors.white:GetRGBA())
        else
            self:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
        end

        self:SetNormalTexture(isSelected and self.selected or self.bg)
    end

    function tab:SetTab(tabID, info)
        self.tabID = tabID
        self.info = info
        self:UpdateText()
        self:UpdateWidth()
    end

    function tab:UpdateText()
        self:SetText("")

        if not self.tabID then
            return
        end

        self:SetText(self.info.header)
    end

    function tab:UpdateWidth()
        self:SetWidth(150)

        if not self.tabID then
            return
        end

        self:SetWidth(self.text:GetStringWidth() + 20)
    end
end
