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

function private:AddBackdrop(frame, options)
    if not frame then
        return
    end

    options = type(options) == "table" and options or {}
    -- options = options and options or {}
    local bg, border, highlight
    local bgColor = options.bgColor == "r" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[options.bgColor or "darker"]
    local borderColor = options.borderColor == "r" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[options.borderColor or "black"]
    local borderSize = options.borderSize or 1
    local highlightColor = options.highlightColor == "r" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[options.highlightColor or "lightest"]
    local hasBorder = options.hasBorder
    local hasHighlight = options.hasHighlight

    bg = frame:CreateTexture(nil, "BORDER")
    bg:SetColorTexture(bgColor:GetRGBA())

    if hasBorder ~= false then -- default has border, thus we want to draw border when hasBorder == nil
        border = frame:CreateTexture(nil, "BACKGROUND")
        border:SetColorTexture(borderColor:GetRGBA())
        border:SetAllPoints(frame)
        bg:SetPoint("TOPLEFT", borderSize, -borderSize)
        bg:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
    else
        bg:SetAllPoints(frame)
    end

    if hasHighlight == true then
        highlight = frame:CreateTexture(nil, "ARTWORK")
        highlight:SetColorTexture(highlightColor:GetRGBA())
        highlight:SetAllPoints(bg)
    end

    return bg, border, highlight
end

function private:GetInterfaceFlairColor()
    return private.interface.colors[private:UseClassColor() and "class" or "flair"]
end

function private:HideTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
end

function private:InitializeInterface()
    local symbolFont = CreateFont("GuildBankSnapshotsSymbolFont")
    symbolFont:SetFont("Fonts/ARIALN.TTF", 10, "OUTLINE")
    symbolFont:SetTextColor(1, 1, 1, 1)

    local symbolFontDisabled = CreateFont("GuildBankSnapshotsSymbolFontDisabled")
    symbolFontDisabled:SetFontObject(symbolFont)
    symbolFontDisabled:SetTextColor(1, 1, 1, 0.25)

    local r, g, b = private:GetClassColor()

    private.interface = {
        backdrop = {
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        },
        colors = {
            darker = CreateColor(0.05, 0.05, 0.05, 1),
            dark = CreateColor(0.1, 0.1, 0.1, 1),
            normal = CreateColor(0.15, 0.15, 0.15, 1),
            light = CreateColor(0.2, 0.2, 0.2, 1),
            lighter = CreateColor(0.25, 0.25, 0.25, 1),
            lightest = CreateColor(0.3, 0.3, 0.3, 1),

            dimmedBlack = CreateColor(0, 0, 0, 0.25),
            black = CreateColor(0, 0, 0, 1),

            dimmedWhite = CreateColor(1, 1, 1, 0.25),
            lightWhite = CreateColor(1, 1, 1, 0.5),
            white = CreateColor(1, 1, 1, 1),

            dimmedClass = CreateColor(r, g, b, 0.25),
            lightClass = CreateColor(r, g, b, 0.5),
            class = CreateColor(r, g, b, 1),

            dimmedFlair = CreateColor(1, 0.82, 0, 0.25),
            lightFlair = CreateColor(1, 0.82, 0, 0.5),
            flair = CreateColor(1, 0.82, 0, 1),
        },
        fonts = {
            symbolFont = symbolFont,
            symbolFontDisabled = symbolFontDisabled,
        },
    }
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

    local color = color == "random" and CreateColor(fastrandom(), fastrandom(), fastrandom()) or private.interface.colors[color or "dark"]

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

function private:UseClassColor()
    return private.db.global.preferences.useClassColor
end
