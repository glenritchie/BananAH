-- ***************************************************************************************************************************************************
-- * PriceSamplers/PercentileTrim.lua                                                                                                                *
-- ***************************************************************************************************************************************************
-- * Percentile Trim price sampler                                                                                                                    *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.24 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local MCeil = math.ceil
local MFloor = math.floor
local TInsert = table.insert
local TSort = table.sort
local pairs = pairs

local ID = "ptrim"
local NAME = L["Samplers/PtrimName"]
local DEFAULT_WEIGHTED = 1
local DEFAULT_LOW_TRIM = 25
local DEFAULT_HIGH_TRIM = 25

local extraDescription =
{
	weighted =
	{
		name = L["Samplers/PtrimWeighted"],
		value = "boolean",
		defaultValue = DEFAULT_WEIGHTED,
	},
	lowTrim =
	{
		name = L["Samplers/PtrimLowTrim"],
		value = "integer",
		minValue = 0,
		maxValue = 100,
		defaultValue = DEFAULT_LOW_TRIM,
	},
	highTrim =
	{
		name = L["Samplers/PtrimHighTrim"],
		value = "integer",
		minValue = 0,
		maxValue = 100,
		defaultValue = DEFAULT_HIGH_TRIM,
	},
	Layout =
	{
		{ "weighted" }, 
		{ "lowTrim" }, 
		{ "highTrim" },
		columns = 1
	}
}

local function SampleFunction(auctions, startTime, extra)
	local weighted = extra and extra.weighted
	if weighted == nil then weighted = DEFAULT_WEIGHTED end
	local lowTrim = extra and extra.lowTrim or DEFAULT_LOW_TRIM
	local highTrim = 100 - (extra and extra.highTrim or DEFAULT_HIGH_TRIM)
	
	if lowTrim > highTrim then return {} end

	local priceOrder = {}
		
	for auctionID, auctionData in pairs(auctions) do
		local weight = weighted and auctionData.stack or 1
		
		for i = 1, weight do
			TInsert(priceOrder, auctionID)
		end
	end
	
	TSort(priceOrder, function(a, b) return auctions[a].buyoutUnitPrice < auctions[b].buyoutUnitPrice end)
	
	local firstIndex, lastIndex = MFloor(lowTrim * #priceOrder / 100) + 1, MCeil(highTrim * #priceOrder / 100)
	
	local filteredAuctions = {}
	
	for index = firstIndex, lastIndex do
		local auctionID = priceOrder[index]
		if auctionID and not filteredAuctions[auctionID] then
			filteredAuctions[auctionID] = auctions[auctionID]
		end
	end

	return filteredAuctions
end

PublicInterface.RegisterPriceSampler(ID, NAME, SampleFunction, extraDescription)
