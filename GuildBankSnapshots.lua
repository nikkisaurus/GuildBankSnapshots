local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function addon:OnInitialize()
    private:InitializeDatabase()
    private:InitializeInterface()
    private:InitializeFrame()
    private:InitializeSlashCommands()
end

function addon:OnEnable()
    C_Timer.After(5, function()
        -- private:LoadFrame()
    end)
end

function addon:OnDisable() end

function addon:SlashCommandFunc(input)
    local cmd, arg = strsplit(" ", strlower(input))
    if cmd == "scan" then
        addon:ScanGuildBank(nil, arg == "o")
    else
        private:LoadFrame()
    end
end

function private:InitializeSlashCommands()
    for command, commandInfo in pairs(private.db.global.commands) do
        if commandInfo.enabled then
            addon:RegisterChatCommand(command, commandInfo.func)
        else
            addon:UnregisterChatCommand(command)
        end
    end
end
