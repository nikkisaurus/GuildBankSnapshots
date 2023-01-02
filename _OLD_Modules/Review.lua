local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

StaticPopupDialogs["GBS_CONFIRM_DELETE"] = {
    text = L["Are you sure you want to delete this scan?"],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        private.db.global.guilds[private.selectedGuild].scans[private.selectedScan] = nil
        private.frame:GetUserData("guildGroup"):SetGroup(private.selectedGuild)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3, -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

local tabGroupList = {
    {
        value = "Review",
        text = L["Review"],
    },
    {
        value = "Analyze",
        text = L["Analyze"],
    },
}

local function GetFilters()
    local filter = {
        name = L["Name"],
        type = L["Type"],
        item = L["Item"],
        ilvl = L["Item Level"],
        clear = L["Clear Filter"],
    }
    local sorting = { "name", "type", "item", "ilvl", "clear" }

    return filter, sorting
end

local function GetTab(reviewTabGroup, _, tab)
    local moneyTab = MAX_GUILDBANK_TABS + 1
    private.selectedBankTab = tab
    reviewTabGroup:ReleaseChildren()

    local editbox, scrollFrame
    if private.selectedCopyText then
        editbox = AceGUI:Create("MultiLineEditBox")
        editbox:SetLabel("")
        reviewTabGroup:AddChild(editbox)
    else
        scrollFrame = AceGUI:Create("ScrollFrame")
        scrollFrame:SetLayout("Flow")
        reviewTabGroup:AddChild(scrollFrame)
    end

    local scan = private.db.global.guilds[private.selectedGuild].scans[private.selectedScan]
    local transactions = tab < moneyTab and (scan.tabs[private.selectedBankTab] and scan.tabs[private.selectedBankTab].transactions or {}) or scan.moneyTransactions
    local text = ""
    for _, transaction in
        addon.pairs(transactions, function(a, b)
            if private.db.global.settings.preferences.sorting == "des" then
                return a > b
            else
                return a < b
            end
        end)
    do
        local info = tab < moneyTab and private:GetTransactionInfo(transaction) or private:GetMoneyTransactionInfo(transaction)

        local filtered
        if private.selectedFilterName and private.selectedFilterName ~= info.name then
            filtered = true
        end
        if private.selectedFilterItem and private.selectedFilterItem ~= info.itemLink then
            filtered = true
        end
        if private.selectedFilterType and private.selectedFilterType ~= info.transactionType then
            filtered = true
        end

        if not filtered then
            local label = tab < moneyTab and private:GetTransactionLabel(private.selectedScan, transaction) or private:GetMoneyTransactionLabel(private.selectedScan, transaction)
            if private.selectedCopyText then
                text = text == "" and label or (text .. "\n" .. label)
                editbox:SetText(text)
            else
                local line = AceGUI:Create("GuildBankSnapshotsTransaction")
                line:SetFullWidth(true)
                line:SetText(label)
                scrollFrame:AddChild(line)
            end
        end
    end
end

local function SelectReviewTab(tabGroup)
    if not private.selectedGuild or not private.selectedScan then
        return
    end
    tabGroup:SetLayout("Flow")

    local filterNames = AceGUI:Create("Dropdown")
    filterNames:SetLabel(L["Filter by Name"])
    filterNames:SetList(private:GetFilterNames(private.selectedGuild, private.selectedScan, true))
    tabGroup:AddChild(filterNames)
    filterNames:SetValue(private.selectedFilterName)

    local filterItems = AceGUI:Create("Dropdown")
    filterItems:SetLabel(L["Filter by Item"])
    filterItems:SetList(private:GetFilterItems(private.selectedGuild, private.selectedScan))
    tabGroup:AddChild(filterItems)
    filterItems:SetValue(private.selectedFilterItem)

    local filterTypes = AceGUI:Create("Dropdown")
    filterTypes:SetLabel(L["Filter by Type"])
    filterTypes:SetList(private:GetFilterTypes(private.selectedGuild, private.selectedScan))
    tabGroup:AddChild(filterTypes)
    filterTypes:SetValue(private.selectedFilterType)

    local clearFilters = AceGUI:Create("Button")
    clearFilters:SetText(L["Clear Filters"])
    tabGroup:AddChild(clearFilters)

    local sortLines = AceGUI:Create("Dropdown")
    sortLines:SetLabel(L["Sorting"])
    sortLines:SetList({
        asc = L["Ascending"],
        des = L["Descending"],
    })
    tabGroup:AddChild(sortLines)
    sortLines:SetValue(private.db.global.settings.preferences.sorting)

    local copyText = AceGUI:Create("CheckBox")
    copyText:SetLabel(L["Copy Text"])
    tabGroup:AddChild(copyText)
    copyText:SetValue(private.selectedCopyText)

    local delete = AceGUI:Create("Button")
    delete:SetText(DELETE)
    tabGroup:AddChild(delete)
    delete:SetCallback("OnClick", function()
        StaticPopup_Show("GBS_CONFIRM_DELETE")
    end)

    local tabs, sel = private:GetGuildTabs(private.selectedGuild, private.selectedScan)
    local reviewTabGroup = AceGUI:Create("TabGroup")
    reviewTabGroup:SetLayout("Fill")
    reviewTabGroup:SetFullWidth(true)
    reviewTabGroup:SetFullHeight(true)
    reviewTabGroup:SetTabs(tabs)
    reviewTabGroup:SetCallback("OnGroupSelected", GetTab)
    tabGroup:AddChild(reviewTabGroup)
    reviewTabGroup:SelectTab(private.selectedBankTab or sel)

    filterNames:SetCallback("OnValueChanged", function(self, _, filter)
        private.selectedFilterName = filter ~= "clear" and filter or nil
        if filter == "clear" then
            self:SetText(false)
        end
        GetTab(reviewTabGroup, _, private.selectedBankTab)
    end)

    filterItems:SetCallback("OnValueChanged", function(self, _, filter)
        private.selectedFilterItem = filter ~= "clear" and filter or nil
        if filter == "clear" then
            self:SetText(false)
        end
        GetTab(reviewTabGroup, _, private.selectedBankTab)
    end)

    filterTypes:SetCallback("OnValueChanged", function(self, _, filter)
        private.selectedFilterType = filter ~= "clear" and filter or nil
        if filter == "clear" then
            self:SetText(false)
        end
        GetTab(reviewTabGroup, _, private.selectedBankTab)
    end)

    clearFilters:SetCallback("OnClick", function()
        private.selectedFilterName = nil
        private.selectedFilterItem = nil
        private.selectedFilterType = nil
        filterNames:SetValue(nil)
        filterItems:SetValue(nil)
        filterTypes:SetValue(nil)
        GetTab(reviewTabGroup, _, private.selectedBankTab)
    end)

    sortLines:SetCallback("OnValueChanged", function(_, _, sorting)
        private.db.global.settings.preferences.sorting = sorting

        GetTab(reviewTabGroup, _, private.selectedBankTab)
    end)

    copyText:SetCallback("OnValueChanged", function(_, _, enabled)
        private.selectedCopyText = enabled

        GetTab(reviewTabGroup, _, private.selectedBankTab)
    end)

    tabGroup:DoLayout()
end

local function SelectTab(tabGroup, _, tab)
    private.selectedReviewTab = tab
    tabGroup:ReleaseChildren()

    if tab == "Review" then
        SelectReviewTab(tabGroup)
    elseif tab == "Analyze" then
        private:GetAnalyzeOptions(tabGroup)
    end
end

local function SelectScan(scanGroup, _, scanID)
    private.selectedScan = scanID
    scanGroup:ReleaseChildren()

    if not private.selectedGuild or not scanID then
        return
    end

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetTabs(tabGroupList)
    tabGroup:SetCallback("OnGroupSelected", SelectTab)
    scanGroup:AddChild(tabGroup)
    tabGroup:SelectTab(private.selectedReviewTab or "Review")
    private.frame:SetUserData("reviewTabGroup", tabGroup)
end

local function SelectGuild(guildGroup, _, guildKey)
    private.selectedGuild = guildKey
    private.selectedScan = nil
    private.selectedCharacter = nil
    private.selectedCharTab = nil
    private.selectedItem = nil
    private.selectedItemTab = nil
    guildGroup:ReleaseChildren()

    local scans, sel = private:GetScansTree(guildKey)
    local scanGroup = AceGUI:Create("TreeGroup")
    scanGroup:SetLayout("Fill")
    scanGroup:SetTree(scans or {})
    scanGroup:SetCallback("OnGroupSelected", SelectScan)
    guildGroup:AddChild(scanGroup)
    scanGroup:SelectByPath(private.selectedScan or sel)
    private.frame:SetUserData("scanGroup", scanGroup)
end

function private:GetReviewOptions(content)
    content:SetLayout("Fill")

    local guildGroup = AceGUI:Create("DropdownGroup")
    guildGroup:SetLayout("Fill")
    guildGroup:SetGroupList(private:GetGuildList())
    guildGroup:SetCallback("OnGroupSelected", SelectGuild)
    content:AddChild(guildGroup)
    guildGroup:SetGroup(private.selectedGuild or private.db.global.settings.preferences.defaultGuild)
    private.frame:SetUserData("guildGroup", guildGroup)
end
