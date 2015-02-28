-- ***************************************************************************************************************************************************
-- * PricingModels/Vendor.lua                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * Vendor price fallback                                                                                                                           *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.24 / Baanano: Rewritten for LibPGCEx                                                                                            *
-- * 0.4.0 / 2012.06.17 / Baanano: Rewritten for 1.9                                                                                                 *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local IIDetail = Inspect.Item.Detail
local MFloor = math.floor
local MMin = math.min
local pcall = pcall

local ID = "vendor"
local NAME = L["Fallbacks/VendorName"]
local DEFAULT_SELL_PRICE = 1
local DEFAULT_BID_MULTIPLIER = 3
local DEFAULT_BUY_MULTIPLIER = 5
local MAX_MULTIPLIER = 100

local extraDescription =
{
	bidMultiplier =
	{
		name = L["Fallbacks/VendorBidMultiplier"],
		value = "integer",
		minValue = 1,
		maxValue = MAX_MULTIPLIER,
		defaultValue = DEFAULT_BID_MULTIPLIER,
	},
	buyMultiplier =
	{
		name = L["Fallbacks/VendorBuyMultiplier"],
		value = "integer",
		minValue = 1,
		maxValue = MAX_MULTIPLIER,
		defaultValue = DEFAULT_BUY_MULTIPLIER,
	},
	Layout = 
	{
		{ "bidMultiplier" },
		{ "buyMultiplier" },
		columns = 1,
	}
}

local function PriceFunction(item, extra)
	local ok, itemDetail = pcall(IIDetail, item)
	
	local bidMultiplier = extra and extra.bidMultiplier or DEFAULT_BID_MULTIPLIER
	local buyMultiplier = extra and extra.buyMultiplier or DEFAULT_BUY_MULTIPLIER
	local sellPrice = ok and itemDetail and itemDetail.sell or DEFAULT_SELL_PRICE
	
	local bid = MFloor(sellPrice * bidMultiplier)
	local buy = MFloor(sellPrice * buyMultiplier)
	bid = MMin(bid, buy)
	
	return bid, buy
end

PublicInterface.RegisterPriceFallback(ID, NAME, PriceFunction, extraDescription)
