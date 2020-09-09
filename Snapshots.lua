local addon, ns = ...

local f = ns.f
local db = ns.db
local L = ns.L

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:CreateSnapshotsTab()
    local tabFrame = CreateFrame("Frame", addon .. "SnapshotTabFrame", f)
    tabFrame:Hide()

    tabFrame:SetAllPoints(f)

    f.tabFrames["Snapshots"] = tabFrame

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local guildDropDownButton = CreateFrame("Button", addon .. "GuildDropDownButton", tabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(guildDropDownButton, 150);
    UIDropDownMenu_SetButtonWidth(guildDropDownButton, 150)

    UIDropDownMenu_SetText(guildDropDownButton, L["Select guild..."])
    UIDropDownMenu_JustifyText(guildDropDownButton, "LEFT")

    guildDropDownButton:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, -45)

    UIDropDownMenu_Initialize(guildDropDownButton, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self, selected)
            f:UpdateFrame(selected, nil, nil, nil, nil, f.exportGuild, f.exportText)
        end

        for k, v in f:pairsByKeys(db.guilds) do
            info.text = f:GetFormattedGuildName(k)
            info.arg1 = k
            info.checked = f.guild == k
            UIDropDownMenu_AddButton(info)
        end

        if f:count(db.guilds) > 0 then
            info.text = L["Clear Selection"]
            info.arg1 = false
            info.checked = false
            UIDropDownMenu_AddButton(info)
        end
    end)

    f.guildDropDownButton = guildDropDownButton

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local tabDropDownButton = CreateFrame("Button", addon .. "TabDropDownButton", tabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(tabDropDownButton, 100);
    UIDropDownMenu_SetButtonWidth(tabDropDownButton, 150)

    UIDropDownMenu_JustifyText(tabDropDownButton, "LEFT")

    tabDropDownButton:SetPoint("LEFT", guildDropDownButton, "RIGHT", 0, 0)

    UIDropDownMenu_Initialize(tabDropDownButton, function(self, level)
        if not f.guild or not f.snapshot then
            return
        end

        local info = UIDropDownMenu_CreateInfo()
        info.func = self.SetValue

        for k, v in f:pairsByKeys(db.guilds[f.guild][f.snapshot]) do
            info.text = v.tabName
            info.arg1 = k
            info.checked = f.tab == k
            UIDropDownMenu_AddButton(info)
        end
    end)

    function tabDropDownButton:SetValue(selected)
        f:UpdateFrame(f.guild, f.snapshot, selected, nil, nil, f.exportGuild, f.exportText)
    end

    f.tabDropDownButton = tabDropDownButton

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local filter = tabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    filter:SetText(L["Filter"])
    filter:SetPoint("LEFT", tabDropDownButton, "RIGHT", 10, 0)

    local filterDropDownButton = CreateFrame("Button", addon .. "FilterDropDownButton", tabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(filterDropDownButton, 150);
    UIDropDownMenu_SetButtonWidth(filterDropDownButton, 150)
    
    UIDropDownMenu_JustifyText(filterDropDownButton, "LEFT")

    filterDropDownButton:SetPoint("LEFT", filter, "RIGHT", 0, 0)

    UIDropDownMenu_Initialize(filterDropDownButton, f.FilterDropDownButton_Initialization, nil, 1, false)
    
    f.filterDropDownButton = filterDropDownButton

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local snapshotScrollFrame = f:CreateScrollFrame("Snapshot", tabFrame, "Interface/FrameGeneral/UI-Background-Marble")
    snapshotScrollFrame:SetSize(150, tabFrame:GetHeight())

    snapshotScrollFrame:SetPoint("TOPLEFT", guildDropDownButton, "BOTTOMLEFT", 15, -15)
    snapshotScrollFrame:SetPoint("BOTTOM", tabFrame, "BOTTOM", 0, 10)

    f.snapshotScrollFrame = snapshotScrollFrame

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local transactionsScrollFrame = f:CreateScrollFrame("Transactions", tabFrame, "Interface/FrameGeneral/UI-Background-Marble")
    transactionsScrollFrame:SetSize(tabFrame:GetWidth(), tabFrame:GetHeight())

    transactionsScrollFrame:SetPoint("TOP", snapshotScrollFrame, "TOP", 0, 0)
    transactionsScrollFrame:SetPoint("LEFT", snapshotScrollFrame.ScrollBar, "RIGHT", 10, 0)
    transactionsScrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -36, 10)
    
    transactionsScrollFrame.ScrollContent:EnableMouse(true)
    
    transactionsScrollFrame.ScrollContent:SetHyperlinksEnabled(true)
    transactionsScrollFrame.ScrollContent:SetScript("OnHyperlinkClick", DEFAULT_CHAT_FRAME:GetScript("OnHyperlinkClick"))
    transactionsScrollFrame.ScrollContent:SetScript("OnHyperlinkEnter", function(_, link)
        ShowUIPanel(GameTooltip)
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    transactionsScrollFrame.ScrollContent:SetScript("OnHyperlinkLeave", function(...)
            HideUIPanel(GameTooltip)
    end)

    f.transactionsScrollFrame = transactionsScrollFrame

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local copySnapshotBTN = CreateFrame("Button", addon .. "CopySnapshotBTN", tabFrame)
    copySnapshotBTN:SetNormalTexture("Interface/BUTTONS/UI-GuildButton-PublicNote-Up")
    copySnapshotBTN:SetSize(15, 15)

    copySnapshotBTN:SetPoint("BOTTOMRIGHT", transactionsScrollFrame.ScrollBar, "TOPLEFT", -5, 30)

    copySnapshotBTN:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Copy"], 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    copySnapshotBTN:SetScript("OnLeave", function()
        GameTooltip_Hide()
    end)

    copySnapshotBTN:SetScript("OnClick", function()
        if not f.copyEditbox then
            local copyEditbox = CreateFrame("EditBox", addon .. "CopySnapshotEditbox", transactionsScrollFrame)
            copyEditbox:SetSize(transactionsScrollFrame:GetWidth(), transactionsScrollFrame:GetHeight())

            copyEditbox:SetFontObject(GameFontHighlightSmall)
            copyEditbox:SetTextInsets(10, 10, 10, 10)
            copyEditbox:SetMaxLetters(999999)
            copyEditbox:SetMultiLine(true)

            copyEditbox:SetAllPoints(transactionsScrollFrame)
            
            copyEditbox:SetAutoFocus(false)

            copyEditbox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            
            f.copyEditbox = copyEditbox
        elseif f.copyEditbox:IsVisible() then
            transactionsScrollFrame.ScrollContent:Show()
            transactionsScrollFrame:SetScrollChild(transactionsScrollFrame.ScrollContent)

            f.copyEditbox:Hide()
            return
        else            
            f.copyEditbox:Show()
        end

        local line = ""
        for k, v in f:pairsByKeys(transactionsScrollFrame.ScrollContent.lines) do
            if v:IsVisible() then
                if k == 0 then
                    line = v:GetText() .. "\n" .. line
                else
                    line = line .. v:GetText() .. "\n"
                end
            end
        end

        transactionsScrollFrame.ScrollContent:Hide()

        transactionsScrollFrame:SetScrollChild(f.copyEditbox)
        f.copyEditbox:SetText(line)
    end)
    
    f.copySnapshotBTN = copySnapshotBTN

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local sortSnapshotBTN = CreateFrame("Button", addon .. "SortSnapshotBTN", tabFrame)
    sortSnapshotBTN:SetNormalTexture("Interface/BUTTONS/Arrow-Up-Up")
    sortSnapshotBTN:SetSize(15, 15)

    sortSnapshotBTN:SetPoint("LEFT", copySnapshotBTN, "RIGHT", 5, 0)

    sortSnapshotBTN:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Sort"], 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    sortSnapshotBTN:SetScript("OnLeave", function()
        GameTooltip_Hide()
    end)

    sortSnapshotBTN:SetScript("OnClick", function()
        if not f.reverseSort then
            f.reverseSort = true
            sortSnapshotBTN:SetNormalTexture("Interface/BUTTONS/Arrow-Down-Up")
        else
            f.reverseSort = false
            sortSnapshotBTN:SetNormalTexture("Interface/BUTTONS/Arrow-Up-Up")
        end

        f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
    end)

    f.sortSnapshotBTN = sortSnapshotBTN
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:LoadSnapshot()
    local frame = f.transactionsScrollFrame.ScrollContent

    if f.copyEditbox and f.transactionsScrollFrame:GetScrollChild() == f.copyEditbox then
        f.copyEditbox:Hide()

        frame:Show()
        f.transactionsScrollFrame:SetScrollChild(frame)
    end

    for k, v in pairs(frame.lines) do
        v:SetText("")
        v:ClearAllPoints()
        v:Hide()
    end

    if not f.guild or not f.snapshot or not f.tab then
        return
    end

    local snapshot = db.guilds[f.guild][f.snapshot]
    local name = snapshot[f.tab].tabName

    local tabName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabName:SetText(name ~= "Money" and name or string.format("Total: %s", GetCoinTextureString(snapshot[f.tab].total)))
    tabName:SetPoint("TOPLEFT", 10, -10)

    frame.lines[0] = tabName

    local line_counter = 0
    for i = f.reverseSort and f:count(snapshot[f.tab]) or 1, f.reverseSort and 1 or f:count(snapshot[f.tab]), f.reverseSort and -1 or 1 do
        local v = snapshot[f.tab][i]
        if type(v) == "table" then
            if (f.filterType and (
                (f.filterType == "name" and v[2] == f.filterKey) or
                (f.filterType == "name" and (f.filterKey == UNKNOWN or f.filterKey == L["Unknown"]) and not v[2]) or
                (f.filterType == "type" and v[3] == f.filterKey) or
                (f.filterType == "item" and v[5] == f.filterKey) or
                (f.filterType == "ilvl" and f.filterKey[v[5]])
            )) or not f.filterType then
                local line = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                line:SetWidth(frame:GetParent():GetWidth() - 20)

                line:SetText(f:FormatLine(v, name == "Money" and "money" or "item"))
                line:SetJustifyH("LEFT")
                line:SetWordWrap(true)

                line:SetPoint(
                    "TOPLEFT", 
                    line_counter == 0 and tabName or frame.lines[line_counter], 
                    "BOTTOMLEFT", 
                    0, 
                    -10
                )
                
                line_counter = line_counter + 1
                frame.lines[line_counter] = line
            end
        end
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

