local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

-- [[ Frame ]]
--------------
local function InitializeGuildDropdownMenu(menu)
    local sortKeys = function(a, b)
        return private:GetGuildDisplayName(a) < private:GetGuildDisplayName(b)
    end

    for guildID, guild in addon:pairs(private.db.global.guilds, sortKeys) do
        menu:AddLine({
            text = private:GetGuildDisplayName(guildID),
            checked = function()
                return menu.dropdown.selected == guildID
            end,
            isRadio = true,
            func = function()
                menu.dropdown:SetValue(guildID, function(dropdown, guildID)
                    dropdown:SetText(private:GetGuildDisplayName(guildID))
                    -- private:LoadTransactions(guildID)
                end)
            end,
        })
    end
end

local tabs = {
    {
        header = L["Review"],
        onClick = function(content)
            local guildDD = content.frames:Acquire(addonName .. "DropdownButton")
            guildDD:SetPoint("TOPLEFT", 10, -10)
            guildDD:SetSize(200, 20)
            guildDD:SetText(guildDD.selected or L["Select a guild"])
            guildDD.onClick = function()
                if addon:tcount(private.db.global.guilds) > 0 then
                    guildDD:ToggleMenu(function()
                        InitializeGuildDropdownMenu(guildDD.menu)
                    end)
                end
            end
            guildDD:Show()

            local sidebar = content.frames:Acquire(addonName .. "ScrollFrame")
            sidebar:SetPoint("TOPLEFT", guildDD, "BOTTOMLEFT", 0, 0)
            sidebar:SetPoint("RIGHT", guildDD, "RIGHT")
            sidebar:SetPoint("BOTTOM", 0, 10)
            private:AddBackdrop(sidebar, "bgColor")
            sidebar:Show()

            for i = 1, 1000 do
                local test = sidebar.frames:Acquire(addonName .. "FontFrame")
                test:SetHeight(20)
                test:SetPoint("TOPLEFT", 5, -(20 * (i - 1)))
                test:SetPoint("RIGHT", -5, 0)
                test:SetText("Testing cows and stuff and things and stuff " .. i)
                test:SetJustifyH("LEFT")
                test:Show()
            end

            sidebar.content:MarkDirty()

            local headers = content.frames:Acquire(addonName .. "CollectionFrame")
            headers:SetPoint("TOPLEFT", guildDD, "TOPRIGHT", 5, 0)
            headers:SetPoint("RIGHT", -10, 0)
            headers:SetPoint("BOTTOM", guildDD, "BOTTOM")
            private:AddBackdrop(headers, "bgColor")
            headers:Show()

            local main = content.frames:Acquire(addonName .. "ScrollFrame")
            main:SetPoint("TOPLEFT", headers, "BOTTOMLEFT")
            main:SetPoint("BOTTOMRIGHT", -10, 10)
            private:AddBackdrop(main, "bgColor")
            main:Show()
        end,
    },
    {
        header = L["Analyze"],
        onClick = function(content) end,
    },
    {
        header = L["Settings"],
        onClick = function(content) end,
    },
}

local function CreateTabButton()
    local button = CreateFrame("Button", nil, UIParent)
    button:SetHeight(20)

    -- Textures
    button:SetNormalTexture(private:AddBackdropTexture(button, "elementColor"))

    -- Text
    button:SetText("")
    button:SetNormalFontObject(private.defaults.fonts.emphasizedFontLarge)
    button:SetHighlightFontObject(private.defaults.fonts.normalFontLarge)
    button:SetPushedTextOffset(0, 0)

    -- Methods
    function button:SetTab(tabID)
        self.tabID = tabID
        self:UpdateText()
        self:UpdateWidth()
    end

    function button:UpdateText()
        button:SetText("")

        if not self.tabID then
            return
        end

        button:SetText(tabs[self.tabID].header)
    end

    function button:UpdateWidth()
        self:SetWidth(150)

        if not self.tabID then
            return
        end

        self:SetWidth(self:GetTextWidth() + 20)
    end

    -- Scripts
    button:SetScript("OnClick", function(self)
        if not self.tabID then
            return
        end

        private.frame:SelectTab(self.tabID)
    end)

    return button
end

local function ResetTabButton(_, button)
    button:Hide()
end

local TabButton = CreateObjectPool(CreateTabButton, ResetTabButton)

