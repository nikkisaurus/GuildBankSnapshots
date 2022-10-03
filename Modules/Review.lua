local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local ACD = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
addon.review = {}

GUILD_BANK_LOG_TIME_PREPEND = GUILD_BANK_LOG_TIME_PREPEND or "|cff009999   "

function addon:GetMoneyTransactionInfo(transaction)
	if not transaction then
		return
	end

	local transactionType, name, amount, year, month, day, hour = select(2, AceSerializer:Deserialize(transaction))

	local info = {
		transactionType = transactionType,
		name = name,
		amount = amount,
		year = year,
		month = month,
		day = day,
		hour = hour,
	}

	return info
end

function addon:GetMoneyTransactionLabel(transaction)
	local info = addon:GetMoneyTransactionInfo(transaction)

	if not info then
		return
	end

	info.name = info.name or UNKNOWN
	info.name = NORMAL_FONT_COLOR_CODE .. info.name .. FONT_COLOR_CODE_CLOSE
	local money = GetDenominationsFromCopper(info.amount)

	local msg
	if info.transactionType == "deposit" then
		msg = format(GUILDBANK_DEPOSIT_MONEY_FORMAT, info.name, money)
	elseif info.transactionType == "withdraw" then
		msg = format(GUILDBANK_WITHDRAW_MONEY_FORMAT, info.name, money)
	elseif info.transactionType == "repair" then
		msg = format(GUILDBANK_REPAIR_MONEY_FORMAT, info.name, money)
	elseif info.transactionType == "withdrawForTab" then
		msg = format(GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, info.name, money)
	elseif info.transactionType == "buyTab" then
		if info.amount > 0 then
			msg = format(GUILDBANK_BUYTAB_MONEY_FORMAT, info.name, money)
		else
			msg = format(GUILDBANK_UNLOCKTAB_FORMAT, info.name)
		end
	elseif info.transactionType == "depositSummary" then
		msg = format(GUILDBANK_AWARD_MONEY_SUMMARY_FORMAT, money)
	end

	if addon.db.global.settings.preferences.dateType == "approx" then
		msg = msg
			and (
				msg
				.. GUILD_BANK_LOG_TIME_PREPEND
				.. date(
					addon.db.global.settings.preferences.dateFormat,
					addon:GetTransactionDate(addon.review.scan or time(), info.year, info.month, info.day, info.hour)
				)
			)
	else
		msg = msg
			and (
				msg
				.. GUILD_BANK_LOG_TIME_PREPEND
				.. format(GUILD_BANK_LOG_TIME, RecentTimeDate(info.year, info.month, info.day, info.hour))
			)
	end

	return msg
end

