local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*------------------------------------------------------------------------

function addon:InitializeDatabase()
    local db, backup, version = GuildBankSnapshotsDB
    if db then
        if db.database and db.database == 3 then
            backup = self:BackupDatabase()
            version = 3
        end
    end

    ------------------------------------------------------------

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

            settings = {
                autoScanDelay = .2,
                autoScanAlert = true,
                reviewAutoScans = false,
                reviewScans = true,

                dateFormat = "%x (%X)",
                dateType = "default", -- "default", "approx"

                guildFormat = "%g (%f) - %r",
                defaultGuild = false, -- guildID

                confirmDeletions = true,
            },
        },
    }

    ------------------------------------------------------------

    self.db = LibStub("AceDB-3.0"):New("GuildBankSnapshotsDB", defaults, true)

    ------------------------------------------------------------

    if backup then
        self:ConvertDatabase(backup, version)
    end

    ------------------------------------------------------------

    self.db.global.version = 4
end

--*------------------------------------------------------------------------

function addon:BackupDatabase()
    local backup  = {}
    for k, v in pairs(GuildBankSnapshotsDB) do
        backup[k] = v
    end
    wipe(GuildBankSnapshotsDB)
    return backup
end

------------------------------------------------------------

function addon:ConvertDatabase(backup, version)
    if version == 3 then
        -- print("Convert version 3 to 4")
    end
end

--*------------------------------------------------------------------------

function addon:UpdateGuildDatabase()
    local guildID, guildName, faction, realm = self:GetGuildID()
    local db = self.db.global.guilds[guildID]

    ------------------------------------------------------------

    db.guildName = guildName
    db.faction = faction
    db.realm = realm

    ------------------------------------------------------------

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