local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*------------------------------------------------------------------------

function addon:OnInitialize()
    self:InitializeDatabase()
    -- self:RegisterEvent("GUILDBANKFRAME_CLOSED")
    self:RegisterEvent("GUILDBANKFRAME_OPENED")
end

--*------------------------------------------------------------------------

-- function addon:OnEnable()
-- end

------------------------------------------------------------

-- function addon:OnDisable()
-- end

--*------------------------------------------------------------------------

-- function addon:GUILDBANKFRAME_CLOSED()
-- end

------------------------------------------------------------

function addon:GUILDBANKFRAME_OPENED()
    self:ScanGuildBank()
end