function private:InitializeFrame()
    local frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "BackdropTemplate")
    frame:SetSize(1000, 500)
    frame:SetPoint("CENTER")
    frame:Hide()

    private:AddBackdrop(frame, "bgColor")
    private:SetFrameSizing(frame, 500, 300, GetScreenWidth() - 400, GetScreenHeight() - 200)
    private:AddSpecialFrame(frame)
    private.frame = frame

    -- [[ Title bar ]]
    frame.titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.titleBar:SetHeight(26)
    frame.titleBar:SetPoint("TOPLEFT")
    frame.titleBar:SetPoint("RIGHT")
    private:AddBackdrop(frame.titleBar, "bgColor")

    frame.closeButton = CreateFrame("Button", nil, frame.titleBar)
    frame.closeButton:SetSize(22, 22)
    frame.closeButton:SetPoint("RIGHT", -4, 0)
    frame.closeButton:SetText("x")
    frame.closeButton:SetNormalFontObject(private.defaults.fonts.emphasizedFontLarge)
    frame.closeButton:SetHighlightFontObject(private.defaults.fonts.normalFontLarge)
    frame.closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.title = private:CreateHeader(frame.titleBar, "CENTER")
    frame.title:SetText(L.addonName)
    frame.title:SetPoint("TOPLEFT", 4, -2)
    frame.title:SetPoint("BOTTOMRIGHT", -4, 2)

    -- [[ Tabs ]]
    frame.tabContainer = CreateFrame("Frame", nil, frame)
    frame.tabContainer:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 10, -10)
    frame.tabContainer:SetPoint("RIGHT", -10, 0)
    frame.tabContainer.children = {}

    function frame.tabContainer:AcquireTabButtons()
        for _, child in pairs(frame.tabContainer.children) do
            TabButton:Release(child)
        end

        local width = 0
        local rows = 1
        for tabID, _ in addon:pairs(tabs) do
            local tabButton = TabButton:Acquire()
            tabButton:SetParent(frame.tabContainer)
            tabButton:Show()
            frame.tabContainer.children[tabID] = tabButton

            tabButton:SetTab(tabID)
            tabButton:ClearAllPoints()
            local buttonWidth = tabButton:GetWidth()

            if tabID == 1 then
                tabButton:SetPoint("BOTTOMLEFT")
                width = buttonWidth
            elseif (width + buttonWidth + ((tabID - 1) * 2)) > frame.tabContainer:GetWidth() then
                tabButton:SetPoint("BOTTOM", frame.tabContainer.children[tabID - 1], "TOP", 0, -2)
                tabButton:SetPoint("LEFT")
                width = buttonWidth
                rows = rows + 1
            else
                tabButton:SetPoint("LEFT", frame.tabContainer.children[tabID - 1], "RIGHT", 2, 0)
                width = width + buttonWidth
            end
        end

        frame.tabContainer:SetHeight((20 * rows) + ((rows - 1) * 2))
    end

    -- [[ Content ]]
    frame.content = CreateFrame("Frame", nil, frame, addonName .. "CollectionFrame")
    frame.content:SetPoint("TOPLEFT", frame.tabContainer, "BOTTOMLEFT")
    frame.content:SetPoint("RIGHT", frame.tabContainer, "RIGHT")
    frame.content:SetPoint("BOTTOMRIGHT", -10, 10)
    private:AddBackdrop(frame.content, "insetColor")

    function frame:SelectTab(tabID)
        self.selected = tabID

        frame.content:ReleaseChildren()
        tabs[tabID].onClick(frame.content)
    end

    frame:SelectTab(1)

    -- -- Scripts
    frame:SetScript("OnSizeChanged", function(self)
        self.tabContainer:AcquireTabButtons()
    end)
end

function private:LoadFrame()
    private.frame:Show()
end

-- [[ Data Provider ]]
----------------------
function private:LoadTransactions(guildID)
    local scrollBox = private.frame.scrollBox

    -- Clear transactions if no guildID is provided
    if not guildID then
        scrollBox:Flush()
        return
    end

    local DataProvider = CreateDataProvider()

    for scanID, scan in pairs(private.db.global.guilds[guildID].scans) do
        for tabID, tab in pairs(scan.tabs) do
            for transactionID, transaction in pairs(tab.transactions) do
                local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

                DataProvider:Insert({
                    scanID = scanID,
                    tabID = tabID,
                    transactionID = transactionID,
                    transactionType = transactionType,
                    name = name,
                    itemLink = itemLink,
                    count = count,
                    moveOrigin = moveOrigin,
                    moveDestination = moveDestination,
                    year = year,
                    month = month,
                    day = day,
                    hour = hour,
                })
            end
        end

        for transactionID, transaction in pairs(scan.moneyTransactions) do
            local transactionType, name, amount, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

            DataProvider:Insert({
                scanID = scanID,
                tabID = MAX_GUILDBANK_TABS + 1,
                transactionID = transactionID,
                transactionType = transactionType,
                name = name,
                amount = amount,
                year = year,
                month = month,
                day = day,
                hour = hour,
            })
        end
    end

    DataProvider:SetSortComparator(function(a, b)
        for i = 1, addon:tcount(private.db.global.settings.preferences.sortHeaders) do
            local id = private.db.global.settings.preferences.sortHeaders[i]
            local sortValue = cols[id].sortValue
            local des = private.db.global.settings.preferences.descendingHeaders[id]

            local sortA = sortValue(a)
            local sortB = sortValue(b)

            if type(sortA) ~= type(sortB) then
                sortA = tostring(sortA)
                sortB = tostring(sortB)
            end

            if sortA > sortB then
                if des then
                    return true
                else
                    return false
                end
            elseif sortA < sortB then
                if des then
                    return false
                else
                    return true
                end
            end
        end
    end)

    scrollBox:SetDataProvider(DataProvider)
end
