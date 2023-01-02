local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local dropdownMixin = {}

function dropdownMixin:SetList(list)
    self.list = list
end

function dropdownMixin:SetValue(key)
    self.selected = key
    self:SetText(self.list[key])
end

local function UpdateScrollBox(self)
    self:FullUpdate(ScrollBoxConstants.UpdateImmediately)
end

function private:InitializeFrame()
    -- Frame
    local frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "SettingsFrameTemplate")
    frame.NineSlice.Text:SetText(L.addonName)
    frame:SetSize(900, 500)
    frame:SetPoint("CENTER")
    private.frame = frame

    -- Content
    local leftScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    leftScrollBar:SetPoint("TOPRIGHT", frame.Bg, "TOPRIGHT", -210, -10)
    leftScrollBar:SetPoint("BOTTOM", 0, 10)

    local leftScrollBox = CreateFrame("ScrollFrame", nil, frame, "WoWScrollBox")
    leftScrollBox:SetPoint("TOPRIGHT", leftScrollBar, "TOPLEFT", -10, 0)
    leftScrollBox:SetPoint("LEFT", 10, 0)
    leftScrollBox:SetPoint("BOTTOM", 0, 10)

    local leftScrollView = CreateScrollBoxLinearView()
    leftScrollView:SetPanExtent(50)

    local content = CreateFrame("Frame", nil, leftScrollBox, "ResizeLayoutFrame")
    content.scrollable = true
    content:SetPoint("TOPLEFT")
    content:SetPoint("TOPRIGHT")
    content:SetScript("OnSizeChanged", GenerateClosure(UpdateScrollBox, leftScrollBox))
    frame.content = content

    ScrollUtil.InitScrollBoxWithScrollBar(leftScrollBox, leftScrollBar, leftScrollView)

    -- Sidebar
    local rightScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    rightScrollBar:SetPoint("TOPRIGHT", frame.Bg, "TOPRIGHT", -10, -10)
    rightScrollBar:SetPoint("BOTTOM", 0, 10)

    local rightScrollBox = CreateFrame("ScrollFrame", nil, frame, "WoWScrollBox")
    rightScrollBox:SetPoint("TOPLEFT", leftScrollBar, "TOPRIGHT", 10, 0)
    rightScrollBox:SetPoint("TOPRIGHT", rightScrollBar, "TOPLEFT", -10, 0)
    rightScrollBox:SetPoint("BOTTOM", 0, 10)

    local rightScrollView = CreateScrollBoxLinearView()
    rightScrollView:SetPanExtent(50)

    local sidebar = CreateFrame("Frame", nil, rightScrollBox, "ResizeLayoutFrame")
    sidebar.scrollable = true
    sidebar:SetPoint("TOPLEFT")
    sidebar:SetPoint("TOPRIGHT")
    sidebar:SetScript("OnSizeChanged", GenerateClosure(UpdateScrollBox, rightScrollBox))
    frame.sidebar = sidebar

    ScrollUtil.InitScrollBoxWithScrollBar(rightScrollBox, rightScrollBar, rightScrollView)

    -- Sidebar widgets
    local dropdown = Mixin(CreateFrame("Button", nil, sidebar, "UIMenuButtonStretchTemplate"), dropdownMixin)
    dropdown:SetPoint("TOPLEFT")
    dropdown:SetPoint("TOPRIGHT")

    dropdown:SetList({
        bob = "Born of Blood",
    })

    dropdown:SetValue("bob")

    sidebar:MarkDirty()
end

function private:LoadTransactions()
    local content = private.frame.content

    for i = 1, 2000 do
        local line = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        line:SetText("Line " .. i)
        line:SetPoint("TOPLEFT", 0, -((i - 1) * 20))
    end

    content:MarkDirty()
end
