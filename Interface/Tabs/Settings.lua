local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local spacer

--*----------[[ Initialize tab ]]----------*--
local SettingsTab
local DoLayout, DrawGroup, GetUnits, SelectGuild

function private:InitializeSettingsTab()
    SettingsTab = {
        guildKey = private.db.global.preferences.defaultGuild,
    }
end

--*----------[[ Data ]]----------*--

-- --*----------[[ Methods ]]----------*--
DrawGroup = function(groupType, group)
    group:ReleaseChildren()

    local guildKey = SettingsTab.guildKey
    if groupType == "guild" and guildKey then
        local review = group:Acquire("GuildBankSnapshotsCheckButton")
        review:SetText(L["Review after manual scan"], true)
        review:SetTooltipInitializer(L["Shows the review frame after manually scanning the bank"])
        review:SetCallbacks({
            OnClick = {
                function(self)
                    private.db.global.guilds[guildKey].settings.review = self:GetChecked()
                end,
            },
            OnShow = {
                function(self)
                    self:SetCheckedState(private.db.global.guilds[guildKey].settings.review, true)
                end,
                true,
            },
        })

        group:AddChild(review)

        spacer = group:Acquire("GuildBankSnapshotsFontFrame")
        spacer.width = "full"
        spacer:SetHeight(1)

        group:AddChild(spacer)

        local reviewPath = group:Acquire("GuildBankSnapshotsDropdownFrame")
        reviewPath:SetLabel(L["Review Path"])
        reviewPath:SetLabelFont(nil, private:GetInterfaceFlairColor())
        reviewPath:SetInfo(function()
            local info = {}

            for _, tab in addon:pairs({ "Analyze", "Review" }) do
                tinsert(info, {
                    id = strlower(tab),
                    text = L[tab],
                    func = function()
                        private.db.global.guilds[guildKey].settings.reviewPath = strlower(tab)
                    end,
                })
            end

            return info
        end)

        reviewPath:SetCallback("OnShow", function(self)
            self:SelectByID(private.db.global.guilds[guildKey].settings.reviewPath)
        end, true)

        group:AddChild(reviewPath)

        local autoScanHeader = group:Acquire("GuildBankSnapshotsFontFrame")
        autoScanHeader.width = "full"
        autoScanHeader:SetTextColor(private:GetInterfaceFlairColor():GetRGBA())
        autoScanHeader:Justify("LEFT")
        autoScanHeader:SetText(L["Auto Scan"])

        group:AddChild(autoScanHeader)

        local autoScanGroup = group:Acquire("GuildBankSnapshotsGroup")
        autoScanGroup.width = "full"
        autoScanGroup:SetWidth(group:GetWidth()) -- have to explicitly set width or its children won't layout properly
        autoScanGroup:SetPadding(10, 10)
        autoScanGroup:SetSpacing(5)
        private:AddBackdrop(autoScanGroup, { bgColor = "dark" })

        group:AddChild(autoScanGroup)

        local autoScan = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoScan:SetText(L["Enable"], true)
        autoScan:SetCallbacks({
            OnClick = {
                function(self)
                    private.db.global.guilds[guildKey].settings.autoScan.enabled = self:GetChecked()
                end,
            },
            OnShow = {
                function(self)
                    self:SetCheckedState(private.db.global.guilds[guildKey].settings.autoScan.enabled, true)
                end,
                true,
            },
        })

        autoScanGroup:AddChild(autoScan)

        local alert = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        alert:SetText(L["Alert scan progress"], true)
        alert:SetTooltipInitializer(L["Displays a message with the status of auto scans"])
        alert:SetCallbacks({
            OnClick = {
                function(self)
                    private.db.global.guilds[guildKey].settings.autoScan.alert = self:GetChecked()
                end,
            },
            OnShow = {
                function(self)
                    self:SetCheckedState(private.db.global.guilds[guildKey].settings.autoScan.alert, true)
                end,
                true,
            },
        })

        autoScanGroup:AddChild(alert)

        local autoScanReview = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        autoScanReview:SetText(L["Review after auto scan"], true)
        autoScanReview:SetTooltipInitializer(L["Shows the review frame after the bank auto scans"])
        autoScanReview:SetCallbacks({
            OnClick = {
                function(self)
                    private.db.global.guilds[guildKey].settings.autoScan.review = self:GetChecked()
                end,
            },
            OnShow = {
                function(self)
                    self:SetCheckedState(private.db.global.guilds[guildKey].settings.autoScan.review, true)
                end,
                true,
            },
        })

        autoScanGroup:AddChild(autoScanReview)

        local limit = autoScanGroup:Acquire("GuildBankSnapshotsCheckButton")
        limit:SetText(L["Limit auto scans"], true)
        limit:SetTooltipInitializer(L["Limits the number of auto scans allowed to run in a specified time period"])
        limit:SetCallbacks({
            OnClick = {
                function(self)
                    private.db.global.guilds[guildKey].settings.autoScan.frequency.enabled = self:GetChecked()
                end,
            },
            OnShow = {
                function(self)
                    self:SetCheckedState(private.db.global.guilds[guildKey].settings.autoScan.frequency.enabled, true)
                end,
                true,
            },
        })

        autoScanGroup:AddChild(limit)

        spacer = autoScanGroup:Acquire("GuildBankSnapshotsFontFrame")
        spacer.width = "full"
        spacer:SetHeight(1)

        autoScanGroup:AddChild(spacer)

        -- local frequencyMeasure = autoScanGroup:Acquire("GuildBankSnapshotsSliderFrame")
        -- frequencyMeasure:SetSize(150, 50)
        -- frequencyMeasure:SetBackdropColor(private.interface.colors.darker)
        -- frequencyMeasure:SetLabel(L["Allow auto scan every"] .. ":")
        -- frequencyMeasure:SetMinMaxValues(1, 59, 1)
        -- frequencyMeasure:ForwardCallbacks({
        --     -- OnValueChanged = {
        --     --     function(self, value, userInput)
        --     --         if userInput then
        --     --             private.db.global.guilds[guildKey].settings.autoScan.frequency.measure = value
        --     --         end
        --     --         if SettingsTab.frequencyUnit then
        --     --             SettingsTab.frequencyUnit:SelectByID(private.db.global.guilds[guildKey].settings.autoScan.frequency.unit)
        --     --         end
        --     --     end,
        --     -- },
        -- })
        -- frequencyMeasure:SetCallback("OnShow", function(self)
        --     self:SetValue(private.db.global.guilds[guildKey].settings.autoScan.frequency.measure)
        -- end, true)

        -- autoScanGroup:AddChild(frequencyMeasure)

        local frequencyUnit = autoScanGroup:Acquire("GuildBankSnapshotsDropdownFrame")
        frequencyUnit:SetWidth(100)
        frequencyUnit:SetInfo(function()
            local info = {}

            for id, unit in addon:pairs(GetUnits(private.db.global.guilds[guildKey].settings.autoScan.frequency.measure)) do
                tinsert(info, {
                    id = id,
                    text = unit,
                    func = function()
                        private.db.global.guilds[guildKey].settings.autoScan.frequency.unit = id
                    end,
                })
            end

            return info
        end)

        frequencyUnit:SetCallback("OnShow", function(self)
            self:SelectByID(private.db.global.guilds[guildKey].settings.autoScan.frequency.unit)
        end, true)

        SettingsTab.frequencyUnit = frequencyUnit
        autoScanGroup:AddChild(frequencyUnit)

        autoScanGroup:DoLayout()

        local autoCleanupHeader = group:Acquire("GuildBankSnapshotsFontFrame")
        autoCleanupHeader:SetPoint("TOPLEFT", autoScanGroup, "BOTTOMLEFT", 0, -10)
        autoCleanupHeader.width = "full"
        autoCleanupHeader:SetTextColor(private:GetInterfaceFlairColor():GetRGBA())
        autoCleanupHeader:Justify("LEFT")
        autoCleanupHeader:SetText(L["Auto Cleanup"])

        group:AddChild(autoCleanupHeader)

        local autoCleanupGroup = group:Acquire("GuildBankSnapshotsGroup")
        autoCleanupGroup.width = "full"
        autoCleanupGroup:SetWidth(group:GetWidth()) -- have to explicitly set width or its children won't layout properly
        autoCleanupGroup:SetPadding(10, 10)
        autoCleanupGroup:SetSpacing(5)
        private:AddBackdrop(autoCleanupGroup, { bgColor = "dark" })

        group:AddChild(autoCleanupGroup)

        local corrupted = autoCleanupGroup:Acquire("GuildBankSnapshotsCheckButton")
        corrupted:SetText(L["Delete corrupted scans"], true)
        corrupted:SetCallbacks({
            OnClick = {
                function(self)
                    private.db.global.guilds[guildKey].settings.autoCleanup.corrupted = self:GetChecked()
                end,
            },
            OnShow = {
                function(self)
                    self:SetCheckedState(private.db.global.guilds[guildKey].settings.autoCleanup.corrupted, true)
                end,
                true,
            },
        })

        autoCleanupGroup:AddChild(corrupted)

        local ageEnabled = autoCleanupGroup:Acquire("GuildBankSnapshotsCheckButton")
        ageEnabled:SetText(L["Delete old scans"], true)
        ageEnabled:SetCallbacks({
            OnClick = {
                function(self)
                    private.db.global.guilds[guildKey].settings.autoCleanup.age.enabled = self:GetChecked()
                end,
            },
            OnShow = {
                function(self)
                    self:SetCheckedState(private.db.global.guilds[guildKey].settings.autoCleanup.age.enabled, true)
                end,
                true,
            },
        })

        autoCleanupGroup:AddChild(ageEnabled)

        spacer = autoCleanupGroup:Acquire("GuildBankSnapshotsFontFrame")
        spacer.width = "full"
        spacer:SetHeight(1)

        autoCleanupGroup:AddChild(spacer)

        -- local ageMeasure = autoCleanupGroup:Acquire("GuildBankSnapshotsSliderFrame")
        -- ageMeasure:SetSize(150, 50)
        -- ageMeasure:SetBackdropColor(private.interface.colors.darker)
        -- ageMeasure:SetLabel(L["Delete scans older than"] .. ":")
        -- ageMeasure:SetMinMaxValues(1, 59, 1)
        -- ageMeasure:ForwardCallbacks({
        --     -- OnValueChanged = {
        --     --     function(self, value, userInput)
        --     --         if userInput then
        --     --             private.db.global.guilds[guildKey].settings.autoCleanup.age.measure = value
        --     --         end
        --     --         if SettingsTab.ageUnit then
        --     --             SettingsTab.ageUnit:SelectByID(private.db.global.guilds[guildKey].settings.autoCleanup.age.unit)
        --     --         end
        --     --     end,
        --     -- },
        -- })
        -- ageMeasure:SetCallback("OnShow", function(self)
        --     self:SetValue(private.db.global.guilds[guildKey].settings.autoCleanup.age.measure)
        -- end, true)

        -- autoCleanupGroup:AddChild(ageMeasure)

        local ageUnit = autoCleanupGroup:Acquire("GuildBankSnapshotsDropdownFrame")
        ageUnit:SetWidth(100)
        ageUnit:SetInfo(function()
            local info = {}

            for id, unit in addon:pairs(GetUnits(private.db.global.guilds[guildKey].settings.autoCleanup.age.measure)) do
                tinsert(info, {
                    id = id,
                    text = unit,
                    func = function()
                        private.db.global.guilds[guildKey].settings.autoCleanup.age.unit = id
                    end,
                })
            end

            return info
        end)

        ageUnit:SetCallbacks({
            OnShow = {
                function(self)
                    self:SelectByID(private.db.global.guilds[guildKey].settings.autoCleanup.age.unit)
                end,
                true,
            },
        })

        SettingsTab.ageUnit = ageUnit
        autoCleanupGroup:AddChild(ageUnit)

        spacer = autoCleanupGroup:Acquire("GuildBankSnapshotsFontFrame")
        spacer.width = "full"
        spacer:SetHeight(1)

        autoCleanupGroup:AddChild(spacer)

        local cleanup = autoCleanupGroup:Acquire("GuildBankSnapshotsButton")
        cleanup:SetText(L["Cleanup"])
        cleanup:SetCallback("OnClick", function(self)
            private:CleanupDatabase(guildKey)
            addon:Print(L["Cleanup finished."])
        end)

        autoCleanupGroup:AddChild(cleanup)

        autoCleanupGroup:DoLayout()
    elseif groupType == "preferences" then
        local useClassColor = group:Acquire("GuildBankSnapshotsCheckButton")
        useClassColor:SetText(L["Use class color"])
        useClassColor:SetTooltipInitializer(L["Applies your class color to emphasized elements of this frame"])
        useClassColor:SetCallbacks({
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
        })

        group:AddChild(useClassColor)

        spacer = group:Acquire("GuildBankSnapshotsFontFrame")
        spacer.width = "full"
        spacer:SetHeight(1)

        group:AddChild(spacer)

        local dateFormat = group:Acquire("GuildBankSnapshotsEditBoxFrame")
        dateFormat:SetWidth(150)
        dateFormat:SetLabel(L["Date Format"])
        dateFormat:SetLabelFont(nil, private:GetInterfaceFlairColor())
        dateFormat:SetTooltipInitializer(function()
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
        end)
        dateFormat:ForwardCallbacks({
            OnEnterPressed = {
                function(self)
                    private.db.global.preferences.dateFormat = self:GetText()
                end,
            },
        })
        dateFormat:SetCallbacks({
            OnShow = {
                function(self)
                    self:SetText(private.db.global.preferences.dateFormat)
                end,
                true,
            },
        })

        group:AddChild(dateFormat)

        local guildFormat = group:Acquire("GuildBankSnapshotsEditBoxFrame")
        guildFormat:SetWidth(150)
        guildFormat:SetLabel(L["Guild Format"])
        guildFormat:SetLabelFont(nil, private:GetInterfaceFlairColor())
        guildFormat:SetTooltipInitializer(function()
            GameTooltip:AddDoubleLine(L["abbreviated faction"], "%f", 1, 1, 1)
            GameTooltip:AddDoubleLine(L["faction"], "%F", 1, 1, 1)
            GameTooltip:AddDoubleLine(L["guild name"], "%g", 1, 1, 1)
            GameTooltip:AddDoubleLine(L["realm name"], "%r", 1, 1, 1)
        end)
        guildFormat:ForwardCallbacks({
            OnEnterPressed = {
                function(self)
                    private.db.global.preferences.guildFormat = self:GetText()
                    private:LoadFrame("Settings")
                end,
            },
        })
        guildFormat:SetCallbacks({
            OnShow = {
                function(self)
                    self:SetText(private.db.global.preferences.guildFormat)
                end,
                true,
            },
        })

        group:AddChild(guildFormat)

        local defaultGuild = group:Acquire("GuildBankSnapshotsDropdownFrame")
        defaultGuild:SetWidth(200)
        defaultGuild:SetLabel(L["Default Guild"] .. "*")
        defaultGuild:SetLabelFont(nil, private:GetInterfaceFlairColor())
        defaultGuild:SetTooltipInitializer(L["Will not take effect until after a reload"])
        defaultGuild:SetStyle({ hasClear = true })
        defaultGuild:SetInfo(private:GetGuildInfo(function(dropdown, info)
            private.db.global.preferences.defaultGuild = info.id
        end))
        defaultGuild:ForwardCallbacks({
            OnClear = {
                function(self)
                    private.db.global.preferences.defaultGuild = false
                end,
            },
            OnShow = {
                function(self)
                    self:SelectByID(private.db.global.preferences.defaultGuild)
                end,
                true,
            },
        })

        group:AddChild(defaultGuild)

        local exportDelimiter = group:Acquire("GuildBankSnapshotsDropdownFrame")
        exportDelimiter:SetWidth(150)
        exportDelimiter:SetLabel(L["Export Delimiter"])
        exportDelimiter:SetLabelFont(nil, private:GetInterfaceFlairColor())
        exportDelimiter:SetTooltipInitializer(L["Sets the CSV delimiter used when exporting data"])
        exportDelimiter:SetInfo(function()
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
        end)
        exportDelimiter:ForwardCallbacks({
            OnShow = {
                function(self)
                    self:SelectByID(private.db.global.preferences.exportDelimiter)
                end,
                true,
            },
        })

        group:AddChild(exportDelimiter)

        local delay = group:Acquire("GuildBankSnapshotsSliderFrame")
        delay:SetSize(150, 50)
        delay:SetLabel(L["Scan Delay"])
        delay:SetLabelFont(nil, private:GetInterfaceFlairColor())
        delay:SetMinMaxValues(0, 5, 0.1, 1)
        delay:SetTooltipInitializer(function()
            GameTooltip:AddLine(L["Determines the amount of time (in seconds) between querying the guild bank transaction logs and saving the scan"])
            GameTooltip:AddLine(L["Increasing this delay may help reduce corrupt scans"])
        end)
        delay:SetCallbacks({
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
        })

        group:AddChild(delay)
    elseif groupType == "commands" then
        for cmd, info in pairs(private.db.global.commands) do
            if cmd ~= "gbs" then
                local toggle = group:Acquire("GuildBankSnapshotsCheckButton")
                toggle:SetText("/" .. cmd, true)
                toggle:SetCallbacks({
                    OnClick = {
                        function(self)
                            private.db.global.commands[cmd].enabled = self:GetChecked()
                            private:InitializeSlashCommands()
                        end,
                    },
                    OnShow = {
                        function(self)
                            self:SetCheckedState(info.enabled, true)
                        end,
                        true,
                    },
                })

                group:AddChild(toggle)
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

