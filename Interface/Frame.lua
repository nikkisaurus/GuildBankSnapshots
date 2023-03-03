local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*----------[[ Data ]]----------*--
local tabs = {
    {
        header = L["Review"],
        onClick = function(content, guildKey)
            private:LoadReviewTab(content, guildKey)
        end,
    },
    {
        header = L["Analyze"],
        onClick = function(content, guildKey)
            private:LoadAnalyzeTab(content, guildKey)
        end,
    },
    {
        header = L["Settings"],
        onClick = function(content, guildKey)
            private:LoadSettingsTab(content, guildKey)
        end,
    },
    {
        header = L["Help"],
        onClick = function(content) end,
    },
}

--*----------[[ Methods ]]----------*--
function private:InitializeFrame()
    local frame = CreateFrame("Frame", "GuildBankSnapshotsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1000, 500)
    frame:SetPoint("CENTER")
    frame:Hide()

    private.bg, private.border = private:AddBackdrop(frame)
    private:SetFrameSizing(frame, 500, 300, GetScreenWidth() - 400, GetScreenHeight() - 200)
    addon:AddSpecialFrame(frame, "GuildBankSnapshotsFrame")
    private.frame = frame

    -- [[ Title bar ]]
    frame.titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.titleBar:SetHeight(20)
    frame.titleBar:SetPoint("TOPLEFT")
    frame.titleBar:SetPoint("RIGHT")
    frame.titleBar.bg, frame.titleBar.border = private:AddBackdrop(frame.titleBar)

    frame.closeButton = CreateFrame("Button", nil, frame.titleBar)
    frame.closeButton:SetSize(22, 22)
    frame.closeButton:SetPoint("RIGHT", -4, 0)
    frame.closeButton:SetText("x")
    frame.closeButton:SetNormalFontObject(GameFontHighlightSmall)
    frame.closeButton:SetHighlightFontObject(GameFontHighlightSmall)
    frame.closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.title = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetText(L.addonName)
    frame.title:SetPoint("TOPLEFT", 4, -2)
    frame.title:SetPoint("BOTTOMRIGHT", -4, 2)
    frame.title:SetTextColor(private.interface.colors[private:UseClassColor() and "class" or "flair"]:GetRGBA())

    -- [[ Tabs ]]
    frame.tabContainer = CreateFrame("Frame", nil, frame, "GuildBankSnapshotsContainer")
    frame.tabContainer:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 10, -10)
    frame.tabContainer:SetPoint("RIGHT", -10, 0)
    frame.tabContainer.children = {}

    -- [[ Content ]]
    frame.content = CreateFrame("Frame", nil, frame, "GuildBankSnapshotsContainer")
    frame.content:SetPoint("TOPLEFT", frame.tabContainer, "BOTTOMLEFT")
    frame.content:SetPoint("RIGHT", frame.tabContainer, "RIGHT")
    frame.content:SetPoint("BOTTOMRIGHT", -10, 10)
    frame.content.bg, frame.content.border = private:AddBackdrop(frame.content, { bgColor = "darkest" })

    function frame:SelectTab(tabID, guildKey)
        self.selectedTab = tabID
        self.content:ReleaseAll()
        tabs[tabID].onClick(self.content, guildKey)
    end

    -- [[ Scripts ]]
    frame:SetScript("OnSizeChanged", function(self)
        self.tabContainer:ReleaseAll()
        private:CloseMenus()

        local width, height = 0, 0

        for tabID, info in addon:pairs(tabs) do
            local tab = self.tabContainer:Acquire("GuildBankSnapshotsTabButton")
            tab:SetTab(tabID, info)
            if tabID == self.selectedTab then
                -- Ensure active tab stays selected when frame size changes, since the tabs are being released and redrawn
                tab:SetSelected(true)
            end
            tab:SetCallback("OnClick", function(...)
                local guildKey = select(#{ ... }, ...)
                guildKey = private.db.global.guilds[guildKey] and guildKey
                self:SelectTab(tabID, guildKey)
            end)

            local tabWidth = tab:GetWidth()
            local tabHeight = tab:GetHeight()

            if (width + tabWidth + ((tabID - 1) * 2)) > self.tabContainer:GetWidth() then
                width = 0
                height = height + tabHeight
            end

            tab:SetPoint("BOTTOMLEFT", width, height)
            width = width + tabWidth

            self.tabContainer:SetHeight(height + tabHeight)
        end
    end, true)

    private:InitializeReviewTab()
    private:InitializeAnalyzeTab()
    private:InitializeSettingsTab()
end

local loaded
function private:LoadFrame(reviewPath, guildKey)
    private.frame:Show()
    if reviewPath then
        loaded = true
        for tab, _ in private.frame.tabContainer:EnumerateActive() do
            if tab:GetText() == reviewPath then
                tab:Fire("OnClick", guildKey)
            end
        end
    elseif not loaded then
        -- Load default tab
        loaded = true
        for tab, _ in private.frame.tabContainer:EnumerateActive() do
            if tab:GetTabID() == 1 then
                tab:Fire("OnClick")
            end
        end
    end
end
