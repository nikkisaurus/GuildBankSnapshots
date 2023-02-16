local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:InitializeDefaults()
    private.defaults = {
        backdrop = {
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        },
        colors = {
            borderColor = CreateColor(0, 0, 0, 1),
            bgColor = CreateColor(26 / 255, 26 / 255, 26 / 255, 1),
            insetColor = CreateColor(0.15, 0.15, 0.15, 1),
            elementColor = CreateColor(0.05, 0.05, 0.05, 1),
            highlightColor = CreateColor(0.3, 0.3, 0.3, 1),

            bgColorLight = CreateColor(0.1, 0.1, 0.1, 1),
            bgColorDark = CreateColor(0, 0, 0, 0.5),
            emphasizeColor = CreateColor(1, 0.82, 0, 0.5),
        },
    }

    local normalFont = CreateFont(addonName .. "NormalFont")
    normalFont:SetFont("Fonts\\2002.TTF", 10, "OUTLINE")
    normalFont:SetTextColor(1, 1, 1, 1)

    local normalFontLarge = CreateFont(addonName .. "NormalFontLarge")
    normalFontLarge:SetFont("Fonts\\2002.TTF", 12, "OUTLINE")
    normalFontLarge:SetTextColor(1, 1, 1, 1)

    local emphasizedFont = CreateFont(addonName .. "EmphasizedFont")
    emphasizedFont:SetFont("Fonts\\2002.TTF", 10, "OUTLINE")
    emphasizedFont:SetTextColor(1, 0.82, 0, 1)

    local emphasizedFontLarge = CreateFont(addonName .. "EmphasizedFontLarge")
    emphasizedFontLarge:SetFont("Fonts\\2002.TTF", 12, "OUTLINE")
    emphasizedFontLarge:SetTextColor(1, 0.82, 0, 1)

    private.defaults.fonts = {
        normalFont = normalFont,
        normalFontLarge = normalFontLarge,
        emphasizedFont = emphasizedFont,
        emphasizedFontLarge = emphasizedFontLarge,
    }

    LibStub("LibDropDown"):RegisterStyle(addonName, {
        backdrop = private.defaults.backdrop,
        backdropColor = private.defaults.colors.bgColorLight,
        backdropBorderColor = private.defaults.colors.borderColor,
    })
end

function private:GetGuildDisplayName(guildID)
    local guild, realm, faction = string.match(guildID, "(.+)%s%-%s(.*)%s%((.+)%)")
    local guildFormat = private.db.global.settings.preferences.guildFormat
    guildFormat = string.gsub(guildFormat, "%%g", guild)
    guildFormat = string.gsub(guildFormat, "%%r", realm)
    guildFormat = string.gsub(guildFormat, "%%f", faction)
    guildFormat = string.gsub(guildFormat, "%%F", strsub(faction, 1, 1)) -- shortened faction

    return guildFormat
end

function private:GetTabName(guildID, tabID)
    if tabID == MAX_GUILDBANK_TABS + 1 then
        return L["Money Tab"]
    end
    return private.db.global.guilds[guildID].tabs[tabID] and private.db.global.guilds[guildID].tabs[tabID].name or L["Tab"] .. " " .. tabID
end

function private:GetTransactionDate(scanTime, year, month, day, hour)
    local sec = (hour * 60 * 60) + (day * 60 * 60 * 24) + (month * 60 * 60 * 24 * 31) + (year * 60 * 60 * 24 * 31 * 12)
    return scanTime - sec
end
