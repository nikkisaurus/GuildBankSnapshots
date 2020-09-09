local addon, ns = ...

local f = ns.f
local db = ns.db
local L = ns.L

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local fLoaded
function f:CreateFrame()
    if fLoaded then
        if f:IsVisible() then
            f:Hide()
        else
            f:Show()
        end
    else
        f:SetSize(700, 400)
        f:SetPoint("CENTER", 0, 0)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetFrameStrata("HIGH")

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        f.tabFrames = {}

        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 10, -5)
        title:SetText(L["Guild Bank Snapshots"])

        local activeSnapshot = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        activeSnapshot:SetPoint("LEFT", title, "RIGHT", 10, 0)
        f.activeSnapshot = activeSnapshot

        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        local tabs = {["Scan"] = 1, ["Snapshots"] = 2, ["Manage"] = 3, ["Settings"] = 4, ["Help"] = 5}

        for k, v in pairs(tabs) do
            local btn = CreateFrame("Button", string.format("%s%sTabBTN", addon, k), f)
            btn:SetSize(100, 30)
            btn:SetPoint("TOPLEFT", f, "BOTTOMLEFT", v == 1 and 0 or ((v - 1) * (btn:GetWidth() - 10 )), 0)
            btn:SetText(k)


            btn:SetNormalFontObject("GameFontHighlightSmall")
            btn:SetHighlightFontObject("GameFontNormalSmall")
            btn:SetPushedTextOffset(0, -1)
            btn:GetFontString():SetWordWrap(false)
            btn:GetFontString():SetPoint("TOP", 0, -5)

            btn:SetNormalTexture("Interface/PaperDollInfoFrame/UI-CHARACTER-INACTIVETAB")

            btn:SetScript("OnClick", function(self, button)
                if k ~= "Scan" then
                    for key, value in pairs(tabs) do
                        value:SetNormalTexture("Interface/PaperDollInfoFrame/UI-CHARACTER-INACTIVETAB")
                        value:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                    end

                    self:SetNormalTexture("Interface/PaperDollInfoFrame/UI-CHARACTER-ACTIVETAB")
                    self:GetNormalTexture():SetTexCoord(0, 1, 0, .65)

                    for key, value in pairs(f.tabFrames) do
                        value:Hide()
                    end

                    f.tabFrames[k]:Show()
                else
                    f:ScanBank()
                end
            end)
            
            tabs[k] = btn

            if v > 1 then
                f["Create" .. k .. "Tab"]()
            end
        end

        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        f:Show()
        _G[string.format("%sSnapshotsTabBTN", addon)]:Click(self)
        fLoaded = true
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

