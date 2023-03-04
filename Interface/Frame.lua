local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local callbacks, tabs
local SelectTab
local loaded

--*----------[[ Data ]]----------*--
callbacks = {
    frame = {
        OnSizeChanged = {
            function(self)
                private:CloseMenus(nil, true)
                for name, child in pairs(self:GetUserData("resizeChildren")) do
                    assert(child.DoLayout, "Resize child does not have a DoLayout function")
                    child:DoLayout()
                end
            end,
        },
    },
    title_ = {
        OnDragStart = {
            function(self)
                private.frame:Fire("OnDragStart")
            end,
        },

        OnDragStop = {
            function(self)
                private.frame:Fire("OnDragStop")
            end,
        },
    },
    closeButton = {
        OnClick = {
            function()
                private.frame:Hide()
            end,
        },
    },
    tab = {
        OnClick = {
            function(self)
                SelectTab(self:GetTabID(), self:GetUserData("guildKey"), self:GetUserData("scanID"))
            end,
        },
        OnShow = {
            function(self)
                local tabID = self:GetTabID()
                if tabID == private.frame.selectedTab then
                    self:Fire("OnClick")
                end
            end,
        },
    },
}

------------------------

tabs = {
    {
        header = L["Review"],
        init = function()
            private:InitializeReviewTab()
        end,
        onClick = function(content, guildKey)
            private:LoadReviewTab(content, guildKey)
        end,
    },
    {
        header = L["Analyze"],
        init = function()
            private:InitializeAnalyzeTab()
        end,
        onClick = function(content, guildKey, scanID)
            private:LoadAnalyzeTab(content, guildKey, scanID)
        end,
    },
    {
        header = L["Settings"],
        init = function()
            private:InitializeSettingsTab()
        end,
        onClick = function(content, guildKey)
            private:LoadSettingsTab(content, guildKey)
        end,
    },
    {
        header = L["Help"],
        init = function()
            -- private:InitializeHelpTab() -- TODO
        end,
        onClick = function(content) end,
    },
}

--*----------[[ Methods ]]----------*--
SelectTab = function(tabID, guildKey, scanID)
    private.frame.selectedTab = tabID
    private.frame.content:ReleaseAll()
    tabs[tabID].onClick(private.frame.content, guildKey, scanID)
end

------------------------

function private:InitializeFrame()
    local frame = CreateFrame("Frame", "GuildBankSnapshotsFrame", UIParent, "GuildBankSnapshotsContainer")
    frame:SetUserData("resizeChildren", {})
    frame:SetPoint("CENTER")
    frame:SetSize(1000, 500)
    frame:Hide()

    private.bg, private.border = private:AddBackdrop(frame)
    private:SetFrameMovable(frame, true)
    private:SetFrameSizing(frame, 500, 300, GetScreenWidth() - 400, GetScreenHeight() - 200)
    addon:AddSpecialFrame(frame, "GuildBankSnapshotsFrame")
    frame:SetCallbacks(callbacks.frame)
    private.frame = frame

    local titleBar = frame:Acquire("GuildBankSnapshotsContainer")
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("RIGHT")
    titleBar:SetHeight(20)
    titleBar.bg, titleBar.border = private:AddBackdrop(titleBar)
    private:SetFrameMovable(titleBar, true)
    titleBar:SetCallbacks(callbacks.title_)

    local closeButton = titleBar:Acquire("GuildBankSnapshotsButton")
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
    closeButton:SetSize(16, 16)
    closeButton:ClearBackdrop()
    closeButton:SetText("x")
    closeButton:SetCallbacks(callbacks.closeButton)

    local title = titleBar:Acquire("GuildBankSnapshotsFontFrame")
    title:SetPoint("TOPLEFT", 2, -2)
    title:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
    title:SetPoint("BOTTOM", 0, 2)
    title:SetText(L.addonName)
    title:SetFont(nil, private:GetInterfaceFlairColor())
    private:SetFrameMovable(title, true)
    title:SetCallbacks(callbacks.title_)

    local tabContainer = frame:Acquire("GuildBankSnapshotsGroup")
    tabContainer:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -10)
    tabContainer:SetPoint("RIGHT", -10, 0)
    tabContainer:SetHeight(20)
    tabContainer:SetReverse(true)
    private:RegisterResizeCallback(tabContainer, "tabContainer")
    frame.tabContainer = tabContainer

    for tabID, info in addon:pairs(tabs) do
        local tab = tabContainer:Acquire("GuildBankSnapshotsTabButton")
        tab:SetTab(tabContainer, tabID, info)
        tab:SetCallbacks(callbacks.tab)
        tabContainer:AddChild(tab)

        info.init()
    end

    local content = frame:Acquire("GuildBankSnapshotsContainer")
    content:SetPoint("TOPLEFT", tabContainer, "BOTTOMLEFT")
    content:SetPoint("RIGHT", tabContainer, "RIGHT")
    content:SetPoint("BOTTOMRIGHT", -10, 10)
    content.bg, content.border = private:AddBackdrop(content, { bgColor = "darkest" })
    frame.content = content
end

------------------------

function private:LoadFrame(reviewPath, guildKey, scanID)
    private.frame:Show()

    for tab, _ in private.frame.tabContainer:EnumerateActive() do
        if reviewPath and tab:GetText() == reviewPath then
            tab:SetUserData("guildKey", guildKey)
            tab:SetUserData("scanID", scanID)
            tab:Fire("OnClick")
            break
        elseif not loaded and not reviewPath and tab:GetTabID() == 1 then
            tab:Fire("OnClick")
            break
        end
    end

    loaded = true
end

------------------------

function private:RegisterResizeCallback(child, name)
    assert(private.frame:GetUserData("resizeChildren"), "GuildBankSnapshotsFrame does not have a resizeChildren table")
    private.frame:GetUserData("resizeChildren")[name] = child
end
