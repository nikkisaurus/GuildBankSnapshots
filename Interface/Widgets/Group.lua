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
                child:SetPoint("TOPLEFT", self:GetUserData("widthPadding"), -self:GetUserData("heightPadding"))
                if child:GetUserData("width") == "full" then
                    child:SetPoint("TOPRIGHT", -self:GetUserData("widthPadding"), -self:GetUserData("heightPadding"))
                    usedWidth = width
                else
                    usedWidth = childWidth + self:GetUserData("widthPadding")
                end
                maxChildHeight = childHeight
            elseif usedWidth + self.spacing + childWidth + self:GetUserData("widthPadding") > width or child:GetUserData("width") == "full" then
                usedHeight = usedHeight + maxChildHeight + self.spacing * 2
                child:SetPoint("TOPLEFT", self:GetUserData("widthPadding"), -usedHeight)
                if child:GetUserData("width") == "full" then
                    child:SetPoint("TOPRIGHT", -self:GetUserData("widthPadding"), -usedHeight)
                    usedWidth = width
                else
                    usedWidth = childWidth + self:GetUserData("widthPadding")
                end
                maxChildHeight = childHeight
            else
                child:SetPoint("TOPLEFT", self.children[i - 1], "TOPRIGHT", self.spacing, 0)
                usedWidth = usedWidth + self.spacing + childWidth
                maxChildHeight = max(maxChildHeight, childHeight)
            end
            self:SetHeight(usedHeight + childHeight + self.spacing * 2) -- see note below
        end

        -- Need to set height in case this group is nested in another group; it needs an explicitly set height in order to properly layout its children
        self:SetHeight(self:GetHeight() + self:GetUserData("heightPadding"))
        self:MarkDirty()
    end

    function group:SetPadding(widthPadding, heightPadding)
        self:SetUserData("widthPadding", widthPadding)
        self:SetUserData("heightPadding", heightPadding)
    end

    function group:SetSpacing(spacing)
        self.spacing = spacing
    end

    function group:ReleaseChildren()
        self:ReleaseAll()
        wipe(self.children)
    end
end
