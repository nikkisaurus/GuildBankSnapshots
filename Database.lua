local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)


local function BackupDatabase()
    local backup  = {}

    for k, v in pairs(GuildBankSnapshotsDB) do
        backup[k] = v
    end

    wipe(GuildBankSnapshotsDB)

    return backup
end


local function ConvertDatabase(backup, version)
    if version == 3 then
        -- print("Convert version 3 to 4")
    end
end




function addon:CleanupDatabase()
    self:DeleteCorruptedScans()

    -- Delete scans by age
    for guildID, guildInfo in pairs(self.db.global.guilds) do
        for scanID, _ in addon.pairs(guildInfo.scans) do
            local autoCleanupSettings = self.db.global.settings.scans.autoCleanup
            if autoCleanupSettings.age.enabled then
                -- Convert age to seconds
                local age = autoCleanupSettings.age.measure * addon.unitsToSeconds[autoCleanupSettings.age.unit]

                -- Delete scans
                if scanID < time() - age then
                    self.db.global.guilds[guildID].scans[scanID] = nil
                end
            end
        end
    end

    -- -- Clear selected scans that have been deleted
    -- if addon.analyze.scan and not addon.db.global.guilds[addon.analyze.guildID].scans[addon.analyze.scan[1]] then
    --     addon:SelectAnalyzeScan()
    -- end
    -- if addon.review.scan and not addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan] then
    --     addon:SelectReviewScan()
    -- end
end


function addon:DeleteCorruptedScans(lastScan)
    if not self.db.global.settings.scans.autoCleanup.corrupted then return end

    local lastScanCorrupted
    for guildID, guildInfo in pairs(self.db.global.guilds) do
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
                self.db.global.guilds[guildID].scans[scanID] = nil
            end
        end
    end

    return lastScanCorrupted
end


function addon:InitializeDatabase()
    local db, backup, version = GuildBankSnapshotsDB

    if db then
        if db.database and db.database == 3 then
            backup = BackupDatabase()
            version = 3
        end
    end

    local defaults = {
        global = {
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
                    enabled = true,
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
                        review = true,
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
                },
            },
        },
    }

    self.db = LibStub("AceDB-3.0"):New("GuildBankSnapshotsDB", defaults, true)

    if backup then
        ConvertDatabase(backup, version)
    end

    self.db.global.version = 4
end


function addon:UpdateGuildDatabase()
    local guildID, guildName, faction, realm = self:GetGuildID()
    local db = self.db.global.guilds[guildID]

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
