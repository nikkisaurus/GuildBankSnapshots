local addonName, addon = ...
local FarmingBar = LibStub("AceAddon-3.0"):GetAddon("FarmingBar")
local L = LibStub("AceLocale-3.0"):GetLocale("FarmingBar", true)
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local CreateFrame, UIParent = CreateFrame, UIParent

--*------------------------------------------------------------------------

-- Similar to AceGUI SimpleGroup
-- No title
local Type = "GBS3SimpleGroup"
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
		self:SetHeight(height or 0)
	end,

	------------------------------------------------------------

	OnHeightSet = function(self, height)
		local content = self.content
		local contentheight = height
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	------------------------------------------------------------

	OnWidthSet = function(self, width)
		local content = self.content
		local contentwidth = width
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

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT")
	content:SetPoint("BOTTOMRIGHT")

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
