local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local selectedGuild

local function SelectGuild(guildGroup, _, guildKey)
    selectedGuild = guildKey
end

function private:GetAnalyzeOptions(content)
    content:SetLayout("Fill")

    local guildGroup = AceGUI:Create("DropdownGroup")
    guildGroup:SetLayout("Fill")
    guildGroup:SetDropdownWidth(content.content:GetWidth())
    guildGroup:SetGroupList(private:GetGuildList())
    guildGroup:SetCallback("OnGroupSelected", SelectGuild)
    content:AddChild(guildGroup)
    guildGroup:SetGroup(selectedGuild or private.db.global.settings.preferences.defaultGuild)
end