SelectGuild = function(dropdown, info)
    SettingsTab.guildKey = info.id
    DrawGroup("guild", SettingsTab.guildGroup)
end

function private:LoadSettingsTab(content, guildKey)
    local container = content:Acquire("GuildBankSnapshotsScrollFrame")
    container:SetAllPoints(content)
    SettingsTab.container = container

    DoLayout = function()
        container.content:MarkDirty()
        container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
    end

    local selectGuild = container.content:Acquire("GuildBankSnapshotsDropdownButton")
    selectGuild:SetPoint("TOPLEFT", 10, 0)
    selectGuild:SetSize(250, 20)
    selectGuild:SetBackdropColor(private.interface.colors.darker)
    selectGuild:SetText(L["Select a guild"])
    selectGuild:SetInfo(private:GetGuildInfo(SelectGuild))

    local guildGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    guildGroup:SetPoint("TOPLEFT", selectGuild, "BOTTOMLEFT", 0, 0)
    guildGroup:SetPoint("TOPRIGHT", -10, 0)
    guildGroup:SetPadding(10, 10)
    guildGroup:SetSpacing(5)
    private:AddBackdrop(guildGroup, { bgColor = "darker" })
    SettingsTab.guildGroup = guildGroup

    local preferencesHeader = container.content:Acquire("GuildBankSnapshotsFontFrame")
    preferencesHeader:SetPoint("TOPLEFT", guildGroup, "BOTTOMLEFT", 0, -10)
    preferencesHeader:SetPoint("TOPRIGHT", -10, 0)
    preferencesHeader:SetHeight(20)
    preferencesHeader:SetText(L["Preferences"])
    preferencesHeader:Justify("LEFT")
    preferencesHeader:SetFont(nil, private:GetInterfaceFlairColor())

    local preferencesGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    preferencesGroup:SetPoint("TOPLEFT", preferencesHeader, "BOTTOMLEFT", 0, 0)
    preferencesGroup:SetPoint("TOPRIGHT", -10, 0)
    preferencesGroup:SetPadding(10, 10)
    preferencesGroup:SetSpacing(5)
    private:AddBackdrop(preferencesGroup, { bgColor = "darker" })

    local commandsHeader = container.content:Acquire("GuildBankSnapshotsFontFrame")
    commandsHeader:SetPoint("TOPLEFT", preferencesGroup, "BOTTOMLEFT", 0, -10)
    commandsHeader:SetPoint("TOPRIGHT", -10, 0)
    commandsHeader:SetHeight(20)
    commandsHeader:SetText(L["Commands"])
    commandsHeader:Justify("LEFT")
    commandsHeader:SetFont(nil, private:GetInterfaceFlairColor())

    local commandsGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    commandsGroup:SetPoint("TOPLEFT", commandsHeader, "BOTTOMLEFT", 0, 0)
    commandsGroup:SetPoint("TOPRIGHT", -10, 0)
    commandsGroup:SetPadding(10, 10)
    commandsGroup:SetSpacing(5)
    private:AddBackdrop(commandsGroup, { bgColor = "darker" })

    local debug = container.content:Acquire("GuildBankSnapshotsCheckButton")
    debug:SetPoint("TOPLEFT", commandsGroup, "BOTTOMLEFT", 0, -10)
    debug:SetText(L["Enable debug messages"], true)
    debug:SetCallbacks({
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
    })

    -- Callbacks
    selectGuild:SetCallback("OnShow", GenerateClosure(selectGuild.SelectByID, selectGuild, guildKey or SettingsTab.guildKey), true)
    container:SetCallback("OnSizeChanged", function()
        DrawGroup("guild", guildGroup)
        DrawGroup("preferences", preferencesGroup)
        DrawGroup("commands", commandsGroup)
    end, true)
