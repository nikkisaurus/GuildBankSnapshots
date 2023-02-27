local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--*----------[[ Initialize tab ]]----------*--
local SettingsTab
local callbacks, forwardCallbacks, info, tooltips
local DoLayout, DrawGroup, GetUnits
local spacer

function private:InitializeSettingsTab()
    SettingsTab = {
        guildKey = private.db.global.preferences.defaultGuild,
    }
end

--*----------[[ Data ]]----------*--
callbacks = {
    container = {
        OnSizeChanged = {
            function()
                DrawGroup("guild", SettingsTab.guildGroup)
                DrawGroup("preferences", SettingsTab.preferencesGroup)
                DrawGroup("commands", SettingsTab.commandsGroup)
            end,
            true,
        },
    },
    selectGuild = {
        OnShow = {
            function(self)
                self:SelectByID(SettingsTab.guild or SettingsTab.guildKey)
            end,
            true,
        },
    },
    debug = {
        OnClick = {
            function(self)
                private.db.global.debug = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.debug, true)
            end,
            true,
        },
    },
    review = {
        OnClick = {
            function(self)
                private.db.global.guilds[SettingsTab.guildKey].settings.review = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.review, true)
            end,
            true,
        },
    },
    reviewPath = {
        OnShow = {
            function(self)
                self:SelectByID(private.db.global.guilds[SettingsTab.guildKey].settings.reviewPath)
            end,
            true,
        },
    },
    autoScanEnabled = {
        OnClick = {
            function(self)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.enabled = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.enabled, true)
            end,
            true,
        },
    },
    autoScanAlert = {
        OnClick = {
            function(self)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.alert = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.alert, true)
            end,
            true,
        },
    },
    autoScanReview = {
        OnClick = {
            function(self)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.review = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.review, true)
            end,
            true,
        },
    },
    autoScanFrequencyEnabled = {
        OnClick = {
            function(self)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.enabled = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.enabled, true)
            end,
            true,
        },
    },
    autoScanFrequencyMeasure = {
        OnShow = {
            function(self)
                self:SetValue(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.measure)
            end,
            true,
        },
        OnSliderValueChanged = {
            function(self, value)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.measure = value
                SettingsTab.autoScanFrequencyUnit:SelectByID(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.unit)
            end,
        },
    },
    autoScanFrequencyUnit = {
        OnShow = {
            function(self)
                self:SelectByID(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.unit)
            end,
            true,
        },
    },
    autoCleanupCorrupted = {
        OnClick = {
            function(self)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.corrupted = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.corrupted, true)
            end,
            true,
        },
    },
    autoCleanupAgeEnabled = {
        OnClick = {
            function(self)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.enabled = self:GetChecked()
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.enabled, true)
            end,
            true,
        },
    },
    autoCleanupAgeMeasure = {
        OnShow = {
            function(self)
                self:SetValue(private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.measure)
            end,
            true,
        },
        OnSliderValueChanged = {
            function(self, value)
                private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.measure = value
                SettingsTab.autoCleanupAgeUnit:SelectByID(private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.unit)
            end,
        },
    },
    autoCleanupAgeUnit = {
        OnShow = {
            function(self)
                self:SelectByID(private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.unit)
            end,
            true,
        },
    },
    cleanup = {
        OnClick = {
            function(self)
                private:CleanupDatabase(SettingsTab.guildKey)
                addon:Print(L["Cleanup finished."])
            end,
        },
    },
    useClassColor = {
        OnClick = {
            function(self)
                private.db.global.preferences.useClassColor = self:GetChecked()
                private:LoadFrame("Settings")
            end,
        },
        OnShow = {
            function(self)
                self:SetCheckedState(private.db.global.preferences.useClassColor, true)
            end,
            true,
        },
    },
    dateFormat = {
        OnShow = {
            function(self)
                self:SetText(private.db.global.preferences.dateFormat)
            end,
            true,
        },
    },
    guildFormat = {
        OnShow = {
            function(self)
                self:SetText(private.db.global.preferences.guildFormat)
            end,
            true,
        },
    },
    defaultGuild = {
        OnShow = {
            function(self)
                self:SelectByID(private.db.global.preferences.defaultGuild)
            end,
            true,
        },
    },
    exportDelimiter = {
        OnShow = {
            function(self)
                self:SelectByID(private.db.global.preferences.exportDelimiter)
            end,
            true,
        },
    },
    delay = {
        OnShow = {
            function(self)
                self:SetValue(private.db.global.preferences.delay)
            end,
            true,
        },
        OnSliderValueChanged = {
            function(self, value)
                private.db.global.preferences.delay = value
            end,
        },
    },
    command = {
        OnClick = {
            function(self)
                local cmd = gsub(self:GetText(), "/", "")
                private.db.global.commands[cmd].enabled = self:GetChecked()
                private:InitializeSlashCommands()
            end,
        },
        OnShow = {
            function(self)
                local cmd = gsub(self:GetText(), "/", "")
                self:SetCheckedState(private.db.global.commands[cmd].enabled, true)
            end,
            true,
        },
    },
}

