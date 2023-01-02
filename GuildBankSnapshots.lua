local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function addon:OnInitialize()
    private:InitializeFrame()
end

function addon:OnEnable()
    -- MOVE TO SLASH COMMAND
    private.frame:Show()
    private:LoadTransactions()
end

function addon:OnDisable() end