end

-- local children = {
--     guild = {
--         {
--             template = "GuildBankSnapshotsDropdownFrame",
--             onLoad = function(self)
--                 self:SetLabel(L["Review Path"])
--                 self:SetLabelFont(nil, private:GetInterfaceFlairColor())
--                 self:SetInfo(function()
--                     local info = {}

--                     for _, tab in addon:pairs({ "Analyze", "Review" }) do
--                         tinsert(info, {
--                             id = strlower(tab),
--                             text = L[tab],
--                             func = function()
--                                 private.db.global.guilds[SettingsTab.guildKey].settings.reviewPath = strlower(tab)
--                             end,
--                         })
--                     end

--                     return info
--                 end)

--                 self:SetCallback("OnShow", function(self)
--                     self:SelectByID(private.db.global.guilds[SettingsTab.guildKey].settings.reviewPath)
--                 end, true)
--             end,
--         },
--         {
--             template = "GuildBankSnapshotsContainer",
--             onLoad = function(self)
--                 local toggle = self:Acquire("GuildBankSnapshotsCheckButton")
--                 toggle:SetText(L["Review after scan"])
--                 toggle:SetHeight(20)
--                 toggle:SetPoint("BOTTOMLEFT")
--                 toggle:SetPoint("BOTTOMRIGHT")

--                 toggle:SetCallback("OnClick", function(toggle)
--                     private.db.global.guilds[SettingsTab.guildKey].settings.review = toggle:GetChecked()
--                 end)

--                 toggle:SetCallback("OnShow", function(toggle)
--                     toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.review, true)
--                 end, true)
--             end,
--         },
--         -- {
--         --     template = "GuildBankSnapshotsFontFrame",
--         --     onLoad = function(self)
--         --         self.width = "full"
--         --         self:SetText(L["Auto Scan"])
--         --         self:Justify("LEFT")
--         --         self:SetFont(nil, private:GetInterfaceFlairColor())
--         --         return nil, 20
--         --     end,
--         -- },
--         {
--             template = "GuildBankSnapshotsGroup",
--             onLoad = function(self)
--                 self.width = "full"
--                 self:SetWidth(SettingsTab.guildGroup:GetWidth())
--                 self:SetPadding(10, 10)
--                 self:SetSpacing(5)
--                 self.bg, self.border = private:AddBackdrop(self, { bgColor = "dark" })

--                 local header = self:Acquire("GuildBankSnapshotsFontFrame")
--                 header.width = "full"
--                 header:SetHeight(20)
--                 header:SetText(L["Auto Scan"])
--                 header:Justify("LEFT")
--                 header:SetFont(nil, private:GetInterfaceFlairColor())
--                 tinsert(self.children, header)

--                 local enable = self:Acquire("GuildBankSnapshotsCheckButton")
--                 enable:SetText(L["Enable"])
--                 enable:SetSize(enable:GetMinWidth(), 20)
--                 tinsert(self.children, enable)

--                 enable:SetCallback("OnClick", function(toggle)
--                     private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.enabled = toggle:GetChecked()
--                 end)

--                 enable:SetCallback("OnShow", function(toggle)
--                     toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.enabled, true)
--                 end, true)

--                 local alert = self:Acquire("GuildBankSnapshotsCheckButton")
--                 alert:SetText(L["Alert scan progress"])
--                 alert:SetSize(alert:GetMinWidth(), 20)
--                 tinsert(self.children, alert)

--                 alert:SetCallback("OnClick", function(toggle)
--                     private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.alert = toggle:GetChecked()
--                 end)

--                 alert:SetCallback("OnShow", function(toggle)
--                     toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.alert, true)
--                 end, true)

