local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function TableCell_OnLoad(cell)
    cell = private:MixinText(cell)
    cell = private:MixinWidget(cell)
    cell:InitScripts({
        -- Scripts
        OnEnter = function(self, ...)
            -- Enable row highlight
            local parent = self:GetParent()
            parent:GetScript("OnEnter")(parent, ...)
            -- Highlight text
            self.text:SetFontObject(GameFontNormalSmall)

            -- Show tooltips
            if not self.data then
                return
            end

            if self.data.tooltip then
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    local line = self.data.tooltip(self.elementData, self.entryID)

                    if line then
                        GameTooltip:AddLine(line, 1, 1, 1)
                    elseif self.text:GetStringWidth() > self:GetWidth() then
                        GameTooltip:AddLine(self.data.text(self.elementData), 1, 1, 1)
                    end
                end, self)
            elseif self.text:GetStringWidth() > self:GetWidth() then
                -- Get truncated text
                private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self)
                    GameTooltip:AddLine(self.data.text(self.elementData), 1, 1, 1)
                end, self)
            end
        end,

        OnLeave = function(self, ...)
            -- Disable row highlight
            local parent = self:GetParent()
            parent:GetScript("OnLeave")(parent, ...)
            -- Unhighlight text
            self.text:SetFontObject(GameFontHighlightSmall)
            -- Hide tooltips
            private:ClearTooltip()
        end,

        OnRelease = function(self)
            self:SetHeight(20)
            self:SetFontObject("GameFontHighlightSmall")
            self:SetText("")
            self:SetPadding(0, 0)
            self:Justify("LEFT", "TOP")
            self.data = nil
            self.elementData = nil
            self.entryID = nil
        end,
    })

    cell:SetHeight(20)

    -- Textures
    cell.icon = cell:CreateTexture(nil, "BACKGROUND")
    cell.icon:SetScript("OnEnter", GenerateClosure(cell.GetScript, cell, "OnEnter"))
    cell.icon:SetScript("OnLeave", GenerateClosure(cell.GetScript, cell, "OnLeave"))

    -- Text
    cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cell:Justify("LEFT", "TOP")
    cell.text:SetWordWrap(false)

    -- Methods
    function cell:SetAnchors()
        self.icon:SetTexture()
        self.icon:ClearAllPoints()
        local iconSize = min(self:GetWidth() - self.paddingX, 12)
        self.icon:SetSize(iconSize, iconSize)

        self.text:ClearAllPoints()

        local icon = self.data.icon
        if type(icon) == "function" then
            icon = self.data.icon(self.elementData)
        end

        if icon then
            self.icon:SetTexture(icon)
            self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", self.paddingX, -self.paddingY)
            self.text:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 2, 0)
        else
            self.text:SetPoint("TOPLEFT", self, "TOPLEFT", self.paddingX, -self.paddingY)
        end
        self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.paddingX, self.paddingY)
    end

    function cell:SetData(data, elementData, entryID)
        self.data = data
        self.elementData = elementData
        self.entryID = entryID
        self:SetAnchors()
    end

    function cell:SetPadding(paddingX, paddingY)
        self.paddingX = paddingX
        self.paddingY = paddingY
    end
end

GuildBankSnapshotsTableCell_OnLoad = TableCell_OnLoad
