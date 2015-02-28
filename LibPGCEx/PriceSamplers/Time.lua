-- ***************************************************************************************************************************************************
-- * PriceSamplers/Time.lua                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Time price sampler                                                                                                                              *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.25 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local TInsert = table.insert
local TSort = table.sort
local pairs = pairs

local ID = "time"
local NAME = L["Samplers/TimeName"]
local DEFAULT_DAYS = 3
local MAX_DAYS = 30
local MAX_MINSAMPLE = 50
local DEFAULT_MINSAMPLE = 0
local DAY_LENGTH = 86400

local extraDescription =
{
	days =
	{
		name = L["Samplers/TimeDays"],
		value = "integer",
		minValue = 0,
		maxValue = MAX_DAYS,
		defaultValue = DEFAULT_DAYS,
	},
	minSample =
	{
		name = L["Samplers/TimeMinSample"],
		value = "integer",
		minValue = 0,
		maxValue = MAX_MINSAMPLE,
		defaultValue = DEFAULT_MINSAMPLE,
	},
	Layout =
	{
		{ "days" },
		{ "minSample" },
		columns = 1,
	}
}

local function SampleFunction(auctions, startTime, extra)
	local days = extra and extra.days or DEFAULT_DAYS
	local minSample = extra and extra.minSample or DEFAULT_MINSAMPLE

	local timeLimit = days > 0 and startTime - days * DAY_LENGTH or nil
	
	local filteredAuctions = {}
	local excludedAuctions = {}
	
	local numAuctions = 0
	for auctionID, auctionData in pairs(auctions) do
		if (timeLimit and auctionData.lastSeenTime >= timeLimit) or (not timeLimit and auctionData.active) then
			filteredAuctions[auctionID] = auctionData
			numAuctions = numAuctions + 1
		else
			TInsert(excludedAuctions, auctionID)
		end
	end
	
	if numAuctions < minSample then
		TSort(excludedAuctions, function(a, b)
			local lastSeenA = auctions[a].lastSeenTime
			local lastSeenB = auctions[b].lastSeenTime
			if lastSeenA == lastSeenB then
				return b > a
			end
			return lastSeenA > lastSeenB
		end)
		
		for index = 1, minSample - numAuctions do
			local auctionID = excludedAuctions[index]
			if auctionID then
				filteredAuctions[auctionID] = auctions[auctionID]
			else
				break
			end
		end
	end

	return filteredAuctions
end

PublicInterface.RegisterPriceSampler(ID, NAME, SampleFunction, extraDescription)
