local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

local draggingID

function GuildBankSnapshotsTableSorter_OnLoad(sorter)
    sorter = private:MixinText(sorter)

    sorter:InitScripts({
        OnAcquire = function(self)
            self:SetSize(150, 20)
            self:ResetButtons()
            sorter.upper:Hide()
            sorter.lower:Hide()
            self:Justify("LEFT", "MIDDLE")
            self:SetFontObject(GameFontHighlightSmall)
        end,

        OnDragStart = function(self)
            draggingID = self.sortID
        end,

        OnDragStop = function(self)
            -- Must reset dragging ID in this script in addition to the receiving sorter in case it isn't dropped on a valid sorter
            -- Need to delay to make sure the ID is still accessible to the receiving sorter
            C_Timer.After(0.1, function()
                draggingID = nil
            end)

            self.bg:SetColorTexture(private.interface.colors.insetColor:GetRGBA())
        end,

        OnEnter = function(self)
            self.highlight:Show()

            local sortID = self.sortID

            if draggingID then
                if draggingID == sortID then
                    self.highlight:Hide()
                else
                    if sortID < draggingID then
                        -- Insert before
                        self.upper:Show()
                    else
                        -- Insert after
                        self.lower:Show()
                    end
                end
            end

            -- Show tooltip if text is truncated
            -- if not self.colID or self.text:GetWidth() > self.text:GetStringWidth() then
            --     return
            -- end

            -- private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, cols)
            --     GameTooltip:AddLine(cols[self.colID].header, 1, 1, 1)
            -- end, self, cols)
        end,

        OnLeave = function(self)
            self.upper:Hide()
            self.lower:Hide()
            self.highlight:Hide()
        end,

        OnMouseDown = function(self)
            self.bg:SetColorTexture(private.interface.colors.emphasizeColor:GetRGBA())
        end,

        OnMouseUp = function(self)
            self.bg:SetColorTexture(private.interface.colors.insetColor:GetRGBA())
        end,

        OnReceiveDrag = function(self)
            local sortID = self.sortID
            if not draggingID or draggingID == sortID then
                return
            end

            local inserting = private.db.global.settings.preferences.sortHeaders[draggingID]
            tremove(private.db.global.settings.preferences.sortHeaders, draggingID)
            tinsert(private.db.global.settings.preferences.sortHeaders, sortID, inserting)

            self.callback()

            draggingID = nil
            self.upper:Hide()
            self.lower:Hide()
        end,

        OnRelease = function(self)
            self.sortID = nil
            self.tableCols = nil
            self.colID = nil
            self.callback = nil
        end,
    })

    sorter:EnableMouse(true)
    sorter:RegisterForDrag("LeftButton")

    -- Textures

    sorter.bg, sorter.border, sorter.highlight = private:AddBackdrop(sorter, { bgColor = "insetColor", hasHighlight = true, highlightColor = "highlightColor" })
    sorter.highlight:Hide()

    sorter.upper = sorter:CreateTexture(nil, "OVERLAY")
    sorter.upper:SetPoint("TOPLEFT", sorter.bg, "TOPLEFT")
    sorter.upper:SetPoint("TOPRIGHT", sorter.bg, "TOPRIGHT")
    sorter.upper:SetHeight(2)
    sorter.upper:SetColorTexture(1, 1, 1, 1)
    sorter.upper:Hide()

    sorter.lower = sorter:CreateTexture(nil, "OVERLAY")
    sorter.lower:SetPoint("BOTTOMLEFT", sorter.bg, "BOTTOMLEFT")
    sorter.lower:SetPoint("BOTTOMRIGHT", sorter.bg, "BOTTOMRIGHT")
    sorter.lower:SetHeight(2)
    sorter.lower:SetColorTexture(1, 1, 1, 1)
    sorter.lower:Hide()

    -- Buttons

    sorter.moveUp = CreateFrame("Button", nil, sorter)
    sorter.moveUp:SetPoint("LEFT", 5, 0)
    sorter.moveUp:SetNormalFontObject(private.interface.fonts.symbolFont)
    sorter.moveUp:SetDisabledFontObject(private.interface.fonts.symbolFontDisabled)
    sorter.moveUp:SetText("▲")

    sorter.moveUp:SetScript("OnClick", function()
        sorter:Move(-1)
    end)

    sorter.moveDown = CreateFrame("Button", nil, sorter)
    sorter.moveDown:SetPoint("LEFT", sorter.moveUp, "RIGHT")
    sorter.moveDown:SetNormalFontObject(private.interface.fonts.symbolFont)
    sorter.moveDown:SetDisabledFontObject(private.interface.fonts.symbolFontDisabled)
    sorter.moveDown:SetText("▼")

    sorter.moveDown:SetScript("OnClick", function()
        sorter:Move(1)
    end)

    -- Text
    sorter.text = sorter:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sorter.text:SetPoint("LEFT", sorter.moveDown, "RIGHT", 5, 0)
    sorter.text:SetPoint("RIGHT", -5, 0)

    -- Methods

    function sorter:Move(i)
        local sortID = self.sortID
        if not sortID then
            return
        end

        local inserting = private.db.global.settings.preferences.sortHeaders[sortID]
        tremove(private.db.global.settings.preferences.sortHeaders, sortID)
        tinsert(private.db.global.settings.preferences.sortHeaders, sortID + i, inserting)

        self.callback()
    end

    function sorter:ResetButtons()
        self.moveUp:SetSize(12, 16)
        self.moveDown:SetSize(12, 16)

        self.moveUp:SetEnabled(true)
        self.moveDown:SetEnabled(true)
    end

    function sorter:SetSorterData(sortID, maxSorters, callback)
        self.sortID = sortID
        self.maxSorters = maxSorters
        self.callback = callback

        if sortID == 1 then
            sorter.moveUp:SetEnabled()
        elseif sortID == maxSorters then
            sorter.moveDown:SetEnabled()
        end
    end
