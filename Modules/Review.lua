local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")
local AceGUI = LibStub("AceGUI-3.0", true)

------------------------------------------------------------

local gsub, tonumber = string.gsub, tonumber
local pairs, tinsert = pairs, table.insert
local GameTooltip = GameTooltip
local GetCoinTextureString = GetCoinTextureString

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
        tinsert(sort, "tab"..i)
    end

    tinsert(list, {text = L["Money"], value = "moneyTab"})
    tinsert(sort, "moneyTab")

    return list, sort
end

------------------------------------------------------------

local function GetTabName(guildID, tabID)
    if tabID == "moneyTab" then
        return L["Money"]
    elseif guildID and tabID then
        tabID = tonumber((gsub(tabID, "^tab", "")))
        return string.format("%s (%s %d)", addon.db.global.guilds[guildID].tabs[tabID].name, L["Tab"], tabID)
    end
end

--*------------------------------------------------------------------------

local function guildList_OnValueChanged(_, _, selectedGuild)
    ReviewFrame:SetSelectedGuild(selectedGuild)
end

------------------------------------------------------------

local function OnHyperlinkEnter(self, transaction)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(addon:GetTransactionInfo(transaction).itemLink)
    GameTooltip:Show()
end

------------------------------------------------------------

local function GetTransactionOffset(lastTransactions, transactions, debug)
    -- local transaction = lastTransactions[#lastTransactions]

    -- for k, v in pairs(transactions) do
    --     if debug then print(gsub(v, sub, ""), gsub(transaction, sub, "")) end
    --     if gsub(v, sub, "") == gsub(transaction, sub, "")  then
    --         return k + 1
    --     end
    -- end

    local transaction = lastTransactions[#lastTransactions]

    for k, v in pairs(transactions) do
        local currentTime = time()

        local info = addon:GetTransactionInfo(v)
        local transactionDate = addon:GetTransactionDate(currentTime, info.year, info.month, info.day, info.hour)

        local lastInfo = addon:GetTransactionInfo(transaction)
        local lastTransactionDate = addon:GetTransactionDate(currentTime, lastInfo.year, lastInfo.month, lastInfo.day, lastInfo.hour)

        local dateDifference = tonumber(date("%S", lastTransactionDate - transactionDate)) or 0

        local isDiff
        for a, b in pairs(info) do
            if a ~= "year" and a ~= "month" and a ~= "day" and a ~= "hour" then
                if b ~= lastInfo[a] and (a ~= "itemLink" or (GetItemInfoInstant(b) ~= GetItemInfoInstant(lastInfo[a]))) then
                    -- if debug and a == "itemLink" then
                    --     print(b, GetItemInfoInstant(b), GetItemInfoInstant(lastInfo[a]))
                    -- end
                    isDiff = true
                    break
                end
            end
        end

        isDiff = isDiff or dateDifference > 0

        -- if not isDiff then if debug then print(k + 1) end return k + 1 end
    end
end

------------------------------------------------------------

local function TransactionsAreUnique(lastTransactions, transactions)
    local isUnique

    for k, transaction in pairs(transactions) do
        -- Get current time to compare dates to get the most accurate seconds
        local currentTime = time()

        local info = addon:GetTransactionInfo(transaction)
        local transactionDate = addon:GetTransactionDate(currentTime, info.year, info.month, info.day, info.hour)

        local lastInfo = addon:GetTransactionInfo(lastTransactions[k])
        local lastTransactionDate = addon:GetTransactionDate(currentTime, lastInfo.year, lastInfo.month, lastInfo.day, lastInfo.hour)

        local dateDifference = tonumber(date("%S", lastTransactionDate - transactionDate)) or 0

        ------------------------------------------------------------

        for k, v in pairs(info) do
            -- Don't compare time values since we'll check this with dateDifference
            if k ~= "year" and k ~= "month" and k ~= "day" and k ~= "hour" then
                -- If any part of the transaction is different, the transaction is unique
                -- There was an issue with an itemLink that was the same with a different link level causing a duplicate transaction to return unique
                -- Get around is to not compare itemLinks directly and just check item names
                -- It's possible this could cause an issue in the future with items that are the same but have different properties... we'll cross this bridge if and when it gets there
                if v ~= lastInfo[k] and (k ~= "itemLink" or (GetItemInfoInstant(v) ~= GetItemInfoInstant(lastInfo[k]))) then
                    isUnique = true
                    break
                end
            end
        end

        -- If the transaction is the same, double check the dateDifference to see if it's unique
        isUnique = isUnique or dateDifference > 0
    end

    -- if not isUnique then print(lastTransactions, transactions) end

    return isUnique
end

------------------------------------------------------------

local function GetRecentTransactionDate(currentTime, snapTime, transaction)
    local info = addon:GetTransactionInfo(transaction)

    local difference = difftime(currentTime - snapTime)

    local year = floor(difference / addon.secondsInYear)
    difference = difference - (year * addon.secondsInYear)

    local month = floor(difference / addon.secondsInMonth)
    difference = difference - (month * addon.secondsInMonth)

    local day = floor(difference / addon.secondsInDay)
    difference = difference - (day * addon.secondsInDay)

    local hour = floor(difference / addon.secondsInHour)

    -- info.hour = info.hour + hour
    -- info.day = info.day + day
    -- info.month = info.month + month
    -- info.year = info.year + year

    return {year = year, month = month, day = day, hour = hour}
end

------------------------------------------------------------

local function masterTabGroup_OnGroupSelected(self, _, selectedTab)
    ReviewFrame:GetUserData("children").masterTabTitle:SetText(GetTabName(ReviewFrame:GetSelected(), selectedTab))
    ReviewFrame:DoLayout()

    local selectedGuild = ReviewFrame:GetSelected()
    local tabPanel = ReviewFrame:GetUserData("children").masterTabPanel
    tabPanel:ReleaseChildren()

    ------------------------------------------------------------

    local transactions = {}
    local tabID = tonumber(strmatch(selectedTab, "^tab(%d+)$"))
    local currentTime = time()
    local lastSnapID

    for snapID, snapshot in addon.pairs(addon.db.global.guilds[selectedGuild].scans) do
        if not lastSnapID then
            for _, transaction in pairs(snapshot.tabs[tabID].transactions) do
                tinsert(transactions, {transaction, snapID}) --! Fix time
            end
        else
            local lastTransactions, currentTransactions = addon.db.global.guilds[selectedGuild].scans[lastSnapID].tabs[tabID].transactions, snapshot.tabs[tabID].transactions

            if TransactionsAreUnique(lastTransactions, currentTransactions) then
                local offset = GetTransactionOffset(lastTransactions, currentTransactions)

                if snapID == 1607086639 then
                local offset = GetTransactionOffset(lastTransactions, currentTransactions, true)
                end

                if offset then
                    for i = offset, #currentTransactions do
                        -- if snapID == 1607086639 then print("offset", i) end
                        tinsert(transactions, {currentTransactions[i], snapID}) --! Fix time
                    end
                else
                    for _, transaction in pairs(snapshot.tabs[tabID].transactions) do
                        tinsert(transactions, {transaction, snapID}) --! Fix time
                    end
                    -- print(date(addon.db.global.settings.dateFormat, snapID))
                    -- if snapID == 1607086639 then print("all") end
                end
            end
        end

        lastSnapID = snapID
    end

    ------------------------------------------------------------

    for _, transaction in addon.pairs(transactions, function(a, b) return b < a end) do
        local label = AceGUI:Create("Label")
        label:SetFullWidth(true)
        label:SetFontObject(GameFontHighlight)
        label:SetText(addon:GetTransactionLabel(unpack(transaction)))
        tabPanel:AddChild(label)

        -- label.frame:EnableMouse(true)
        -- label.frame:SetHyperlinksEnabled(true)
        -- label.frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
        -- label.frame:SetScript("OnHyperlinkEnter", function(frame) OnHyperlinkEnter(frame, transaction[1]) end)
        -- label.frame:SetScript("OnHyperlinkLeave", Tooltip_OnLeave)
    end

    ------------------------------------------------------------

    -- local transactions, lastSnap = {}
    -- for snapID, snapshot in addon.pairs(addon.db.global.guilds[selectedGuild].scans) do
    --     local tabID = tonumber(strmatch(selectedTab, "^tab(%d+)$"))
    --     local currentTransactions = addon.db.global.guilds[selectedGuild].scans[snapID].tabs[tabID].transactions

    --     if not lastSnap then
    --         for _, transaction in addon.pairs(currentTransactions) do
    --             local currentInfo = addon:GetTransactionInfo(transaction)
    --             -- transactions[transaction] = addon:GetTransactionDate(snapID, currentInfo.year, currentInfo.month, currentInfo.day, currentInfo.hour)
    --             tinsert(transactions, {transaction, addon:GetTransactionDate(snapID, currentInfo.year, currentInfo.month, currentInfo.day, currentInfo.hour)})
    --         end
    --     else
    --         local lastTransactions = addon.db.global.guilds[selectedGuild].scans[lastSnap].tabs[tabID].transactions
    --         local diffSnap
    --         for k, transaction in addon.pairs(currentTransactions) do
    --             local currentTime = time()

    --             local currentInfo = addon:GetTransactionInfo(transaction)
    --             local currentDate = addon:GetTransactionDate(currentTime, currentInfo.year, currentInfo.month, currentInfo.day, currentInfo.hour)

    --             local lastInfo = addon:GetTransactionInfo(lastTransactions[k])
    --             local lastDate = addon:GetTransactionDate(currentTime, lastInfo.year, lastInfo.month, lastInfo.day, lastInfo.hour)

    --             local dateDiff = tonumber(date("%S", currentDate - lastDate))

    --             local diffTrans
    --             for k, v in pairs(currentInfo) do
    --                 if k ~= "year" and k ~= "month" and k ~= "day" and k ~= "hour" then
    --                     if v ~= lastInfo[k] then
    --                         if k ~= "itemLink" or (GetItemInfoInstant(v) ~= GetItemInfoInstant(lastInfo[k])) then
    --                             diffTrans = true
    --                             break
    --                         end
    --                     end
    --                 end
    --             end

    --             diffTrans = diffTrans or dateDiff > 0

    --             if diffTrans then
    --                 diffSnap = true
    --                 break
    --             end
    --         end

    --         if diffSnap then
    --             print(date(addon.db.global.settings.dateFormat, snapID), date(addon.db.global.settings.dateFormat, lastSnap))

    --             local offset
    --             local lastTrans = lastTransactions[1]
    --             for i = 0, #currentTransactions do
    --                 if lastTrans == currentTransactions[i] then
    --                     offset = i
    --                 end
    --             end

    --             if offset then
    --                 print('offset', offset)
    --                 for i = offset - 1, 1, -1 do
    --                     local currentInfo = addon:GetTransactionInfo(currentTransactions[i])
    --                     -- transactions[currentTransactions[i]] = addon:GetTransactionDate(snapID, currentInfo.year, currentInfo.month, currentInfo.day, currentInfo.hour)
    --                     tinsert(transactions, {currentTransactions[i], addon:GetTransactionDate(snapID, currentInfo.year, currentInfo.month, currentInfo.day, currentInfo.hour)})
    --                 end
    --             else
    --                 print("all")
    --                 for _, transaction in addon.pairs(currentTransactions) do
    --                     local currentInfo = addon:GetTransactionInfo(transaction)
    --                     tinsert(transactions, {transaction, addon:GetTransactionDate(snapID, currentInfo.year, currentInfo.month, currentInfo.day, currentInfo.hour)})
    --                 end
    --             end
    --         end
    --     end

    --     lastSnap = snapID
    -- end

    -- for _, transaction in pairs(transactions) do
    --     local label = AceGUI:Create("Label")
    --     label:SetFullWidth(true)
    --     label:SetFontObject(GameFontHighlight)
    --     label:SetText(transaction[2]..addon:GetTransactionLabel(unpack(transaction)))
    --     tabPanel:AddChild(label)

    --     label.frame:EnableMouse(true)
    --     label.frame:SetHyperlinksEnabled(true)
    --     label.frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
    --     label.frame:SetScript("OnHyperlinkEnter", function(frame) OnHyperlinkEnter(frame, transaction[1]) end)
    --     label.frame:SetScript("OnHyperlinkLeave", Tooltip_OnLeave)
    -- end
end

------------------------------------------------------------

local function Tooltip_OnLeave()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

------------------------------------------------------------

local function snapshot_OnClick(self)
    -- print(self:GetUserData("snapID"))
    ReviewFrame:SetSelectedSnap(self:GetUserData("snapID"))
end

------------------------------------------------------------

local function tabGroup_OnGroupSelected(self, _, selectedTab)
    ReviewFrame:GetUserData("children").tabTitle:SetText(GetTabName(ReviewFrame:GetSelected(), selectedTab))
    ReviewFrame:SetSelectedTab(selectedTab)
    ReviewFrame:DoLayout()
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
        children.guildList:SetDisabled(addon.tcount(guildList) == 0)
        local selectedGuild = self:GetUserData("selectedGuild") or addon.db.global.settings.defaultGuild
        if selectedGuild then
            children.guildList:SetValue(selectedGuild)
            self:SetSelectedGuild(selectedGuild)
        end
    end,

    ------------------------------------------------------------

    LoadSnapshotList = function(self, selectedGuild)
        local snapshotList = self:GetUserData("children").snapshotList
        snapshotList:ReleaseChildren()

        local masterSnapshot = AceGUI:Create("Button")
        masterSnapshot:SetFullWidth(true)
        masterSnapshot:SetText(L["Master"])
        snapshotList:AddChild(masterSnapshot)

        masterSnapshot:SetCallback("OnClick", function() addon:LoadMasterSnapshot() end)

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

    LoadTransactions = function(self)
        local selectedGuild, selectedSnapshot, selectedTab = self:GetSelected()
        local tabPanel = ReviewFrame:GetUserData("children").tabPanel
        tabPanel:ReleaseChildren()

        if not selectedTab then return end

        if selectedTab ~= "moneyTab" then
            local tabID = tonumber(strmatch(selectedTab, "^tab(%d+)$"))
            for _, transaction in addon.pairs(addon.db.global.guilds[selectedGuild].scans[selectedSnapshot].tabs[tabID].transactions, function(a, b) return b < a end) do
                local label = AceGUI:Create("Label")
                label:SetFullWidth(true)
                label:SetFontObject(GameFontHighlight)
                label:SetText(addon:GetTransactionLabel(transaction))
                tabPanel:AddChild(label)

                label.frame:EnableMouse(true)
                label.frame:SetHyperlinksEnabled(true)
                label.frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
                label.frame:SetScript("OnHyperlinkEnter", function(frame) OnHyperlinkEnter(frame, transaction) end)
                label.frame:SetScript("OnHyperlinkLeave", Tooltip_OnLeave)
            end
        else
            for _, transaction in addon.pairs(addon.db.global.guilds[selectedGuild].scans[selectedSnapshot].moneyTransactions, function(a, b) return b < a end) do
                local label = AceGUI:Create("Label")
                label:SetFullWidth(true)
                label:SetFontObject(GameFontHighlight)
                label:SetText(addon:GetMoneyTransactionLabel(transaction))
                tabPanel:AddChild(label)
            end
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
        addon:LoadReviewPanel()

        self:GetUserData("children").tabGroup:SelectTab(self:GetUserData("selectedTab") or "tab1")
    end,

    ------------------------------------------------------------

    SetSelectedTab = function(self, selectedTab)
        self:SetUserData("selectedTab", selectedTab)
        self:LoadTransactions()
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

    ------------------------------------------------------------

    if self.db.global.debug.ReviewFrame then
        C_Timer.After(1, function()
            ReviewFrame:Load()
        end)
    end
end

--*------------------------------------------------------------------------

function addon:LoadMasterSnapshot()
    local reviewPanel = ReviewFrame:GetUserData("children").reviewPanel
    local children = ReviewFrame:GetUserData("children")
    local selectedGuild = ReviewFrame:GetSelected()

    reviewPanel:ReleaseChildren()

    ------------------------------------------------------------

    local lastScan
    for k, v in addon.pairs(self.db.global.guilds[selectedGuild].scans, function(a, b) return b < a end) do
        lastScan = v
        break
    end

    ------------------------------------------------------------

    local snapshot = AceGUI:Create("Label")
    snapshot:SetFullWidth(true)
    snapshot:SetColor(1, .82, 0, 1)
    snapshot:SetFontObject(GameFontNormal)
    snapshot:SetText(L["Master"])
    reviewPanel:AddChild(snapshot)

    ------------------------------------------------------------

    local totalMoney = AceGUI:Create("Label")
    totalMoney:SetFullWidth(true)
    totalMoney:SetText(GetCoinTextureString(lastScan.totalMoney))
    reviewPanel:AddChild(totalMoney)

    ------------------------------------------------------------

    local tabTitle = AceGUI:Create("Label")
    tabTitle:SetFullWidth(true)
    reviewPanel:AddChild(tabTitle)
    children.masterTabTitle = tabTitle

    ------------------------------------------------------------

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetFullWidth(true)
    tabGroup:SetFullHeight(true)
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs(GetTabList())
    reviewPanel:AddChild(tabGroup)
    children.masterTabGroup = tabGroup

    tabGroup:SetCallback("OnGroupSelected", masterTabGroup_OnGroupSelected)

    ------------------------------------------------------------

    local tabPanel = AceGUI:Create("ScrollFrame")
    tabPanel:SetLayout("List")
    tabGroup:AddChild(tabPanel)
    children.masterTabPanel = tabPanel

    ------------------------------------------------------------

    tabGroup:SelectTab("tab1")
end

--*------------------------------------------------------------------------

function addon:LoadReviewPanel()
    local reviewPanel = ReviewFrame:GetUserData("children").reviewPanel
    local children = ReviewFrame:GetUserData("children")
    local selectedGuild, selectedSnapshot, selectedTab = ReviewFrame:GetSelected()
    local scan = self.db.global.guilds[selectedGuild].scans[selectedSnapshot]

    reviewPanel:ReleaseChildren()

    ------------------------------------------------------------

    local snapshot = AceGUI:Create("Label")
    snapshot:SetFullWidth(true)
    snapshot:SetColor(1, .82, 0, 1)
    snapshot:SetFontObject(GameFontNormal)
    snapshot:SetText(date(addon.db.global.settings.dateFormat, selectedSnapshot))
    reviewPanel:AddChild(snapshot)
    children.tabTitle = snapshot

    ------------------------------------------------------------

    local totalMoney = AceGUI:Create("Label")
    totalMoney:SetFullWidth(true)
    totalMoney:SetText(GetCoinTextureString(scan.totalMoney))
    reviewPanel:AddChild(totalMoney)

    ------------------------------------------------------------

    local tabTitle = AceGUI:Create("Label")
    tabTitle:SetFullWidth(true)
    tabTitle:SetText(GetTabName(selectedGuild, selectedTab))
    reviewPanel:AddChild(tabTitle)
    children.tabTitle = tabTitle

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

    ------------------------------------------------------------

    ReviewFrame:LoadTransactions()
end