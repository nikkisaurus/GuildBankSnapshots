local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--*----------[[ Initialize tab ]]----------*--
local SettingsTab
local DoLayout, DrawGroup, SelectGuild

function private:InitializeSettingsTab()
    SettingsTab = {
        guildKey = private.db.global.preferences.defaultGuild,
    }
end

--*----------[[ Data ]]----------*--

-- --*----------[[ Methods ]]----------*--
DrawGroup = function(groupType, group)
    group:ReleaseChildren()

    if groupType == "guild" then
    elseif groupType == "preferences" then
    elseif groupType == "commands" then
        for cmd, info in pairs(private.db.global.commands) do
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

            tinsert(group.children, toggle)
        end
    end

    group:DoLayout()
    DoLayout()
end

SelectGuild = function(dropdown, info)
    SettingsTab.guildKey = info.id
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
    selectGuild:SetPoint("TOPLEFT", 10, -10)
    selectGuild:SetSize(250, 20)
    selectGuild:SetBackdropColor(private.interface.colors.darker)
    selectGuild:SetText(L["Select a guild"])
    selectGuild:SetInfo(private:GetGuildInfo(SelectGuild))

    local guildGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    guildGroup:SetPoint("TOPLEFT", selectGuild, "BOTTOMLEFT", 0, 0)
    guildGroup:SetPoint("RIGHT", -10, 0)
    guildGroup:SetHeight(100)
    guildGroup:SetPadding(10, 10)
    guildGroup:SetSpacing(5)
    private:AddBackdrop(guildGroup, { bgColor = "darker" })

    local preferencesHeader = container.content:Acquire("GuildBankSnapshotsFontFrame")
    preferencesHeader:SetPoint("TOPLEFT", guildGroup, "BOTTOMLEFT", 0, -10)
    preferencesHeader:SetPoint("RIGHT", -10, 0)
    preferencesHeader:SetHeight(20)
    preferencesHeader:SetText(L["Preferences"])
    preferencesHeader:Justify("LEFT")
    preferencesHeader:SetFont(nil, private.interface.colors[private:UseClassColor() and "class" or "flair"])

    local preferencesGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    preferencesGroup:SetPoint("TOPLEFT", preferencesHeader, "BOTTOMLEFT", 0, 0)
    preferencesGroup:SetPoint("RIGHT", -10, 0)
    preferencesGroup:SetHeight(100)
    preferencesGroup:SetPadding(10, 10)
    preferencesGroup:SetSpacing(5)
    private:AddBackdrop(preferencesGroup, { bgColor = "darker" })

    local commandsHeader = container.content:Acquire("GuildBankSnapshotsFontFrame")
    commandsHeader:SetPoint("TOPLEFT", preferencesGroup, "BOTTOMLEFT", 0, -10)
    commandsHeader:SetPoint("RIGHT", -10, 0)
    commandsHeader:SetHeight(20)
    commandsHeader:SetText(L["Commands"])
    commandsHeader:Justify("LEFT")
    commandsHeader:SetFont(nil, private.interface.colors[private:UseClassColor() and "class" or "flair"])

    local commandsGroup = container.content:Acquire("GuildBankSnapshotsGroup")
    commandsGroup:SetPoint("TOPLEFT", commandsHeader, "BOTTOMLEFT", 0, 0)
    commandsGroup:SetPoint("RIGHT", -10, 0)
    commandsGroup:SetHeight(100)
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
    guildGroup:SetCallback("OnShow", GenerateClosure(DrawGroup, "guild", guildGroup), true)
    preferencesGroup:SetCallback("OnShow", GenerateClosure(DrawGroup, "preferences", preferencesGroup), true)
    commandsGroup:SetCallback("OnShow", GenerateClosure(DrawGroup, "commands", commandsGroup), true)

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
--                 self:SetLabelFont(nil, private.interface.colors[private:UseClassColor() and "class" or "flair"])
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
--         --         self:SetFont(nil, private.interface.colors[private:UseClassColor() and "class" or "flair"])
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
--                 header:SetFont(nil, private.interface.colors[private:UseClassColor() and "class" or "flair"])
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
--         --         self:SetLabelFont(nil, private.interface.colors[private:UseClassColor() and "class" or "flair"])
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
--     -- -- commandsLabel:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
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
--     -- -- preferencesLabel:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
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
--     -- -- guildLabel:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())
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