--                 local review = self:Acquire("GuildBankSnapshotsCheckButton")
--                 review:SetText(L["Review after auto scan"])
--                 review:SetSize(review:GetMinWidth(), 20)
--                 tinsert(self.children, review)

--                 review:SetCallback("OnClick", function(toggle)
--                     private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.review = toggle:GetChecked()
--                 end)

--                 review:SetCallback("OnShow", function(toggle)
--                     toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.review, true)
--                 end, true)

--                 local enableFrequency = self:Acquire("GuildBankSnapshotsCheckButton")
--                 enableFrequency:SetText(L["Enable frequency limit"])
--                 enableFrequency:SetSize(enableFrequency:GetMinWidth(), 20)
--                 tinsert(self.children, enableFrequency)

--                 enableFrequency:SetCallback("OnClick", function(toggle)
--                     private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.enabled = toggle:GetChecked()
--                 end)

--                 enableFrequency:SetCallback("OnShow", function(toggle)
--                     toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.enabled, true)
--                 end, true)

--                 local spacer = self:Acquire("GuildBankSnapshotsFontFrame")
--                 spacer.width = "full"
--                 spacer:SetHeight(5)
--                 tinsert(self.children, spacer)

--                 local measure = self:Acquire("GuildBankSnapshotsSliderFrame")
--                 measure:SetBackdropColor(private.interface.colors.darker)
--                 measure:SetSize(150, 50)
--                 measure:SetMinMaxValues(0, 59)
--                 measure:SetLabel(L["Frequency Measure"])
--                 tinsert(self.children, measure)

