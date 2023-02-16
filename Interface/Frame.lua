local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local loaded

local tabs = {
    {
        header = L["Review"],
        onClick = function(content)
            private:LoadReviewTab(content)
        end,
    },
    {
        header = L["Analyze"],
        onClick = function(content) end,
    },
    {
        header = L["Settings"],
        onClick = function(content)
            private:LoadSettingsTab(content)
        end,
    },
}

local function CreateTabButton()
    local button = CreateFrame("Button", nil, UIParent)
    button:SetHeight(20)

    -- Textures
    button:SetNormalTexture(private:AddBackdrop(button, "elementColor"))

    -- Text
    button:SetText("")
    button:SetNormalFontObject(GameFontNormal)
    button:SetHighlightFontObject(GameFontHighlight)
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
    frame.closeButton:SetNormalFontObject(GameFontNormal)
    frame.closeButton:SetHighlightFontObject(GameFontHighlight)
    frame.closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.title = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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

    -- [[ Scripts ]]
    frame:SetScript("OnSizeChanged", function(self)
        self.tabContainer:AcquireTabButtons()
    end)
end

function private:LoadFrame()
    private.frame:Show()
    if not loaded then
        loaded = true
        private.frame:SelectTab(1)
    end
end
