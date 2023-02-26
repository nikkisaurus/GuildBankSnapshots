local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsScrollFrame_OnLoad(frame)
    frame = private:MixinWidget(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
            self:ClearBackdrop()
        end,

        OnSizeChanged = function(self)
            self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
        end,

        OnRelease = function(self)
            self.content:ReleaseAll()
        end,
    })

    -- ScrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 0)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    -- frame.scrollBar:SetFrameLevel(1)

    -- ScrollBox
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBox")

    -- ScrollView
    frame.scrollView = CreateScrollBoxLinearView()
    frame.scrollView:SetPanExtent(50)

    -- Content
    frame.content = CreateFrame("Frame", nil, frame.scrollBox, "ResizeLayoutFrame")
    frame.content = private:MixinContainer(frame.content)
    frame.content.scrollable = true
    frame.content:SetAllPoints(frame.scrollBox)

    -- ScrollUtil
    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, -10),
        CreateAnchor("BOTTOMRIGHT", frame.scrollBar, "BOTTOMLEFT", -5, 10),
    }

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", frame, "TOPLEFT", 0, -10),
        CreateAnchor("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 10),
    }

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.scrollBox, frame.scrollBar, anchorsWithBar, anchorsWithoutBar)
    ScrollUtil.InitScrollBoxWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)
end