--                 self:DoLayout()
--                 SettingsTab.guildGroup:DoLayout()
--             end,
--         },
--         -- {
--         --     template = "GuildBankSnapshotsCheckButton",
--         --     onLoad = function(self)
--         --         self:SetText(L["Enable"])

--         --         self:SetCallback("OnClick", function(toggle)
--         --             private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.enabled = toggle:GetChecked()
--         --         end)

--         --         self:SetCallback("OnShow", function(toggle)
--         --             toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.enabled, true)
--         --         end, true)

--         --         return self:GetMinWidth(), 20
--         --     end,
--         -- },
--         -- {
--         --     template = "GuildBankSnapshotsCheckButton",
--         --     onLoad = function(self)
--         --         self:SetText(L["Alert scan progress"])

--         --         self:SetCallback("OnClick", function(toggle)
--         --             private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.alert = toggle:GetChecked()
--         --         end)

--         --         self:SetCallback("OnShow", function(toggle)
--         --             toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.alert, true)
--         --         end, true)

--         --         return self:GetMinWidth(), 20
--         --     end,
--         -- },
--         -- {
--         --     template = "GuildBankSnapshotsCheckButton",
--         --     onLoad = function(self)
--         --         self:SetText(L["Review after auto scan"])

--         --         self:SetCallback("OnClick", function(toggle)
--         --             private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.review = toggle:GetChecked()
--         --         end)

--         --         self:SetCallback("OnShow", function(toggle)
--         --             toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.review, true)
--         --         end, true)

