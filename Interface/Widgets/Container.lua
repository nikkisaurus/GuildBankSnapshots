local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsContainer_OnLoad(frame)
    frame = private:MixinContainer(frame)
end
