local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:ConvertDatabaseV7()
    -- Update masterScan
    if private.db.global and private.db.global.guilds then
        for guildKey, guildInfo in pairs(private.db.global.guilds) do
            -- private.db.global.guilds[guildKey].tabs = guildInfo.tabs or {}
            -- private.db.global.guilds[guildKey].scans = guildInfo.scans or {}
            -- private.db.global.guilds[guildKey].masterScan = guildInfo.masterScan or {}
            private.db.global.guilds[guildKey].filters = guildInfo.filters or {}
            -- private.db.global.guilds[guildKey].filters = {}
        end
    end
end
