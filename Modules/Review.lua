local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local selectedGuild, selectedScan, selectedTab, selectedReviewTab, selectedFilterNames, selectedFilterItems, selectedFilterTypes, selectedCopyText

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
    selectedReviewTab = tab
    reviewTabGroup:ReleaseChildren()

    local editbox, scrollFrame
    if selectedCopyText then
        editbox = AceGUI:Create("MultiLineEditBox")
        editbox:SetLabel("")
        reviewTabGroup:AddChild(editbox)
    else
        scrollFrame = AceGUI:Create("ScrollFrame")
        scrollFrame:SetLayout("Flow")
        reviewTabGroup:AddChild(scrollFrame)
    end

    local scan = private.db.global.guilds[selectedGuild].scans[selectedScan]
    local transactions = tab < moneyTab and scan.tabs[selectedReviewTab].transactions or scan.moneyTransactions
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
        if selectedFilterNames and selectedFilterNames ~= info.name then
            filtered = true
        end
        if selectedFilterItems and selectedFilterItems ~= info.itemLink then
            filtered = true
        end
        if selectedFilterTypes and selectedFilterTypes ~= info.transactionType then
            filtered = true
        end

        if not filtered then
            local label = tab < moneyTab and private:GetTransactionLabel(selectedScan, transaction) or private:GetMoneyTransactionLabel(selectedScan, transaction)
            if selectedCopyText then
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
    local filterNames = AceGUI:Create("Dropdown")
    filterNames:SetLabel(L["Filter by Name"])
    filterNames:SetList(private:GetFilterNames(selectedGuild, selectedScan))
    tabGroup:AddChild(filterNames)

    local filterItems = AceGUI:Create("Dropdown")
    filterItems:SetLabel(L["Filter by Item"])
    filterItems:SetList(private:GetFilterItems(selectedGuild, selectedScan))
    tabGroup:AddChild(filterItems)

    local filterTypes = AceGUI:Create("Dropdown")
    filterTypes:SetLabel(L["Filter by Type"])
    filterTypes:SetList(private:GetFilterTypes(selectedGuild, selectedScan))
    tabGroup:AddChild(filterTypes)

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

    local tabs, sel = private:GetGuildTabs(selectedGuild)
    local reviewTabGroup = AceGUI:Create("TabGroup")
    reviewTabGroup:SetLayout("Fill")
    reviewTabGroup:SetFullWidth(true)
    reviewTabGroup:SetFullHeight(true)
    reviewTabGroup:SetTabs(tabs)
    reviewTabGroup:SetCallback("OnGroupSelected", GetTab)
    tabGroup:AddChild(reviewTabGroup)
    reviewTabGroup:SelectTab(sel)

    filterNames:SetCallback("OnValueChanged", function(self, _, filter)
        selectedFilterNames = filter ~= "clear" and filter or nil
        if filter == "clear" then
            self:SetText(false)
        end
        GetTab(reviewTabGroup, _, selectedReviewTab)
    end)

    filterItems:SetCallback("OnValueChanged", function(self, _, filter)
        selectedFilterItems = filter ~= "clear" and filter or nil
        if filter == "clear" then
            self:SetText(false)
        end
        GetTab(reviewTabGroup, _, selectedReviewTab)
    end)

    filterTypes:SetCallback("OnValueChanged", function(self, _, filter)
        selectedFilterTypes = filter ~= "clear" and filter or nil
        if filter == "clear" then
            self:SetText(false)
        end
        GetTab(reviewTabGroup, _, selectedReviewTab)
    end)

    clearFilters:SetCallback("OnClick", function()
        selectedFilterNames = nil
        selectedFilterItems = nil
        selectedFilterTypes = nil
        filterNames:SetValue(nil)
        filterItems:SetValue(nil)
        filterTypes:SetValue(nil)
        GetTab(reviewTabGroup, _, selectedReviewTab)
    end)

    sortLines:SetCallback("OnValueChanged", function(_, _, sorting)
        private.db.global.settings.preferences.sorting = sorting

        GetTab(reviewTabGroup, _, selectedReviewTab)
    end)

    copyText:SetCallback("OnValueChanged", function(_, _, enabled)
        selectedCopyText = enabled

        GetTab(reviewTabGroup, _, selectedReviewTab)
    end)

    tabGroup:DoLayout()
end

local function SelectTab(tabGroup, _, tab)
    selectedTab = tab
    tabGroup:ReleaseChildren()

    if tab == "Review" then
        SelectReviewTab(tabGroup)
    elseif tab == "Analyze" then
    end
end

local function SelectScan(scanGroup, _, scanID)
    selectedScan = scanID
    scanGroup:ReleaseChildren()

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetTabs(tabGroupList)
    tabGroup:SetCallback("OnGroupSelected", SelectTab)
    scanGroup:AddChild(tabGroup)
    tabGroup:SelectTab("Review")
end

local function SelectGuild(guildGroup, _, guildKey)
    selectedGuild = guildKey
    guildGroup:ReleaseChildren()

    local scans, sel = private:GetScansTree(guildKey)
    local scanGroup = AceGUI:Create("TreeGroup")
    scanGroup:SetLayout("Fill")
    scanGroup:SetTree(scans)
    scanGroup:SetCallback("OnGroupSelected", SelectScan)
    guildGroup:AddChild(scanGroup)
    scanGroup:SelectByPath(sel)
end

function private:GetReviewOptions(content)
    content:SetLayout("Fill")

    local guildKey = selectedGuild or private.db.global.settings.preferences.defaultGuild

    local guildGroup = AceGUI:Create("DropdownGroup")
    guildGroup:SetLayout("Fill")
    guildGroup:SetGroupList(private:GetGuildList())
    guildGroup:SetCallback("OnGroupSelected", SelectGuild)
    content:AddChild(guildGroup)
    guildGroup:SetGroup(guildKey)
end