f.snapshotBTNs = {}
function f:LoadSnapshotsList(export)
    local frame = export and f.snapshotExportScrollFrame.ScrollContent or f.snapshotScrollFrame.ScrollContent

    for k, v in pairs(frame.lines) do
        v:SetText("")
        v:ClearAllPoints()
        v:Hide()
    end
    
    if (export and not f.exportGuild) or (not export and not f.guild) then
        return
    end

    local line_counter = 0
    for k, v in f:pairsByKeys(export and db.guilds[f.exportGuild] or db.guilds[f.guild], function(a, b) return b < a end) do
        if not export or (export and not f.pendingExportsScrollFrame.snapshots[k]) then
            local snapshotBTN = CreateFrame("Button", nil, frame)
            snapshotBTN:SetSize(frame:GetParent():GetWidth() - 20, 20)

            snapshotBTN:SetNormalFontObject("GameFontHighlightSmall")
            snapshotBTN:SetText(f:GetFormattedDate(k, true))
            snapshotBTN:GetFontString():SetJustifyH("LEFT")
            snapshotBTN:GetFontString():SetPoint("LEFT", snapshotBTN, "LEFT", 2, 0)
            snapshotBTN:GetFontString():SetWidth(snapshotBTN:GetWidth() - 4)
            snapshotBTN:GetFontString():SetWordWrap(false)
            snapshotBTN:SetPushedTextOffset(0, 0)

            snapshotBTN:SetPoint("TOPLEFT", 10, -(line_counter * 20) - 10)

            snapshotBTN:SetHighlightTexture("Interface/Buttons/GreyscaleRamp64")
            snapshotBTN:GetHighlightTexture():SetColorTexture(1, 1, 1, .15)

            if not export and (f.snapshot and f.snapshot == k) then
                snapshotBTN:SetNormalTexture("Interface/Buttons/GreyscaleRamp64")
                snapshotBTN:GetNormalTexture():SetColorTexture(1, 1, 1, .15)
            end

            snapshotBTN:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(f:GetFormattedDate(k), 1, 1, 1, 1)
                GameTooltip:Show()
            end)

            snapshotBTN:SetScript("OnLeave", function()
                GameTooltip_Hide()
            end)

            snapshotBTN:SetScript("OnClick", function(self)
                if not export then
                    for _, line in pairs(frame.lines) do
                        line:SetNormalTexture("")
                    end

                    self:SetNormalTexture("Interface/Buttons/GreyscaleRamp64")
                    self:GetNormalTexture():SetColorTexture(1, 1, 1, .15)

                    f:UpdateFrame(f.guild, k, 1, nil, nil, f.exportGuild, f.exportText)
                else
                    f.pendingExportsScrollFrame.snapshots[k] = f.exportGuild
                    f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
                end
            end)

            if not export then
                f.snapshotBTNs[string.format("%s:%s", f.guild, k)] = snapshotBTN
            end

            -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

            frame.lines[line_counter] = snapshotBTN
            line_counter = line_counter + 1
        end
    end
end