end

-- local function CreateSorter()
--     local sorter = CreateFrame("Frame", nil, private.frame.sorters, "BackdropTemplate")
--     sorter:EnableMouse(true)
--     sorter:RegisterForDrag("LeftButton")
--     sorter:SetHeight(20)

--     -- Textures
--     private:AddBackdrop(sorter)

--     -- Text
--     sorter.orderText = private:CreateFontString(sorter)
--     sorter.orderText:SetSize(20, 20)
--     sorter.orderText:SetPoint("RIGHT", -4, 0)

--     sorter.text = private:CreateFontString(sorter)
--     sorter.text:SetHeight(20)
--     sorter.text:SetPoint("TOPLEFT", 4, -4)
--     sorter.text:SetPoint("RIGHT", sorter.orderText, "LEFT", -4, 0)
--     sorter.text:SetPoint("BOTTOM", 0, 4)

--     -- Methods
--     function sorter:IsDescending()
--         if not self.colID then
--             return
--         end

--         return private.db.global.settings.preferences.descendingHeaders[self.colID]
--     end

--     function sorter:SetColID(sorterID, colID)
--         sorter.sorterID = sorterID
--         sorter.colID = colID
--         self:UpdateText()
--     end

--     function sorter:SetDescending(bool)
--         if not self.colID then
--             return
--         end

--         private.db.global.settings.preferences.descendingHeaders[self.colID] = bool
--     end

--     function sorter:UpdateText(insertSorter)
--         if not self.colID then
--             self.orderText:SetText("")
--             self.text:SetText("")
--             return
--         end

--         local order = self:IsDescending() and "▼" or "▲"
--         self.orderText:SetText(order)

--         local header = cols[self.colID].header
--         self.text:SetText(format("%s%s%s", insertSorter or "", insertSorter and " " or "", header))
--     end

--     function sorter:UpdateWidth()
--         self:SetWidth((self:GetParent():GetWidth() - 10) / addon:tcount(cols))
--     end

--     -- Scripts
--     sorter:SetScript("OnDragStart", function(self)
--         private.frame.sorters.dragging = self.sorterID
--         self:SetBackdropColor(unpack(private.defaults.gui.emphasizeBgColor))
--     end)

--     sorter:SetScript("OnDragStop", function(self)
--         -- Must reset dragging ID in this script in addition to the receiving sorter in case it isn't dropped on a valid sorter
--         -- Need to delay to make sure the ID is still accessible to the receiving sorter
--         C_Timer.After(1, function()
--             private.frame.sorters.dragging = nil
--         end)

--         sorter:SetBackdropColor(unpack(private.defaults.gui.bgColor))
--     end)

--     sorter:SetScript("OnEnter", function(self)
--         -- Emphasize highlighted text
--         self.text:SetTextColor(unpack(private.defaults.gui.emphasizeFontColor))

--         -- Add indicator for sorting insertion
--         local sorterID = self.sorterID
--         local draggingID = private.frame.sorters.dragging

--         if draggingID and draggingID ~= sorterID then
--             if sorterID < draggingID then
--                 -- Insert before
--                 self:UpdateText("<")
--             else
--                 -- Insert after
--                 self:UpdateText(">")
--             end

--             -- Highlight frame to indicate where dragged header is moving
--             sorter:SetBackdropColor(unpack(private.defaults.gui.highlightBgColor))
--         end

--         -- Show tooltip if text is truncated
--         if not self.colID or self.text:GetWidth() > self.text:GetStringWidth() then
--             return
--         end

--         private:InitializeTooltip(self, "ANCHOR_RIGHT", function(self, cols)
--             GameTooltip:AddLine(cols[self.colID].header, 1, 1, 1)
--         end, self, cols)
--     end)

--     sorter:SetScript("OnLeave", function(self)
--         -- Restore default text color
--         sorter.text:SetTextColor(unpack(private.defaults.gui.fontColor))

--         -- Remove sorting indicator
--         self:UpdateText()
--         if self.sorterID ~= private.frame.sorters.dragging then
--             -- Don't reset backdrop on dragging frame; this is done in OnDragStop
--             self:SetBackdropColor(unpack(private.defaults.gui.bgColor))
--         end

--         -- Hide tooltips
--         private:ClearTooltip()
--     end)

--     sorter:SetScript("OnMouseUp", function(self)
--         -- Changes sorting order
--         self:SetDescending(not private.db.global.settings.preferences.descendingHeaders[sorter.colID])
--         self:UpdateText()
--         private.frame.scrollBox.Sort()
--     end)

--     sorter:SetScript("OnReceiveDrag", function(self)
--         local sorterID = self.sorterID
--         local draggingID = private.frame.sorters.dragging

--         if not draggingID or draggingID == sorterID then
--             return
--         end

--         -- Get the colID to be inserted and remove the col from the sorting table
--         -- The insert will go before/after by default because of the removed entry
--         local colID = private.frame.sorters.children[draggingID].colID
--         tremove(private.db.global.settings.preferences.sortHeaders, draggingID)
--         tinsert(private.db.global.settings.preferences.sortHeaders, sorterID, colID)

--         -- Reset sorters based on new order
--         self:GetParent():LoadSorters()
--     end)

--     return sorter
-- end

-- local function ResetSorter(__, frame)
--     frame:Hide()
-- end

-- local Sorter = CreateObjectPool(CreateSorter, ResetSorter)
