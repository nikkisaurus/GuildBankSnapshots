local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)


function addon:InitializeOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self:GetOptions())
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 850, 600)
end


function addon:GetOptions()
    self.options = {
        type = "group",
        name = L.addon,
        args = {
            review = {
                order = 1,
                type = "group",
                name = L["Review"],
                childGroups = "tab",
                args = self:GetReviewOptions(),
            },
            analyze = {
                order = 2,
                type = "group",
                name = L["Analyze"],
                childGroups = "tab",
                args = self:GetAnalyzeOptions(),
            },
            export = {
                order = 3,
                type = "group",
                name = L["Export"],
                args = self:GetExportOptions(),
            },
            settings = {
                order = 4,
                type = "group",
                name = L["Settings"],
                childGroups = "tab",
                args = self:GetSettingsOptions(),
            },
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db),
            help = {
                order = 6,
                type = "group",
                name = L["Help"],
                args = self:GetHelpOptions(),
            },
        },
    }

    self.options.args.profiles.order = 5

    return self.options
end

