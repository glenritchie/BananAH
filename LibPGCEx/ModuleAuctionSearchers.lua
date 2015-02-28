-- ***************************************************************************************************************************************************
-- * ModuleAuctionSearchers.lua                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * Manages "Auction Searcher" modules                                                                                                              *
-- ***************************************************************************************************************************************************
-- * 0.4.12/ 2013.09.17 / Baanano: Updated to the new event model                                                                                    *
-- * 0.4.1 / 2012.08.10 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local CAScan = Command.Auction.Scan
local CEAttach = Command.Event.Attach
local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive
local GetAuctionData = LibPGC.GetAuctionData
local IInteraction = Inspect.Interaction
local CreateTask = LibScheduler.CreateTask
local Release = LibScheduler.Release
local SearchAuctions = LibPGC.SearchAuctions
local TInsert = table.insert
local UECreate = Utility.Event.Create
local pairs = pairs
local pcall = pcall
local tostring = tostring
local type = type

local auctionSearchers = {}
local nextSearch = nil
local AuctionSearcherRegisteredEvent = UECreate(addonID, "AuctionSearcherRegistered")
local AuctionSearcherUnregisteredEvent = UECreate(addonID, "AuctionSearcherUnregistered")

function PublicInterface.RegisterAuctionSearcher(id, name, searchFunction, extraDescription)
	if auctionSearchers[id] then return false end
	
	auctionSearchers[id] =
	{
		id = id,
		name = name,
		searchFunction = searchFunction,
		extraDescription = extraDescription,
	}
	AuctionSearcherRegisteredEvent(id, name)
	
	return true
end

function PublicInterface.UnregisterAuctionSearcher(id)
	if not auctionSearchers[id] then return false end
	
	auctionSearchers[id] = nil
	AuctionSearcherUnregisteredEvent(id)
	
	return true
end

function PublicInterface.GetAuctionSearchers()
	local ret = {}
	
	for id, info in pairs(auctionSearchers) do
		ret[id] = info.name
	end
	
	return ret
end

function PublicInterface.GetAuctionSearcherFunction(id)
	return auctionSearchers[id] and auctionSearchers[id].searchFunction or nil
end

function PublicInterface.GetAuctionSearcherExtraDescription(id)
	return auctionSearchers[id] and CopyTableRecursive(auctionSearchers[id].extraDescription) or nil
end

function PublicInterface.SearchAuctions(callback, id, online, text, extra)
	if not id or not auctionSearchers[id] or type(callback) ~= "function" then return false end
	
	local searchFunction = auctionSearchers[id].searchFunction
	searchFunction = type(searchFunction) == "function" and searchFunction or function(nativeAuctions, extra) return nativeAuctions end
	local extraDescription = auctionSearchers[id].extraDescription or {}
	local nativeFixed = extraDescription.NativeFixed or {}
	local nativeMapping = extraDescription.NativeMapping or {}
	
	local role = nativeFixed.role or (nativeMapping.role and extra and extra[nativeMapping.role] or nil) or nil
	local rarity = nativeFixed.rarity or (nativeMapping.rarity and extra and extra[nativeMapping.rarity] or nil) or nil
	local levelMin = nativeFixed.levelMin or (nativeMapping.levelMin and extra and extra[nativeMapping.levelMin] or nil) or 0
	local levelMax = nativeFixed.levelMax or (nativeMapping.levelMax and extra and extra[nativeMapping.levelMax] or nil) or 50
	local category = nativeFixed.category or (nativeMapping.category and extra and extra[nativeMapping.category] or nil) or nil
	local priceMin = nativeFixed.priceMin or (nativeMapping.priceMin and extra and extra[nativeMapping.priceMin] or nil) or 0
	local priceMax = nativeFixed.priceMax or (nativeMapping.priceMax and extra and extra[nativeMapping.priceMax] or nil) or 0
	
	text = text and tostring(text) or nil
	levelMin = levelMin > 0 and levelMin or nil
	levelMax = levelMax > 0 and levelMax or nil
	priceMin = priceMin > 0 and priceMin or nil
	priceMax = priceMax > 0 and priceMax or nil
	
	online = online and IInteraction("auction") and online or false
	
	if type(online) == "table" then
		local index = ((online.page or 1) - 1) * 50
		local sortType = online.sortType or "time"
		local sortOrder = online.sortOrder or "ascending"
		if pcall(CAScan, { type = "search", index = index, text = text, rarity = rarity, category = category ~= "" and category or nil, role = role, levelMin = levelMin, levelMax = levelMax, priceMin = priceMin, priceMax = priceMax, sort = sortType, sortOrder = sortOrder }) then
			nextSearch = 
				function(h, criteria, auctionIDs)
					if criteria ~= "search" then return end
					
					online.morePages = #auctionIDs >= 50 and true or false
					
					local auctions = {}
					for _, auctionID in pairs(auctionIDs) do
						auctions[auctionID] = GetAuctionData(nil, auctionID)
					end
					CreateTask(function() local found = searchFunction(auctions, extra) Release() return found end, function(auctions) callback(auctions, online) end)
					
					nextSearch = nil
				end
		else
			return false
		end
	else
		SearchAuctions(function(auctions) CreateTask(function() local found = searchFunction(auctions, extra) Release() return found end, function(auctions) callback(auctions, false) end) end, role, rarity, levelMin, levelMax, category, priceMin, priceMax, text)
	end
	
	return true
end
CEAttach(Event.LibPGC.AuctionData, function(...) if type(nextSearch) == "function" then nextSearch(...) end end, addonID .. ".AuctionSearchers.OnAuctionData")
