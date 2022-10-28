local lib = LibStub:NewLibrary("LibAddonUtils-1.0", 2)

if not lib then
  return
end

if not lib.frame then
    lib.frame = CreateFrame("Frame")
end

lib.frame:SetScript("OnEvent", function(self, event, ...)
    return self[event] and self[event](self, event, ...)
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- Numbers

local numSuffixes = {
   [3] = "K",
   [6] = "M",
   [9] = "B",
   [12] = "t",
   [15] = "q",
   [18] = "Q",
   [21] = "s",
   [24] = "S",
   [27] = "o",
   [30] = "n",
   [33] = "d",
   [36] = "U",
   [39] = "D",
   [42] = "T",
   [45] = "Qt",
   [48] = "Qd",
   [51] = "Sd",
   [54] = "St",
   [57] = "O",
   [60] = "N",
   [63] = "v",
   [66] = "c",
}

function lib.iformat(i, fType)
    if not i then return end
    local orig = i

    if fType == 1 then
        local i, j, minus, integer, fraction = string.format("%f", i):find('([-]?)(%d+)([.]?%d*)')
        return string.format("%s%s%s", minus, integer:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), (tonumber(fraction) > 0 and fraction or "")), orig
    elseif fType == 2 then
        i = string.format("%f", i)
        local mod = tonumber(strlen(strsplit(".", i)) - 1) - math.fmod(tonumber(strlen(strsplit(".", i)) - 1), 3)

        if mod == 0 then
            return tonumber(i), orig
        elseif mod > 66 then
            mod = 66
        end

        local int, dec = strsplit(".", tostring(i / 10^mod))
        dec = dec and lib.round(dec / 10^(strlen(dec) - 1), 0) or 0

        if dec == 10 then
            return lib.iformat(tonumber((int + 1) * 10^mod), 2), orig
        end

        local suffix = numSuffixes[mod]
        return string.format("%s%s", tonumber(int .. "." .. dec), suffix), orig
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function lib.round(num, decimals)
    return tonumber((("%%.%df"):format(decimals)):format(num))
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- Tables

local keys = {}
function lib.GetTableKey(tbl, value)
    wipe(keys)
    for k, v in pairs(tbl) do
        if v == value then
            tinsert(keys, k)
        end
    end
    return unpack(keys)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function lib.pairs(tbl, func)
    local a = {}

    for n in pairs(tbl) do
        tinsert(a, n)
    end

    sort(a, func)

    local i = 0
    local iter = function ()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], tbl[a[i]]
        end
    end

    return iter
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function lib.printt(tbl, cond)
    if type(tbl) == "table" then
        for k, v in lib.pairs(tbl) do
            if cond == 1 then
                print(k)
            elseif cond == 2 then
                print(v)
            else
                print(k, v)
            end
        end

        return true
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function lib.tcount(tbl, key, value)
    local counter = 0
    for k, v in pairs(tbl) do
        if (key and k == key) or (value and v[value]) or (not key and not value) then
            counter = counter + 1
        end
    end

    return counter
end
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local keys = {}
function lib.tpairs(tbl, callback, duration, key, value)
    wipe(keys)
    for k, v in pairs(tbl) do
        if (key and k == key) or (value and v[value]) or (not key and not value) then
            tinsert(keys, k)
        end
    end

    local index = 0
    local ticker = C_Timer.NewTicker(math.max(duration or .00001, .00001), function(self)
        index = index + 1
        if index > #keys then
            self:Cancel()
            return
        end
        callback(tbl, keys[index])
    end)
end
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function lib.unpack(tbl, default)
    if type(tbl) == "table" then
        if not unpack(tbl) then
            local newTbl = {}
            for k, v in lib.pairs(tbl) do
                tinsert(newTbl, v)
            end
            return unpack(newTbl)
        else
            return unpack(tbl)
        end
    elseif default then
        return unpack(default)
    else
        return tbl
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- Caching

local cache = {}
function lib.CacheItem(itemID, callback, ...)
    local args = {...}
    if type(itemID) == "table" then
        itemID = callback
        if callback then
            callback = args[1]
            args[1] = nil
        end
    end

    itemID = GetItemInfoInstant(itemID)
    if itemID and not GetItemInfo(itemID) then
        tinsert(cache, {itemID, callback, lib.unpack(args)})
        return false
    elseif callback then
        callback(lib.unpack(args))
        return true
    end
end

lib.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
function lib.frame:GET_ITEM_INFO_RECEIVED(_, itemID, success)
    if (not itemID or not success) then return end

    local itemName, itemLink = GetItemInfo(itemID)
    for k, v in pairs(cache) do
        if v[1] == itemName or v[1] == itemLink or v[1] == itemID then
            lib:CacheItem(lib.unpack(cache[k]))
            cache[k] = nil
        end
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- Strings

-- Color codes courtesy of:
-- http://www.ac-web.org/forums/showthread.php?105949-Lua-Color-Codes
lib.ChatColors = {
    ["LIGHTRED"] = "|cffff6060",
    ["LIGHTBLUE"] = "|cff00ccff",
    ["TORQUISEBLUE"] = "|cff00C78C",
    ["SPRINGGREEN"] = "|cff00FF7F",
    ["GREENYELLOW"] = "|cffADFF2F",
    ["BLUE"] = "|cff0000ff",
    ["PURPLE"] = "|cffDA70D6",
    ["GREEN"] = "|cff00ff00",
    ["RED"] = "|cffff0000",
    ["GOLD"] = "|cffffcc00",
    ["GOLD2"] = "|cffFFC125",
    ["GREY"] = "|cff888888",
    ["WHITE"] = "|cffffffff",
    ["SUBWHITE"] = "|cffbbbbbb",
    ["MAGENTA"] = "|cffff00ff",
    ["YELLOW"] = "|cffffff00",
    ["ORANGEY"] = "|cffFF4500",
    ["CHOCOLATE"] = "|cffCD661D",
    ["CYAN"] = "|cff00ffff",
    ["IVORY"] = "|cff8B8B83",
    ["LIGHTYELLOW"] = "|cffFFFFE0",
    ["SEXGREEN"] = "|cff71C671",
    ["SEXTEAL"] = "|cff388E8E",
    ["SEXPINK"] = "|cffC67171",
    ["SEXBLUE"] = "|cff00E5EE",
    ["SEXHOTPINK"] = "|cffFF6EB4",
}

function lib.ColorFontString(str, color)
    return string.format("%s%s|r", lib.ChatColors[strupper(color)], str)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- Embeds

lib.mixinTargets = lib.mixinTargets or {}
local mixins = {"iformat", "round", "GetTableKey", "pairs", "printt", "tcount", "tpairs", "unpack", "CacheItem", "ColorFontString"}

function lib:Embed(target)
  for _,name in pairs(mixins) do
    target[name] = lib[name]
  end
  lib.mixinTargets[target] = true
end

for target,_ in pairs(lib.mixinTargets) do
  lib:Embed(target)
end