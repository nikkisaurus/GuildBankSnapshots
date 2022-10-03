local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0", true)
addon.export = { pending = {} }

local function GetGuildList()
	local guilds, order = {}, {}

	for guildID, guildInfo in addon.pairs(addon.db.global.guilds) do
		guilds[guildID] = addon:GetGuildDisplayName(guildID)
		tinsert(order, guildID)
	end

	return guilds, order
end

function addon:GetExportOptions()
	local options = {
		selectScans = {
			order = 1,
			type = "execute",
			name = L["Select Scans"],
			func = function()
				addon:SelectExportScans()
			end,
		},
	}

	return options
end

function addon:SelectExportScans()
	ACD:Close(addonName)

	-- Main frame
	local frame = AceGUI:Create("Frame")
	frame:SetLayout("Flow")
	frame:SetTitle(format("%s %s", L.addon, L["Export"]))

	frame:SetCallback("OnClose", function()
		ACD:Open(addonName)
	end)

	local selectScansContainer = AceGUI:Create("InlineGroup")
	selectScansContainer:SetFullWidth(true)
	selectScansContainer:SetFullHeight(true)
	selectScansContainer:SetLayout("Fill")
	selectScansContainer:SetTitle("")
	frame:AddChild(selectScansContainer)

	local selectScanFrame = AceGUI:Create("ScrollFrame")
	selectScanFrame:SetLayout("Flow")
	selectScansContainer:AddChild(selectScanFrame)

	-- Variables needed for selectGuild
	local selectAll = AceGUI:Create("Button")
	local deselectAll = AceGUI:Create("Button")
	local pendingScansContainer = AceGUI:Create("InlineGroup")
	local pendingScans = AceGUI:Create("ScrollFrame")
	local start = AceGUI:Create("Button")
	local cancel = AceGUI:Create("Button")

	-- Guild selection
	local selectGuild = AceGUI:Create("Dropdown")
	selectGuild:SetFullWidth(true)
	selectGuild:SetLabel(L["Guild"])
	selectGuild:SetList(GetGuildList())
	selectScanFrame:AddChild(selectGuild)

	-- Load pending scans
	selectGuild:SetCallback("OnValueChanged", function(self)
		addon.export.guildID = self.value

		-- Update widget
		selectAll:SetDisabled(true)
		deselectAll:SetDisabled(true)
		start:SetDisabled(true)
		cancel:Fire("OnClick", "LeftButton")
		pendingScans:ReleaseChildren()

		-- Throttle loading scans so the client doesn't hang up with large databases
		local i = 1
		addon.tpairs(
			addon.db.global.guilds[self:GetValue()].scans,
			function(scans, scanID)
				-- Update loading progress
				pendingScansContainer:SetTitle(format("%s (%d%%)", L["Loading scans"], (i / addon.tcount(scans)) * 100))

				-- Create checkbox
				if scans[scanID] then
					local scan = AceGUI:Create("CheckBox")
					scan:SetLabel(date(addon.db.global.settings.preferences.dateFormat, scanID))
					scan:SetUserData("scanID", scanID)
					pendingScans:AddChild(scan)

					scan:SetCallback("OnValueChanged", function(self)
						addon.export.pending[scanID] = self:GetValue() and self or nil
					end)
				end

				-- If scans are finished, remove status from title
				if i == addon.tcount(scans) then
					pendingScansContainer:SetTitle(L["Scans"])
					selectAll:SetDisabled()
					deselectAll:SetDisabled()
					start:SetDisabled()
				end

				i = i + 1
			end,
			0.001,
			nil,
			nil,
			function(a, b)
				return b < a
			end
		)
	end)

	-- Selection buttons
	selectAll:SetText(L["Select All"])
	selectAll:SetDisabled(true)
	selectScanFrame:AddChild(selectAll)

	selectAll:SetCallback("OnClick", function()
		for _, scan in pairs(pendingScans.children) do
			scan:SetValue(true)
			addon.export.pending[scan:GetUserData("scanID")] = scan
		end
	end)

	deselectAll:SetText(L["Deselect All"])
	deselectAll:SetDisabled(true)
	selectScanFrame:AddChild(deselectAll)

	deselectAll:SetCallback("OnClick", function()
		for scanID, scan in pairs(addon.export.pending) do
			if scan then
				scan:SetValue(false)
			end
		end
		wipe(addon.export.pending)
	end)

	-- Pending scans
	pendingScansContainer:SetFullWidth(true)
	pendingScansContainer:SetLayout("Fill")
	pendingScansContainer:SetAutoAdjustHeight(false)
	pendingScansContainer:SetTitle("")
	selectScanFrame:AddChild(pendingScansContainer)

	pendingScans:SetLayout("Flow")
	pendingScansContainer:AddChild(pendingScans)

	-- Variables needed for start
	local copyBox = AceGUI:Create("EditBox")

	-- Process buttons
	start:SetText(L["Start"])
	start:SetDisabled(true)
	selectScanFrame:AddChild(start)

	-- Process scans
	start:SetCallback("OnClick", function()
		copyBox:SetDisabled(true)
		copyBox:SetText("")
		cancel:SetDisabled(false)
		addon.export.processing = true

		if not addon.export.guildID then
			return
		end
		if addon.tcount(addon.export.pending) == 0 then
			cancel:Fire("OnClick", "LeftButton")
			return
		end

		local i = 1
		local msg = ""
		addon.tpairs(
			addon.export.pending,
			function(scans, scanID)
				if not addon.export.processing then
					return
				end

				-- Update labels
				copyBox:SetLabel(format("%s (%d%%)", L["Processing"], (i / addon.tcount(scans)) * 100))

				if addon.db.global.guilds[addon.export.guildID].scans[scanID] then
					local guild = addon.db.global.guilds[addon.export.guildID]
					local guildName = addon:GetGuildDisplayName(addon.export.guildID)
					local scanDate = date(addon.db.global.settings.preferences.dateFormat, scanID)

					-- Scan item transactions
					for tab, tabInfo in pairs(addon.db.global.guilds[addon.export.guildID].scans[scanID].tabs) do
						if not addon.export.processing then
							return
						end
						for _, transaction in pairs(tabInfo.transactions) do
							if not addon.export.processing then
								return
							end

							local transactionInfo = addon:GetTransactionInfo(transaction)

							-- transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour
							local line = {}
							tinsert(line, guildName)
							tinsert(line, scanDate)
							tinsert(line, guild.tabs[tab].name)
							tinsert(line, transactionInfo.transactionType)
							tinsert(line, transactionInfo.name or "")
							tinsert(line, transactionInfo.itemLink)
							tinsert(line, transactionInfo.count)
							tinsert(
								line,
								guild.tabs[transactionInfo.moveOrigin] and guild.tabs[transactionInfo.moveOrigin].name
									or ""
							)
							tinsert(
								line,
								guild.tabs[transactionInfo.moveDestination]
										and guild.tabs[transactionInfo.moveDestination].name
									or ""
							)
							tinsert(
								line,
								date(
									addon.db.global.settings.preferences.dateFormat,
									addon:GetTransactionDate(
										scanID,
										transactionInfo.year,
										transactionInfo.month,
										transactionInfo.day,
										transactionInfo.hour
									)
								)
							)
							tinsert(line, addon:GetTransactionLabel(transaction))
							line = table.concat(line, addon.db.global.settings.preferences.exportDelimiter)

							msg = format("%s%s\n", msg, line)
						end
					end

					-- Scan money transactions
					for _, transaction in
						pairs(addon.db.global.guilds[addon.export.guildID].scans[scanID].moneyTransactions)
					do
						if not addon.export.processing then
							return
						end

						local transactionInfo = addon:GetMoneyTransactionInfo(transaction)

						-- transactionType, name, amount, year, month, day, hour
						local line = {}
						tinsert(line, guildName)
						tinsert(line, scanDate)
						tinsert(line, L["Money"])
						tinsert(line, transactionInfo.transactionType)
						tinsert(line, transactionInfo.name or "")
						tinsert(line, "")
						tinsert(line, GetCoinText(transactionInfo.amount, " "))
						tinsert(line, "")
						tinsert(line, "")
						tinsert(
							line,
							date(
								addon.db.global.settings.preferences.dateFormat,
								addon:GetTransactionDate(
									scanID,
									transactionInfo.year,
									transactionInfo.month,
									transactionInfo.day,
									transactionInfo.hour
								)
							)
						)
						tinsert(line, addon:GetMoneyTransactionLabel(transaction))
						line = table.concat(line, addon.db.global.settings.preferences.exportDelimiter)

						msg = format("%s%s\n", msg, line)
					end
				end

				if i == addon.tcount(addon.export.pending) then
					addon.export.processing = nil

					cancel:SetDisabled(true)
					copyBox:SetDisabled(false)

					copyBox:SetLabel("")

					local header = table.concat({
						"guildName",
						"snapshotDate",
						"tabName",
						"transactionType",
						"name",
						"itemName",
						"itemMoneyCount",
						"moveTabName1",
						"moveTabName2",
						"transactionDate",
						"transactionLine",
					}, addon.db.global.settings.preferences.exportDelimiter)
					copyBox:SetText(format("%s\n%s", header, msg))
				else
					i = i + 1
				end
			end,
			0.001,
			nil,
			nil,
			function(a, b)
				return b < a
			end
		)
	end)

	cancel:SetText(L["Cancel"])
	cancel:SetDisabled(true)
	selectScanFrame:AddChild(cancel)

	cancel:SetCallback("OnClick", function(self)
		addon.export.processing = nil
		copyBox:SetText("")
		copyBox:SetLabel("")
		copyBox:SetDisabled(true)
		self:SetDisabled(true)
	end)

	-- Copy box
	copyBox:SetLabel("")
	copyBox:SetFullWidth(true)
	copyBox:DisableButton(true)
	copyBox:SetDisabled(true)
	selectScanFrame:AddChild(copyBox)
end
