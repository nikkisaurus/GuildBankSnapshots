local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local function BackupDatabase()
    local backup = {}

    for k, v in pairs(GuildBankSnapshotsDB) do
        backup[k] = v
    end

    wipe(GuildBankSnapshotsDB)

    return backup
end

local function ConvertDatabase(backup, version)
    if version == 4 then
        private:ConvertDB4_5(backup)
    end
end

function private:CleanupDatabase()
    private:DeleteCorruptedScans()

    -- Delete scans by age
    for guildID, guildInfo in pairs(private.db.global.guilds) do
        for scanID, _ in addon.pairs(guildInfo.scans) do
            local autoCleanupSettings = private.db.global.settings.scans.autoCleanup
            if autoCleanupSettings.age.enabled then
                -- Convert age to seconds
                local age = autoCleanupSettings.age.measure * private.unitsToSeconds[autoCleanupSettings.age.unit]

                -- Delete scans
                if scanID < time() - age then
                    private.db.global.guilds[guildID].scans[scanID] = nil
                end
            end
        end
    end

    -- TODO
    -- -- Clear selected scans that have been deleted
    -- if private.analyze.scan and not private.db.global.guilds[private.analyze.guildID].scans[private.analyze.scan[1]] then
    --     private:SelectAnalyzeScan()
    -- end
    -- if private.review.scan and not private.db.global.guilds[private.review.guildID].scans[private.review.scan] then
    --     private:SelectReviewScan()
    -- end
end

function private:DeleteCorruptedScans(lastScan)
    if not private.db.global.settings.scans.autoCleanup.corrupted then
        return
    end

    local lastScanCorrupted
    for guildID, guildInfo in pairs(private.db.global.guilds) do
        for scanID, scan in pairs(guildInfo.scans) do
            local empty = 0

            -- Count empty transactions
            for _, tabInfo in pairs(scan.tabs) do
                if addon.tcount(tabInfo.transactions) == 0 then
                    empty = empty + 1
                end
            end

            -- Count empty money transactions
            if addon.tcount(scan.moneyTransactions) == 0 then
                empty = empty + 1
            end

            -- Delete corrupt scan
            if empty == guildInfo.numTabs + 1 then
                lastScanCorrupted = scanID == lastScan
                private.db.global.guilds[guildID].scans[scanID] = nil
            end
        end
    end

    return lastScanCorrupted
end

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
            guilds = {
                ["**"] = { -- guildID: "Guild Name (F) - Realm Name"
                    guildName = "",
                    faction = "",
                    realm = "",
                    numTabs = 0,
                    tabs = {},
                    masterScan = {},
                    scans = {},
                },
            },
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
            settings = {
                scans = {
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
                    delay = 0.5,
                    review = true,
                    reviewPath = "review", -- "review", "analyze", "export"
                },
                preferences = {
                    confirmDeletions = true,
                    dateFormat = "%x (%I:%M %p)", -- "%x (%X)"
                    dateType = "default", -- "default", "approx"
                    defaultGuild = false, -- guildID
                    guildFormat = "%g - %r (%F)",
                    exportDelimiter = ",",
                    sorting = "des",
                },
            },
        },
    }

    private.db = LibStub("AceDB-3.0"):New("GuildBankSnapshotsDB", defaults, true)

    backup = backup or private.db.global.backup
    version = version or private.db.global.backup and private.db.global.backup.database

    if backup then
        private.db.global.backup = backup
        ConvertDatabase(backup, version)
    end

    private.db.global.version = 5
end

function private:UpdateGuildDatabase()
    local guildID, guildName, faction, realm = private:GetGuildID()
    local db = private.db.global.guilds[guildID]

    db.guildName = guildName
    db.faction = faction
    db.realm = realm

    local numTabs = GetNumGuildBankTabs()
    db.numTabs = numTabs

    for tab = 1, numTabs do
        local name, icon = GetGuildBankTabInfo(tab)
        db.tabs[tab] = {
            name = name,
            icon = icon,
        }
    end
end
