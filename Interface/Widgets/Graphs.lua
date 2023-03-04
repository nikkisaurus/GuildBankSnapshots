local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local LibGraph = LibStub("LibGraph-2.0")

local numPies = 0

function GuildBankSnapshotsPieGraph_OnLoad(frame)
    frame = private:MixinContainer(frame)
    frame:InitScripts({
        OnAcquire = function(self)
            self:ResetPie()

            self.label:Fire("OnAcquire")

            self:SetLabelFont(GameFontHighlightSmall, private.interface.colors.white)

            self:SetSize(150, 150)
        end,

        OnSizeChanged = function(self, width, height)
            self.pie:SetWidth(width)
            self.pie:SetHeight(width)
            self.pie:SetPoint("TOP")
        end,
    })

    -- Elements
    numPies = numPies + 1
    frame.pie = LibGraph:CreateGraphPieChart(addonName .. "PieGraph" .. numPies, frame, "TOPLEFT", "TOPLEFT", 0, 0, 150, 150)

    frame.label = frame:Acquire("GuildBankSnapshotsFontFrame")
    frame.label:SetPoint("TOPLEFT", frame.pie, "BOTTOMLEFT", 0, -5)
    frame.label:SetPoint("TOPRIGHT", frame.pie, "BOTTOMRIGHT", 0, -5)

    frame.legend = frame:Acquire("GuildBankSnapshotsGroup")
    frame.legend.bg, frame.legend.border = private:AddBackdrop(frame.legend)
    frame.legend:SetPoint("TOPLEFT", frame.label, "BOTTOMLEFT", 0, 0)
    frame.legend:SetPoint("TOPRIGHT", frame.label, "BOTTOMRIGHT", 0, 0)
    frame.legend:SetSize(200, 20)
    frame.legend:SetPadding(5, 5)
    frame.legend:SetSpacing(0)

    -- Methods
    function frame:AddPie(legendKey, ...)
        local color = self.pie:AddPie(...)
        self:UpdateLegend(legendKey, select(1, ...), color)
    end

    function frame:CompletePie(legendKey, ...)
        local color = self.pie:CompletePie(...)
        self:UpdateLegend(legendKey, 100, color)
    end

    function frame:ResetPie()
        self.pie:ResetPie()
        self.legend:ReleaseChildren()
    end

    function frame:SetLabel(text)
        self.label:SetText(text)
    end

    function frame:SetLabelFont(fontObject, color)
        self.label:SetFontObject(fontObject or GameFontHighlightSmall)
        self.label:SetTextColor((color and color or private.interface.colors.white):GetRGBA())
    end

    function frame:UpdateLegend(legendKey, percent, color)
        local r, g, b, a = unpack(color)
        local key = self.legend:Acquire("GuildBankSnapshotsFontFrame")
        key:SetUserData("width", "full")
        key:Justify("LEFT")
        key:SetText(format("%s - %d%%", legendKey, percent))
        key:SetTextColor(r, g, b, a or 1)
        self.legend:AddChild(key)

        self.legend:DoLayout()

        self:SetHeight(self.pie:GetHeight() + self.label:GetHeight() + self.legend:GetHeight() + 5)
    end
end
