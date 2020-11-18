local addonName = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
LibStub("LibAddonUtils-1.0"):Embed(addon)

--*------------------------------------------------------------------------

L["No changes detected."] = true
L["Scan failed."] = true
L["Scan finished."] = true
L["Scanning"] = true
L["Tab"] = true

--*------------------------------------------------------------------------

L.BankClosedError = "Please open your guild bank frame and try again."