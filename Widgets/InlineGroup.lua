local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local CreateFrame, UIParent = CreateFrame, UIParent

--*------------------------------------------------------------------------

-- Similar to AceGUI InlineGroup
-- No title
local Type = "GBS3InlineGroup"
local Version = 1

--*------------------------------------------------------------------------

local methods = {
	OnAcquire = function(self)
		self:SetWidth(300)
		self:SetHeight(100)
	end,

    ------------------------------------------------------------

	LayoutFinished = function(self, width, height)
		if self.noAutoHeight then return end
		self:SetHeight((height or 0) + 24)
	end,

	------------------------------------------------------------

	OnHeightSet = function(self, height)
		local content = self.content
		local contentheight = height - 16
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	------------------------------------------------------------

	OnWidthSet = function(self, width)
		local content = self.content
		local contentwidth = width - 16
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end,
}

--*------------------------------------------------------------------------

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:Hide()
    -- addon:SetPanelBackdrop(frame)

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 8, -8)
	content:SetPoint("BOTTOMRIGHT", -8, 8)

    ------------------------------------------------------------

    if IsAddOnLoaded("ElvUI") then
        local E = unpack(_G["ElvUI"])
        local S = E:GetModule('Skins')

        frame:StripTextures()
        frame:SetTemplate("Transparent")
    end

    ------------------------------------------------------------

	local widget = {
		type = Type,
		frame = frame,
		content = content,
    }

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