function addon:GetReviewOptions()
	local moneyTab = MAX_GUILDBANK_TABS + 1

	local options = {
		selectGuild = {
			order = 1,
			type = "select",
			style = "dropdown",
			name = L["Guild"],
			width = "full",
			get = function()
				return addon.review.guildID
					or addon:SelectReviewGuild(addon.db.global.settings.preferences.defaultGuild)
			end,
			set = function(_, guildID)
				addon:SelectReviewGuild(guildID)
			end,
			disabled = function()
				return addon.tcount(addon.db.global.guilds) == 0
			end,
			values = function()
				local guilds = {}

				for guildID, guildInfo in addon.pairs(addon.db.global.guilds) do
					guilds[guildID] = addon:GetGuildDisplayName(guildID)
				end

				return guilds
			end,
		},
		selectScan = {
			order = 2,
			type = "select",
			style = "dropdown",
			name = L["Scan"],
			width = "full",
			get = function()
				return addon.review.scan
			end,
			set = function(_, scanID)
				addon:SelectReviewScan(scanID)
			end,
			disabled = function()
				return not addon.review.guildID or addon.tcount(addon.db.global.guilds[addon.review.guildID].scans) == 0
			end,
			values = function()
				if not addon.review.guildID then
					return {}
				end

				local scans = {}

				for scanID, _ in pairs(addon.db.global.guilds[addon.review.guildID].scans) do
					scans[scanID] = date(addon.db.global.settings.preferences.dateFormat, scanID)
				end

				return scans
			end,
			sorting = function()
				if not addon.review.guildID then
					return {}
				end

				local scans = {}

				for scanID, _ in
					addon.pairs(addon.db.global.guilds[addon.review.guildID].scans, function(a, b)
						return b < a
					end)
				do
					tinsert(scans, scanID)
				end

				return scans
			end,
		},
		analyzeScan = {
			order = 3,
			type = "execute",
			name = L["Analyze Scan"],
			disabled = function()
				return not addon.review.scan
			end,
			func = function(info)
				ACD:SelectGroup(addonName, "analyze")
				addon:SelectAnalyzeGuild(addon.review.guildID)
				addon:SelectAnalyzeScan(addon.review.scan, info)
			end,
		},
		deleteScan = {
			order = 4,
			type = "execute",
			name = L["Delete Scan"],
			disabled = function()
				return not addon.review.scan
			end,
			confirm = function()
				return addon.db.global.settings.preferences.confirmDeletions and L.ConfirmDeleteScan
			end,
			func = function()
				addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan] = nil
				addon:SelectReviewScan()
			end,
		},
		sorting = {
			order = 5,
			type = "select",
			style = "dropdown",
			name = L["Sorting"],
			values = {
				asc = L["Ascending"],
				des = L["Descending"],
			},
			disabled = function()
				return not addon.review.scan
			end,
			get = function()
				return addon.db.global.settings.preferences.sorting
			end,
			set = function(_, value)
				addon.db.global.settings.preferences.sorting = value
				addon:RefreshOptions()
			end,
		},
		copyText = {
			order = 6,
			type = "toggle",
			name = L["Copy Text"],
			disabled = function()
				return not addon.review.scan
			end,
			get = function()
				return addon.review.copyText
			end,
			set = function(_, value)
				addon.review.copyText = value
			end,
		},
	}

	for tab = 1, moneyTab do
		options["tab" .. tab] = {
			order = tab + 6,
			type = "group",
			name = function()
				local tabName
				if tab == moneyTab then
					tabName = L["Money Tab"]
				elseif addon.review.scan then
					tabName = addon.db.global.guilds[addon.review.guildID].tabs[tab].name
				end
				tabName = tabName ~= "" and tabName or format("%s %d", L["Tab"], tab)
				return tabName
			end,
			disabled = function()
				return not addon.review.scan
					or (tab ~= moneyTab and addon.db.global.guilds[addon.review.guildID].numTabs < tab)
			end,
			args = {
				filter = {
					order = 1,
					type = "select",
					style = "dropdown",
					name = L["Filter"],
					values = tab == moneyTab and {
						name = L["Name"],
						type = L["Type"],
						clear = L["Clear Filter"],
					} or {
						name = L["Name"],
						type = L["Type"],
						item = L["Item"],
						ilvl = L["Item Level"],
						clear = L["Clear Filter"],
					},
					sorting = tab == moneyTab and { "name", "type", "clear" }
						or { "name", "type", "item", "ilvl", "clear" },
					get = function()
						return addon.review.filterType
					end,
					set = function(_, value)
						addon.review.filterType = value ~= "clear" and value
						addon.review.filter = nil
						addon.review.minIlvl = nil
						addon.review.maxIlvl = nil
					end,
				},
				filter2 = {
					order = 2,
					type = "select",
					style = "dropdown",
					name = function()
						return addon.review.filter or ""
					end,
					values = function()
						local values = {
							clear = L["Clear Filter"],
						}

						local filterType = addon.review.filterType
						local scan = addon.review.guildID
							and addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan]
						local transactions = addon.review.scan
							and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)

						if not transactions then
							return values
						end

						if filterType == "name" then
							for _, transaction in pairs(transactions) do
								local info = addon:GetTransactionInfo(transaction)
								values[info.name] = info.name
							end
						elseif filterType == "type" then
							values.deposit = L["Deposit"]
							values.withdraw = L["Withdraw"]
							if tab == moneyTab then
								values.repair = L["Repair"]
							else
								values.move = L["Move"]
							end
						elseif filterType == "item" then
							for _, transaction in pairs(transactions) do
								local info = addon:GetTransactionInfo(transaction)
								values[info.itemLink] = info.itemLink
							end
						end

						return values
					end,
					sorting = function()
						local values = {}

						local filterType = addon.review.filterType
						local scan = addon.review.guildID
							and addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan]
						local transactions = addon.review.scan
							and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)

						if not transactions then
							tinsert(values, "clear")
							return values
						end

						if filterType == "name" then
							for _, transaction in
								addon.pairs(transactions, function(a, b)
									local infoA = addon:GetTransactionInfo(transactions[a])
									local infoB = addon:GetTransactionInfo(transactions[b])

									return infoA.name < infoB.name
								end)
							do
								local info = addon:GetTransactionInfo(transaction)
								if not addon.GetTableKey(values, info.name) then
									tinsert(values, info.name)
								end
							end
						elseif filterType == "type" then
							if tab == moneyTab then
								return { "deposit", "repair", "withdraw", "clear" }
							else
								return { "deposit", "move", "withdraw", "clear" }
							end
						elseif filterType == "item" then
							for _, transaction in
								addon.pairs(transactions, function(a, b)
									local infoA = addon:GetTransactionInfo(transactions[a])
									local infoB = addon:GetTransactionInfo(transactions[b])
									local _, _, itemA =
										strfind(select(3, strfind(infoA.itemLink, "|H(.+)|h")), "%[(.+)%]")
									local _, _, itemB =
										strfind(select(3, strfind(infoB.itemLink, "|H(.+)|h")), "%[(.+)%]")

									return itemA < itemB
								end)
							do
								local info = addon:GetTransactionInfo(transaction)
								if not addon.GetTableKey(values, info.itemLink) then
									tinsert(values, info.itemLink)
								end
							end
						end

						tinsert(values, "clear")

						return values
					end,
					hidden = function()
						if
							tab == moneyTab
							and (addon.review.filterType == "item" or addon.review.filterType == "ilvl")
						then
							addon.review.filterType = nil
						end

						return not addon.review.filterType or addon.review.filterType == "ilvl"
					end,
					get = function()
						return addon.review.filter ~= "clear" and addon.review.filter
					end,
					set = function(_, value)
						addon.review.filter = value ~= "clear" and value
					end,
				},
				minIlvl = {
					order = 3,
					type = "range",
					min = 1,
					max = 304,
					step = 1,
					name = L["Min Item Level"],
					hidden = function()
						return addon.review.filterType ~= "ilvl"
					end,
					get = function(info)
						return addon.review[info[#info]] or 1
					end,
					set = function(info, value)
						addon.review[info[#info]] = value
					end,
				},
				maxIlvl = {
					order = 4,
					type = "range",
					min = 1,
					max = 304,
					step = 1,
					name = L["Max Item Level"],
					hidden = function()
						return addon.review.filterType ~= "ilvl"
					end,
					get = function(info)
						return addon.review[info[#info]] or 304
					end,
					set = function(info, value)
						addon.review[info[#info]] = value
					end,
				},
				copyText = {
					order = 5,
					type = "input",
					multiline = 10,
					width = "full",
					name = "",
					hidden = function()
						return not addon.review.copyText
					end,
					get = function()
						local text = ""
						local scan = addon.review.guildID
							and addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan]
						local transactions = addon.review.scan
							and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)

						for transactionID, transaction in
							addon.pairs(transactions, function(a, b)
								if addon.db.global.settings.preferences.sorting == "des" then
									return a > b
								else
									return a < b
								end
							end)
						do
							local info = tab == moneyTab and addon:GetMoneyTransactionInfo(transactions[transactionID])
								or addon:GetTransactionInfo(transactions[transactionID])
							local line = (
								tab < moneyTab and addon:GetTransactionLabel(transactions[transactionID])
								or addon:GetMoneyTransactionLabel(transactions[transactionID])
							) or ""

							local filterType, isFiltered = addon.review.filterType
							if filterType then
								if filterType == "name" and addon.review.filter then
									isFiltered = info.name ~= addon.review.filter
								elseif filterType == "type" and addon.review.filter then
									isFiltered = info.transactionType ~= addon.review.filter
								elseif filterType == "item" and addon.review.filter then
									isFiltered = info.itemLink ~= addon.review.filter
								elseif filterType == "ilvl" then
									local _, _, _, _, _, itemType = GetItemInfo(info.itemLink)
									if itemType ~= "Weapon" and itemType ~= "Armor" then
										isFiltered = true
									else
										local ilvl = GetDetailedItemLevelInfo(info.itemLink)
										isFiltered = ilvl < (addon.review.minIlvl or 1)
											or ilvl > (addon.review.maxIlvl or 304)
									end
								end
							end

							if not isFiltered then
								text = text == "" and line or (text .. "|r\n" .. line)
							end
						end
						return text
					end,
				},
			},
		}

		local i = 101
		for line = 25, 1, -1 do
			options["tab" .. tab].args["line" .. line] = {
				order = i,
				type = "description",
				dialogControl = "GuildBankSnapshotsTransaction",
				hidden = function()
					-- Check if should be hidden to copy text
					if addon.review.copyText then
						return true
					end

					if tab == moneyTab and (addon.review.filterType == "item" or addon.review.filterType == "ilvl") then
						addon.review.filterType = nil
					end
					local filterType = addon.review.filterType
					local scan = addon.review.guildID
						and addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan]
					local transactions = addon.review.scan
						and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)

					if not transactions then
						return true
					end

					local info = tab == moneyTab and addon:GetMoneyTransactionInfo(transactions[line])
						or addon:GetTransactionInfo(transactions[line])
					if
						(tab ~= moneyTab and addon.review.filter == "repair")
						or (tab == moneyTab and addon.review.filter == "move")
					then
						addon.review.filter = nil
					end

					if filterType == "name" and addon.review.filter then
						return info.name ~= addon.review.filter
					elseif filterType == "type" and addon.review.filter then
						return info.transactionType ~= addon.review.filter
					elseif filterType == "item" and addon.review.filter then
						return info.itemLink ~= addon.review.filter
					elseif filterType == "ilvl" then
						local _, _, _, _, _, itemType = GetItemInfo(info.itemLink)
						if itemType ~= "Weapon" and itemType ~= "Armor" then
							return true
						end
						local ilvl = GetDetailedItemLevelInfo(info.itemLink)
						return ilvl < (addon.review.minIlvl or 1) or ilvl > (addon.review.maxIlvl or 304)
					end

					return not addon.review.scan
				end,
				name = function()
					local scan = addon.review.guildID
						and addon.db.global.guilds[addon.review.guildID].scans[addon.review.scan]
					local transactions = addon.review.scan
						and (tab < moneyTab and scan.tabs[tab].transactions or scan.moneyTransactions)
					return addon.review.scan
							and (tab < moneyTab and addon:GetTransactionLabel(transactions[line]) or addon:GetMoneyTransactionLabel(
								transactions[line]
							))
						or ""
				end,
				width = "full",
			}
			if addon.db.global.settings.preferences.sorting == "des" then
				i = i + 1
			else
				i = i - 1
			end
		end
	end

	return options
end

function addon:GetTransactionDate(scanTime, year, month, day, hour)
	local sec = (hour * 60 * 60) + (day * 60 * 60 * 24) + (month * 60 * 60 * 24 * 31) + (year * 60 * 60 * 24 * 31 * 12)
	return scanTime - sec
end

function addon:GetTransactionInfo(transaction)
	if not transaction then
		return
	end

	local transactionType, name, itemLink, count, moveOrigin, moveDestination, year, month, day, hour =
		select(2, AceSerializer:Deserialize(transaction))

	local info = {
		transactionType = transactionType,
		name = name,
		itemLink = itemLink,
		count = count,
		moveOrigin = moveOrigin,
		moveDestination = moveDestination,
		year = year,
		month = month,
		day = day,
		hour = hour,
	}

	return info
end

function addon:GetTransactionLabel(transaction)
	local info = addon:GetTransactionInfo(transaction)
	if not info then
		return
	end

	info.name = info.name or UNKNOWN
	info.name = NORMAL_FONT_COLOR_CODE .. info.name .. FONT_COLOR_CODE_CLOSE

	local msg
	if info.transactionType == "deposit" then
		msg = format(GUILDBANK_DEPOSIT_FORMAT, info.name, info.itemLink)
		if info.count > 1 then
			msg = msg .. format(GUILDBANK_LOG_QUANTITY, info.count)
		end
	elseif info.transactionType == "withdraw" then
		msg = format(GUILDBANK_WITHDRAW_FORMAT, info.name, info.itemLink)
		if info.count > 1 then
			msg = msg .. format(GUILDBANK_LOG_QUANTITY, info.count)
		end
	elseif info.transactionType == "move" then
		msg = format(GUILDBANK_MOVE_FORMAT, info.name, info.itemLink, info.count, info.moveOrigin, info.moveDestination)
	end

	local recentDate = RecentTimeDate(info.year, info.month, info.day, info.hour)
	if addon.db.global.settings.preferences.dateType == "approx" then
		msg = msg
			and (
				msg
				.. GUILD_BANK_LOG_TIME_PREPEND
				.. date(
					addon.db.global.settings.preferences.dateFormat,
					addon:GetTransactionDate(addon.review.scan or time(), info.year, info.month, info.day, info.hour)
				)
			)
	else
		msg = msg and (msg .. GUILD_BANK_LOG_TIME_PREPEND .. format(GUILD_BANK_LOG_TIME, recentDate))
	end

	return msg
end

function addon:SelectReviewGuild(guildID)
	addon.review.guildID = guildID
	addon.review.scan = nil
	LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
	return guildID
end

function addon:SelectReviewScan(scanID)
	addon.review.scan = scanID
	ACD:SelectGroup(addonName, "review", "tab1")
	return scanID
end
