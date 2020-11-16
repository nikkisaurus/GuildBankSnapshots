local addon, ns = ...

local f = ns.f
local db = ns.db
local L = ns.L

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:CreateManageTab()
    local tabFrame = CreateFrame("ScrollFrame", addon .. "ManageTabScrollFrame", f, "UIPanelScrollFrameTemplate")
    tabFrame:SetSize(f:GetWidth() - 20, f:GetHeight() - 44)
    f.tabFrames["Manage"] = tabFrame
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
    header:SetText(L["Manage Snapshots"])

    local options = {
        {
            type = "header",
            text = "Delete",
        },
        {
            type = "text",
            text = "WARNING: Deletion is permanent. If you need to clear space, you can export your snapshots to create a CSV file for backup.",
        },
        {
            type = "Button",
            text = "Delete Active Snapshot",
            name = "DeleteActiveSnapshotBTN",
            func = function(self, ...)
                if db.settings.confirmDeletion then
                    local confirm = StaticPopup_Show(strupper(addon) .. "_CONFIRM_DELETION")
                    if confirm then
                        confirm.data = self
                        confirm.data2 = "snapshot"
                    end
                else
                    f:Delete(self, "snapshot")
                end
            end,
            disable = function()
                return not f.snapshot
            end,
        },
        {
            type = "Button",
            text = "Delete Active Guild",
            name = "DeleteActiveGuildBTN",
            func = function(self, ...)
                if db.settings.confirmDeletion then
                    local confirm = StaticPopup_Show(strupper(addon) .. "_CONFIRM_DELETION")
                    if confirm then
                        confirm.data = self
                        confirm.data2 = "guild"
                    end
                else
                    f:Delete(self, "guild")
                end
            end,
            group = 2,
            disable = function()
                return not f.guild
            end,
        },
        {
            type = "Button",
            text = "Delete All",
            name = "DeleteAllSnapshotsBTN",
            func = function(self, ...)
                if db.settings.confirmDeletion then
                    local confirm = StaticPopup_Show(strupper(addon) .. "_CONFIRM_DELETION")
                    if confirm then
                        confirm.data = self
                        confirm.data2 = "all"
                    end
                else
                    f:Delete(self, "all")
                end
            end,
            group = 3,
            disable = function()
                return f:count(db.guilds) == 0
            end,
        },
        {
            type = "header",
            text = "Export",
        },
        {
            type = "text",
            text = "See the Help tab for detailed instructions on exporting snapshots.",
        },
        {
            type = "Button",
            text = "Export All Guilds",
            name = "ExportAllBTN",
            func = function(self, ...)
                for guildID, guildTable in pairs(db.guilds) do
                    for snapshotID, snapshotTable in pairs(guildTable) do
                        f.pendingExportsScrollFrame.snapshots[snapshotID] = guildID
                    end
                end

                f:ExportPending()
            end,
            disable = function()
                return f:count(db.guilds) == 0
            end,
        },
        {
            type = "Button",
            text = "Export Pending",
            name = "ExportPendingBTN",
            func = f.ExportPending,
            disable = function()
                return true
            end,
            group = 2,
        },
    }

    local lines = {}

    i = 1
    for k, v in f:pairsByKeys(options) do
        if v.type == "CheckButton" then
            lines[i] = CreateFrame("CheckButton", nil, tabFrame.ScrollContent, "OptionsBaseCheckButtonTemplate")
            lines[i]:SetScript("OnClick", function(self)
                db.settings[v.value] = self:GetChecked()
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

            UIDropDownMenu_Initialize(lines[i], v.func)
        elseif v.type == "Button" then
            lines[i] = CreateFrame("Button", addon .. v.name, tabFrame.ScrollContent, "UIMenuButtonStretchTemplate")
            f[v.name] = lines[i]
            lines[i]:SetText(L[v.text])
            lines[i]:SetSize(150, 25)
            lines[i]:SetScript("OnClick", v.func)
            if v.disable and v.disable() then
                lines[i]:Disable()
            end
        elseif v.type == "text" then
            lines[i] = tabFrame.ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lines[i]:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
            lines[i]:SetText(L[v.text])
            lines[i]:SetWordWrap(true)
            lines[i]:SetJustifyH("LEFT")
            lines[i]:SetWidth(tabFrame.ScrollContent:GetWidth() - 20)
        end

        if v.group then
            lines[i].offset = v.group
        end

        lines[i]:SetPoint(
            v.group and "LEFT" or "TOPLEFT",
            i > 1 and (not v.group and lines[i - 1].offset and lines[i - (lines[i - 1].offset)] or lines[i - 1]) or header,
            v.group and "RIGHT" or "BOTTOMLEFT",
            v.group and 10 or 0,
            v.group and 0 or (v.type == "header" and -10 or -5)
        )

        i = i + 1
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local guildExportDropDownButton = CreateFrame("Button", addon .. "GuildExportDropDownButton", tabFrame.ScrollContent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(guildExportDropDownButton, 130);
    UIDropDownMenu_SetButtonWidth(guildExportDropDownButton, 150)

    UIDropDownMenu_SetText(guildExportDropDownButton, L["Select guild..."])
    UIDropDownMenu_JustifyText(guildExportDropDownButton, "LEFT")

    guildExportDropDownButton:SetPoint("TOPLEFT", lines[i - 2], "BOTTOMLEFT", -15, -5)

    UIDropDownMenu_Initialize(guildExportDropDownButton, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self, selected)
            f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, selected, f.exportText)
        end

        for k, v in f:pairsByKeys(db.guilds) do
            info.text = f:GetFormattedGuildName(k)
            info.arg1 = k
            info.checked = f.exportGuild == k
            UIDropDownMenu_AddButton(info)
        end

        if f:count(db.guilds) > 0 then
            info.text = L["Clear Selection"]
            info.arg1 = false
            info.checked = false
            UIDropDownMenu_AddButton(info)
        end
    end)

    f.guildExportDropDownButton = guildExportDropDownButton

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local snapshotExportTXT = tabFrame.ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    snapshotExportTXT:SetText(L["Available Snapshots"])
    snapshotExportTXT:SetPoint("TOPLEFT", f.guildExportDropDownButton, "BOTTOMLEFT", 17, -5)

    local snapshotExportScrollFrame = f:CreateScrollFrame("Snapshot", tabFrame.ScrollContent, "Interface/FrameGeneral/UI-Background-Marble")
    snapshotExportScrollFrame:SetSize(175, 200)

    snapshotExportScrollFrame:SetPoint("TOPLEFT", snapshotExportTXT, "BOTTOMLEFT", 0, -5)

    f.snapshotExportScrollFrame = snapshotExportScrollFrame

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local selectAllSnapshotsBTN = CreateFrame("Button", addon .. "SelectAllSnapshotsBTN", tabFrame.ScrollContent, "UIMenuButtonStretchTemplate")
    f.selectAllSnapshotsBTN = selectAllSnapshotsBTN
    selectAllSnapshotsBTN:SetText(L["Select All"])
    selectAllSnapshotsBTN:SetSize(150, 25)
    selectAllSnapshotsBTN:SetPoint("TOP", snapshotExportScrollFrame, "BOTTOM", 0, -5)
    selectAllSnapshotsBTN:SetScript("OnClick", function()
        for k, v in pairs(db.guilds[f.exportGuild]) do
            f.pendingExportsScrollFrame.snapshots[k] = f.exportGuild
        end
        f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
    end)
    if not f.exportGuild then
        selectAllSnapshotsBTN:Disable()
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local pendingExportsScrollFrame = f:CreateScrollFrame("Snapshot", tabFrame.ScrollContent, "Interface/FrameGeneral/UI-Background-Marble")
    pendingExportsScrollFrame:SetSize(175, 200)

    pendingExportsScrollFrame:SetPoint("TOPLEFT", snapshotExportScrollFrame, "TOPRIGHT", 40, 0)

    pendingExportsScrollFrame.snapshots = {}
    f.pendingExportsScrollFrame = pendingExportsScrollFrame

    local pendingExportTXT = tabFrame.ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pendingExportTXT:SetText(L["Pending Snapshots"])
    pendingExportTXT:SetPoint("BOTTOMLEFT", pendingExportsScrollFrame, "TOPLEFT", 0, 5)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local removeAllSnapshotsBTN = CreateFrame("Button", addon .. "RemoveAllSnapshotsBTN", tabFrame.ScrollContent, "UIMenuButtonStretchTemplate")
    f.removeAllSnapshotsBTN = removeAllSnapshotsBTN
    removeAllSnapshotsBTN:SetText(L["Remove All"])
    removeAllSnapshotsBTN:SetSize(150, 25)
    removeAllSnapshotsBTN:SetPoint("TOP", pendingExportsScrollFrame, "BOTTOM", 0, -5)
    removeAllSnapshotsBTN:SetScript("OnClick", function()
        table.wipe(f.pendingExportsScrollFrame.snapshots)
        f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
    end)
    if f:count(f.pendingExportsScrollFrame.snapshots) == 0 then
        removeAllSnapshotsBTN:Disable()
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local exportScrollFrame = f:CreateScrollFrame("Snapshot", tabFrame.ScrollContent, "Interface/FrameGeneral/UI-Background-Marble")
    exportScrollFrame:SetSize(175, 35)

    exportScrollFrame:SetPoint("TOPLEFT", pendingExportsScrollFrame, "TOPRIGHT", 40, 0)

    f.exportScrollFrame = exportScrollFrame

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local exportEditbox = CreateFrame("EditBox", addon .. "ExportSnapshotsEditbox", tabFrame.ScrollContent)
    exportEditbox:SetSize(exportScrollFrame:GetWidth() - 20, 35)
    exportEditbox:SetAllPoints(pendingExportsScrollFrame)
    exportScrollFrame:SetScrollChild(exportEditbox)
    f.exportEditbox = exportEditbox

    exportEditbox:SetFontObject(GameFontHighlightSmall)
    exportEditbox:SetAutoFocus(false)
    exportEditbox:SetTextInsets(10, 10, 10, 10)
    exportEditbox:GetRegions():SetNonSpaceWrap(false)

    exportEditbox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    exportEditbox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local resetExportsBTN = CreateFrame("Button", addon .. "ResetExportsBTN", tabFrame.ScrollContent, "UIMenuButtonStretchTemplate")
    f.resetExportsBTN = resetExportsBTN
    resetExportsBTN:SetText(L["Reset"])
    resetExportsBTN:SetSize(150, 25)
    resetExportsBTN:SetPoint("TOP", exportScrollFrame, "BOTTOM", 0, -5)
    resetExportsBTN:SetScript("OnClick", function()
        table.wipe(f.pendingExportsScrollFrame.snapshots)
        f.exportEditbox:SetText("")
        f.exportEditbox:ClearFocus()
        f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, db.settings.defaultGuild)
    end)
    if not f.exportText then
        resetExportsBTN:Disable()
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:Delete(self, type)
    if type == "snapshot" then
        db.guilds[f.guild][f.snapshot] = nil
        f:UpdateFrame(f.guild, nil, nil, nil, nil, f.exportGuild, f.exportText)
    elseif type == "guild" then
        if f.exportGuild and f.exportGuild == f.guild then
            f.exportGuild = nil
        end
        db.guilds[f.guild] = nil
        f:UpdateFrame(nil, nil, nil, nil, nil, f.exportGuild, f.exportText)
    elseif type == "all" then
        table.wipe(db.guilds)
        f:UpdateFrame()
    end

    f:LoadSnapshot()
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:ExportPending()
    local lines = {}
    for snapshotID, guildID in pairs(f.pendingExportsScrollFrame.snapshots) do
        for tab, tabTable in pairs(db.guilds[guildID][snapshotID]) do
            local tabName = db.guilds[guildID][snapshotID][tab].tabName

            for  transaction, transactionTable in pairs(tabTable) do
                if type(transactionTable) == "table" then
                    local itemName = tabName ~= "Money" and gsub(gsub(strsub(transactionTable[5], string.find(transactionTable[5], "%["), string.find(transactionTable[5], "%]")), "%[", ""), "%]", "") or ""
                    local approxDate = date("approx. %I %p on %x", transactionTable[1]):gsub(" 0", " ")
                    local line = {}

                    tinsert(line, f:GetFormattedGuildName(guildID)) -- guildName
                    tinsert(line, f:GetFormattedDate(snapshotID)) -- snapshotDate
                    tinsert(line, tabName) -- tabName
                    tinsert(line, transactionTable[3]) -- transactionType
                    tinsert(line, transactionTable[2] or "") -- name
                    tinsert(line, itemName) -- itemLink
                    tinsert(line, transactionTable[8] or "") -- itemLevel
                    tinsert(line, tabName ~= "Money" and transactionTable[4] or f:GetMoneyString(transactionTable[4])) -- itemCount/moneyAmount
                    tinsert(line, transactionTable[6] or "") -- moveTabName1
                    tinsert(line, transactionTable[7] or "") -- moveTabName2
                    tinsert(line, string.format("%s ago", f:GetElapsedTime(transactionTable[1], not db.settings.timeSinceCurrent and snapshotID))) -- timeSince
                    tinsert(line, approxDate) -- transactionDate
                    tinsert(line, f:FormatLine(transactionTable, tabTable.total and "money" or "item")) -- line

                    line = table.concat(line, ",")

                    tinsert(lines, line)
                end
            end

            if tabName == "Money" then
                tinsert(lines, string.format("%s,%s,%s,%s,,,,%s", f:GetFormattedGuildName(guildID), f:GetFormattedDate(snapshotID), tabName, L["total"], f:GetMoneyString(db.guilds[guildID][snapshotID][tab].total)))
            end
        end
    end

    local exportText = table.concat(lines, "\n"):gsub("|%w%w%w%w%w%w%w%w%w", ""):gsub("|r", "")
    exportText = "guildName,snapshotDate,tabName,transactionType,name,itemName,itemLevel,itemMoneyCount,moveTabName1,moveTabName2,timeSince,transactionDate,line\n" .. exportText

    f.exportEditbox:SetText(exportText)
    f.exportEditbox:SetFocus()

    f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild or db.settings.defaultGuild, exportText)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:LoadPendingSnapshotsList()
    local frame = f.pendingExportsScrollFrame.ScrollContent

    for k, v in pairs(frame.lines) do
        v:SetText("")
        v:ClearAllPoints()
        v:Hide()
    end

    local line_counter = 0
    for k, v in f:pairsByKeys(frame:GetParent().snapshots, function(a, b) return b < a end) do
        local snapshotBTN = CreateFrame("Button", nil, frame)
        snapshotBTN:SetSize(frame:GetParent():GetWidth() - 20, 20)

        snapshotBTN:SetNormalFontObject("GameFontHighlightSmall")
        snapshotBTN:SetText(string.format("%s (%s)", f:GetFormattedDate(k, true), f:GetFormattedGuildName(v)))
        snapshotBTN:GetFontString():SetJustifyH("LEFT")
        snapshotBTN:GetFontString():SetPoint("LEFT", snapshotBTN, "LEFT", 2, 0)
        snapshotBTN:GetFontString():SetWidth(snapshotBTN:GetWidth() - 4)
        snapshotBTN:GetFontString():SetWordWrap(false)
        snapshotBTN:SetPushedTextOffset(0, 0)

        snapshotBTN:SetPoint("TOPLEFT", 10, -(line_counter * 20) - 10)

        snapshotBTN:SetHighlightTexture("Interface/Buttons/GreyscaleRamp64")
        snapshotBTN:GetHighlightTexture():SetColorTexture(1, 1, 1, .15)

        snapshotBTN:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(string.format("%s (%s)", f:GetFormattedDate(k, true), f:GetFormattedGuildName(v)), 1, 1, 1, 1)
            GameTooltip:Show()
        end)

        snapshotBTN:SetScript("OnLeave", function()
            GameTooltip_Hide()
        end)

        snapshotBTN:SetScript("OnClick", function(self)
            frame:GetParent().snapshots[k] = nil
            f:UpdateFrame(f.guild, f.snapshot, f.tab, f.filterType, f.filterKey, f.exportGuild, f.exportText)
        end)

        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        frame.lines[line_counter] = snapshotBTN
        line_counter = line_counter + 1
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

StaticPopupDialogs[strupper(addon) .. "_CONFIRM_DELETION"] = {
    text = L["Are you sure you want to continue with deletion?"],
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(_, button, type)
        f:Delete(button, type)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
preferredIndex = 3,
}