--         --         return self:GetMinWidth(), 20
--         --     end,
--         -- },
--         -- {
--         --     template = "GuildBankSnapshotsCheckButton",
--         --     onLoad = function(self)
--         --         self:SetText(L["Enable frequency limit"])

--         --         self:SetCallback("OnClick", function(toggle)
--         --             private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.enabled = toggle:GetChecked()
--         --         end)

--         --         self:SetCallback("OnShow", function(toggle)
--         --             toggle:SetCheckedState(private.db.global.guilds[SettingsTab.guildKey].settings.autoScan.frequency.enabled, true)
--         --         end, true)

--         --         return self:GetMinWidth(), 20
--         --     end,
--         -- },
--         -- {
--         --     template = "GuildBankSnapshotsFontFrame",
--         --     onLoad = function(self)
--         --         self.width = "full"
--         --         return nil, 10
--         --     end,
--         -- },
--         -- {
--         --     template = "GuildBankSnapshotsDropdownFrame",
--         --     onLoad = function(self)
--         --         self:SetLabel(L["Frequency Unit"])
--         --         self:SetLabelFont(nil, private:GetInterfaceFlairColor())
--         --         self:SetInfo(function()
--         --             local info = {}

--         --             -- for _, tab in addon:pairs({ "Analyze", "Review" }) do
--         --             --     tinsert(info, {
--         --             --         id = strlower(tab),
--         --             --         text = L[tab],
--         --             --         func = function()
--         --             --             -- private.db.global.guilds[SettingsTab.guildKey].settings.reviewPath = strlower(tab)
--         --             --         end,
--         --             --     })
--         --             -- end

--         --             return info
--         --         end)

--         --         self:SetCallback("OnShow", function(self)
--         --             -- self:SelectByID(private.db.global.guilds[SettingsTab.guildKey].settings.reviewPath)
--         --         end, true)
--         --     end,
--         -- },
--     },
-- }

