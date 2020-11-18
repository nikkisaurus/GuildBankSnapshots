local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local CreateFrame, UIParent = CreateFrame, UIParent

--*------------------------------------------------------------------------

-- Similar to AceGUI Window
-- Can be hidden on escape
local Type = "GBS3Frame"
local Version = 1

--*------------------------------------------------------------------------

local function sizer_OnMouseDown(self)
    self:GetParent():StartSizing()
    self.obj:Fire("OnMouseDown")
end

------------------------------------------------------------

local function sizer_OnMouseUp(self)
    self:GetParent():StopMovingOrSizing()
    self.obj:Fire("OnMouseUp")
end

------------------------------------------------------------

local function sizer_OnUpdate(self)
    self.obj:Fire("OnUpdate")
end

------------------------------------------------------------

local function title_OnMouseDown(self)
    self:GetParent():StartMoving()
end

------------------------------------------------------------

local function title_OnMouseUp(self)
    self:GetParent():StopMovingOrSizing()
end

--*------------------------------------------------------------------------

local methods = {
    OnAcquire = function(self)
        local frame = self.frame
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        frame:SetSize(750, 600)
    end,

    GetTitle = function(self)
        return self.titleText:GetText()
    end,

    Hide = function(self, ...)
        self.frame:Hide()
        self:Release()
    end,

    SetSize = function(self, ...)
        self.frame:SetSize(...)
    end,

    SetTitle = function(self, title)
        self.titleText:SetText(title)
    end,

    Show = function(self, ...)
        self.frame:Show()
    end,
}

--*------------------------------------------------------------------------

local function Constructor()
    local frame = CreateFrame("Frame", Type..AceGUI:GetNextWidgetNum(Type), UIParent, (BackdropTemplateMixin and "BackdropTemplate, " or "").."BaseBasicFrameTemplate")
    tinsert(UISpecialFrames, frame:GetName())

    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetPoint("CENTER")
    frame:SetSize(700, 500)
    frame:SetMinResize(240,240)

    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", frame_OnMouseDown)
    frame:SetScript("OnMouseUp", frame_OnMouseUp)

    ------------------------------------------------------------

    local title = CreateFrame("Button", nil, frame)
    title:SetPoint("TOPLEFT", 2, -2)
    title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -2, -20)
    title:SetScript("OnMouseDown", title_OnMouseDown)
    title:SetScript("OnMouseUp", title_OnMouseUp)

    local titleBG = frame:CreateTexture(nil, "BACKGROUND")
    titleBG:SetAllPoints(title)
    titleBG:SetTexture(251966)

    local titleText = frame:CreateFontString(nil, "ARTWORK")
    titleText:SetFontObject(GameFontNormal)
    titleText:SetAllPoints(title)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", titleBG, "BOTTOMLEFT", 0, -2)
    background:SetPoint("BOTTOMRIGHT", -1, 2)
    background:SetTexture(137056)
    background:SetVertexColor(0, 0, 0, .75)

    local sizer = CreateFrame("Button", nil, frame)
    sizer:SetPoint("BOTTOMRIGHT", -5, 5)
    sizer:SetSize(15, 15)
    sizer:SetNormalTexture([[INTERFACE\ADDONS\GUILDBANKSNAPSHOTS\WIDGETS\RESIZE]])
    sizer:GetNormalTexture():SetVertexColor(1, 1, 1, .5)
    sizer:SetScript("OnMouseDown", sizer_OnMouseDown)
    sizer:SetScript("OnMouseUp", sizer_OnMouseUp)
    sizer:SetScript("OnUpdate", sizer_OnUpdate)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", background, "TOPLEFT", 5, -5)
    content:SetPoint("BOTTOM", sizer, "TOP", 0, 5)
    content:SetPoint("RIGHT", background, "RIGHT", -5, 0)

    ------------------------------------------------------------

    if IsAddOnLoaded("ElvUI") then
        local E = unpack(_G["ElvUI"])
        local S = E:GetModule('Skins')

        frame:StripTextures()
        frame:SetTemplate("Transparent")
        S:HandleCloseButton(frame.CloseButton)
    end

    ------------------------------------------------------------

    local widget = {
		type  = Type,
        frame = frame,
        titleText = titleText,
        content = content,
    }

    frame.obj, title.obj, sizer.obj = widget, widget, widget

    for method, func in pairs(methods) do
        widget[method] = func
    end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

