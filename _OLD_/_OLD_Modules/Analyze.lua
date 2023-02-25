local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

local function moneyTabGroupList(moneyInfo)
    return {
        {
            value = "summary",
            text = L["Summary"],
        },
        {
            value = "deposit",
            text = L["Deposits"],
            disabled = addon:tcount(moneyInfo.deposit) == 0,
        },
        {
            value = "withdraw",
            text = L["Withdrawals"],
            disabled = addon:tcount(moneyInfo.withdraw) == 0,
        },
        {
            value = "repair",
            text = L["Repairs"],
            disabled = addon:tcount(moneyInfo.repair) == 0,
        },
    }
end

local function itemTabGroupList(itemInfo)
    return {
        {
            value = "deposit",
            text = L["Deposits"],
            disabled = addon:tcount(itemInfo.deposit) == 0,
        },
        {
            value = "withdraw",
            text = L["Withdrawals"],
            disabled = addon:tcount(itemInfo.withdraw) == 0,
        },
    }
end

local function charTabGroupList(charInfo)
    return {
        {
            value = "summary",
            text = L["Summary"],
        },
        {
            value = "deposit",
            text = L["Deposits"],
            disabled = addon:tcount(charInfo.deposit) == 0,
        },
        {
            value = "withdraw",
            text = L["Withdrawals"],
            disabled = addon:tcount(charInfo.withdraw) == 0,
        },
    }
end

local tabGroupList = {
    {
        value = "Character",
        text = L["Character"],
    },
    {
        value = "Item",
        text = L["Item"],
    },
    {
        value = "Money",
        text = L["Money"],
    },
}

local function SelectMoneyGroupTab(moneyTabGroup, tab, moneyInfo)
    private.selectedMoneyTab = tab
    moneyTabGroup:ReleaseChildren()

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    moneyTabGroup:AddChild(scrollFrame)

    if tab == "summary" then
        local money = AceGUI:Create("InlineGroup")
        money:SetLayout("Flow")
        money:SetFullWidth(true)
        money:SetTitle(L["Money"])
        scrollFrame:AddChild(money)

        local totalMoney = AceGUI:Create("Label")
        totalMoney:SetFullWidth(true)
        totalMoney:SetText(format("%s: %s|r", L["Total Money"], GetCoinTextureString(math.abs(moneyInfo.totalMoney))))
        money:AddChild(totalMoney)

        local deposits = 0
        for _, count in pairs(moneyInfo.deposit) do
            deposits = deposits + count
        end
        for _, count in pairs(moneyInfo.buyTab) do
            deposits = deposits + count
        end
        local moneyDeposits = AceGUI:Create("Label")
        moneyDeposits:SetFullWidth(true)
        moneyDeposits:SetText(format("%s: %s", L["Deposits"], GetCoinTextureString(deposits)))
        money:AddChild(moneyDeposits)

        local withdrawals = 0
        for _, count in pairs(moneyInfo.withdraw) do
            withdrawals = withdrawals + count
        end
        local moneyWithdrawals = AceGUI:Create("Label")
        moneyWithdrawals:SetFullWidth(true)
        moneyWithdrawals:SetText(format("%s: %s", L["Withdrawals"], GetCoinTextureString(withdrawals)))
        money:AddChild(moneyWithdrawals)

        local repairs = 0
        for _, count in pairs(moneyInfo.repair) do
            repairs = repairs + count
        end
        local moneyRepairs = AceGUI:Create("Label")
        moneyRepairs:SetFullWidth(true)
        moneyRepairs:SetText(format("%s: %s", L["Repairs"], GetCoinTextureString(repairs)))
        money:AddChild(moneyRepairs)

        local netCount = deposits - withdrawals - repairs
        local red = LibStub("LibAddonUtils-1.0").ChatColors["RED"]
        local white = LibStub("LibAddonUtils-1.0").ChatColors["WHITE"]

        local netMoney = AceGUI:Create("Label")
        netMoney:SetFullWidth(true)
        netMoney:SetText(format("%s: %s%s|r", L["Net"], netCount < 0 and red or white, GetCoinTextureString(math.abs(netCount))))
        money:AddChild(netMoney)
    elseif tab == "deposit" then
        for character, count in addon:pairs(moneyInfo.deposit) do
            local line = AceGUI:Create("GuildBankSnapshotsTransaction")
            line:SetFullWidth(true)
            line:SetText(format("%s: %s", character, GetCoinTextureString(count)))
            scrollFrame:AddChild(line)
        end
    elseif tab == "withdraw" then
        for character, count in addon:pairs(moneyInfo.withdraw) do
            local line = AceGUI:Create("GuildBankSnapshotsTransaction")
            line:SetFullWidth(true)
            line:SetText(format("%s: %s", character, GetCoinTextureString(count)))
            scrollFrame:AddChild(line)
        end
    elseif tab == "repair" then
        for character, count in addon:pairs(moneyInfo.repair) do
            local line = AceGUI:Create("GuildBankSnapshotsTransaction")
            line:SetFullWidth(true)
            line:SetText(format("%s: %s", character, GetCoinTextureString(count)))
            scrollFrame:AddChild(line)
        end
    end