forwardCallbacks = {
    dateFormat = {
        OnEnterPressed = {
            function(self)
                private.db.global.preferences.dateFormat = self:GetText()
            end,
        },
    },
    guildFormat = {
        OnEnterPressed = {
            function(self)
                private.db.global.preferences.guildFormat = self:GetText()
                private:LoadFrame("Settings")
            end,
        },
    },
    defaultGuild = {
        OnClear = {
            function(self)
                private.db.global.preferences.defaultGuild = false
            end,
        },
    },
}

info = {
    selectGuild = function()
        local info = {}

        private:IterateGuilds(function(guildKey, guildName, guild)
            tinsert(info, {
                id = guildKey,
                text = guildName,
                func = function(dropdown, info)
                    SettingsTab.guildKey = info.id
                    DrawGroup("guild", SettingsTab.guildGroup)
                end,
            })
        end)

        return info
    end,
    reviewPath = function()
        local info = {}

        for _, tab in addon:pairs({ "Analyze", "Review" }) do
            tinsert(info, {
                id = strlower(tab),
                text = L[tab],
                func = function()
                    private.db.global.guilds[SettingsTab.guildKey].settings.reviewPath = strlower(tab)
                end,
            })
        end

        return info
    end,
    autoScanFrequencyUnit = function()
        local info = {}

        for id, unit in addon:pairs(GetUnits(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.measure)) do
            tinsert(info, {
                id = id,
                text = unit,
                func = function()
                    private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.unit = id
                end,
            })
        end

        return info
    end,
    autoCleanupAgeUnit = function()
        local info = {}

        for id, unit in addon:pairs(GetUnits(private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.measure)) do
            tinsert(info, {
                id = id,
                text = unit,
                func = function()
                    private.db.global.guilds[SettingsTab.guildKey].settings.autoCleanup.age.unit = id
                end,
            })
        end

        return info
    end,
    defaultGuild = function()
        local info = {}

        private:IterateGuilds(function(guildKey, guildName, guild)
            tinsert(info, {
                id = guildKey,
                text = guildName,
                func = function(dropdown, info)
                    private.db.global.preferences.defaultGuild = info.id
                end,
            })
        end)

        return info
    end,
    exportDelimiter = function()
        local info = {}

        local delimiters = {
            [","] = format("%s (%s)", L["Comma"], ","),
            [";"] = format("%s (%s)", L["Semicolon"], ";"),
            ["|"] = format("%s (%s)", L["Pipe"], "|"),
        }

        for id, text in pairs(delimiters) do
            tinsert(info, {
                id = id,
                text = text,
                func = function(self)
                    private.db.global.preferences.exportDelimiter = id
                end,
            })
        end

        return info
    end,
}

