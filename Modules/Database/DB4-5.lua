local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceSerializer = LibStub("AceSerializer-3.0")

function addon:ConvertDB4_5(backup)
	if backup.guilds then
		for guildKey, scans in pairs(backup.guilds) do
			local _, guildName, faction, realm = strsplit(":", guildKey)
			guildName = gsub(guildName, "|s", " ")
			faction = faction == "H" and "Horde" or "Alliance"
			realm = gsub(realm, "|s", " ")

			local guildID = format("%s - %s (%s)", guildName, realm, faction)
			local db = self.db.global.guilds[guildID]

			db.guildName = guildName
			db.faction = faction
			db.realm = realm

			for tab = 1, MAX_GUILDBANK_TABS do
				db.tabs[tab] = {
					name = "",
					icon = 134400,
				}
			end

			for scanID, scan in
				addon.pairs(scans, function(a, b)
					return a > b
				end)
			do
				db.numTabs = db.numTabs == 0 and addon.tcount(scan) or db.numTabs
				db.scans[scanID] = { totalMoney = 0, moneyTransactions = {}, tabs = {} }

				for tab, transactions in pairs(scan) do
					db.scans[scanID].tabs[tab] = { items = {}, transactions = {} }
					for transactionID, transaction in pairs(transactions) do
						if transactionID == "total" then
							db.scans[scanID].totalMoney = transaction
						elseif transactionID == "tabName" then
							if db.tabs[tab] then
								db.tabs[tab].name = transaction
							end
						elseif type(transaction) == "table" then
							local t = date("*t", time())
							if (transaction.tabName and transaction.tabName == "Money") or tab == 9 then
								local transactionTime, name, transactionType, count = unpack(transaction)
								transactionTime = date("*t", transactionTime)

								tinsert(
									db.scans[scanID].moneyTransactions,
									AceSerializer:Serialize(
										transactionType,
										name,
										count,
										t.year - transactionTime.year,
										t.month - transactionTime.month,
										t.day - transactionTime.day,
										t.hour - transactionTime.hour
									)
								)
							else
								local transactionTime, name, transactionType, count, itemLink, moveOrigin, moveDestination =
									unpack(transaction)
								transactionTime = date("*t", transactionTime)

								tinsert(
									db.scans[scanID].tabs[tab].transactions,
									AceSerializer:Serialize(
										transactionType,
										name,
										itemLink,
										count,
										moveOrigin or 0,
										moveDestination or 0,
										t.year - transactionTime.year,
										t.month - transactionTime.month,
										t.day - transactionTime.day,
										t.hour - transactionTime.hour
									)
								)
							end
						end
					end
				end
			end
		end
	end

	if backup.settings then
		addon.db.global.settings.scans.review = backup.settings.showFrameAfterScan
		addon.db.global.settings.scans.autoScan.enabled = backup.settings.autoScan
		addon.db.global.settings.scans.autoScan.review = backup.settings.showFrameAfterAutoScan
		addon.db.global.settings.preferences.dateFormat = backup.settings.dateFormat
		addon.db.global.settings.preferences.defaultGuild = backup.settings.defaultGuild
		addon.db.global.settings.preferences.confirmDeletions = backup.settings.confirmDeletion
		addon.db.global.settings.preferences.dateType = backup.settings.approxDates and "approx" or "default"
		addon.db.global.settings.preferences.exportDelimiter = backup.settings.exportDelimiter
	end

	addon.db.global.backup = nil
end
