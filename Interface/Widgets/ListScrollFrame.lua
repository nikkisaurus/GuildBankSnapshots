local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsListScrollFrame_OnLoad(frame)
    frame = private:MixinWidget(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
        end,

        OnRelease = function(self)
            self.scrollBox:Flush()
            self.scrollView:Reset()
        end,
    })

    -- ScrollBar
    frame.scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, 0)
    frame.scrollBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    -- frame.scrollBar:SetFrameLevel(1)

    -- ScrollBox
    frame.scrollBox = CreateFrame("Frame", nil, frame, "WoWScrollBoxList")

    -- ScrollView
    frame.scrollView = CreateScrollBoxListLinearView()

    function frame.scrollView:Initialize(extent, initializer, template)
        if type(extent) == "function" then
            self:SetElementExtentCalculator(extent)
        else
            self:SetElementExtent(extent or 20)
        end

        assert(type(initializer) == "function", "GuildBankSnapshotsListScrollFrame: invalid initializer function")
        self:SetElementInitializer(template or "Frame", initializer)
    end

    function frame.scrollView:Reset()
        self:SetElementExtent(20)
        self:SetElementInitializer("Frame", private.NullFunc)
        frame.scrollBox:SetView(self)
    end

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
    ScrollUtil.InitScrollBoxListWithScrollBar(frame.scrollBox, frame.scrollBar, frame.scrollView)

    -- Methods
    function frame:SetDataProvider(callback)
        assert(type(callback) == "function", callback and "GuildBankSnapshotsListScrollFrame: data provider callback must be a function" or "GuildBankSnapshotsListScrollFrame: attempting to create empty data provider")

        local DataProvider = CreateDataProvider()
        callback(DataProvider)
        self.scrollBox:SetDataProvider(DataProvider)

        return DataProvider
    end
end