tooltips = {
    dateFormat = function()
        -- http://www.lua.org/pil/22.1.html
        GameTooltip:AddDoubleLine("abbreviated weekday name (e.g., Wed)", "%a", 1, 1, 1)
        GameTooltip:AddDoubleLine("full weekday name (e.g., Wednesday)", "%A", 1, 1, 1)
        GameTooltip:AddDoubleLine("abbreviated month name (e.g., Sep)", "%b", 1, 1, 1)
        GameTooltip:AddDoubleLine("full month name (e.g., September)", "%B", 1, 1, 1)
        GameTooltip:AddDoubleLine("date and time (e.g., 09/16/98 23:48:10)", "%c", 1, 1, 1)
        GameTooltip:AddDoubleLine("day of the month (16) [01-31]", "%d", 1, 1, 1)
        GameTooltip:AddDoubleLine("hour, using a 24-hour clock (23) [00-23]", "%H", 1, 1, 1)
        GameTooltip:AddDoubleLine("hour, using a 12-hour clock (11) [01-12]", "%I", 1, 1, 1)
        GameTooltip:AddDoubleLine("minute (48) [00-59]", "%M", 1, 1, 1)
        GameTooltip:AddDoubleLine("month (09) [01-12]", "%m", 1, 1, 1)
        GameTooltip:AddDoubleLine("either 'am' or 'pm' (pm)", "%p", 1, 1, 1)
        GameTooltip:AddDoubleLine("second (10) [00-61]", "%S", 1, 1, 1)
        GameTooltip:AddDoubleLine("weekday (3) [0-6 = Sunday-Saturday]", "%w", 1, 1, 1)
        GameTooltip:AddDoubleLine("date (e.g., 09/16/98)", "%x", 1, 1, 1)
        GameTooltip:AddDoubleLine("time (e.g., 23:48:10)", "%X", 1, 1, 1)
        GameTooltip:AddDoubleLine("full year (1998)", "%Y", 1, 1, 1)
        GameTooltip:AddDoubleLine("two-digit year (98) [00-99]", "%y", 1, 1, 1)
        GameTooltip:AddDoubleLine("the character `%´", "%%", 1, 1, 1)
        GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1)
        GameTooltip:AddLine(format(L["See '%s' for more information"], "http://www.lua.org/pil/22.1.html"), 1, 1, 1)
    end,
    guildFormat = function()
        GameTooltip:AddDoubleLine(L["abbreviated faction"], "%f", 1, 1, 1)
        GameTooltip:AddDoubleLine(L["faction"], "%F", 1, 1, 1)
        GameTooltip:AddDoubleLine(L["guild name"], "%g", 1, 1, 1)
        GameTooltip:AddDoubleLine(L["realm name"], "%r", 1, 1, 1)
    end,
    delay = function()
        GameTooltip:AddLine(L["Determines the amount of time (in seconds) between querying the guild bank transaction logs and saving the scan"])
        GameTooltip:AddLine(L["Increasing this delay may help reduce corrupt scans"])
    end,
}

-- --*----------[[ Methods ]]----------*--
DoLayout = function()
    SettingsTab.container.content:MarkDirty()
    SettingsTab.container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
end

