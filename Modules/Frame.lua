local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local menuList = {
    {
        value = "Review",
        text = L["Review"],
    },
    {
        value = "Export",
        text = L["Export"],
    },
    -- {
    --     value = "Trends",
    --     text = L["Trends"],
    -- },
    {
        value = "Settings",
        text = L["Settings"],
    },
    -- {
    --     value = "Help",
    --     text = L["Help"],
    -- },
}

function private:InitializeFrame()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(L.addonName)
    frame:SetLayout("Fill")
    frame:SetWidth(950)
    frame:SetHeight(600)
    frame:Hide()
    _G["GuildBankSnapshotsFrame"] = frame.frame
    tinsert(UISpecialFrames, "GuildBankSnapshotsFrame")
    private.frame = frame

    local menu = AceGUI:Create("TabGroup")
    menu:SetTabs(menuList)
    menu:SetCallback("OnGroupSelected", function(content, _, group)
        content:ReleaseChildren()
        private["Get" .. group .. "Options"](private, content)
    end)
    frame:AddChild(menu)
    menu:SelectTab("Review")
    frame:SetUserData("menu", menu)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName .. "Settings", private:GetSettingsOptionsTable())
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName .. "Help", private:GetHelpOptionsTable())
end

function private:LoadFrame(tab, guild, scanID)
    private.frame:Show()

    if tab then
        private.frame:GetUserData("menu"):SelectTab(tab)
    end

    if guild then
        private.frame:GetUserData("guildGroup"):SetGroupList(private:GetGuildList())
        private.frame:GetUserData("guildGroup"):SetGroup(guild)
    end

    if scanID then
        private.frame:GetUserData("scanGroup"):SelectByPath(scanID)
    end
end

function private:GetGuildList()
    local guilds, sorting = {}, {}

    for guildID, guildInfo in
        addon.pairs(private.db.global.guilds, function(a, b)
            return tostring(a) < tostring(b)
        end)
    do
        if addon.tcount(guildInfo.scans) > 0 then
            guilds[guildID] = private:GetGuildDisplayName(guildID)
            tinsert(sorting, guildID)
        end
    end

    return guilds, sorting
end

function private:GetScansTree(guildKey)
    local scanList, sel = {}

    for scanID, _ in
        addon.pairs(private.db.global.guilds[guildKey].scans, function(a, b)
            return a > b
        end)
    do
        if not sel then
            sel = scanID
        end

        tinsert(scanList, {
            value = scanID,
            text = date(private.db.global.settings.preferences.dateFormat, scanID),
        })
    end

    return scanList, sel
end

function private:GetGuildTabs(guildKey, scanID)
    local tabs, sel = {}

    if not private.db.global.guilds[guildKey].scans[scanID] then
        return
    end

    for tab, tabInfo in pairs(private.db.global.guilds[guildKey].scans[scanID].tabs) do
        if not sel then
            sel = tab
        end

        tinsert(tabs, {
            value = tab,
            text = private.db.global.guilds[guildKey].tabs[tab] and private.db.global.guilds[guildKey].tabs[tab].name or L["Tab"] .. " " .. tab,
        })
    end

    tinsert(tabs, {
        value = MAX_GUILDBANK_TABS + 1,
        text = L["Money"],
    })

    return tabs, sel
end
