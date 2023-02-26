local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function BackupDatabase()
    local backup = addon:CloneTable(GuildBankSnapshotsDB)
    wipe(GuildBankSnapshotsDB)
    return backup
end

local function ConvertDatabase(backup, version)
    if version == 4 or version == 3 then
        private:ConvertDB4_5(backup)
    end
end

private.defaults = {
    guild = {
        guildName = "",
        faction = "",
        realm = "",
        numTabs = 0,
        tabs = {},
        masterScan = {},
        scans = {},
        filters = {},
        settings = {
            autoCleanup = {
                corrupted = true,
                age = {
                    enabled = false,
                    measure = 2,
                    unit = "months", -- minutes, hours, days, weeks, months
                },
            },
            autoScan = {
                enabled = true,
                alert = true,
                frequency = {
                    enabled = true,
                    measure = 1,
                    unit = "days", -- minutes, hours, days, weeks, months
                },
                review = false,
            },
            review = true,
            reviewPath = "review", -- "review", "analyze", "export"
        },
    },
}

function private:InitializeDatabase()
    local db, backup, version = GuildBankSnapshotsDB

    if db then
        if db.database then
            version = db.database
            backup = BackupDatabase()
        end
    end

    local defaults = {
        global = {
            -- debug = true,
            guilds = {},
            commands = {
                gbs = {
                    enabled = true,
                    func = "SlashCommandFunc",
                },

                scan = {
                    enabled = true,
                    func = "ScanGuildBank",
                },

                snap = {
                    enabled = false,
                    func = "ScanGuildBank",
                },

                snapshot = {
                    enabled = false,
                    func = "ScanGuildBank",
                },
            },
            preferences = {
                delay = 0.5,
                useClassColor = false,
                dateFormat = "%x (%I:%M %p)", -- "%x (%X)"
                sortHeaders = { 1, 2, 4, 3, 5, 6, 7, 8, 9 },
                descendingHeaders = {
                    [1] = true,
                    [2] = false,
                    [3] = false,
                    [4] = false,
                    [5] = false,
                    [6] = false,
                    [7] = false,
                    [8] = false,
                    [9] = false,
                },
                defaultGuild = false, -- guildID
                guildFormat = "%g - %r (%F)",
                exportDelimiter = ",",
            },
        },
    }

    private.db = LibStub("AceDB-3.0"):New("GuildBankSnapshotsDB", defaults, true)

    -- Version < 5
    backup = backup or private.db.global.backup
    version = version or private.db.global.backup and private.db.global.backup.database
    if backup then
        private.db.global.backup = backup
        if version == 3 or version == 4 then
            private:ConvertDatabaseV5(backup)
        end
    end

    -- Version < 6
    if not private.db.global.version or private.db.global.version < 6 then
        private:ConvertDatabaseV6()
    end

    -- Version < 7
    if private.db.global.version < 7 then
        private:ConvertDatabaseV7()
    end

    private.db.global.version = 7
end
