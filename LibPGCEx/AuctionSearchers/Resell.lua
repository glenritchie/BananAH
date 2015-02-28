-- ***************************************************************************************************************************************************
-- * AuctionSearchers/Resell.lua                                                                                                                     *
-- ***************************************************************************************************************************************************
-- * Resell auction searcher                                                                                                                         *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.12 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local GetLastTask = LibPGC.GetLastTask
local GetPrices = PublicInterface.GetPrices
local IIDetail = Inspect.Item.Detail
local L = InternalInterface.Localization.L
local MFloor = math.floor
local MHuge = math.huge
local TInsert = table.insert
local Time = Inspect.Time.Server
local WaitOn = LibScheduler.WaitOn
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local type = type

local ID = "resell"
local NAME = L["Searchers/ResellName"]
local ONLINE_CAPABLE = false
local DEFAULT_USE_BUY = true
local DEFAULT_USE_BID = true
local DEFAULT_MIN_DISCOUNT = 25
local DEFAULT_MIN_PROFIT = 1
local DEFAULT_CATEGORY = ""

local extraDescription =
{
	Online = ONLINE_CAPABLE,
	useBuy =
	{
		name = L["Searchers/ResellUseBuy"],
		value = "boolean",
		defaultValue = DEFAULT_USE_BUY,
	},
	useBid =
	{
		name = L["Searchers/ResellUseBid"],
		value = "boolean",
		defaultValue = DEFAULT_USE_BID,
	},
	bidDuration =
	{
		name = L["Searchers/ResellBidDuration"],
		value = "integer",
		minValue = 1,
		maxValue = 48,
		defaultValue = 48,
	},
	pricingModel =
	{
		name = L["Searchers/ResellModel"],
		value = "pricingModel"
	},
	minDiscount =
	{
		name = L["Searchers/ResellMinDiscount"],
		value = "integer",
		minValue = 0,
		maxValue = 100,
		defaultValue = DEFAULT_MIN_DISCOUNT,
	},
	minProfit =
	{
		name = L["Searchers/ResellMinProfit"],
		value = "money",
		defaultValue = DEFAULT_MIN_PROFIT,
	},
	category =
	{
		name = L["Searchers/ResellCategory"],
		value = "category",
		defaultValue = DEFAULT_CATEGORY,
	},
	rarity =
	{
		name = "Rarity",
		value = "rarity",
		defaultValue = "sellable",
	},
	NativeFixed =
	{
		role = nil,
		rarity = nil,
		levelMin = nil,
		levelMax = nil,
		category = nil,
		priceMin = nil,
		priceMax = nil,
	},
	NativeMapping =
	{
		role = nil,
		rarity = "rarity",
		levelMin = nil,
		levelMax = nil,
		category = "category",
		priceMin = nil,
		priceMax = nil,
	},
	Layout =
	{ 
		{ "useBuy", "pricingModel", nil, "rarity", nil, "category", nil, },
		{ "useBid", "bidDuration", nil, "minDiscount", nil, "minProfit", nil, },
		columns = 7,		
	},
	ExtraInfo =
	{
		bidProfit =
		{
			name = L["Searchers/ResellBidProfit"],
			value = "money",
		},
		buyProfit =
		{
			name = L["Searchers/ResellBuyProfit"],
			value = "money",
		},
		"bidProfit", "buyProfit",
	},
}

local function SearchFunction(nativeAuctions, extra)
	extra = type(extra) == "table" and extra or {}
	if not extra.useBid and not extra.useBuy or not extra.pricingModel then return {} end
	
	local maxTime = Time() + (extra.bidDuration or 48) * 3600
	local maxScore = 100 - (extra.minDiscount or DEFAULT_MIN_DISCOUNT)
	local minProfit = extra.minProfit or DEFAULT_MIN_PROFIT
	local referencePrice = extra.pricingModel
	
	local remainingItemTypes = 1
	local itemTypes = {}
	for auctionID, auctionData in pairs(nativeAuctions) do
		local auctionItemType = auctionData.itemType
		itemTypes[auctionItemType] = itemTypes[auctionItemType] or {}
		TInsert(itemTypes[auctionItemType], auctionID)
	end
	
	local function AssignScore(itemType, prices)
		local price = prices and prices[referencePrice] or nil
		if itemType and price and price.buy and price.buy > 0 then
			for _, auctionID in ipairs(itemTypes[itemType]) do
				local auctionData = nativeAuctions[auctionID]
				local totalSell = auctionData.stack * price.buy
				
				local bidScore = MFloor(auctionData.bidUnitPrice * 100 / price.buy)
				local buyScore = auctionData.buyoutUnitPrice and MFloor(auctionData.buyoutUnitPrice * 100 / price.buy) or MHuge
				
				auctionData.bidProfit = totalSell - auctionData.bidPrice
				auctionData.buyProfit = auctionData.buyoutPrice and totalSell - auctionData.buyoutPrice or -1

				if (not extra.useBid or auctionData.maxExpireTime > maxTime or bidScore > maxScore or auctionData.bidProfit < minProfit) and (not extra.useBuy or buyScore > maxScore or auctionData.buyProfit < minProfit) then
					nativeAuctions[auctionID] = nil
				end
			end
		elseif itemType then
			for _, auctionID in ipairs(itemTypes[itemType]) do
				nativeAuctions[auctionID] = nil
			end
		end
		remainingItemTypes = remainingItemTypes - 1
	end
	
	for itemType, auctions in pairs(itemTypes) do
		if GetPrices(function(prices) AssignScore(itemType, prices) end, itemType, 1, referencePrice, true) then
			remainingItemTypes = remainingItemTypes + 1
		else
			for _, auctionID in ipairs(auctions) do
				nativeAuctions[auctionID] = nil
			end
		end
	end
	AssignScore()
	
	WaitOn(GetLastTask())
	
	return nativeAuctions
end

PublicInterface.RegisterAuctionSearcher(ID, NAME, SearchFunction, extraDescription)
