local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:GetOptions()
    private.options = {
        type = "group",
        name = L.addonName,
        args = {
            review = {
                order = 1,
                type = "group",
                name = L["Review"],
                childGroups = "select",
                args = private:GetReviewOptions(),
            },
            analyze = {
                order = 2,
                type = "group",
                name = L["Analyze"],
                childGroups = "tab",
                args = private:GetAnalyzeOptions(),
            },
            export = {
                order = 3,
                type = "group",
                name = L["Export"],
                args = private:GetExportOptions(),
            },
            settings = {
                order = 4,
                type = "group",
                name = L["Settings"],
                childGroups = "tab",
                args = private:GetSettingsOptions(),
            },
            help = {
                order = 6,
                type = "group",
                name = L["Help"],
                args = private:GetHelpOptions(),
            },
        },
    }

    return private.options
end

function private:InitializeOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, private:GetOptions())
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 850, 600)
end

function private:RefreshOptions()
    if not private.options then
        return
    end

    if private.options.args.review then
        private.options.args.review.args = private:GetReviewOptions()
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    LibStub("AceConfigDialog-3.0"):Open(addonName)
end
