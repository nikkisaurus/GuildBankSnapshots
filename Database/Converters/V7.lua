local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

function private:ConvertDatabaseV7()
    private.db.global.backup = addon:CloneTable(private.db)

    -- Update master scan
    if private.db.global and private.db.global.guilds then
        for guildKey, guildInfo in pairs(private.db.global.guilds) do
            private.db.global.guilds[guildKey].masterScan = {}
            private.db.global.guilds[guildKey].filters = {}

            if guildInfo.scans then
                for scanID, _ in addon:pairs(guildInfo.scans) do
                    private:AddScanToMaster(guildKey, scanID)
                end
            end
        end
    end

    -- Move settings around
    if private.db.global and private.db.global.settings then
        local scanSettings = private.db.global.settings.scans

        if private.db.global.guilds then
            for guildKey, guildInfo in pairs(private.db.global.guilds) do
                if not guildInfo.settings then
                    private.db.global.guilds[guildKey].settings = {
                        autoCleanup = {
                            corrupted = scanSettings.autoCleanup.corrupted ~= false and true or false,
                            age = {
                                enabled = scanSettings.autoCleanup.age.enabled ~= false and true or false,
                                measure = scanSettings.autoCleanup.age.measure or 1,
                                unit = scanSettings.autoCleanup.age.unit or "months",
                            },
                        },
                        autoScan = {
                            enabled = scanSettings.autoScan.enabled ~= false and true or false,
                            alert = scanSettings.autoScan.alert ~= false and true or false,
                            frequency = {
                                enabled = scanSettings.autoScan.frequency.enabled ~= false and true or false,
                                measure = scanSettings.autoScan.frequency.measure or 1,
                                unit = scanSettings.autoScan.frequency.unit or "months",
                            },
                            review = scanSettings.autoScan.review ~= false and true or false,
                        },
                        review = scanSettings.review ~= false and true or false,
                        reviewPath = scanSettings.reviewPath or "review",
                    }
                end
            end
        end

        private.db.global.preferences.delay = scanSettings.delay or 0.5

        local preferences = private.db.global.settings.preferences
        if preferences then
            if preferences.dateFormat then
                private.db.global.preferences.dateFormat = preferences.dateFormat
            end
            if preferences.defaultGuild then
                private.db.global.preferences.defaultGuild = preferences.defaultGuild
            end
            if preferences.guildFormat then
                private.db.global.preferences.guildFormat = preferences.guildFormat
            end
            if preferences.exportDelimiter then
                private.db.global.preferences.exportDelimiter = preferences.exportDelimiter
            end
        end

        private.db.global.settings = nil
    end
end
