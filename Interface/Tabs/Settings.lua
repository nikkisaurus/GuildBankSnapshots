local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--*----------[[ Initialize tab ]]----------*--
local SettingsTab
local GetUnits

function private:InitializeSettingsTab()
    SettingsTab = {
        guildID = private.db.global.settings.preferences.defaultGuild,
    }
end

--*----------[[ Data ]]----------*--
-- local groups = {
--     commands = function(group)
--         group:ReleaseAll()

--         local width, height = 5, 5

--         local i = 1
--         for command, commandInfo in pairs(private.db.global.commands) do
--             local toggle = group:Acquire("GuildBankSnapshotsCheckButton")
--             toggle:SetText(command)
--             toggle:SetSize(toggle:GetMinWidth(), 20)
--             toggle:SetCheckedState(commandInfo.enabled, true)

--             toggle:SetCallback("OnClick", function(self)
--                 private.db.global.commands[command].enabled = self:GetChecked()
--                 private:InitializeSlashCommands()
--             end)

--             local toggleWidth = toggle:GetWidth()
--             local toggleHeight = toggle:GetHeight()

--             if (width + toggleWidth + ((i - 1) * 2)) > (group:GetWidth() - 10) then
--                 width = 0
--                 height = height + toggleHeight
--             end

--             toggle:SetPoint("TOPLEFT", width, -height)
--             width = width + toggleWidth

--             i = i + 1
--         end
--     end,
--     preferences = function(group)
--         group:ReleaseAll()

--         local settings = private.db.global.settings.preferences
--         local width, height = 5, 5

--         local dateFormatContainer = group:Acquire("GuildBankSnapshotsContainer")
--         dateFormatContainer:SetPoint("TOPLEFT", 5, -5)

--         local dateFormatLabel = dateFormatContainer:Acquire("GuildBankSnapshotsFontFrame")
--         dateFormatLabel:SetText(L["Date Format"])
--         dateFormatLabel:SetSize(dateFormatLabel:GetStringWidth(), 20)
--         dateFormatLabel:SetPoint("LEFT", 0, 0)
--         dateFormatLabel:Justify("LEFT")

--         local dateFormat = dateFormatContainer:Acquire("GuildBankSnapshotsEditBox")
--         dateFormat:SetLabel(L["Date Format"])
--         dateFormat:SetSize(200, 20)
--         dateFormat:SetText(settings.dateFormat)
--         dateFormat:SetPoint("LEFT", dateFormatLabel, "RIGHT")

--         dateFormat:SetCallback("OnEnterPressed", function(self) end)

--         dateFormatContainer:SetSize(dateFormatLabel:GetWidth() + dateFormat:GetWidth(), 20)

--         -- width = width + dateFormatLabel:GetWidth()
--         -- local dateFormatWidth = dateFormat:GetWidth()
--         -- local dateFormatHeight = dateFormat:GetHeight()

--         -- if (width + dateFormatWidth + 5) > (group:GetWidth()) then
--         --     width = 0
--         --     height = height + dateFormatHeight
--         -- end

--         -- dateFormat:SetPoint("TOPLEFT", width, -height)
--         -- width = width + dateFormatWidth
--     end,
--     guild = function(group)
--         group:ReleaseAll()

--         local width, height = 5, 5
--     end,
-- }

--*----------[[ Methods ]]----------*--
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

function private:LoadSettingsTab(content, guildKey) end