-- local groups = {
--     -- commands = function(group)
--     --     group:ReleaseAll()

--     --     local width, height = 5, 5

--     --     local i = 1
--     --     for command, commandInfo in pairs(private.db.global.commands) do
--     --         local toggle = group:Acquire("GuildBankSnapshotsCheckButton")
--     --         toggle:SetText(command)
--     --         toggle:SetSize(toggle:GetMinWidth(), 20)
--     --         toggle:SetCheckedState(commandInfo.enabled, true)

--     --         toggle:SetCallback("OnClick", function(self)
--     --             private.db.global.commands[command].enabled = self:GetChecked()
--     --             private:InitializeSlashCommands()
--     --         end)

--     --         local toggleWidth = toggle:GetWidth()
--     --         local toggleHeight = toggle:GetHeight()

--     --         if (width + toggleWidth + ((i - 1) * 2)) > (group:GetWidth() - 10) then
--     --             width = 0
--     --             height = height + toggleHeight
--     --         end

--     --         toggle:SetPoint("TOPLEFT", width, -height)
--     --         width = width + toggleWidth

--     --         i = i + 1
--     --     end
--     -- end,
--     -- preferences = function(group)
--     --     group:ReleaseAll()

--     --     local settings = private.db.global.preferences
--     --     local width, height = 5, 5

--     --     local dateFormatContainer = group:Acquire("GuildBankSnapshotsContainer")
--     --     dateFormatContainer:SetPoint("TOPLEFT", 5, -5)

--     --     local dateFormatLabel = dateFormatContainer:Acquire("GuildBankSnapshotsFontFrame")
--     --     dateFormatLabel:SetText(L["Date Format"])
--     --     dateFormatLabel:SetSize(dateFormatLabel:GetStringWidth(), 20)
--     --     dateFormatLabel:SetPoint("LEFT", 0, 0)
--     --     dateFormatLabel:Justify("LEFT")

--     --     local dateFormat = dateFormatContainer:Acquire("GuildBankSnapshotsEditBox")
--     --     dateFormat:SetLabel(L["Date Format"])
--     --     dateFormat:SetSize(200, 20)
--     --     dateFormat:SetText(settings.dateFormat)
--     --     dateFormat:SetPoint("LEFT", dateFormatLabel, "RIGHT")

--     --     dateFormat:SetCallback("OnEnterPressed", function(self) end)

--     --     dateFormatContainer:SetSize(dateFormatLabel:GetWidth() + dateFormat:GetWidth(), 20)

--     --     -- width = width + dateFormatLabel:GetWidth()
--     --     -- local dateFormatWidth = dateFormat:GetWidth()
--     --     -- local dateFormatHeight = dateFormat:GetHeight()

--     --     -- if (width + dateFormatWidth + 5) > (group:GetWidth()) then
--     --     --     width = 0
--     --     --     height = height + dateFormatHeight
--     --     -- end

--     --     -- dateFormat:SetPoint("TOPLEFT", width, -height)
--     --     -- width = width + dateFormatWidth
--     -- end,
--     guild = function(group)
--         group:ReleaseChildren()

--         if not SettingsTab.guildKey then
--             return
--         end

--         for _, child in pairs(children.guild) do
--             local object = group:Acquire(child.template)
--             local width, height = child.onLoad(object)
--             object:SetSize(width or 150, height or 40)
--             tinsert(group.children, object)
--         end

--         group:MarkDirty()
--         group:DoLayout()
--     end,
-- -- }

-- GetUnits = function(measure)
--     if measure == 1 then
--         return {
--             minutes = L["minute"],
--             hours = L["hour"],
--             days = L["day"],
--             weeks = L["week"],
--             months = L["month"],
--         }
--     else
--         return {
--             minutes = L["minutes"],
--             hours = L["hours"],
--             days = L["days"],
--             weeks = L["weeks"],
--             months = L["months"],
--         }
--     end
-- end

-- function private:LoadSettingsTab(content, guildKey)
--     -- local container = content:Acquire("GuildBankSnapshotsScrollFrame")
--     -- container:SetAllPoints(content)
--     -- -- container:SetPoint("TOPLEFT", 10, -10)
--     -- -- container:SetPoint("TOPRIGHT", -10, 10)
--     -- SettingsTab.container = container

--     -- -- container.bg, container.border = private:AddBackdrop(container, { bgColor = "darker" })

--     -- -- local commandsLabel = container.content:Acquire("GuildBankSnapshotsFontFrame")
--     -- -- commandsLabel:SetTextColor(private:GetInterfaceFlairColor():GetRGBA())
--     -- -- commandsLabel:SetHeight(20)
--     -- -- commandsLabel:SetPoint("TOPLEFT", 5, 0)
--     -- -- commandsLabel:SetPoint("TOPRIGHT", -5, 0)
--     -- -- commandsLabel:Justify("LEFT")
--     -- -- commandsLabel:SetText(L["Commands"])

--     -- -- local commandsGroup = container.content:Acquire("GuildBankSnapshotsGroup")
--     -- -- commandsGroup:SetHeight(20)
--     -- -- commandsGroup:SetPoint("TOPLEFT", commandsLabel, "BOTTOMLEFT")
--     -- -- commandsGroup:SetPoint("TOPRIGHT", commandsLabel, "BOTTOMRIGHT")
--     -- -- commandsGroup.bg, commandsGroup.border = private:AddBackdrop(commandsGroup, { bgColor = "darker" })

--     -- -- commandsGroup:SetCallback("OnShow", function()
--     -- --     groups.commands(commandsGroup)
--     -- --     container.content:MarkDirty()
--     -- --     container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
--     -- -- end, true)

--     -- -- commandsGroup:SetCallback("OnSizeChanged", function()
--     -- --     groups.commands(commandsGroup)
--     -- --     container.content:MarkDirty()
--     -- --     container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
--     -- -- end)

--     -- -- local preferencesLabel = container.content:Acquire("GuildBankSnapshotsFontFrame")
--     -- -- preferencesLabel:SetTextColor(private:GetInterfaceFlairColor():GetRGBA())
--     -- -- preferencesLabel:SetHeight(20)
--     -- -- preferencesLabel:SetPoint("TOPLEFT", commandsGroup, "BOTTOMLEFT")
--     -- -- preferencesLabel:SetPoint("TOPRIGHT", commandsGroup, "BOTTOMRIGHT")
--     -- -- preferencesLabel:Justify("LEFT")
--     -- -- preferencesLabel:SetText(L["Preferences"])

--     -- -- local preferencesGroup = container.content:Acquire("GuildBankSnapshotsGroup")
--     -- -- preferencesGroup:SetHeight(20)
--     -- -- preferencesGroup:SetPoint("TOPLEFT", preferencesLabel, "BOTTOMLEFT")
--     -- -- preferencesGroup:SetPoint("TOPRIGHT", preferencesLabel, "BOTTOMRIGHT")
--     -- -- preferencesGroup.bg, preferencesGroup.border = private:AddBackdrop(preferencesGroup, { bgColor = "darker" })

