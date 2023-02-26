local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsGroup_OnLoad(group)
    group = private:MixinContainer(group)
    group.children = {}
    group:InitScripts({
        OnAcquire = function(self)
            self:SetSize(600, 200)
            self:SetPadding(0, 0)
            self:SetSpacing(0)
            self:ClearBackdrop()
        end,

        OnRelease = function(self)
            self.widthPadding = nil
            self.heightPadding = nil
            self:ReleaseChildren()
        end,
    })

    -- Methods
    function group:AddChild(child)
        tinsert(self.children, child)
    end

    function group:DoLayout()
        local usedWidth, usedHeight = 0, self.spacing
        local maxChildHeight
        for i, child in addon:pairs(self.children) do
            local width = self:GetWidth()
            local childWidth = child:GetWidth()
            local childHeight = child:GetHeight()

            child:ClearAllPoints()
            if i == 1 then
                child:SetPoint("TOPLEFT", self.widthPadding, -self.heightPadding)
                if child.width == "full" then
                    child:SetPoint("TOPRIGHT", -self.widthPadding, -self.heightPadding)
                    usedWidth = width
                else
                    usedWidth = childWidth + self.widthPadding
                end
                maxChildHeight = childHeight
            elseif usedWidth + self.spacing + childWidth + self.widthPadding > width or child.width == "full" then
                usedHeight = usedHeight + maxChildHeight + self.spacing * 2
                child:SetPoint("TOPLEFT", self.widthPadding, -usedHeight)
                if child.width == "full" then
                    child:SetPoint("TOPRIGHT", -self.widthPadding, -usedHeight)
                    usedWidth = width
                else
                    usedWidth = childWidth + self.widthPadding
                end
                maxChildHeight = childHeight
            else
                child:SetPoint("TOPLEFT", self.children[i - 1], "TOPRIGHT", self.spacing, 0)
                usedWidth = usedWidth + self.spacing + childWidth
                maxChildHeight = max(maxChildHeight, childHeight)
            end
        end

        self:MarkDirty()
    end

    function group:SetPadding(widthPadding, heightPadding)
        self.widthPadding = widthPadding
        self.heightPadding = heightPadding
    end

    function group:SetSpacing(spacing)
        self.spacing = spacing
    end

    function group:ReleaseChildren()
        self:ReleaseAll()
        wipe(self.children)
    end
end
