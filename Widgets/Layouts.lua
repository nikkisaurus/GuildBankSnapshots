local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0", true)

------------------------------------------------------------

local pairs, sort, wipe = pairs, table.sort, table.wipe

--*------------------------------------------------------------------------

-- Adds padding between list items, allows the last item to fill the remaining height of the frame, and allows sorting children
AceGUI:RegisterLayout("GBS3List", function(content, children)
    local padding = (content.obj and content.obj:GetUserData("childPadding")) or (content.widget and content.widget:GetUserData("childPadding")) or 5
    local height = 0

    local sortFunc = content.obj:GetUserData("sortFunc")
    if sortFunc then
        sort(children, sortFunc)
    end

    for key, child in addon.pairs(children) do
        local frame = child.frame
        frame:ClearAllPoints()

        if not child:GetUserData("filtered") then
            frame:Show()
            frame:SetWidth(content:GetWidth() - 10)

            if i == 1 then
                frame:SetPoint("TOPLEFT", padding, -padding)
            else
                frame:SetPoint("TOPLEFT", padding, -(padding + height))
            end

            height = height + frame:GetHeight() + padding

            if child.height == "fill" then
                frame:SetPoint("BOTTOM")
                break
            end

            if child.DoLayout then
                child:DoLayout()
            end
        else
            frame:Hide()
        end
    end

    if content.obj.LayoutFinished then
        content.obj:LayoutFinished(nil, height + padding)
    end
end)

--*------------------------------------------------------------------------

-- Content should contain two children containers to create a sidebar and main panel
AceGUI:RegisterLayout("GBS3SidebarGroup", function(content, children)
    local contentWidth = content.width or content:GetWidth() or 0
    local height = 0

    for i = 1, 2 do
        local child = children[i]
        if child then
            local frame = child.frame
            frame:ClearAllPoints()
            frame:Show()

            if i == 1 then
                frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
                frame:SetPoint("BOTTOMRIGHT", content, "BOTTOMLEFT", contentWidth / (content.obj:GetUserData("sidebarDenom") or 3), 0)
            elseif i == 2 then
                frame:SetPoint("TOPLEFT", children[1].frame, "TOPRIGHT", 0, 0)
                frame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
            end

            height = height + frame:GetHeight()

            if child.DoLayout then
                child:DoLayout()
            end
        end
    end

    if content.obj.LayoutFinished then
        content.obj:LayoutFinished(nil, height)
    end
end)

--*------------------------------------------------------------------------

-- Content should contain three children containers to create a top panel, sidebar, and main panel
AceGUI:RegisterLayout("GBS3TopSidebarGroup", function(content, children)
    local contentWidth = content.width or content:GetWidth() or 0
    local height = 0

    for i = 1, 3 do
        local child = children[i]
        if child then
            local frame = child.frame
            frame:ClearAllPoints()
            frame:Show()

            if i == 1 then
                frame:SetPoint("TOPLEFT")
                frame:SetPoint("TOPRIGHT")
            elseif i == 2 then
                frame:SetPoint("TOPLEFT", children[1].frame, "BOTTOMLEFT")
                frame:SetPoint("BOTTOMRIGHT", content, "BOTTOMLEFT", contentWidth / (content.obj:GetUserData("sidebarDenom") or 3), 0)
            elseif i == 3 then
                frame:SetPoint("TOPLEFT", children[2].frame, "TOPRIGHT")
                frame:SetPoint("BOTTOMRIGHT")
            end

            height = height + frame:GetHeight()

            if child.DoLayout then
                child:DoLayout()
            end
        end
    end

    if content.obj.LayoutFinished then
        content.obj:LayoutFinished(nil, height)
    end
end)


--*------------------------------------------------------------------------
--*Needs work... a lot of it*----------------------------------------------
--*------------------------------------------------------------------------

