local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:GetHelpOptions(content)
    LibStub("AceConfigDialog-3.0"):Open(addonName .. "Help", content)
end

function private:GetHelpOptionsTable()
    local options = {
        type = "group",
        name = "",
        args = {},
    }

    return options
end