end

local function SelectMoneyTab(tabGroup)
    local guild = private.db.global.guilds[private.selectedGuild]
    local scan = guild.scans[private.selectedScan]

    local moneyInfo = {
        totalMoney = scan.totalMoney,
        buyTab = {},
        repair = {},
        deposit = {},
        withdraw = {},
    }

    for _, transaction in pairs(scan.moneyTransactions) do
        local transactionInfo = private:GetMoneyTransactionInfo(transaction)
        transactionInfo.name = transactionInfo.name or L["Unknown"]

        if moneyInfo[transactionInfo.transactionType] then
            moneyInfo[transactionInfo.transactionType][transactionInfo.name] = transactionInfo.amount + (moneyInfo[transactionInfo.transactionType][transactionInfo.name] or 0)
        end
    end

    local moneyTabGroup = AceGUI:Create("TabGroup")
    moneyTabGroup:SetLayout("Flow")
    moneyTabGroup:SetTabs(moneyTabGroupList(moneyInfo))
    moneyTabGroup:SetCallback("OnGroupSelected", function(moneyTabGroup, _, tab)
        SelectMoneyGroupTab(moneyTabGroup, tab, moneyInfo)
    end)
    tabGroup:AddChild(moneyTabGroup)
    moneyTabGroup:SelectTab(private.selectedMoneyTab or "summary")
end

local function SelectItemGroupTab(itemTabGroup, tab, itemInfo)
    private.selectedItemTab = tab
    itemTabGroup:ReleaseChildren()

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    itemTabGroup:AddChild(scrollFrame)

    if tab == "deposit" then
        for character, count in addon:pairs(itemInfo.deposit) do
            local line = AceGUI:Create("GuildBankSnapshotsTransaction")
            line:SetFullWidth(true)
            line:SetText(format("%s x%d", character, count))
            scrollFrame:AddChild(line)
        end
    elseif tab == "withdraw" then
        for character, count in addon:pairs(itemInfo.withdraw) do
            local line = AceGUI:Create("GuildBankSnapshotsTransaction")
            line:SetFullWidth(true)
            line:SetText(format("%s x%d", character, count))
            scrollFrame:AddChild(line)
        end
    end
end

local function SelectItem(itemGroup, _, item)
    private.selectedItem = item
    private.selectedItemTab = nil
    itemGroup:ReleaseChildren()

    if not item then
        return
    end

    local guild = private.db.global.guilds[private.selectedGuild]
    local scan = guild.scans[private.selectedScan]

    local itemInfo = {
        withdraw = {},
        deposit = {},
        move = {},
    }

    for _, tabInfo in pairs(scan.tabs) do
        for _, transaction in pairs(tabInfo.transactions) do
            local transactionInfo = private:GetTransactionInfo(transaction)
            transactionInfo.name = transactionInfo.name or L["Unknown"]

            if transactionInfo.itemLink == item then
                itemInfo[transactionInfo.transactionType][transactionInfo.name] = transactionInfo.count + (itemInfo[transactionInfo.transactionType][transactionInfo.name] or 0)
            end
        end
    end

    local itemTabGroup = AceGUI:Create("TabGroup")
    itemTabGroup:SetLayout("Flow")
    itemTabGroup:SetTabs(itemTabGroupList(itemInfo))
    itemTabGroup:SetCallback("OnGroupSelected", function(charTabGroup, _, tab)
        SelectItemGroupTab(charTabGroup, tab, itemInfo)
    end)
    itemGroup:AddChild(itemTabGroup)
    itemTabGroup:SelectTab(private.selectedItemTab or "deposit")
