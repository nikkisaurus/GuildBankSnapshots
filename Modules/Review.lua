local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0", true)

------------------------------------------------------------

local gsub = string.gsub
local pairs, tinsert = pairs, table.insert

local ReviewFrame

--*------------------------------------------------------------------------

local function GetGuildList()
    local list = {}
    local sort = {}

    for guildID, v in pairs(addon.db.global.guilds, function(a, b) return a < b end) do
        list[guildID] = addon:GetGuildDisplayName(guildID)
        tinsert(sort, guildID)
    end

    return list, sort
end

------------------------------------------------------------

local function GetTabList()
    local list = {}
    local sort = {}

    for i = 1, addon.db.global.guilds[ReviewFrame:GetSelected()].numTabs do
        tinsert(list, {text = L["Tab"].." "..i, value = "tab"..i})
        tinsert(sort, i)
    end

    return list, sort
end

--*------------------------------------------------------------------------

local function guildList_OnValueChanged(_, _, selectedGuild)
    ReviewFrame:SetSelectedGuild(selectedGuild)
end

------------------------------------------------------------

local function snapshot_OnClick(self)
    ReviewFrame:SetSelectedSnap(self:GetUserData("snapID"))
end

------------------------------------------------------------

local function tabGroup_OnGroupSelected(self, _, selectedTab)
    ReviewFrame:SetSelectedTab(selectedTab)
end

--*------------------------------------------------------------------------

local methods = {
    ClearSelectedSnap = function(self)
        ReviewFrame:GetUserData("children").reviewPanel:ReleaseChildren()
    end,

    ------------------------------------------------------------

    GetSelected = function(self)
        return self:GetUserData("selectedGuild"), self:GetUserData("selectedSnap"), self:GetUserData("selectedTab")
    end,

    ------------------------------------------------------------

    Load = function(self)
        self:Show()
        local children = self:GetUserData("children")
        local guildList = GetGuildList()
        children.guildList:SetList(guildList)
        children.guildList:SetValue(self:GetUserData("selectedGuild") or addon.db.global.settings.defaultGuild)
        children.guildList:SetDisabled(addon.tcount(guildList) == 0)
    end,

    ------------------------------------------------------------

    LoadSnapshotList = function(self, selectedGuild)
        local snapshotList = self:GetUserData("children").snapshotList
        snapshotList:ReleaseChildren()
        for snapID, _ in addon.pairs(addon.db.global.guilds[selectedGuild].scans, function(a, b) return b < a end) do
            local snapshot = AceGUI:Create("Button")
            snapshot:SetFullWidth(true)
            snapshot:SetText(date(addon.db.global.settings.dateFormat, snapID))
            snapshot:SetUserData("snapID", snapID)
            snapshotList:AddChild(snapshot)

            snapshot:SetCallback("OnClick", snapshot_OnClick)
        end
    end,

    ------------------------------------------------------------

    LoadTransactions = function(self, selectedGuild, selectedSnapshot, selectedTab)
        -- print(selectedGuild, selectedSnapshot, selectedTab)
        local tabPanel = ReviewFrame:GetUserData("children").tabPanel
        -- tabPanel:ReleaseChildren()

        local tabID = tonumber(strmatch(selectedTab, "^tab(%d+)$"))
        for _, transaction in addon.pairs(addon.db.global.guilds[selectedGuild].scans[selectedSnapshot][tabID].transactions, function(a, b) return b < a end) do
            local label = AceGUI:Create("Label")
            label:SetFullWidth(true)
            label:SetText(addon:GetTransactionLine(transaction))
            tabPanel:AddChild(label)

            label.frame:EnableMouse(true)
            label.frame:SetHyperlinksEnabled(true)
            label.frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
            label.frame:SetScript("OnHyperlinkEnter", function(frame)
                GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
                GameTooltip:SetHyperlink(select(4, LibStub("AceSerializer-3.0"):Deserialize(transaction)))
                GameTooltip:Show()
            end)
            label.frame:SetScript("OnHyperlinkLeave", function()
                GameTooltip:ClearLines()
                GameTooltip:Hide()
            end)
        end
    end,

    ------------------------------------------------------------

    SetSelectedGuild = function(self, selectedGuild)
        ReviewFrame:SetUserData("selectedGuild", selectedGuild)
        ReviewFrame:LoadSnapshotList(selectedGuild)
        ReviewFrame:SetTitle("Guild Bank Snapshots"..(selectedGuild and (" - "..addon:GetGuildDisplayName(selectedGuild)) or ""))
        self:ClearSelectedSnap()
    end,

    ------------------------------------------------------------

    SetSelectedSnap = function(self, selectedSnap)
        self:SetUserData("selectedSnap", selectedSnap)
        addon:LoadReviewPanel(selectedSnap)
    end,

    ------------------------------------------------------------

    SetSelectedTab = function(self, selectedTab)
        self:SetUserData("selectedTab", selectedTab)
        self:LoadTransactions(self:GetSelected())
    end,
}

------------------------------------------------------------

function addon:InitializeReviewFrame()
    ReviewFrame = AceGUI:Create("GBS3Frame")
    ReviewFrame:SetTitle("Guild Bank Snapshots")
    ReviewFrame:SetLayout("GBS3TopSidebarGroup")
    ReviewFrame:SetUserData("sidebarDenom", 4)
    ReviewFrame:SetUserData("children", {})
    addon.ReviewFrame = ReviewFrame

    for method, func in pairs(methods) do
        ReviewFrame[method] = func
    end

    local children = ReviewFrame:GetUserData("children")

    ------------------------------------------------------------

    local guildListContainer = AceGUI:Create("GBS3SimpleGroup")
    guildListContainer:SetFullWidth(true)
    guildListContainer:SetLayout("Flow")
    ReviewFrame:AddChild(guildListContainer)

    local guildList = AceGUI:Create("Dropdown")
    guildList:SetFullWidth(true)
    guildListContainer:AddChild(guildList)
    children.guildList = guildList

    guildList:SetCallback("OnValueChanged", guildList_OnValueChanged)

    ------------------------------------------------------------

    local snapshotListContainer = AceGUI:Create("GBS3InlineGroup")
    snapshotListContainer:SetLayout("Fill")
    ReviewFrame:AddChild(snapshotListContainer)

    local snapshotList = AceGUI:Create("ScrollFrame")
    snapshotList:SetLayout("List")
    snapshotListContainer:AddChild(snapshotList)
    children.snapshotList = snapshotList

    ------------------------------------------------------------

    local reviewPanel = AceGUI:Create("GBS3InlineGroup")
    reviewPanel:SetLayout("Flow")
    ReviewFrame:AddChild(reviewPanel)
    children.reviewPanel = reviewPanel
end

--*------------------------------------------------------------------------

function addon:LoadReviewPanel(selectedSnap)
    local reviewPanel = ReviewFrame:GetUserData("children").reviewPanel
    local children = ReviewFrame:GetUserData("children")

    ------------------------------------------------------------

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetFullWidth(true)
    tabGroup:SetFullHeight(true)
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs(GetTabList())
    reviewPanel:AddChild(tabGroup)
    children.tabGroup = tabGroup

    tabGroup:SetCallback("OnGroupSelected", tabGroup_OnGroupSelected)

    ------------------------------------------------------------

    local tabPanel = AceGUI:Create("ScrollFrame")
    tabPanel:SetLayout("List")
    tabGroup:AddChild(tabPanel)
    children.tabPanel = tabPanel
end