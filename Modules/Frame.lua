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
    {
        value = "Settings",
        text = L["Settings"],
    },
    {
        value = "Help",
        text = L["Help"],
    },
}

function private:InitializeFrame()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle(L.addonName)
    frame:SetLayout("Fill")
    frame:SetWidth(950)
    frame:SetHeight(600)
    frame:Hide()
    private.frame = frame

    local menu = AceGUI:Create("TabGroup")
    menu:SetTabs(menuList)
    menu:SetCallback("OnGroupSelected", function(content, _, group)
        content:ReleaseChildren()
        private["Get" .. group .. "Options"](private, content)
    end)
    frame:AddChild(menu)
    menu:SelectTab("Review")
end

function private:LoadFrame()
    private.frame:Show()
end

function private:GetGuildList()
    local guilds, sorting = {}, {}

    for guildID, guildInfo in addon.pairs(private.db.global.guilds) do
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

function private:GetGuildTabs(guildKey)
    local tabs, sel = {}

    for tab, tabInfo in pairs(private.db.global.guilds[guildKey].tabs) do
        if not sel then
            sel = tab
        end

        tinsert(tabs, {
            value = tab,
            text = tabInfo.name or L["Tab"] .. " " .. tab,
        })
    end

    tinsert(tabs, {
        value = MAX_GUILDBANK_TABS + 1,
        text = L["Money"],
    })

    return tabs, sel
end