end

local function SelectItemTab(tabGroup)
    tabGroup:SetLayout("Fill")

    local itemGroup = AceGUI:Create("DropdownGroup")
    itemGroup:SetLayout("Fill")
    itemGroup:SetGroupList(private:GetFilterItems(private.selectedGuild, private.selectedScan))
    itemGroup:SetCallback("OnGroupSelected", SelectItem)
    tabGroup:AddChild(itemGroup)
    itemGroup:SetGroup(private.selectedItem)
end

local function SelectCharacterGroupTab(charTabGroup, tab, charInfo)
    private.selectedCharTab = tab
    charTabGroup:ReleaseChildren()

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    charTabGroup:AddChild(scrollFrame)

    if tab == "summary" then
        -- Items
        local items = AceGUI:Create("InlineGroup")
        items:SetLayout("Flow")
        items:SetFullWidth(true)
        items:SetTitle(L["Items"])
        scrollFrame:AddChild(items)

        -- Get deposits total
        local total = 0
        for _, count in pairs(charInfo.deposit) do
            total = total + count
        end

        local deposits = AceGUI:Create("Label")
        deposits:SetFullWidth(true)
        deposits:SetText(format("%s: %d (%d)", L["Deposits"], addon:tcount(charInfo.deposit), total))
        items:AddChild(deposits)

        -- Get withdrawals total
        total = 0
        for _, count in pairs(charInfo.withdraw) do
            total = total + count
        end

        local withdrawals = AceGUI:Create("Label")
        withdrawals:SetFullWidth(true)
        withdrawals:SetText(format("%s: %d (%d)", L["Withdrawals"], addon:tcount(charInfo.withdraw), total))
        items:AddChild(withdrawals)

        -- Money
        local money = AceGUI:Create("InlineGroup")
        money:SetLayout("Flow")
        money:SetFullWidth(true)
        money:SetTitle(L["Money"])
        scrollFrame:AddChild(money)

        local moneyDeposits = AceGUI:Create("Label")
        moneyDeposits:SetFullWidth(true)
        moneyDeposits:SetText(format("%s: %s", L["Deposits"], GetCoinTextureString(charInfo.money.deposit + charInfo.money.buyTab)))
        money:AddChild(moneyDeposits)

        local moneyWithdrawals = AceGUI:Create("Label")
        moneyWithdrawals:SetFullWidth(true)
        moneyWithdrawals:SetText(format("%s: %s", L["Withdrawals"], GetCoinTextureString(charInfo.money.withdraw)))
        money:AddChild(moneyWithdrawals)

        local repairs = AceGUI:Create("Label")
        repairs:SetFullWidth(true)
        repairs:SetText(format("%s: %s", L["Repairs"], GetCoinTextureString(charInfo.money.repair)))
        money:AddChild(repairs)

        local netCount = charInfo.money.deposit + charInfo.money.buyTab - charInfo.money.withdraw - charInfo.money.repair
        local red = LibStub("LibAddonUtils-1.0").ChatColors["RED"]
        local white = LibStub("LibAddonUtils-1.0").ChatColors["WHITE"]

        local netMoney = AceGUI:Create("Label")
        netMoney:SetFullWidth(true)
        netMoney:SetText(format("%s: %s%s|r", L["Net"], netCount < 0 and red or white, GetCoinTextureString(math.abs(netCount))))
        money:AddChild(netMoney)
    elseif tab == "deposit" then
        for itemLink, count in
            addon:pairs(charInfo.deposit, function(a, b)
                local _, _, itemA = strfind(select(3, strfind(a, "|H(.+)|h")), "%[(.+)%]")
                local _, _, itemB = strfind(select(3, strfind(b, "|H(.+)|h")), "%[(.+)%]")

                return itemA < itemB
            end)
        do
            local line = AceGUI:Create("GuildBankSnapshotsTransaction")
            line:SetFullWidth(true)
            line:SetText(format("%s x%d", itemLink, count))
            scrollFrame:AddChild(line)
        end
    elseif tab == "withdraw" then
        for itemLink, count in
            addon:pairs(charInfo.withdraw, function(a, b)
                local _, _, itemA = strfind(select(3, strfind(a, "|H(.+)|h")), "%[(.+)%]")
                local _, _, itemB = strfind(select(3, strfind(b, "|H(.+)|h")), "%[(.+)%]")

                return itemA < itemB
            end)
        do
            local line = AceGUI:Create("GuildBankSnapshotsTransaction")
            line:SetFullWidth(true)
            line:SetText(format("%s x%d", itemLink, count))
            scrollFrame:AddChild(line)
        end
    end
