local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")

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
            export = {
                order = 2,
                type = "group",
                name = L["Export"],
                args = private:GetExportOptions(),
            },
            settings = {
                order = 3,
                type = "group",
                name = L["Settings"],
                childGroups = "tab",
                args = private:GetSettingsOptions(),
            },
            help = {
                order = 4,
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
    ACD:SetDefaultSize(addonName, 850, 600)
end

function private:RefreshOptions()
    if not private.options then
        return
    end

    if private.options.args.review then
        private.options.args.review.args = private:GetReviewOptions()
    end

    if private.options.args.analyze then
        private.options.args.analyze.args = private:GetAnalyzeOptions()
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    ACD:Open(addonName)
end

function private:RefreshReviewOptions()
    if not private.options then
        return
    end

    if private.options.args.review then
        private.options.args.review.args = private:GetReviewOptions()
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    ACD:Open(addonName)
end

function private:RefreshAnalyzeOptions(guildKey, scanID)
    if not private.options then
        return
    end

    if private.options.args.analyze then
        private.options.args.analyze.args = private:GetAnalyzeOptions(guildKey, scanID)
    end

    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end