-- from AceGUI-3.0.lua
-- Used to set width/height without calling the layout function (e.g. when we're calling during the layout function)
local layoutrecursionblock = nil
local function safelayoutcall(object, func, ...)
	layoutrecursionblock = true
	object[func](object, ...)
	layoutrecursionblock = nil
end

------------------------------------------------------------

-- scroll:SetLayout("GBS3Table")
-- scroll:SetUserData("table", {
--     {
--         cols = {
--             {width = "fill"},
--         },
--         rowHeight = 20,
--     },
--     {
--         cols = {
--             {width = "relative", height = 500, relWidth = 1/3, vOffset = -5},
--             {width = 5, height = "row", vOffset = 50},
--             {width = "relative", relWidth = 1/3, vOffset = -50},
--         },
--         hpadding = 5,
--         vOffset = 10,
--         rowHeight = "stretch",
--     },
--     {
--         cols = {
--             {width = "fill"},
--         },
--     },
-- })

------------------------------------------------------------

-- table is set as a table filled with row tables
-- row tables can include the arguments: cols (table), rowHeight (integer, "fill" to fill to bottom of frame or "stretch" to stretch all cells to the max height of the row), hpadding (horizontal padding between cells (cols)), vOffset (vertical offset; note that same row offsets will be in relation to the first cell in a row)
-- rowHeight fills will stop after next row
-- cols tables consist of cell (col) tables and can include the arguments: width ("fill", "relative", or an integer), relWidth (required if width is set to "relative"; integer), height (integer or "row" to match max row height), vOffset (integer)
-- col table settings for height and hpadding will take precedence over row settings, but vOffset will compound

-- any children unaccounted for within the table userdata will not be displayed (in the example above, 5 children are shown: 1, 3, 1)
-- haven't decided whether or not I want everything to fit without overflowing or let that be a user problem to set up correctly; for now I'm not implementing this

-- add setting: constrainOverflow

------------------------------------------------------------

AceGUI:RegisterLayout("GBS3Table", function(content, children)
    if layoutrecursionblock or #children == 0 then return end
    local container = content.obj or content.widget
    local tableInfo = container:GetUserData("table")
    if not tableInfo then return end

    local contentWidth = content.width or content:GetWidth() or 0
    local height = 0

    local i = 1
    for row, rowInfo in pairs(tableInfo) do
        local colsFilled = 0
        local rowHeight = rowInfo.vOffset or 0
        local usedWidth = 0

        local fillToRow = {}

        for col, colInfo in pairs(rowInfo.cols) do
            local child = children[i]
            if not child then break end

            local frame = child.frame
            local frameWidth = child:GetUserData("userWidth") or colInfo.width or frame.width or frame:GetWidth() or 0
            local frameHeight = colInfo.height or rowInfo.rowHeight or frame.height or frame:GetHeight() or 0

            if not tonumber(frameHeight) then -- rowInfo.rowHeight == "stretch" or colInfo.height == "row"
                fillToRow[i] = true
                frameHeight = (tonumber(rowInfo.rowHeight) and rowInfo.rowHeight) or (tonumber(colInfo.height) and colInfo.height) or frame.height or frame:GetHeight() or 0
            end

            local hpadding = colInfo.hpadding or rowInfo.hpadding or 0
            local vOffset = colInfo.vOffset or 0

            ------------------------------------------------------------

            frame:Show()
            frame:ClearAllPoints()

            if i == 1 then
                -- first child
                frame:SetPoint("TOPLEFT")
                frame:SetPoint("BOTTOM", content, "TOP", 0, -frameHeight)
                colsFilled = colsFilled + 1
                -- usedWidth = usedWidth + frameWidth
            elseif colsFilled == 0 then
                -- new row
                frame:SetPoint("TOPLEFT", 0, -(height + rowHeight + vOffset))
                frame:SetPoint("BOTTOM", content, "TOP", 0, -(frameHeight + height))
                colsFilled = colsFilled + 1
                -- usedWidth = usedWidth + frameWidth
            elseif colsFilled <= #rowInfo.cols then
                -- same row
                frame:SetPoint("TOPLEFT", children[i - 1].frame, "TOPRIGHT", hpadding, -vOffset)
                frame:SetPoint("BOTTOM", content, "TOP", 0, -(frameHeight + height))
                colsFilled = colsFilled + 1
                -- usedWidth = usedWidth + frameWidth
            end

            if child.DoLayout then
                child:DoLayout()
            end

            ------------------------------------------------------------

            if frameWidth == "fill" then
                child.width = contentWidth
            elseif frameWidth == "relative" then
                child.relWidth = child.relWidth or colInfo.relWidth or 0
                child.width = contentWidth * child.relWidth
            else
                child.width = width
            end

            frame:SetPoint("RIGHT", content, "LEFT", child.width + usedWidth, 0)
            usedWidth = usedWidth + frame:GetWidth()

            ------------------------------------------------------------

            rowHeight = math.max(rowHeight, frameHeight)
            i = i + 1
        end

        height = height + rowHeight

        -- Set rows to max rowHeight after the whole row is drawn, to make sure we have the overall height
        for numChild, _ in pairs(fillToRow) do
            local child = children[numChild]
            local frame = child.frame

            if rowInfo.rowHeight == "fill" then
                frame:SetPoint("BOTTOM", 0, 0)
            else
                frame:SetPoint("BOTTOM", content, "TOP", 0, -height)
            end

            if child.DoLayout then
                child:DoLayout()
            end
        end

        if rowInfo.rowHeight == "fill" then
            -- won't draw any more rows if this row is filling
            break
        end
    end

    ------------------------------------------------------------

    if container.LayoutFinished then
        container:LayoutFinished(nil, height)
    end
end)