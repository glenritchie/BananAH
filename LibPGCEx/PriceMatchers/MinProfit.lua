-- ***************************************************************************************************************************************************
-- * PriceMatchers/MinProfit.lua                                                                                                                     *
-- ***************************************************************************************************************************************************
-- * Minimum profit matcher                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.29 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local IIDetail = Inspect.Item.Detail
local MCeil = math.ceil
local MMax = math.max
local pcall = pcall

local ID = "minprofit"
local NAME = L["Matchers/MinprofitName"]
local DEFAULT_MIN_PROFIT = 0
local DEFAULT_SELL_PRICE = 1
local AH_FEE_MULTIPLIER = 0.95

local extraDescription =
{
	minProfit =
	{
		name = L["Matchers/MinprofitMinProfit"],
		value = "money",
		defaultValue = DEFAULT_MIN_PROFIT,
	},
	Layout =
	{
		{ "minProfit", },
		columns = 1
	},
}

local function MatchFunction(item, originalBid, originalBuy, adjustedBid, adjustedBuy, auctions, extra)
	local minProfit = extra and extra.minProfit or DEFAULT_MIN_PROFIT
	local ok, itemDetail = pcall(IIDetail, item)
	
	local sellPrice = ok and itemDetail and itemDetail.sell or DEFAULT_SELL_PRICE
	sellPrice = MCeil((sellPrice + minProfit) / AH_FEE_MULTIPLIER)
	
	adjustedBid = MMax(sellPrice, adjustedBid)
	adjustedBuy = MMax(sellPrice, adjustedBuy)
	
	return adjustedBid, adjustedBuy
end

PublicInterface.RegisterPriceMatcher(ID, NAME, MatchFunction, extraDescription)
