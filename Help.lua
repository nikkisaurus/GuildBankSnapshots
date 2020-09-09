local addon, ns = ...

local f = ns.f
local db = ns.db
local L = ns.L

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:CreateHelpTab()
    local tabFrame = CreateFrame("ScrollFrame", addon .. "HelpTabScrollFrame", f, "UIPanelScrollFrameTemplate")
    tabFrame:SetSize(f:GetWidth() - 20, f:GetHeight() - 44)
    f.tabFrames["Help"] = tabFrame
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
    header:SetText(L["Help"])

    local strings = {
        {"If you need any assistance or have any suggestions/requests, please leave a comment on CurseForge (Twitch) or WoW Interface. You may also message me on Discord @Niketa#1247 for a faster response, but please limit this to troubleshooting purposes only.", false},
        {"What's new in GBS 2.0?", true},
        {"* Complete addon rewrite", false},
        {"* Revamped database", false},
        {"* User-friendly snapshot selection", false},
        {"* Exports are no longer limited to 8 snapshots per export.", false},
        {"* You can now select a default guild to view or export snapshots.", false},
        {"* Customize snapshot transaction dates by default time since snapshot date, time since current date, or approximate date.", false},
        {"* Sorting transactions both by ascending and descending dates is now possible.", false},
        {"* Choose how you'd like to see dates formatted.", false},
        {"Slash Commands", true},
        {"/gbs = Opens main addon frame", false},
        {"/gbs scan = Scans guild bank to create log (same function as using the button)", false},
        {"Common Issues", true},
        {"If you have an incomplete scan (usually upon first logging in), simply delete the scan and try again. Usually when this is happening, it's because there wasn't enough time to query the bank log. The second scan should be complete.", false},
        {"Export Instructions: Selecting Snapshots", true},
        {"Select the snapshots you'd like to export by selecting a guild from the dropdown and clicking each snapshot in the Available Snapshots frame that you want to export. You can add all snapshots for the selected guild to the pending frame by clicking the Select All button.", false},
        {"If you want to remove a snapshot from your pending exports, click on it in the Pending Snapshots frame or use the Remove All button to clear your pending snapshots.", false},
        {"Once you've selected the snapshots you want to export, click on the Export Pending button. If you want to export your entire database (all guilds, all snapshots), click the Export All Guilds button (you don't need to follow the previous steps). Your export text will populate in the third frame. Click into the frame and press Ctrl+C to copy the text.", false},
        -- {"Export Instructions: Large Exports", true},
        -- {"If you are exporting a large number of snapshots, your export text will be broken up into separate buffers. After clicking either Export All Guilds or Export Pending, the first portion of the buffer will be available in the third frame.", false},
        -- {"Above this frame, the current buffer position and total number of buffers will be displayed (e.g. 1 of 2). Paste this text into your text editor as you normally would and then click the Next button below the frame. Copy the new export text in the frame and paste this after the text from the first buffer into your text editor. Repeat this step until you've gone through all buffers and then click Done to reset the export frame.", false},
        -- {"You can now save your CSV file.", false},
        {"Export Instructions: Creating a CSV", true},
        {"Open a text editor, such as Notepad, and paste your copied export text into the editor. Save the file with a .csv extension. Please note, some text editors require you to select All Files from the file type and then manually type in .csv after the name.", false},
        {"Once your file is saved you can open it in Excel or another reader of your choice.", false}, 
    }

    local lines = {}

    i = 1
    for k, v in pairs(strings) do
        lines[i] = tabFrame.ScrollContent:CreateFontString(nil, "OVERLAY", v[2] and "GameFontNormal" or "GameFontHighlight")
        lines[i]:SetWidth(tabFrame.ScrollContent:GetWidth() - 20)
        lines[i]:SetPoint("TOPLEFT", i > 1 and lines[i - 1] or header, "BOTTOMLEFT", 0, v[2] and -10 or -5)

        lines[i]:SetText(v[1])
        lines[i]:SetJustifyH("LEFT")
        lines[i]:SetWordWrap(true)

        i = i + 1
    end
end