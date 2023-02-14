local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:AddBackdrop(frame)
    if not frame or not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop(private.defaults.gui.backdrop)
    frame:SetBackdropBorderColor(unpack(private.defaults.gui.borderColor))
    frame:SetBackdropColor(unpack(private.defaults.gui.bgColor))
end

function private:ClearTooltip()
    GameTooltip:ClearLines()
    GameTooltip:Hide()
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
