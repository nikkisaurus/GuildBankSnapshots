local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

function private:ConvertDatabaseV7()
    -- Update masterScan
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
end