--     -- -- preferencesGroup:SetCallback("OnShow", function()
--     -- --     groups.preferences(preferencesGroup)
--     -- --     container.content:MarkDirty()
--     -- --     container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
--     -- -- end, true)

--     -- -- preferencesGroup:SetCallback("OnSizeChanged", function()
--     -- --     groups.preferences(preferencesGroup)
--     -- --     container.content:MarkDirty()
--     -- --     container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
--     -- -- end)

--     -- -- local guildLabel = container.content:Acquire("GuildBankSnapshotsFontFrame")
--     -- -- guildLabel:SetTextColor(private:GetInterfaceFlairColor():GetRGBA())
--     -- -- guildLabel:SetHeight(20)
--     -- -- guildLabel:SetPoint("TOPLEFT", preferencesGroup, "BOTTOMLEFT")
--     -- -- guildLabel:SetPoint("TOPRIGHT", preferencesGroup, "BOTTOMRIGHT")
--     -- -- guildLabel:Justify("LEFT")
--     -- -- guildLabel:SetText(L["Guild"])

--     -- -- local guildGroup = container.content:Acquire("GuildBankSnapshotsGroup")
--     -- -- guildGroup:SetHeight(20)
--     -- -- guildGroup:SetPoint("TOPLEFT", guildLabel, "BOTTOMLEFT")
--     -- -- guildGroup:SetPoint("TOPRIGHT", guildLabel, "BOTTOMRIGHT")
--     -- -- guildGroup.bg, guildGroup.border = private:AddBackdrop(guildGroup, { bgColor = "darker" })

--     -- -- guildGroup:SetCallback("OnShow", function()
--     -- --     groups.guild(guildGroup)
--     -- --     container.content:MarkDirty()
--     -- --     container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
--     -- -- end, true)

--     -- -- guildGroup:SetCallback("OnSizeChanged", function()
--     -- --     groups.guild(guildGroup)
--     -- --     container.content:MarkDirty()
--     -- --     container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
--     -- -- end)

--     -- -- local enableDebug = container.content:Acquire("GuildBankSnapshotsCheckButton")
--     -- -- enableDebug:SetText(L["Enable debug"])
--     -- -- enableDebug:SetHeight(20)
--     -- -- enableDebug:SetPoint("TOPLEFT", guildGroup, "BOTTOMLEFT", 0, -5)
--     -- -- enableDebug:SetPoint("TOPRIGHT", guildGroup, "BOTTOMRIGHT", 0, -5)

--     -- -- enableDebug:SetCallback("OnClick", function(self)
--     -- --     private.db.global.debug = self:GetChecked()
--     -- -- end)

--     -- -- enableDebug:SetCallback("OnShow", function(self)
--     -- --     enableDebug:SetCheckedState(private.db.global.debug, true)
--     -- -- end)

--     -- -- container.content:MarkDirty()
--     -- -- container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)

--     -- local guildDropdown = container.content:Acquire("GuildBankSnapshotsDropdownButton")
--     -- guildDropdown:SetPoint("TOPLEFT", 10, -10)
--     -- guildDropdown:SetSize(250, 20)
--     -- guildDropdown:SetText(L["Select a guild"])
--     -- guildDropdown:SetBackdropColor(private.interface.colors.darker)
--     -- guildDropdown:SetInfo(function()
--     --     local info = {}

--     --     local sortKeys = function(a, b)
--     --         return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
--     --     end

--     --     for guildKey, guild in addon:pairs(private.db.global.guilds, sortKeys) do
--     --         local text = private:GetGuildDisplayName(guildKey)
--     --         tinsert(info, {
--     --             id = guildKey,
--     --             text = text,
--     --             func = function()
--     --                 SettingsTab.guildKey = guildKey
--     --                 groups.guild(SettingsTab.guildGroup)
--     --             end,
--     --         })
--     --     end

--     --     return info
--     -- end)

--     -- local guildGroup = container.content:Acquire("GuildBankSnapshotsGroup")
--     -- guildGroup:SetPoint("TOPLEFT", guildDropdown, "BOTTOMLEFT", 0, 0)
--     -- guildGroup:SetPoint("RIGHT", -10, 0)
--     -- guildGroup:SetHeight(100)
--     -- guildGroup:SetPadding(10, 10)
--     -- guildGroup:SetSpacing(5)
--     -- guildGroup.bg, guildGroup.border = private:AddBackdrop(guildGroup, { bgColor = "darker" })
--     -- SettingsTab.guildGroup = guildGroup

--     -- guildDropdown:SetCallback("OnShow", function()
--     --     if guildKey then
--     --         guildDropdown:SelectByID(guildKey)
--     --     elseif SettingsTab.guildKey then
--     --         guildDropdown:SelectByID(SettingsTab.guildKey)
--     --     end
--     -- end, true)

--     -- container:SetCallback("OnSizeChanged", function()
--     --     groups.guild(SettingsTab.guildGroup)
--     -- end, true)

--     -- -- container.content:MarkDirty()
--     -- container.scrollBox:FullUpdate(ScrollBoxConstants.UpdateQueued)
-- end
