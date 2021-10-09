local addonName = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
LibStub("LibAddonUtils-1.0"):Embed(addon)

L["Analyze"] = true
L["Analyze Scan"] = true
L["Character"] = true
L["Delete Scan"] = true
L["Deposits"] = true
L["Export"] = true
L["Export Scan"] = true
L["Filters"] = true
L["Guild"] = true
L["Help"] = true
L["Item"] = true
L["Master"] = true
L["Money"] = true
L["Money Tab"] = true
L["Net"] = true
L["No changes detected."] = true
L["Repairs"] = true
L["Review"] = true
L["Scan"] = true
L["Scan failed."] = true
L["Scan finished."] = true
L["Scanning"] = true
L["Settings"] = true
L["Summary"] = true
L["Tab"] = true
L["Tabs"] = true
L["Type"] = true
L["Unknown"] = true
L["Withdrawals"] = true

L.addon = "Guild Bank Snapshots"
L.BankClosedError = "Please open your guild bank frame and try again."
L.ConfirmDeleteScan = "Are you sure you want to delete this scan?"
