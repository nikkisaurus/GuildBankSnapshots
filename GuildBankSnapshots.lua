local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
LibStub("LibAddonUtils-2.0"):Embed(addon)

local function InitializeSlashCommands()
    for command, commandInfo in pairs(private.db.global.commands) do
        if commandInfo.enabled then
            addon:RegisterChatCommand(command, commandInfo.func)
        else
            addon:UnregisterChatCommand(command)
        end
    end
end

function addon:OnDisable() end

function addon:OnEnable()
    C_Timer.After(1, function()
        private:LoadFrame()
    end)
end

function addon:OnInitialize()
    private:InitializeDatabase()
    InitializeSlashCommands()
    private:InitializeInterface()
    private:InitializeFrame()
end

function addon:SlashCommandFunc(input)
    local cmd, arg = strsplit(" ", strlower(input))
    if strlower(cmd) == "scan" then
        addon:ScanGuildBank(nil, arg == "o")
    else
        private:LoadFrame()
    end
end
