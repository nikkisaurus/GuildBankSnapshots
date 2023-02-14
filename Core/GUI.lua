local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:AddBackdrop(frame, lightBg)
    if not frame or not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop(private.defaults.gui.backdrop)
    frame:SetBackdropBorderColor(unpack(private.defaults.gui.borderColor))
    frame:SetBackdropColor(unpack(private.defaults.gui[lightBg and "bgColor" or "darkBgColor"]))
end

function private:AddBackdropTexture(frame, lightBg)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(unpack(private.defaults.gui[lightBg and "bgColor" or "darkBgColor"]))

    return bg
end

function private:AddSpecialFrame(frame)
    tinsert(UISpecialFrames, frame:GetName())
end

function private:ClearTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

function private:CreateDropdown(parent, name, setter, initializer)
    local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
    local dropdown = LibDD:Create_UIDropDownMenu(name, parent)
    dropdown.info = LibDD:UIDropDownMenu_CreateInfo()

    -- Methods
    function dropdown:AddButton()
        LibDD:UIDropDownMenu_AddButton(self.info)
    end

    function dropdown:SetText(text)
        LibDD:UIDropDownMenu_SetText(self, text)
    end

    function dropdown:SetDropdownWidth(width)
        LibDD:UIDropDownMenu_SetWidth(self, width)
    end

    function dropdown:SetValue(...)
        setter(...)
    end

    function dropdown:Initialize()
        LibDD:UIDropDownMenu_Initialize(self, function(...)
            -- local self, level, menuList = ...
            initializer(...)
        end)
    end

    dropdown:Initialize()

    -- Strip and redraw background textures
    dropdown.Left:SetTexture()
    dropdown.Middle:SetTexture()
    dropdown.Right:SetTexture()

    dropdown.border = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.border:SetColorTexture(unpack(private.defaults.gui.borderColor))
    dropdown.border:SetPoint("TOPLEFT", 4, -4)
    dropdown.border:SetPoint("BOTTOMRIGHT", -4, 4)

    local r, g, b = unpack(private.defaults.gui.bgColor)
    dropdown.background = dropdown:CreateTexture(nil, "ARTWORK")
    dropdown.background:SetColorTexture(r, g, b, 0.75)
    dropdown.background:SetPoint("TOPLEFT", dropdown.border, "TOPLEFT", 1, -1)
    dropdown.background:SetPoint("BOTTOMRIGHT", dropdown.border, "BOTTOMRIGHT", -1, 1)

    -- Strip and redraw button
    dropdown.Button:SetNormalTexture(136961)
    dropdown.Button:SetHighlightTexture(136961)
    dropdown.Button:SetPushedTexture(136961)
    dropdown.Button:SetDisabledTexture(136961)

    dropdown.Button:GetNormalTexture():SetTexCoord(0 / 64, 32 / 64, 3 / 64, 29 / 64)
    dropdown.Button:GetHighlightTexture():SetTexCoord(0 / 64, 32 / 64, 3 / 64, 29 / 64)
    dropdown.Button:GetPushedTexture():SetTexCoord(0 / 64, 32 / 64, 3 / 64, 29 / 64)
    dropdown.Button:GetDisabledTexture():SetTexCoord(0 / 64, 32 / 64, 3 / 64, 29 / 64)

    -- Realign elements
    dropdown.Button:ClearAllPoints()
    dropdown.Button:SetPoint("RIGHT", -5, 0)
    dropdown.Text:ClearAllPoints()
    dropdown.Text:SetPoint("LEFT", 2, 0)
    dropdown.Text:SetPoint("TOPRIGHT", dropdown.Button, "TOPLEFT", -2, 0)
    dropdown.Text:SetPoint("BOTTOM", dropdown.Button, "BOTTOM", 0, 0)

    -- Update font
    dropdown.Text:SetFont(unpack(private.defaults.gui.font))

    return dropdown
end

function private:CreateFontString(parent, justifyH, justifyV)
    if not parent or not parent.CreateFontString then
        return
    end

    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(unpack(private.defaults.gui.font))
    text:SetTextColor(unpack(private.defaults.gui.fontColor))
    text:SetJustifyH(justifyH or "LEFT")
    text:SetJustifyV(justifyV or "MIDDLE")
    return text
end

function private:InitializeTooltip(frame, anchor, callback, ...)
    GameTooltip:SetOwner(frame, anchor or "ANCHOR_CURSOR")
    if type(callback) == "function" then
        callback(...)
    end
    GameTooltip:Show()
end

function private:SetFrameSizing(frame, minWidth, minHeight, maxWidth, maxHeight)
    -- Set movable
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Set resizable
    frame:SetResizable(true)
    frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
    frame.resizer = CreateFrame("Button", nil, frame)
    frame.resizer:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
    frame.resizer:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
    frame.resizer:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
    frame.resizer:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.resizer:SetSize(16, 16)
    frame.resizer:EnableMouse(true)

    frame.resizer:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)

    frame.resizer:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
end
