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

            self.bg:SetColorTexture(private.interface.colors.dark:GetRGBA())
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
            self.bg:SetColorTexture(private.interface.colors[private:UseClassColor() and "dimmedClass" or "dimmedFlair"]:GetRGBA())
        end,

        OnMouseUp = function(self)
            self.bg:SetColorTexture(private.interface.colors.dark:GetRGBA())
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

    sorter.bg, sorter.border, sorter.highlight = private:AddBackdrop(sorter, { bgColor = "dark", hasHighlight = true, highlightColor = "lightest" })
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
