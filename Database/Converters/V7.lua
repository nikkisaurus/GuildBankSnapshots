local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

function private:ConvertDatabaseV7()
    private.db.global.backup = addon:CloneTable(private.db)

    local delay
    if private.db.global and private.db.global.guilds then
        for guildKey, guildInfo in pairs(private.db.global.guilds) do
            private.db.global.guilds[guildKey].masterScan = {}
            private.db.global.guilds[guildKey].filters = {}

            if guildInfo.scans then
                for scanID, _ in addon:pairs(guildInfo.scans) do
                    private:AddScanToMaster(guildKey, scanID)
                end
            end

            if private.db.global.settings then
                private.db.global.guilds[guildKey].settings = addon:CloneTable(private.db.global.settings.scans or private.defaults.guild.settings)
                delay = private.db.global.guilds[guildKey].settings.delay
                private.db.global.guilds[guildKey].settings.delay = nil
                private.db.global.settings.scans = nil
            end
        end
    end

    if private.db.global and private.db.global.settings then
        if private.db.global.settings.preferences then
            private.db.global.preferences = addon:CloneTable(private.db.global.settings.preferences)
            private.db.global.preferences.confirmDeletions = nil
            private.db.global.preferences.dateType = nil
            private.db.global.preferences.delay = delay or 0.5
            private.db.global.settings.preferences = nil
        end
    end
end
