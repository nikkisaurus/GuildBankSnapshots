local addon, ns = ...

local f = ns.f
local db = ns.db
local L = ns.L

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:CreateSettingsTab()
    local tabFrame = CreateFrame("ScrollFrame", addon .. "SettingsTabScrollFrame", f, "UIPanelScrollFrameTemplate")
    tabFrame:SetSize(f:GetWidth() - 20, f:GetHeight() - 44)
    f.tabFrames["Settings"] = tabFrame
    tabFrame:Hide()

    tabFrame:SetPoint("TOP", 0, -34)
    tabFrame:SetPoint("LEFT", 10, 0)
    tabFrame:SetPoint("BOTTOM", 0, 7)
    tabFrame:SetPoint("RIGHT", -32, 0)

    tabFrame.ScrollBar:EnableMouseWheel(true)
    tabFrame.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
        ScrollFrameTemplate_OnMouseWheel(tabFrame, direction)
    end)

    tabFrame.scrollTexture = tabFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
    tabFrame.scrollTexture:SetPoint("TOP")
    tabFrame.scrollTexture:SetPoint("BOTTOM")
    tabFrame.scrollTexture:SetPoint("RIGHT", 26, 0)
    tabFrame.scrollTexture:SetWidth(26)
    tabFrame.scrollTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar.blp")
    tabFrame.scrollTexture:SetTexCoord(0, 0.45, 0.1640625, 1)
    tabFrame.scrollTexture:SetAlpha(0.5)

    tabFrame.texture = tabFrame:CreateTexture()
    tabFrame.texture:SetAllPoints(tabFrame)
    tabFrame.texture:SetTexture(0, 0, 0, 0.5)

    tabFrame.ScrollContent = CreateFrame("Frame", nil, tabFrame)
    tabFrame.ScrollContent:SetSize(tabFrame:GetWidth(), tabFrame:GetHeight())
    tabFrame.ScrollContent:SetAllPoints(tabFrame)
    tabFrame:SetScrollChild(tabFrame.ScrollContent)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local header = tabFrame.ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetText(L["Settings"])
   
   -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
 
    local settings = {
        {
            type = "header",
            text = "Scanning",
        },
        {
            type = "CheckButton",
            value = "autoScan",
            text = "Auto scan bank (once daily)",
        },
        {
            type = "CheckButton",
            value = "showFrameAfterAutoScan",
            text = "Show snapshot frame after auto scan",
        },
        {
            type = "CheckButton",
            value = "showFrameAfterScan",
            text = "Show snapshot frame after bank scan",
        },
        {
            type = "header",
            text = "Viewing",
        },
        {
            type = "CheckButton",
            value = "approxDates",
            text = "Show approximate dates for snapshot transactions",
            func = function()
                f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
            end,
        },
        {
            type = "CheckButton",
            value = "timeSinceCurrent",
            text = "Calculate time since by current date",
            func = function()
                f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
            end,
        },
        {
            type = "header",
            text = "Managing",
        },
        {
            type = "CheckButton",
            value = "confirmDeletion",
            text = "Confirm before deleting snapshots",
        },
        {
            type = "header",
            text = "Date Format",
        },
        {
            type = "dropdown",
            text = date(db.settings.dateFormat),
            func = function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                info.func = function(_, selected, text)
                    db.settings.dateFormat = selected
                    UIDropDownMenu_SetText(self, text)
                    f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)            
                end

                local formats = {
                    [date("%b %d, %Y (%X)")] = "%b %d, %Y (%X)",
                    [date("%b %d, %Y (%H:%M)")] = "%b %d, %Y (%H:%M)",
                    [date("%b %d, %Y (%I:%M:%S %p)")] = "%b %d, %Y (%I:%M:%S %p)",
                    [date("%b %d, %Y (%I:%M %p)")] = "%b %d, %Y (%I:%M %p)",

                    [date("%B %d, %Y (%X)")] = "%B %d, %Y (%X)",
                    [date("%B %d, %Y (%H:%M)")] = "%B %d, %Y (%H:%M)",
                    [date("%B %d, %Y (%I:%M:%S %p)")] = "%B %d, %Y (%I:%M:%S %p)",
                    [date("%B %d, %Y (%I:%M %p)")] = "%B %d, %Y (%I:%M %p)",

                    [date("%x (%X)")] = "%x (%X)",
                    [date("%x (%H:%M)")] = "%x (%H:%M)",
                    [date("%x (%I:%M:%S %p)")] = "%x (%I:%M:%S %p)",
                    [date("%x (%I:%M %p)")] = "%x (%I:%M %p)",

                    [date("%m/%d/%Y (%X)")] = "%m/%d/%Y (%X)",
                    [date("%m/%d/%Y (%H:%M)")] = "%m/%d/%Y (%H:%M)",
                    [date("%m/%d/%Y (%I:%M:%S %p)")] = "%m/%d/%Y (%I:%M:%S %p)",
                    [date("%m/%d/%Y (%I:%M %p)")] = "%m/%d/%Y (%I:%M %p)",
                }

                for k, v in f:pairsByKeys(formats) do
                    info.text = k
                    info.arg1 = v
                    info.arg2 = info.text
                    info.checked = db.settings.dateFormat == v
                    UIDropDownMenu_AddButton(info)
                end
            end,
        },
        {
            type = "header",
            text = "Default Guild",
        },
        {
            type = "dropdown",
            name = "defaultGuildDropDown",
            text = db.settings.defaultGuild and f:GetFormattedGuildName(db.settings.defaultGuild) or "",
            func = function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                info.func = function(_, selected, text)
                    db.settings.defaultGuild = selected
                    UIDropDownMenu_SetText(self, text)

                    if selected and not f.guild then
                        f:UpdateFrame(selected, nil, nil, nil, nil, f.exportGuild, f.exportText)
                    end
                end

                for k, v in f:pairsByKeys(db.guilds) do
                    info.text = f:GetFormattedGuildName(k)
                    info.arg1 = k
                    info.arg2 = info.text
                    info.checked = db.settings.defaultGuild and db.settings.defaultGuild == k
                    UIDropDownMenu_AddButton(info)
                end

                if f:count(db.guilds) > 0 then
                    info.text = L["Clear Selection"]
                    info.arg1 = false
                    info.arg2 = ""
                    info.checked = false
                    UIDropDownMenu_AddButton(info)
                end
            end,
        },
        {
            type = "header",
            text = "Export Settings",
        },
        {
            type = "dropdown",
            name = "exportDelimiterDropDown",
            text = db.settings.exportDelimiter or ",",
            func = function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                info.func = function(_, selected, text)
                    db.settings.exportDelimiter = selected
                    UIDropDownMenu_SetText(self, text)
                    f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
                end

                for k in [",",";"] do
                    info.text = k
                    info.arg1 = k
                    info.arg2 = info.text
                    info.checked = db.settings.exportDelimiter and db.settings.exportDelimiter == k
                    UIDropDownMenu_AddButton(info)
                end

            end,
        },
    }

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local lines = {}

    i = 1
    for k, v in f:pairsByKeys(settings) do
        if v.type == "CheckButton" then
            lines[i] = CreateFrame("CheckButton", nil, tabFrame.ScrollContent, "OptionsBaseCheckButtonTemplate")
            lines[i]:SetScript("OnClick", function(self)
                db.settings[v.value] = self:GetChecked()
                if v.func then
                    v.func()
                end
            end)
            lines[i]:SetScript("OnShow", function(self)
                self:SetChecked(db.settings[v.value])
            end)
            lines[i]:SetChecked(db.settings[v.value])

            lines[i].text = tabFrame.ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lines[i].text:SetPoint("LEFT", lines[i], "RIGHT", 5, 0)
            lines[i].text:SetText(L[v.text])
        elseif v.type == "header" then
            lines[i] = tabFrame.ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lines[i]:SetText(L[v.text])
        elseif v.type == "dropdown" then
            lines[i] = CreateFrame("Button", nil, tabFrame.ScrollContent, "UIDropDownMenuTemplate")
            UIDropDownMenu_SetText(lines[i], L[v.text])
            UIDropDownMenu_JustifyText(lines[i], "LEFT")
            UIDropDownMenu_SetWidth(lines[i], 150);
            UIDropDownMenu_SetButtonWidth(lines[i], 150)
            if v.name then
                f[v.name] = lines[i]
            end

            UIDropDownMenu_Initialize(lines[i], v.func)
        end

        lines[i]:SetPoint("TOPLEFT", i > 1 and lines[i - 1] or header, "BOTTOMLEFT", 0, v.type == "header" and -10 or -5)
        i = i + 1
    end
end