DrawGroup = function(groupType, group)
    group:ReleaseChildren()

    if groupType == "guild" and SettingsTab.guildKey then
        local review = group:Acquire("GuildBankSnapshotsCheckButton")
        review:SetText(L["Review after manual scan"], true)
        review:SetTooltipInitializer(L["Shows the review frame after manually scanning the bank"])
        review:SetCallbacks(callbacks.review)
        group:AddChild(review)

        --.....................
        spacer = group:Acquire("GuildBankSnapshotsFontFrame")
        spacer:SetUserData("width", "full")
        spacer:SetHeight(1)
        group:AddChild(spacer)
        --.....................

        local reviewPath = group:Acquire("GuildBankSnapshotsDropdownFrame")
        reviewPath:SetLabel(L["Review Path"])
        reviewPath:SetLabelFont(nil, private:GetInterfaceFlairColor())
        reviewPath:SetInfo(info.reviewPath)
        reviewPath:SetCallbacks(callbacks.reviewPath)
        group:AddChild(reviewPath)

        -----------------------

        local autoScanHeader = group:Acquire("GuildBankSnapshotsFontFrame")
        autoScanHeader:SetUserData("width", "full")
        autoScanHeader:SetTextColor(private:GetInterfaceFlairColor():GetRGBA())
        autoScanHeader:Justify("LEFT")
        autoScanHeader:SetText(L["Auto Scan"])
        group:AddChild(autoScanHeader)

        local autoScanGroup = group:Acquire("GuildBankSnapshotsGroup")
        autoScanGroup:SetUserData("width", "full")
        autoScanGroup:SetWidth(group:GetWidth()) -- have to explicitly set width or its children won't layout properly
        autoScanGroup:SetPadding(10, 10)
        autoScanGroup:SetSpacing(5)
        private:AddBackdrop(autoScanGroup, { bgColor = "dark" })
        group:AddChild(autoScanGroup)

        local autoScanEnabled = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoScanEnabled:SetText(L["Enable"], true)
        autoScanEnabled:SetCallbacks(callbacks.autoScanEnabled)
        autoScanGroup:AddChild(autoScanEnabled)

        local autoScanAlert = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoScanAlert:SetText(L["Alert scan progress"], true)
        autoScanAlert:SetTooltipInitializer(L["Displays a message with the status of auto scans"])
        autoScanAlert:SetCallbacks(callbacks.autoScanAlert)
        autoScanGroup:AddChild(autoScanAlert)

        local autoScanReview = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoScanReview:SetText(L["Review after auto scan"], true)
        autoScanReview:SetTooltipInitializer(L["Shows the review frame after the bank auto scans"])
        autoScanReview:SetCallbacks(callbacks.autoScanReview)
        autoScanGroup:AddChild(autoScanReview)

        local autoScanFrequencyEnabled = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoScanFrequencyEnabled:SetText(L["Limit auto scans"], true)
        autoScanFrequencyEnabled:SetTooltipInitializer(L["Limits the number of auto scans allowed to run in a specified time period"])
        autoScanFrequencyEnabled:SetCallbacks(callbacks.autoScanFrequencyEnabled)
        autoScanGroup:AddChild(autoScanFrequencyEnabled)

        --.....................
        spacer = autoScanGroup:Acquire("GuildBankSnapshotsFontFrame")
        spacer:SetUserData("width", "full")
        spacer:SetHeight(1)
        autoScanGroup:AddChild(spacer)
        --.....................

        local autoScanFrequencyMeasure = autoScanGroup:Acquire("GuildBankSnapshotsSliderFrame")
        autoScanFrequencyMeasure:SetBackdropColor(private.interface.colors.darker)
        autoScanFrequencyMeasure:SetSize(150, 50)
        autoScanFrequencyMeasure:SetMinMaxValues(1, 59, 1, 0)
        autoScanFrequencyMeasure:SetLabel(L["Allow auto scan every"] .. ":")
        autoScanFrequencyMeasure:SetCallbacks(callbacks.autoScanFrequencyMeasure)
        autoScanGroup:AddChild(autoScanFrequencyMeasure)

        local autoScanFrequencyUnit = autoScanGroup:Acquire("GuildBankSnapshotsDropdownFrame")
        autoScanFrequencyUnit:SetWidth(100)
        autoScanFrequencyUnit:SetInfo(info.autoScanFrequencyUnit)
        autoScanFrequencyUnit:SetCallbacks(callbacks.autoScanFrequencyUnit)
        SettingsTab.autoScanFrequencyUnit = autoScanFrequencyUnit
        autoScanGroup:AddChild(autoScanFrequencyUnit)

        autoScanGroup:DoLayout()

        -----------------------

        local autoCleanupHeader = group:Acquire("GuildBankSnapshotsFontFrame")
        autoCleanupHeader:SetPoint("TOPLEFT", autoScanGroup, "BOTTOMLEFT", 0, -10)
        autoCleanupHeader:SetUserData("width", "full")
        autoCleanupHeader:SetTextColor(private:GetInterfaceFlairColor():GetRGBA())
        autoCleanupHeader:Justify("LEFT")
        autoCleanupHeader:SetText(L["Auto Cleanup"])
        group:AddChild(autoCleanupHeader)

        local autoCleanupGroup = group:Acquire("GuildBankSnapshotsGroup")
        autoCleanupGroup:SetUserData("width", "full")
        autoCleanupGroup:SetWidth(group:GetWidth()) -- have to explicitly set width or its children won't layout properly
        autoCleanupGroup:SetPadding(10, 10)
        autoCleanupGroup:SetSpacing(5)
        private:AddBackdrop(autoCleanupGroup, { bgColor = "dark" })
        group:AddChild(autoCleanupGroup)

        local autoCleanupCorrupted = autoCleanupGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoCleanupCorrupted:SetText(L["Delete corrupted scans"], true)
        autoCleanupCorrupted:SetCallbacks(callbacks.autoCleanupCorrupted)
        autoCleanupGroup:AddChild(autoCleanupCorrupted)

        local autoCleanupAgeEnabled = autoCleanupGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoCleanupAgeEnabled:SetText(L["Delete old scans"], true)
        autoCleanupAgeEnabled:SetCallbacks(callbacks.autoCleanupAgeEnabled)
        autoCleanupGroup:AddChild(autoCleanupAgeEnabled)

        --.....................
        spacer = autoCleanupGroup:Acquire("GuildBankSnapshotsFontFrame")
        spacer:SetUserData("width", "full")
        spacer:SetHeight(1)
        autoCleanupGroup:AddChild(spacer)
        --.....................

        local autoCleanupAgeMeasure = autoCleanupGroup:Acquire("GuildBankSnapshotsSliderFrame")
        autoCleanupAgeMeasure:SetSize(150, 50)
        autoCleanupAgeMeasure:SetBackdropColor(private.interface.colors.darker)
        autoCleanupAgeMeasure:SetLabel(L["Delete scans older than"] .. ":")
        autoCleanupAgeMeasure:SetMinMaxValues(1, 59, 1, 0)
        autoCleanupAgeMeasure:SetCallbacks(callbacks.autoCleanupAgeMeasure)
        autoCleanupGroup:AddChild(autoCleanupAgeMeasure)

        local autoCleanupAgeUnit = autoCleanupGroup:Acquire("GuildBankSnapshotsDropdownFrame")
        autoCleanupAgeUnit:SetWidth(100)
        autoCleanupAgeUnit:SetInfo(info.autoCleanupAgeUnit)
        autoCleanupAgeUnit:SetCallbacks(callbacks.autoCleanupAgeUnit)
        SettingsTab.autoCleanupAgeUnit = autoCleanupAgeUnit
        autoCleanupGroup:AddChild(autoCleanupAgeUnit)

        --.....................
        spacer = autoCleanupGroup:Acquire("GuildBankSnapshotsFontFrame")
        spacer:SetUserData("width", "full")
        spacer:SetHeight(1)
        autoCleanupGroup:AddChild(spacer)
        --.....................

        local cleanup = autoCleanupGroup:Acquire("GuildBankSnapshotsButton")
        cleanup:SetText(L["Cleanup"])
        cleanup:SetCallbacks(callbacks.cleanup)
        autoCleanupGroup:AddChild(cleanup)

        autoCleanupGroup:DoLayout()

        -----------------------
    elseif groupType == "preferences" then
        local useClassColor = group:Acquire("GuildBankSnapshotsCheckButton")
        useClassColor:SetText(L["Use class color"])
        useClassColor:SetTooltipInitializer(L["Applies your class color to emphasized elements of this frame"])
        useClassColor:SetCallbacks(callbacks.useClassColor)
        group:AddChild(useClassColor)

        --.....................
        spacer = group:Acquire("GuildBankSnapshotsFontFrame")
        spacer:SetUserData("width", "full")
        spacer:SetHeight(1)
        group:AddChild(spacer)
        --.....................

        local dateFormat = group:Acquire("GuildBankSnapshotsEditBoxFrame")
        dateFormat:SetWidth(150)
        dateFormat:SetLabel(L["Date Format"])
        dateFormat:SetLabelFont(nil, private:GetInterfaceFlairColor())
        dateFormat:SetTooltipInitializer(tooltips.dateFormat)
        dateFormat:ForwardCallbacks(forwardCallbacks.dateFormat)
        dateFormat:SetCallbacks(callbacks.dateFormat)
        group:AddChild(dateFormat)

        local guildFormat = group:Acquire("GuildBankSnapshotsEditBoxFrame")
        guildFormat:SetWidth(150)
        guildFormat:SetLabel(L["Guild Format"])
        guildFormat:SetLabelFont(nil, private:GetInterfaceFlairColor())
        guildFormat:SetTooltipInitializer(tooltips.guildFormat)
        guildFormat:ForwardCallbacks(forwardCallbacks.guildFormat)
        guildFormat:SetCallbacks(callbacks.guildFormat)
        group:AddChild(guildFormat)

        local defaultGuild = group:Acquire("GuildBankSnapshotsDropdownFrame")
        defaultGuild:SetWidth(200)
        defaultGuild:SetLabel(L["Default Guild"] .. "*")
        defaultGuild:SetLabelFont(nil, private:GetInterfaceFlairColor())
        defaultGuild:SetTooltipInitializer(L["Will not take effect until after a reload"])
        defaultGuild:SetStyle({ hasClear = true })
        defaultGuild:SetInfo(info.defaultGuild)
        defaultGuild:ForwardCallbacks(forwardCallbacks.defaultGuild)
        defaultGuild:SetCallbacks(callbacks.defaultGuild)
        group:AddChild(defaultGuild)

        local exportDelimiter = group:Acquire("GuildBankSnapshotsDropdownFrame")
        exportDelimiter:SetWidth(150)
        exportDelimiter:SetLabel(L["Export Delimiter"])
        exportDelimiter:SetLabelFont(nil, private:GetInterfaceFlairColor())
        exportDelimiter:SetTooltipInitializer(L["Sets the CSV delimiter used when exporting data"])
        exportDelimiter:SetInfo(info.exportDelimiter)
        exportDelimiter:SetCallbacks(callbacks.exportDelimiter)
        group:AddChild(exportDelimiter)

        local delay = group:Acquire("GuildBankSnapshotsSliderFrame")
        delay:SetSize(150, 50)
        delay:SetMinMaxValues(0, 5, 0.1, 1)
        delay:SetLabel(L["Scan Delay"])
        delay:SetLabelFont(nil, private:GetInterfaceFlairColor())
        delay:SetTooltipInitializer(tooltips.delay)
        delay:SetCallbacks(callbacks.delay)
        group:AddChild(delay)
    elseif groupType == "commands" then
        for cmd, info in pairs(private.db.global.commands) do
            if cmd ~= "gbs" then
                local command = group:Acquire("GuildBankSnapshotsCheckButton")
                command:SetText("/" .. cmd, true)
                command:SetCallbacks(callbacks.command)
                group:AddChild(command)
            end
        end
    end

    group:DoLayout()
    DoLayout()
