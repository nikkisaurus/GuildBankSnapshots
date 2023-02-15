local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:AddBackdrop(frame, bgColor)
    if not frame or not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop(private.defaults.backdrop)
    frame:SetBackdropBorderColor(private.defaults.colors.borderColor:GetRGBA())
    frame:SetBackdropColor(private.defaults.colors[bgColor or "bgColorDark"]:GetRGBA())
end

function private:AddBackdropTexture(frame, bgColor)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(private.defaults.colors[bgColor or "bgColorDark"]:GetRGBA())

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
    local LDD = LibStub("LibDropDown")
    local dropdown = LDD:NewButton(parent, "LibDropDownTest")
    dropdown:SetStyle(addonName) -- can be omitted, defaults to 'DEFAULT'
    dropdown:SetJustifyH("RIGHT")
    dropdown:SetText("TestDropDown")
    dropdown:SetCheckAlignment("LEFT")

    -- Methods
    function dropdown:Initialize()
        initializer(self)
    end

    function dropdown:SetValue(...)
        setter(...)
    end

    -- Strip and redraw background textures
    dropdown.Left:SetTexture()
    dropdown.Middle:SetTexture()
    dropdown.Right:SetTexture()

    dropdown.border = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.border:SetColorTexture(private.defaults.colors.borderColor:GetRGBA())
    dropdown.border:SetAllPoints(dropdown)

    local r, g, b = private.defaults.colors.bgColorLight:GetRGBA()
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
    dropdown.Button:SetPoint("RIGHT", 0, 0)
    dropdown.Text:ClearAllPoints()
    dropdown.Text:SetPoint("LEFT", 4, 0)
    dropdown.Text:SetPoint("TOPRIGHT", dropdown.Button, "TOPLEFT", -2, 0)
    dropdown.Text:SetPoint("BOTTOM", dropdown.Button, "BOTTOM", 0, 0)

    -- Update font
    dropdown.Text:SetFontObject(private.defaults.fonts.normalFont)

    return dropdown
end

function private:CreateFontString(parent, justifyH, justifyV, isHeader)
    if not parent or not parent.CreateFontString then
        return
    end

    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(private.defaults.fonts[isHeader and "headerFont" or "normalFont"])
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

    frame.resizer:SetScript("OnMouseDown", function(self)
        self:GetParent():StartSizing("BOTTOMRIGHT")
    end)

    frame.resizer:SetScript("OnMouseUp", function(self)
        self:GetParent():StopMovingOrSizing()
    end)
end
