local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local Type, Version = "GuildBankSnapshotsTransaction", 1

local function Constructor()
	local label = AceGUI:Create("Label")
	local frame = label.frame

	frame:SetHyperlinksEnabled(true)
	frame:SetScript("OnHyperlinkClick", DEFAULT_CHAT_FRAME:GetScript("OnHyperlinkClick"))
	frame:SetScript("OnHyperlinkEnter", function(_, link)
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end)
	frame:SetScript("OnHyperlinkLeave", function(...)
		HideUIPanel(GameTooltip)
	end)

	local widget = {}
	for method, func in pairs(label) do
		widget[method] = func
	end
	widget.type = Type

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
