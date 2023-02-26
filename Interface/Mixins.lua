local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--*----------[[ Mixins ]]----------*--
local ContainerMixin = {}

function ContainerMixin:Acquire(template, parent)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")

    local object = self.pool:Acquire(template)
    assert(object.Fire, "ContainerMixin: template '" .. template .. "' is not initialized as a widget")
    object:Fire("OnAcquire")
    object:SetParent(parent or self)
    object:Show()

    return object
end

function ContainerMixin:EnumerateActive()
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    return self.pool:EnumerateActive()
end

function ContainerMixin:EnumerateActiveByTemplate(template)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    return self.pool:EnumerateActiveByTemplate(template)
end

function ContainerMixin:Release(object)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    self.pool:Release(object)
end

function ContainerMixin:ReleaseAll()
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    self.pool:ReleaseAll()
end

function ContainerMixin:ReleaseAllByTemplate(template)
    assert(self.pool, "ContainerMixin: collection pool has not been initialized")
    self.pool:ReleaseAllByTemplate(template)
end

function ContainerMixin:SetAutoHeight(autoHeight)
    self.autoHeight = autoHeight
end

function private:MixinContainer(tbl)
    tbl = private:MixinWidget(tbl)
    tbl = private:MixinCollection(tbl)
    tbl = Mixin(tbl, ContainerMixin)
    return tbl
end

-----------------------

local TextMixin = {}

local function TextMixin_Validate(self)
    return assert(self.text, "TextMixin: text has not been initialized")
end

function TextMixin:GetStringWidth()
    return self.text:GetStringWidth()
end

function TextMixin:GetText()
    return self.text:GetText()
end

function TextMixin:Justify(justifyH, justifyV)
    TextMixin_Validate(self)
    self.text:SetJustifyH(justifyH or "CENTER")
    self.text:SetJustifyV(justifyV or "MIDDLE")
end

function TextMixin:SetAutoHeight(autoHeight)
    TextMixin_Validate(self)
    self.text:SetWordWrap(autoHeight)
    self.autoHeight = autoHeight
end

function TextMixin:SetFontObject(fontObject)
    TextMixin_Validate(self)
    self.text:SetFontObject(fontObject or GameFontHighlightSmall)
end

function TextMixin:SetPadding(x, y)
    TextMixin_Validate(self)
    self.text:ClearAllPoints()
    self.text:SetPoint("TOPLEFT", self, "TOPLEFT", x, -y)
    self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -x, y)
end

function TextMixin:SetText(text)
    TextMixin_Validate(self)
    self.text:SetText(text or "")
    if self.autoHeight then
        self:SetHeight(self.text:GetStringHeight() + 8)
    end
end

function TextMixin:SetTextColor(...)
    self.text:SetTextColor(...)
end

function TextMixin:SetWordWrap(canWordWrap)
    TextMixin_Validate(self)
    self.text:SetWordWrap(canWordWrap or "")
end

function private:MixinText(tbl)
    tbl = private:MixinWidget(tbl)
    tbl = Mixin(tbl, TextMixin)
    return tbl
end

-----------------------

local WidgetMixin = {}
local validScripts = {
    OnClear = true,
    OnRelease = true,
}

function WidgetMixin:ClearBackdrop()
    if self.bg then
        self.bg:SetTexture()
    end

    if self.border then
        self.border:SetTexture()
    end
end

function WidgetMixin:Fire(script, ...)
    if script == "OnAcquire" and self.scripts.OnAcquire then
        self.scripts.OnAcquire(self)
    else
        assert(self.scripts, "WidgetMixin: Scripts have not been initialized")

        if self.scripts[script] then
            self.scripts[script](self, ...)
        end

        if self.handlers[script] then
            self.handlers[script](self, ...)
        end
    end
end

function WidgetMixin:InitializeScripts()
    for script, callback in pairs(self.scripts) do
        local success, err = pcall(self.SetScript, self, script, callback)
        if success then
            self:SetScript(script, callback)
        end
    end
end

function WidgetMixin:InitScripts(scripts)
    self.handlers = {}
    self.scripts = scripts or {}

    self:InitializeScripts()
end

function WidgetMixin:Reset()
    self:Fire("OnRelease")

    for script, callback in pairs(self.handlers) do
        local success, err = pcall(self.SetScript, self, script, callback)
        if success then
            self:SetScript(script, nil)
        end
    end

    wipe(self.handlers)

    self:ClearAllPoints()
    self:Hide()
end

function WidgetMixin:SetBackdropColor(bgColor, highlightColor)
    if bgColor then
        self.bg:SetColorTexture(bgColor:GetRGBA())
    end

    if highlightColor then
        self.highlight:SetColorTexture(highlightColor:GetRGBA())
    end
end

function WidgetMixin:SetCallback(script, callback, init)
    local success, err = pcall(self.SetScript, self, script, callback)
    assert(success or validScripts[script], "WidgetMixin: invalid script")
    assert(type(callback) == "function", callback and "WidgetMixin: callback must be a function" or "WidgetMixin: attempting to create empty callback")

    self.handlers[script] = callback
    local existingScript = self.scripts[script]
    if success then
        self:SetScript(script, function(...)
            if existingScript then
                existingScript(...)
            end

            callback(...)
        end)
    end

    if init then
        callback(self)
    end
end

function WidgetMixin:ShowTooltip(anchor, callback)
    assert(type(callback) == "function", "WidgetMixin: ShowTooltip callback must be a function")
    private:InitializeTooltip(self, anchor or "ANCHOR_RIGHT", callback)
end

function WidgetMixin:UnregisterCallback(script)
    assert(self.handlers[script], "WidgetMixin: script '" .. "' is not registered")

    local existingScript = self.scripts[script]
    self:SetScript(script, existingScript)
end

function private:MixinWidget(tbl)
    tbl = Mixin(tbl, WidgetMixin)
    tbl:InitScripts()
    return tbl
end

--*----------[[ Collection pool ]]----------*--
local function Resetter(_, self)
    if self.Reset then
        self:Reset()
    else
        self:ClearAllPoints()
        self:Hide()
    end
end

function private:MixinCollection(tbl, parent)
    tbl.pool = CreateFramePoolCollection()
    tbl.pool:CreatePool("Button", parent or tbl, "GuildBankSnapshotsButton", Resetter)
    tbl.pool:CreatePool("CheckButton", parent or tbl, "GuildBankSnapshotsCheckButton", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsCheckButtonFrame", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsContainer", Resetter)
    tbl.pool:CreatePool("Button", parent or tbl, "GuildBankSnapshotsDropdownButton", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsDropdownFrame", Resetter)
    tbl.pool:CreatePool("Button", parent or tbl, "GuildBankSnapshotsDropdownListButton", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsDualSlider", Resetter)
    tbl.pool:CreatePool("EditBox", parent or tbl, "GuildBankSnapshotsEditBox", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsEditBoxFrame", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsFontFrame", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsGroup", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsListScrollFrame", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsMinMaxFrame", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsScrollFrame", Resetter)
    tbl.pool:CreatePool("Slider", parent or tbl, "GuildBankSnapshotsSlider", Resetter)
    tbl.pool:CreatePool("Frame", parent or tbl, "GuildBankSnapshotsSliderFrame", Resetter)
    tbl.pool:CreatePool("Button", parent or tbl, "GuildBankSnapshotsTabButton", Resetter)
    tbl.pool:CreatePool("Button", parent or tbl, "GuildBankSnapshotsTableCell", Resetter)
    tbl.pool:CreatePool("Button", parent or tbl, "GuildBankSnapshotsTableSorter", Resetter)
    return tbl
end
