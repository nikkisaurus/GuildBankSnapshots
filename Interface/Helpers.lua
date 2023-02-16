local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:AddBackdrop(frame, bgColor)
    if not frame then
        return
    end

    local color = bgColor == "random" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[bgColor or "bgColor"]

    if frame.SetBackdrop then
        frame:SetBackdrop(private.interface.backdrop)
        frame:SetBackdropBorderColor(private.interface.colors.borderColor:GetRGBA())
        frame:SetBackdropColor(color:GetRGBA())
    else
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(frame)
        bg:SetColorTexture(color:GetRGBA())

        return bg
    end
end

function private:AddSpecialFrame(frame)
    tinsert(UISpecialFrames, frame:GetName())
end

function private:ClearTooltip()
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
            -- darkest > lightest
            elementColor = CreateColor(0.05, 0.05, 0.05, 1),
            bgColor = CreateColor(0.1, 0.1, 0.1, 1),
            insetColor = CreateColor(0.15, 0.15, 0.15, 1),
            highlightColor = CreateColor(0.3, 0.3, 0.3, 1),
        },
    }

    LibStub("LibDropDown"):RegisterStyle(addonName, {
        backdrop = private.interface.backdrop,
        backdropBorderColor = private.interface.colors.borderColor,
        backdropColor = private.interface.colors.insetColor,
    })
end

function private:InitializeTooltip(frame, anchor, callback, ...)
    GameTooltip:SetOwner(frame, anchor or "ANCHOR_CURSOR")
    if type(callback) == "function" then
        callback(...)
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