end

GetUnits = function(measure)
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

function private:LoadSettingsTab(content, guildKey)
    SettingsTab.guild = guildKey

    local container = content:Acquire("GuildBankSnapshotsScrollFrame")
    container:SetAllPoints(content)
    SettingsTab.container = container

    local selectGuild = container.content:Acquire("GuildBankSnapshotsDropdownButton")
    selectGuild:SetPoint("TOPLEFT", 10, 0)
    selectGuild:SetSize(250, 20)
    selectGuild:SetBackdropColor(private.interface.colors.darker)
    selectGuild:SetText(L["Select a guild"])
    selectGuild:SetInfo(info.selectGuild)

    local guildGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    private:AddBackdrop(guildGroup, { bgColor = "darker" })
    guildGroup:SetPoint("TOPLEFT", selectGuild, "BOTTOMLEFT", 0, 0)
    guildGroup:SetPoint("TOPRIGHT", -10, 0)
    guildGroup:SetPadding(10, 10)
    guildGroup:SetSpacing(5)
    SettingsTab.guildGroup = guildGroup

    local preferencesHeader = container.content:Acquire("GuildBankSnapshotsFontFrame")
    preferencesHeader:SetPoint("TOPLEFT", guildGroup, "BOTTOMLEFT", 0, -10)
    preferencesHeader:SetPoint("TOPRIGHT", -10, 0)
    preferencesHeader:SetHeight(20)
    preferencesHeader:SetText(L["Preferences"])
    preferencesHeader:Justify("LEFT")
    preferencesHeader:SetFont(nil, private:GetInterfaceFlairColor())

    local preferencesGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    private:AddBackdrop(preferencesGroup, { bgColor = "darker" })
    preferencesGroup:SetPoint("TOPLEFT", preferencesHeader, "BOTTOMLEFT", 0, 0)
    preferencesGroup:SetPoint("TOPRIGHT", -10, 0)
    preferencesGroup:SetPadding(10, 10)
    preferencesGroup:SetSpacing(5)
    SettingsTab.preferencesGroup = preferencesGroup

    local commandsHeader = container.content:Acquire("GuildBankSnapshotsFontFrame")
    commandsHeader:SetPoint("TOPLEFT", preferencesGroup, "BOTTOMLEFT", 0, -10)
    commandsHeader:SetPoint("TOPRIGHT", -10, 0)
    commandsHeader:SetHeight(20)
    commandsHeader:SetText(L["Commands"])
    commandsHeader:Justify("LEFT")
    commandsHeader:SetFont(nil, private:GetInterfaceFlairColor())

    local commandsGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    private:AddBackdrop(commandsGroup, { bgColor = "darker" })
    commandsGroup:SetPoint("TOPLEFT", commandsHeader, "BOTTOMLEFT", 0, 0)
    commandsGroup:SetPoint("TOPRIGHT", -10, 0)
    commandsGroup:SetPadding(10, 10)
    commandsGroup:SetSpacing(5)
    SettingsTab.commandsGroup = commandsGroup

    local debug = container.content:Acquire("GuildBankSnapshotsCheckButton")
    debug:SetPoint("TOPLEFT", commandsGroup, "BOTTOMLEFT", 0, -10)
    debug:SetText(L["Enable debug messages"], true)
    debug:SetCallbacks(callbacks.debug)

    -- These callbacks need all elements acquired before being initialized
    selectGuild:SetCallbacks(callbacks.selectGuild)
    container:SetCallbacks(callbacks.container)
end