end

local function SelectCharacter(characterGroup, _, character)
    private.selectedCharacter = character
    private.selectedCharTab = nil
    characterGroup:ReleaseChildren()

    if not character then
        return
    end

    local guild = private.db.global.guilds[private.selectedGuild]
    local scan = guild.scans[private.selectedScan]

    local charInfo = {
        withdraw = {},
        deposit = {},
        move = {},
        money = {
            buyTab = 0,
            repair = 0,
            deposit = 0,
            withdraw = 0,
        },
    }

    for _, tabInfo in pairs(scan.tabs) do
        for _, transaction in pairs(tabInfo.transactions) do
            local transactionInfo = private:GetTransactionInfo(transaction)
            transactionInfo.name = transactionInfo.name or L["Unknown"]

            if transactionInfo.name == character then
                charInfo[transactionInfo.transactionType][transactionInfo.itemLink] = transactionInfo.count + (charInfo[transactionInfo.transactionType][transactionInfo.itemLink] or 0)
            end
        end
    end

    for _, transaction in pairs(scan.moneyTransactions) do
        local transactionInfo = private:GetMoneyTransactionInfo(transaction)
        transactionInfo.name = transactionInfo.name or L["Unknown"]

        if transactionInfo.name == character then
            charInfo.money[transactionInfo.transactionType] = (charInfo.money[transactionInfo.transactionType] or 0) + transactionInfo.amount
        end
    end

    local charTabGroup = AceGUI:Create("TabGroup")
    charTabGroup:SetLayout("Flow")
    charTabGroup:SetTabs(charTabGroupList(charInfo))
    charTabGroup:SetCallback("OnGroupSelected", function(charTabGroup, _, tab)
        SelectCharacterGroupTab(charTabGroup, tab, charInfo)
    end)
    characterGroup:AddChild(charTabGroup)
    charTabGroup:SelectTab(private.selectedCharTab or "summary")
end

local function SelectCharacterTab(tabGroup)
    tabGroup:SetLayout("Fill")

    local characterGroup = AceGUI:Create("DropdownGroup")
    characterGroup:SetLayout("Fill")
    characterGroup:SetGroupList(private:GetFilterNames(private.selectedGuild, private.selectedScan))
    characterGroup:SetCallback("OnGroupSelected", SelectCharacter)
    tabGroup:AddChild(characterGroup)
    characterGroup:SetGroup(private.selectedCharacter)
end

local function SelectTab(tabGroup, _, tab)
    private.selectedAnalyzeTab = tab
    tabGroup:ReleaseChildren()

    if tab == "Character" then
        SelectCharacterTab(tabGroup)
    elseif tab == "Item" then
        SelectItemTab(tabGroup)
    elseif tab == "Money" then
        SelectMoneyTab(tabGroup)
    end
end

function private:GetAnalyzeOptions(content)
    content:SetLayout("Fill")

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs(tabGroupList)
    tabGroup:SetCallback("OnGroupSelected", SelectTab)
    content:AddChild(tabGroup)
    tabGroup:SelectTab(private.selectedAnalyzeTab or "Character")
end
