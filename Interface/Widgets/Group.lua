local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsGroup_OnLoad(group)
    group = private:MixinContainer(group)
    group.children = {}
    group:InitScripts({
        OnAcquire = function(self)
            self:ClearBackdrop()
            self:SetSize(600, 200)
            self:SetPadding(0, 0)
            self:SetSpacing(0)
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
        if not self:GetUserData("spacing") or not self:GetUserData("widthPadding") or not self:GetUserData("heightPadding") then
            private:dprint("GuildBankSnapshotsGroup: DoLayout is being called before OnAcquire has been fired.")
            self:Fire("OnAcquire")
        end

        local usedWidth, usedHeight, maxChildHeight = 0, self:GetUserData("heightPadding")
        for i, child in addon:pairs(self.children) do
            local width = self:GetWidth()
            local childWidth = child:GetWidth()
            local childHeight = child:GetHeight()

            child:ClearAllPoints()

            if i == 1 then
                if self:GetUserData("isReverse") then
                    child:SetPoint("BOTTOMLEFT", self:GetUserData("widthPadding"), self:GetUserData("heightPadding") + (child:GetUserData("yOffset") or 0))
                else
                    child:SetPoint("TOPLEFT", self:GetUserData("widthPadding"), -(self:GetUserData("heightPadding") + (child:GetUserData("yOffset") or 0)))
                end
                if child:GetUserData("width") == "full" then
                    if self:GetUserData("isReverse") then
                        child:SetPoint("BOTTOMRIGHT", -self:GetUserData("widthPadding"), self:GetUserData("heightPadding") + (child:GetUserData("yOffset") or 0))
                    else
                        child:SetPoint("TOPRIGHT", -self:GetUserData("widthPadding"), -(self:GetUserData("heightPadding") + (child:GetUserData("yOffset") or 0)))
                    end
                    usedWidth = width
                else
                    usedWidth = childWidth + self:GetUserData("widthPadding")
                end
                maxChildHeight = childHeight + (child:GetUserData("yOffset") or 0)
            elseif usedWidth + self:GetUserData("spacing") + childWidth + self:GetUserData("widthPadding") > width or child:GetUserData("width") == "full" then
                usedHeight = usedHeight + maxChildHeight + (self:GetUserData("spacing") * 2) + (child:GetUserData("yOffset") or 0)
                if self:GetUserData("isReverse") then
                    child:SetPoint("BOTTOMLEFT", self:GetUserData("widthPadding"), usedHeight)
                else
                    child:SetPoint("TOPLEFT", self:GetUserData("widthPadding"), -usedHeight)
                end
                if child:GetUserData("width") == "full" then
                    if self:GetUserData("isReverse") then
                        child:SetPoint("BOTTOMRIGHT", -self:GetUserData("widthPadding"), usedHeight)
                    else
                        child:SetPoint("TOPRIGHT", -self:GetUserData("widthPadding"), -usedHeight)
                    end
                    usedWidth = width
                else
                    usedWidth = childWidth + self:GetUserData("widthPadding")
                end
                maxChildHeight = childHeight + (child:GetUserData("yOffset") or 0)
            else
                child:SetPoint(self:GetUserData("isReverse") and "BOTTOMLEFT" or "TOPLEFT", self.children[i - 1], self:GetUserData("isReverse") and "BOTTOMRIGHT" or "TOPRIGHT", self:GetUserData("spacing"), child:GetUserData("yOffset") or 0)
                usedWidth = usedWidth + self:GetUserData("spacing") + childWidth
                maxChildHeight = max(maxChildHeight, childHeight + (child:GetUserData("yOffset") or 0))
            end

            self:SetHeight(usedHeight + maxChildHeight + self:GetUserData("spacing") + self:GetUserData("heightPadding"))
        end
    end

    function group:SetPadding(widthPadding, heightPadding)
        self:SetUserData("widthPadding", widthPadding)
        self:SetUserData("heightPadding", heightPadding)
    end

    function group:SetReverse(isReverse)
        self:SetUserData("isReverse", isReverse)
    end

    function group:SetSpacing(spacing)
        self:SetUserData("spacing", spacing)
    end

    function group:ReleaseChildren()
        self:ReleaseAll()
        wipe(self.children)
    end
end

function GuildBankSnapshotsScrollingGroup_OnLoad(frame)
    frame = private:MixinElementContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self.container:Fire("OnAcquire")
            self.group:Fire("OnAcquire")

            self.container:ClearBackdrop()

            self:SetSize(500, 200)
            self:Fire("OnSizeChanged", self:GetWidth(), self:GetHeight())

            self:RegisterCallbacks(self.group)
        end,

        OnSizeChanged = function(self)
            self.container:SetAllPoints(self)
            self.group:SetPoint("TOPLEFT", self.container.content, "TOPLEFT")
            self.group:SetPoint("TOPRIGHT", self.container.content, "TOPRIGHT")
            self.group:SetHeight(1)
        end,

        OnRelease = function(self)
            self.group:ReleaseChildren()
        end,
    })

    -- Elements
    frame.bg, frame.border = private:AddBackdrop(frame)
    frame.container = frame:Acquire("GuildBankSnapshotsScrollFrame")
    frame.group = frame.container.content:Acquire("GuildBankSnapshotsGroup")

    -- Methods
    function frame:AcquireElement(...)
        return self.group:Acquire(...)
    end

    function frame:AddChild(...)
        self.group:AddChild(...)
    end

    function frame:DoLayout()
        self.group:DoLayout()

        self.container.content:MarkDirty()
        self.container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
    end

    function frame:RegisterCallbacks(mainElement)
        self:SetUserData("mainElement", mainElement)
    end

    function frame:ReleaseChildren()
        self.group:ReleaseChildren()
    end

    function frame:SetPadding(...)
        self.group:SetPadding(...)
    end

    function frame:SetSpacing(...)
        self.group:SetSpacing(...)
    end
end
