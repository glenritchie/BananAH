-- ***************************************************************************************************************************************************
-- * PriceSamplers/StandardDeviation.lua                                                                                                             *
-- ***************************************************************************************************************************************************
-- * Standard Deviation price sampler                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.24 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local pairs = pairs

local ID = "stdev"
local NAME = L["Samplers/StdevName"]
local DEFAULT_WEIGHTED = true
local DEFAULT_LOW_DEVIATION = 15
local DEFAULT_HIGH_DEVIATION = 15
local MAX_DEVIATION = 100

local extraDescription =
{
	weighted =
	{
		name = L["Samplers/StdevWeighted"],
		value = "boolean",
		defaultValue = DEFAULT_WEIGHTED,
	},
	lowDeviation =
	{
		name = L["Samplers/StdevLowDeviation"],
		value = "integer",
		minValue = 0,
		maxValue = MAX_DEVIATION,
		defaultValue = DEFAULT_LOW_DEVIATION,
	},
	highDeviation =
	{
		name = L["Samplers/StdevHighDeviation"],
		value = "integer",
		minValue = 0,
		maxValue = MAX_DEVIATION,
		defaultValue = DEFAULT_HIGH_DEVIATION,
	},
	Layout =
	{
		{ "weighted" },
		{ "lowDeviation" },
		{ "highDeviation" },
		columns = 1
	}
}

local function SampleFunction(auctions, startTime, extra)
	local weighted = extra and extra.weighted
	if weighted == nil then weighted = DEFAULT_WEIGHTED end
	local lowDeviation = (extra and extra.lowDeviation or DEFAULT_LOW_DEVIATION) / 10
	local highDeviation = (extra and extra.highDeviation or DEFAULT_HIGH_DEVIATION) / 10

	local totalWeight, average, squaredDeltaSum = 0, 0, 0
		
	for auctionID, auctionData in pairs(auctions) do
		local buy = auctionData.buyoutUnitPrice
		local weight = weighted and auctionData.stack or 1
		
		local prevAverage = average
		totalWeight = totalWeight + weight
		average = average + weight * (buy - average) / totalWeight
		squaredDeltaSum = squaredDeltaSum + weight * (buy - prevAverage) * (buy - average)
	end
	
	local squaredLow, squaredHigh = squaredDeltaSum * lowDeviation * lowDeviation / totalWeight, squaredDeltaSum * highDeviation * highDeviation / totalWeight

	local filteredAuctions = {}
	for auctionID, auctionData in pairs(auctions) do
		local buy = auctionData.buyoutUnitPrice
		local squaredDeviation = (buy - average) * (buy - average)
		
		if (buy <= average and squaredDeviation <= squaredLow) or (buy > average and squaredDeviation <= squaredHigh) then
			filteredAuctions[auctionID] = auctionData
		end
	end
		
	return filteredAuctions
end

PublicInterface.RegisterPriceSampler(ID, NAME, SampleFunction, extraDescription)
