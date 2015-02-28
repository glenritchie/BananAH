-- ***************************************************************************************************************************************************
-- * PricingModels/Fixed.lua                                                                                                                         *
-- ***************************************************************************************************************************************************
-- * Fixed price fallback                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.10.27 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local MMin = math.min

local ID = "fixed"
local NAME = L["Fallbacks/FixedName"]
local DEFAULT_PRICE = 1

local extraDescription =
{
	bidPrice =
	{
		name = L["Fallbacks/FixedBidPrice"],
		value = "money",
		defaultValue = DEFAULT_PRICE,
	},
	buyPrice =
	{
		name = L["Fallbacks/FixedBuyPrice"],
		value = "money",
		defaultValue = DEFAULT_PRICE,
	},
	Layout = 
	{
		{ "bidPrice" },
		{ "buyPrice" },
		columns = 1,
	}
}

local function PriceFunction(item, extra)
	local bid = extra and extra.bidPrice or DEFAULT_PRICE
	local buy = extra and extra.buyPrice or DEFAULT_PRICE

	bid = MMin(bid, buy)
	
	return bid, buy
end

PublicInterface.RegisterPriceFallback(ID, NAME, PriceFunction, extraDescription)