f:SetScript("OnShow", function()
    if db.settings.defaultGuild then
        f:UpdateFrame(f.guild or db.settings.defaultGuild, nil, nil, nil, nil, f.exportGuild or db.settings.defaultGuild, f.exportText)
    end
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:CreateScrollFrame(frameName, parent, texture)
    local scrollFrame = CreateFrame("ScrollFrame", addon .. frameName .. "ScrollFrame", parent, "UIPanelScrollFrameTemplate")

    scrollFrame.ScrollBar:EnableMouseWheel(true)
    scrollFrame.ScrollBar:SetScript("OnMouseWheel", function(self, direction)
        ScrollFrameTemplate_OnMouseWheel(scrollFrame, direction)
    end)

    scrollFrame.scrollTexture = scrollFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
    scrollFrame.scrollTexture:SetPoint("TOP")
    scrollFrame.scrollTexture:SetPoint("BOTTOM")
    scrollFrame.scrollTexture:SetPoint("RIGHT", 26, 0)
    scrollFrame.scrollTexture:SetWidth(26)
    scrollFrame.scrollTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar.blp")
    scrollFrame.scrollTexture:SetTexCoord(0, 0.45, 0.1640625, 1)
    scrollFrame.scrollTexture:SetAlpha(0.5)

    if texture then
        scrollFrame.texture = scrollFrame:CreateTexture()
        scrollFrame.texture:SetAllPoints(scrollFrame)
        scrollFrame.texture:SetTexture(texture)
    end

    scrollFrame.ScrollContent = CreateFrame("Frame", addon .. frameName .. "ScrollContent", scrollFrame)
    scrollFrame.ScrollContent:SetSize(1, 1)
    scrollFrame.ScrollContent:SetAllPoints(scrollFrame)
    scrollFrame:SetScrollChild(scrollFrame.ScrollContent)

    scrollFrame.ScrollContent.lines = {}

    return scrollFrame
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:UpdateFrame(guild, snapshot, tab, filterType, filterKey, exportGuild, exportText)
    f.guild = guild
    f.snapshot = snapshot
    f.tab = tab
    f.filterType = filterType
    f.filterKey = filterKey
    f.exportGuild = exportGuild
    f.exportText = exportText

    if not guild then
        UIDropDownMenu_SetText(f.guildDropDownButton, "")
        f.DeleteActiveGuildBTN:Disable()
    else
        UIDropDownMenu_SetText(f.guildDropDownButton, f:GetFormattedGuildName(guild))
        f.DeleteActiveGuildBTN:Enable()
    end

    if not snapshot then
        -- update title text
        f.activeSnapshot:SetText("")

        -- disable snapshot viewing buttons
        f.tabDropDownButton:Disable()
        UIDropDownMenu_SetText(f.filterDropDownButton, "")
        f.filterDropDownButton:Disable()
        f.copySnapshotBTN:Disable()
        f.sortSnapshotBTN:Disable()


        f.DeleteActiveSnapshotBTN:Disable()
    else
        -- update title text
        f.activeSnapshot:SetText(string.format("%s %s", f:GetFormattedGuildName(guild), f:GetFormattedDate(snapshot)))

        -- enable snapshot viewing buttons
        f.tabDropDownButton:Enable()
        f.filterDropDownButton:Enable()
        f.copySnapshotBTN:Enable()
        f.sortSnapshotBTN:Enable()

        -- enable deletion buttons
        f.DeleteActiveSnapshotBTN:Enable()
    end

    if not filterType or not filterKey then
        UIDropDownMenu_SetText(f.filterDropDownButton, "")
    end

    if not exportGuild then
        f.selectAllSnapshotsBTN:Disable()
        UIDropDownMenu_SetText(f.guildExportDropDownButton, L["Select guild..."])
    else
        local numPendingSnapshots = 0
        for k, v in pairs(f.pendingExportsScrollFrame.snapshots) do
            if v == exportGuild then
                numPendingSnapshots = numPendingSnapshots + 1
            end
        end

        if numPendingSnapshots == f:count(db.guilds[exportGuild]) then
            f.selectAllSnapshotsBTN:Disable()
        else
            f.selectAllSnapshotsBTN:Enable()
        end
        UIDropDownMenu_SetText(f.guildExportDropDownButton, f:GetFormattedGuildName(exportGuild))
    end

    if not exportText then
        f.resetExportsBTN:Disable()
    else
        f.resetExportsBTN:Enable()
    end

    if f:count(f.pendingExportsScrollFrame.snapshots) > 0 then
        f.ExportPendingBTN:Enable()
        f.removeAllSnapshotsBTN:Enable()
    else
        f.ExportPendingBTN:Disable()
        f.removeAllSnapshotsBTN:Disable()
    end

    if db.settings.defaultGuild and not db.guilds[db.settings.defaultGuild] then
        db.settings.defaultGuild = false
        UIDropDownMenu_SetText(f.defaultGuildDropDown, "")
    end

    if f:count(db.guilds) == 0 then
        f.DeleteAllSnapshotsBTN:Disable()
        f.ExportAllBTN:Disable()
    else
        f.DeleteAllSnapshotsBTN:Enable()
        f.ExportAllBTN:Enable()
    end

    f.snapshotScrollFrame.ScrollBar:SetValue(0)
    f.transactionsScrollFrame.ScrollBar:SetValue(0)
    f.snapshotExportScrollFrame.ScrollBar:SetValue(0)
    f.pendingExportsScrollFrame.ScrollBar:SetValue(0)

    f:LoadSnapshotsList()
    f:LoadSnapshot()

    f:LoadSnapshotsList(true)
    f:LoadPendingSnapshotsList()
end