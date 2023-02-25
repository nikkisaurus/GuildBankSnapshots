local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function GuildBankSnapshotsGroup_OnLoad(group)
    group = private:MixinContainer(group)
    group.scrollable = true
end
