local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private.NullFunc()
    return
end

function private:strcheck(str)
    -- Validates string exists and is not empty
    return str and str ~= ""
end

function private:AddBackdrop(frame, bgColor, borderColor, borderSize, noBorder)
    if not frame then
        return
    end

    local backdrop = private.interface.backdrop
    if noBorder then
        backdrop.edgeFile = nil
        backdrop.edgeSize = nil
    else
        backdrop.edgeSize = borderSize or backdrop.edgeSize
    end

    bgColor = bgColor == "random" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[bgColor or "bgColor"]
    borderColor = borderColor == "random" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[borderColor or "borderColor"]

    if frame.SetBackdrop then
        frame:SetBackdrop(backdrop)
        frame:SetBackdropColor(bgColor:GetRGBA())
        if not noBorder then
            frame:SetBackdropBorderColor(borderColor:GetRGBA())
        end
    else
        local border
        if not noBorder then
            border = frame:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints(frame)
            border:SetColorTexture(borderColor:GetRGBA())
        end

        local bg = frame:CreateTexture(nil, "ARTWORK")
        if noBorder then
            bg:SetAllPoints(frame)
        else
            bg:SetPoint("TOPLEFT", backdrop.edgeSize, -backdrop.edgeSize)
            bg:SetPoint("BOTTOMRIGHT", -backdrop.edgeSize, backdrop.edgeSize)
        end
        bg:SetColorTexture(bgColor:GetRGBA())

        return bg, border
    end
end

function private:AddSpecialFrame(frame)
    tinsert(UISpecialFrames, frame:GetName())
end

function private:ClearTooltip()
    private:HideTooltip()
end

function private:HideTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

function private:InitializeDataProvider(scrollBox, callback)
    scrollBox:SetDataProvider(function(provider)
        if type(callback) == "function" then
            callback(provider)
        end
    end)
end

function private:InitializeInterface()
    private.interface = {
        backdrop = {
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        },
        colors = {
            borderColor = CreateColor(0, 0, 0, 1),
            emphasizeColor = CreateColor(1, 0.82, 0, 0.5),
            elementColor = CreateColor(0.05, 0.05, 0.05, 1),
            bgColor = CreateColor(0.1, 0.1, 0.1, 1),
            insetColor = CreateColor(0.15, 0.15, 0.15, 1),
            highlightColor = CreateColor(0.3, 0.3, 0.3, 1),
            fontColor = CreateColor(1, 1, 1, 1),
            emphasizedFontColor = CreateColor(1, 0.82, 0, 1),
        },
    }

    -- LibStub("LibDropDown"):RegisterStyle(addonName, {
    --     backdrop = private.interface.backdrop,
    --     backdropBorderColor = private.interface.colors.borderColor,
    --     backdropColor = private.interface.colors.insetColor,
    -- })
end

function private:InitializeTooltip(frame, anchor, callback, ...)
    GameTooltip:SetOwner(frame, anchor or "ANCHOR_NONE")
    if type(callback) == "function" then
        callback(frame, ...)
    end
    GameTooltip:Show()
end

function private:SetColorTexture(texture, color)
    if not texture then
        return
    end

    local color = color == "random" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[color or "elementColor"]

    texture:SetColorTexture(color:GetRGBA())
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
