local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsTableCell_OnLoad(cell)
    cell = private:MixinText(cell)

    cell:InitScripts({
        OnAcquire = function(self)
            self:SetHeight(20)
            self:SetFontObject("GameFontHighlightSmall")
            self:SetText("")
            self:SetPadding(0, 0)
            self:Justify("LEFT", "TOP")
            self.bg:Hide()
            self:SetBackdropColor(private.interface.colors[private:UseClassColor() and "dimmedClass" or "dimmedFlair"])
        end,

        OnEnter = function(self, ...)
            self.bg:Show()

            -- Enable row highlight
            local parent = self:GetParent()
            parent:GetScript("OnEnter")(parent, ...)

            -- Show tooltips
            if not self:GetUserData("data") then
                return
            end

            if self:GetUserData("data").tooltip then
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    local line = self:GetUserData("data").tooltip(self:GetUserData("elementData"), self:GetUserData("entryID"))

                    if line then
                        GameTooltip:AddLine(line, 1, 1, 1)
                    elseif self.text:GetStringWidth() > self:GetWidth() then
                        GameTooltip:AddLine(self:GetUserData("data").text(self:GetUserData("elementData")), 1, 1, 1)
                    end
                end, self)
            elseif self.text:GetStringWidth() > self:GetWidth() then
                -- Get truncated text
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    GameTooltip:AddLine(self:GetUserData("data").text(self:GetUserData("elementData")), 1, 1, 1)
                end, self)
            end
        end,

        OnLeave = function(self, ...)
            self.bg:Hide()

            -- Disable row highlight
            local parent = self:GetParent()
            parent:GetScript("OnLeave")(parent, ...)
            -- Hide tooltips
            private:ClearTooltip()
        end,

        OnRelease = function(self) end,
    })

    cell:SetHeight(20)

    -- Textures
    cell.bg = cell:CreateTexture(nil, "BACKGROUND")
    cell.bg:SetAllPoints(cell)

    cell.icon = cell:CreateTexture(nil, "BACKGROUND")
    cell.icon:SetScript("OnEnter", GenerateClosure(cell.GetScript, cell, "OnEnter"))
    cell.icon:SetScript("OnLeave", GenerateClosure(cell.GetScript, cell, "OnLeave"))

    -- Text
    cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cell.text:SetWordWrap(false)

    -- Methods
    function cell:SetAnchors()
        self.icon:SetTexture()
        self.icon:ClearAllPoints()
        local iconSize = min(self:GetWidth() - self:GetUserData("paddingX"), 12)
        self.icon:SetSize(iconSize, iconSize)

        self.text:ClearAllPoints()

        local icon = self:GetUserData("data").icon
        if type(icon) == "function" then
            icon = self:GetUserData("data").icon(self:GetUserData("elementData"))
        end

        if icon then
            self.icon:SetTexture(icon)
            self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", self:GetUserData("paddingX"), -self:GetUserData("paddingY"))
            self.text:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
        else
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self:GetUserData("paddingX"), -self:GetUserData("paddingY"))
        end
        self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self:GetUserData("paddingX"), self:GetUserData("paddingY"))
    end

    function cell:SetData(data, elementData, entryID)
        self:SetUserData("data", data)
        self:SetUserData("elementData", elementData)
        self:SetUserData("entryID", entryID)
        self:SetAnchors()
    end

    function cell:SetPadding(paddingX, paddingY)
        self:SetUserData("paddingX", paddingX)
        self:SetUserData("paddingY", paddingY)
    end
end
