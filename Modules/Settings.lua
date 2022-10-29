local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local function GetUnits(measure)
    if measure == 1 then
        return {
            minutes = L["minute"],
            hours = L["hour"],
            days = L["day"],
            weeks = L["week"],
            months = L["month"],
        }
    else
        return {
            minutes = L["minutes"],
            hours = L["hours"],
            days = L["days"],
            weeks = L["weeks"],
            months = L["months"],
        }
    end
end

function private:GetSettingsOptions(content)
    LibStub("AceConfigDialog-3.0"):Open(addonName .. "Settings", content)
end

function private:GetSettingsOptionsTable()
    local options = {
        type = "group",
        childGroups = "tab",
        name = "",
        args = {

            scans = {
                order = 1,
                type = "group",
                name = L["Scans"],
                get = function(info)
                    return private.db.global.settings.scans[info[#info]]
                end,
                set = function(info, value)
                    private.db.global.settings.scans[info[#info]] = value
                end,
                args = {
                    delay = {
                        order = 1,
                        type = "range",
                        name = L["Delay"],
                        desc = L.ScanDelayDescription,
                        min = 0,
                        max = 5,
                        step = 0.01,
                    },
                    reviewPath = {
                        order = 2,
                        type = "select",
                        style = "dropdown",
                        name = L["Review Path"],
                        desc = L.ScanReviewPathDescription,
                        hidden = function()
                            return not private.db.global.settings.scans.review
                        end,
                        values = function()
                            return {
                                analyze = L["Analyze"],
                                export = L["Export"],
                                review = L["Review"],
                            }
                        end,
                        sorting = { "review", "analyze", "export" },
                    },
                    review = {
                        order = 3,
                        type = "toggle",
                        name = L["Review after scan"],
                        desc = L.ScanReviewDescription,
                    },
                    autoScan = {
                        order = 4,
                        type = "group",
                        inline = true,
                        name = L["Auto Scan"],
                        get = function(info)
                            return private.db.global.settings.scans.autoScan[info[#info]]
                        end,
                        set = function(info, value)
                            private.db.global.settings.scans.autoScan[info[#info]] = value
                        end,
                        args = {
                            enabled = {
                                order = 1,
                                type = "toggle",
                                width = 0.75,
                                name = L["Enable"],
                            },
                            alert = {
                                order = 2,
                                type = "toggle",
                                width = 1.25,
                                name = L["Alert scan progress"],
                                desc = L.ScanAutoAlertDescription,
                            },
                            review = {
                                order = 3,
                                type = "toggle",
                                width = 1.25,
                                name = L["Review after auto scan"],
                                desc = L.ScanAutoReviewDescription,
                            },
                            frequencyEnabled = {
                                order = 4,
                                type = "toggle",
                                width = 1.25,
                                name = L["Enable frequency limit"],
                                desc = L.ScanAutoFrequncyEnabledDescription,
                                get = function()
                                    return private.db.global.settings.scans.autoScan.frequency.enabled
                                end,
                                set = function(_, value)
                                    private.db.global.settings.scans.autoScan.frequency.enabled = value
                                end,
                            },
                            frequencyMeasure = {
                                order = 5,
                                type = "range",
                                name = L["Frequency Measure"],
                                desc = L.ScanAutoFrequencyDescription,
                                disabled = function()
                                    return not private.db.global.settings.scans.autoScan.frequency.enabled
                                end,
                                get = function()
                                    return private.db.global.settings.scans.autoScan.frequency.measure
                                end,
                                set = function(_, value)
                                    private.db.global.settings.scans.autoScan.frequency.measure = value
                                end,
                                min = 1,
                                max = 59,
                                step = 1,
                            },
                            frequencyUnit = {
                                order = 6,
                                type = "select",
                                style = "dropdown",
                                name = L["Frequency Unit"],
                                disabled = function()
                                    return not private.db.global.settings.scans.autoScan.frequency.enabled
                                end,
                                get = function()
                                    return private.db.global.settings.scans.autoScan.frequency.unit
                                end,
                                set = function(_, value)
                                    private.db.global.settings.scans.autoScan.frequency.unit = value
                                end,
                                values = function()
                                    return GetUnits(private.db.global.settings.scans.autoScan.frequency.measure)
                                end,
                                sorting = { "minutes", "hours", "days", "weeks", "months" },
                            },
                        },
                    },
                    autoCleanup = {
                        order = 5,
                        type = "group",
                        inline = true,
                        name = L["Auto Cleanup"],
                        get = function(info)
                            return private.db.global.settings.scans.autoCleanup[info[#info]]
                        end,
                        set = function(info, value)
                            private.db.global.settings.scans.autoCleanup[info[#info]] = value
                        end,
                        args = {
                            corrupted = {
                                order = 1,
                                type = "toggle",
                                width = 1.25,
                                name = L["Delete corrupted scans"],
                            },
                            ageEnabled = {
                                order = 2,
                                type = "toggle",
                                width = 1.5,
                                name = L["Delete scans older than"] .. ":",
                                desc = L.ScanAutoCleanupEnabledDescription,
                                get = function()
                                    return private.db.global.settings.scans.autoCleanup.age.enabled
                                end,
                                set = function(_, value)
                                    private.db.global.settings.scans.autoCleanup.age.enabled = value
                                end,
                            },
                            ageMeasure = {
                                order = 3,
                                type = "range",
                                name = L["Age Measure"],
                                desc = L.ScanAutoCleanupDescription,
                                disabled = function()
                                    return not private.db.global.settings.scans.autoCleanup.age.enabled
                                end,
                                get = function()
                                    return private.db.global.settings.scans.autoCleanup.age.measure
                                end,
                                set = function(_, value)
                                    private.db.global.settings.scans.autoCleanup.age.measure = value
                                end,
                                min = 1,
                                max = 59,
                                step = 1,
                            },
                            ageUnit = {
                                order = 4,
                                type = "select",
                                style = "dropdown",
                                name = L["Age Unit"],
                                disabled = function()
                                    return not private.db.global.settings.scans.autoCleanup.age.enabled
                                end,
                                get = function()
                                    return private.db.global.settings.scans.autoCleanup.age.unit
                                end,
                                set = function(_, value)
                                    private.db.global.settings.scans.autoCleanup.age.unit = value
                                end,
                                values = function()
                                    return GetUnits(private.db.global.settings.scans.autoCleanup.age.measure)
                                end,
                                sorting = { "minutes", "hours", "days", "weeks", "months" },
                            },
                            cleanup = {
                                order = 5,
                                type = "execute",
                                name = L["Cleanup"],
                                confirm = function()
                                    return L.ConfirmCleanup
                                end,
                                func = function()
                                    private:CleanupDatabase()
                                    private:SelectAnalyzeGuild(private.analyze.guildID)
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
                                    addon:Print(L["Cleanup finished."])
                                end,
                            },
                        },
                    },
                },
            },
            preferences = {
                order = 2,
                type = "group",
                name = L["Preferences"],
                get = function(info)
                    return private.db.global.settings.preferences[info[#info]]
                end,
                set = function(info, value)
                    private.db.global.settings.preferences[info[#info]] = value
                end,
                args = {
                    dateFormat = {
                        order = 1,
                        type = "select",
                        style = "dropdown",
                        name = L["Date Format"],
                        width = "double",
                        values = function()
                            local currentTime = time()
                            return {
                                ["%b %d, %Y (%X)"] = date("%b %d, %Y (%X)", currentTime),
                                ["%b %d, %Y (%H:%M)"] = date("%b %d, %Y (%H:%M)", currentTime),
                                ["%b %d, %Y (%I:%M:%S %p)"] = date("%b %d, %Y (%I:%M:%S %p)", currentTime),
                                ["%b %d, %Y (%I:%M %p)"] = date("%b %d, %Y (%I:%M %p)", currentTime),

                                ["%B %d, %Y (%X)"] = date("%B %d, %Y (%X)", currentTime),
                                ["%B %d, %Y (%H:%M)"] = date("%B %d, %Y (%H:%M)", currentTime),
                                ["%B %d, %Y (%I:%M:%S %p)"] = date("%B %d, %Y (%I:%M:%S %p)", currentTime),
                                ["%B %d, %Y (%I:%M %p)"] = date("%B %d, %Y (%I:%M %p)", currentTime),

                                ["%x (%X)"] = date("%x (%X)", currentTime),
                                ["%x (%H:%M)"] = date("%x (%H:%M)", currentTime),
                                ["%x (%I:%M:%S %p)"] = date("%x (%I:%M:%S %p)", currentTime),
                                ["%x (%I:%M %p)"] = date("%x (%I:%M %p)", currentTime),

                                ["%m/%d/%Y (%X)"] = date("%m/%d/%Y (%X)", currentTime),
                                ["%m/%d/%Y (%H:%M)"] = date("%m/%d/%Y (%H:%M)", currentTime),
                                ["%m/%d/%Y (%I:%M:%S %p)"] = date("%m/%d/%Y (%I:%M:%S %p)", currentTime),
                                ["%m/%d/%Y (%I:%M %p)"] = date("%m/%d/%Y (%I:%M %p)", currentTime),
                            }
                        end,
                    },
                    dateType = {
                        order = 2,
                        type = "select",
                        style = "dropdown",
                        name = L["Date Type"],
                        desc = L.DateTypeDescription,
                        values = function()
                            return {
                                default = L["Default"],
                                approx = L["Approximate"],
                            }
                        end,
                        sorting = { "default", "approx" },
                    },
                    defaultGuild = {
                        order = 3,
                        type = "select",
                        style = "dropdown",
                        name = L["Default Guild"],
                        desc = L.DefaultGuildDescription,
                        width = "double",
                        disabled = function()
                            return addon.tcount(private.db.global.guilds) == 0
                        end,
                        values = function()
                            local guilds = {}

                            for guildID, guildInfo in addon.pairs(private.db.global.guilds) do
                                guilds[guildID] = private:GetGuildDisplayName(guildID)
                            end

                            return guilds
                        end,
                    },
                    guildFormat = {
                        order = 4,
                        type = "input",
                        name = L["Guild Format"],
                        desc = L.GuildFormatDescription,
                    },
                    exportDelimiter = {
                        order = 5,
                        type = "select",
                        style = "dropdown",
                        name = L["Date Type"],
                        desc = L.DateTypeDescription,
                        values = function()
                            return {
                                [","] = format("%s (%s)", L["Comma"], ","),
                                [";"] = format("%s (%s)", L["Semicolon"], ";"),
                                ["|"] = format("%s (%s)", L["Pipe"], "|"),
                            }
                        end,
                        sorting = { ",", ";", "|" },
                    },
                    confirmDeletions = {
                        order = 6,
                        type = "toggle",
                        name = L["Confirm Deletions"],
                        desc = L.ConfirmDeletionsDescription,
                    },
                    commands = {
                        order = 7,
                        type = "group",
                        inline = true,
                        name = L["Scan Shortcuts"],
                        args = {},
                    },
                },
            },
        },
    }

    for cmd, info in pairs(private.db.global.commands) do
        if cmd ~= "gbs" then
            options.args.preferences.args.commands.args[cmd] = {
                type = "toggle",
                name = "/" .. cmd,
                get = function()
                    return info.enabled
                end,
                set = function(_, value)
                    private.db.global.commands[cmd].enabled = value and true or false
                    private:InitializeSlashCommands()
                end,
            }
        end
    end

    return options
end
