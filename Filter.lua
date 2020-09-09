local addon, ns = ...

local f = ns.f
local db = ns.db
local L = ns.L

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function f:FilterDropDownButton_Initialization(level, menuList, ...)
    if not f.guild or not f.snapshot or not f.tab then
        return
    end

    local snapshotTable = db.guilds[f.guild][f.snapshot][f.tab]
    local info = UIDropDownMenu_CreateInfo()

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    if level == 1 then
        info.text = L["Name"]
        info.hasArrow = true
        info.menuList = L["Name"]
        UIDropDownMenu_AddButton(info)

        info.text = L["Type"]
        info.hasArrow = true
        info.menuList = L["Type"]
        UIDropDownMenu_AddButton(info)

        if not snapshotTable.total then
            info.text = L["Item"]
            info.hasArrow =  true
            info.menuList = L["Item"]
            UIDropDownMenu_AddButton(info)

            info.text = L["Item Level"]
            info.hasArrow = false
            info.func = function()
                local currentMax = 500
                if not f.itemLevelFrame then
                    local itemLevelFrame = CreateFrame("Frame", addon .. "ItemLevelFrame", UIParent, "BasicFrameTemplate")
                    itemLevelFrame:SetSize(200, 125)

                    itemLevelFrame:SetPoint("CENTER", 0, 0)

                    itemLevelFrame:SetFrameStrata("DIALOG")
                    itemLevelFrame:EnableMouse(true)
                    itemLevelFrame:SetMovable(true)
                    itemLevelFrame:RegisterForDrag("LeftButton")

                    itemLevelFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
                    itemLevelFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
                    itemLevelFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

                    f.itemLevelFrame = itemLevelFrame

                    local title = itemLevelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    title:SetText(L["Set Item Level Range"])
                    title:SetPoint("TOPLEFT", 10, -5)
                    
                    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

                    local minRangeTXT = itemLevelFrame:CreateFontString("OVERLAY", nil, "GameFontNormal")
                    minRangeTXT:SetText(L["Minimum"])
                    minRangeTXT:SetPoint("TOPLEFT", 15, -35)
                    
                    local minRangeEditbox = CreateFrame("EditBox", addon .. "minRangeEditbox", itemLevelFrame, "InputBoxTemplate")
                    minRangeEditbox:SetSize(50, 25)

                    minRangeEditbox:SetFontObject(GameFontHighlightSmall)
                    minRangeEditbox:SetTextInsets(1, 1, 1, 1)
                    minRangeEditbox:SetMaxLetters(4)
                    minRangeEditbox:SetText("1")

                    minRangeEditbox:SetPoint("CENTER", minRangeTXT, "CENTER", 0, -25)
                    
                    minRangeEditbox:SetAutoFocus(false)
                    
                    minRangeEditbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
                    minRangeEditbox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
                    minRangeEditbox:SetScript("OnTabPressed", function(self)
                        self:ClearFocus()
                        f.maxRangeEditbox:SetFocus()
                    end)

                    minRangeEditbox:SetScript("OnTextChanged", function(self)
                        local text = string.gsub(self:GetText(), "[%s%c%p%a]", "")
                        self:SetText(text)
                    end)

                    minRangeEditbox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
                    minRangeEditbox:SetScript("OnEditFocusLost", function(self)
                        local text = tonumber(self:GetText())
                        if not text or text == 0 then
                            self:SetText("1")
                        elseif text > currentMax then
                            self:SetText(currentMax)
                        elseif text > tonumber(f.maxRangeEditbox:GetText()) then
                            f.maxRangeEditbox:SetText(text)
                        end
                        self:HighlightText(0, 0)
                    end)
                    
                    f.minRangeEditbox = minRangeEditbox
                    
                    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

                    local maxRangeTXT = itemLevelFrame:CreateFontString("OVERLAY", nil, "GameFontNormal")
                    maxRangeTXT:SetText(L["Maximum"])
                    maxRangeTXT:SetPoint("LEFT", minRangeTXT, "RIGHT", 50, 0)
                    
                    local maxRangeEditbox = CreateFrame("EditBox", addon .. "maxRangeEditbox", itemLevelFrame, "InputBoxTemplate")
                    maxRangeEditbox:SetSize(50, 25)

                    maxRangeEditbox:SetFontObject(GameFontHighlightSmall)
                    maxRangeEditbox:SetTextInsets(1, 1, 1, 1)
                    maxRangeEditbox:SetMaxLetters(4)
                    maxRangeEditbox:SetText(currentMax)

                    maxRangeEditbox:SetPoint("CENTER", maxRangeTXT, "CENTER", 0, -25)
                    maxRangeEditbox:SetAutoFocus(false)
                    
                    maxRangeEditbox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
                    maxRangeEditbox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
                    maxRangeEditbox:SetScript("OnTabPressed", function(self)
                        self:ClearFocus()
                        f.minRangeEditbox:SetFocus()
                    end)
                    
                    maxRangeEditbox:SetScript("OnTextChanged", function(self)
                        local text = string.gsub(self:GetText(), "[%s%c%p%a]", "")
                        self:SetText(text)
                    end)
                    
                    maxRangeEditbox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)        
                    maxRangeEditbox:SetScript("OnEditFocusLost", function(self)
                        local text = tonumber(self:GetText())
                        if not text or text == 0 then
                            self:SetText(currentMax)
                        elseif text > currentMax then
                            self:SetText(currentMax)
                        elseif text < tonumber(f.minRangeEditbox:GetText()) then
                            f.minRangeEditbox:SetText(text)
                        end
                        self:HighlightText(0, 0)
                    end)

                    f.maxRangeEditbox = maxRangeEditbox
                    
                    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

                    local acceptRangeBTN = CreateFrame("Button", addon .. "acceptRangeBTN", itemLevelFrame, "UIMenuButtonStretchTemplate")
                    acceptRangeBTN:SetSize(125, 25)

                    acceptRangeBTN:SetText(L["Filter"])
                    acceptRangeBTN:SetPushedTextOffset(0, 0)

                    acceptRangeBTN:SetPoint("BOTTOM", itemLevelFrame, "BOTTOM", 0, 15)
                    
                    acceptRangeBTN:SetScript("OnClick", function()
                        itemLevelFrame:Hide()

                        local minRange = tonumber(f.minRangeEditbox:GetText())
                        local maxRange = tonumber(f.maxRangeEditbox:GetText())
                                
                        local items = {}

                        for k, v in pairs(db.guilds[f.guild][f.snapshot][f.tab]) do
                            if type(v) == "table" then
                                local _, _, _, itemLvl, _, itemType = GetItemInfo(v[5])
                                
                                if itemType == "Armor" or itemType == "Weapon" then
                                    if itemLvl >= minRange and itemLvl <= maxRange then
                                        local itemName = gsub(gsub(strsub(v[5], string.find(v[5], "%["), string.find(v[5], "%]")), "%[", ""), "%]", "")
                                        items[v[5]] = itemName
                                    end
                                end
                            end
                        end

                        UIDropDownMenu_SetText(f.filterDropDownButton, string.format(L["Item Level: %s-%s"], minRange, maxRange))
                        f:UpdateFrame(f.guild, f.snapshot, f.tab, "ilvl", items, f.exportGuild, f.exportText)
                    end)
                else
                    f.itemLevelFrame:Show()
                end
                    
                f.minRangeEditbox:SetFocus() 
                f.minRangeEditbox:HighlightText()
                
                -- Query cache
                for k, v in pairs(snapshotTable) do
                    if type(v) == "table" then
                        local _, _, _, itemLvl, _, itemType = GetItemInfo(v[5])
                    end
                end
            end

            UIDropDownMenu_AddButton(info)
        end

        info.text = L["Clear Filter"]
        info.hasArrow = false

        info.func = function()
            f:UpdateFrame(f.guild, f.snapshot, f.tab, nil, nil, f.exportGuild, f.exportText)
        end

        UIDropDownMenu_AddButton(info)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    elseif menuList == L["Name"] then
        local names = {}
        
        for k, v in pairs(snapshotTable) do
            if type(v) == "table" then
                local name = v[2] or (UNKNOWN or L["Unknown"])
                names[name] = true
            end
        end

        for k, v in f:pairsByKeys(names) do
            info.text = k
            info.checked = f.filterKey == k

            info.func = function(self, ...)
                f:UpdateFrame(f.guild, f.snapshot, f.tab, "name", k, f.exportGuild, f.exportText)

                UIDropDownMenu_SetText(f.filterDropDownButton, string.format("%s: %s", menuList, k))
                CloseDropDownMenus()
            end

            UIDropDownMenu_AddButton(info, level)
        end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    elseif menuList == "Type" then
        local types = {}

        for k, v in pairs(snapshotTable) do
            if type(v) == "table" then
                local transType = v[3]
                types[transType] = true
            end
        end

        for k, v in f:pairsByKeys(types) do
            info.text = k
            info.checked = f.filterKey == k

            info.func = function(self, ...)
                f:UpdateFrame(f.guild, f.snapshot, f.tab, "type", k, f.exportGuild, f.exportText)

                UIDropDownMenu_SetText(f.filterDropDownButton, string.format("%s: %s", menuList, k))
                CloseDropDownMenus()
            end

            UIDropDownMenu_AddButton(info, level)
        end
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    elseif menuList == "Item" then
        local items = {}

        for k, v in pairs(snapshotTable) do
            if type(v) == "table" then
                local itemName = gsub(gsub(strsub(v[5], string.find(v[5], "%["), string.find(v[5], "%]")), "%[", ""), "%]", "")
                local itemLink = v[5]
                items[itemName] = itemLink
            end
        end

        for k, v in f:pairsByKeys(items) do
            info.text = k
            info.checked = f.filterKey == k

            info.func = function(self, ...)
                f:UpdateFrame(f.guild, f.snapshot, f.tab, "item", v, f.exportGuild, f.exportText)
                
                UIDropDownMenu_SetText(f.filterDropDownButton, string.format("%s: %s", menuList, k))
                CloseDropDownMenus()
            end

            UIDropDownMenu_AddButton(info, level)
        end
    end
end