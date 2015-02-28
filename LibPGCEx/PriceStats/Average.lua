-- ***************************************************************************************************************************************************
-- * PriceStats/Average.lua                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Average price stat                                                                                                                              *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.24 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local MCeil = math.ceil
local pairs = pairs

local ID = "avg"
local NAME = L["Stats/AvgName"]
local DEFAULT_WEIGHTED = true

local extraDescription =
{
	weighted =
	{
		name = L["Stats/AvgWeighted"],
		value = "boolean",
		defaultValue = DEFAULT_WEIGHTED,
	},
	Layout =
	{
		{ "weighted" },
		columns = 1
	}
}

local function StatFunction(auctions, extra)
	local weighted = extra and extra.weighted
	if weighted == nil then weighted = DEFAULT_WEIGHTED end

	local totalWeight, totalPrice = 0, 0
		
	for auctionID, auctionData in pairs(auctions) do
		local buy = auctionData.buyoutUnitPrice
		local weight = weighted and auctionData.stack or 1
		
		totalWeight = totalWeight + weight
		totalPrice = totalPrice + buy * weight
	end	

	if totalWeight <= 0 then return nil end
	return MCeil(totalPrice / totalWeight)
end

PublicInterface.RegisterPriceStat(ID, NAME, StatFunction, extraDescription)
