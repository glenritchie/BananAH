-- ***************************************************************************************************************************************************
-- * PriceStats/RelativePosition.lua                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Relative Position price stat                                                                                                                    *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.28 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local MFloor = math.floor
local MMin = math.min
local TInsert = table.insert
local TSort = table.sort
local pairs = pairs

local ID = "rpos"
local NAME = L["Stats/RposName"]
local DEFAULT_WEIGHTED = true
local DEFAULT_POSITION = 50

local extraDescription =
{
	weighted =
	{
		name = L["Stats/RposWeighted"],
		value = "boolean",
		defaultValue = DEFAULT_WEIGHTED,
	},
	position =
	{
		name = L["Stats/RposPosition"],
		value = "integer",
		minValue = 0,
		maxValue = 100,
		defaultValue = DEFAULT_POSITION,	
	},
	Layout =
	{
		{ "weighted" },
		{ "position" },
		columns = 1
	}
}

local function StatFunction(auctions, extra)
	local weighted = extra and extra.weighted
	if weighted == nil then weighted = DEFAULT_WEIGHTED end
	local position = extra and extra.position or DEFAULT_POSITION
	
	local priceOrder = {}
	
	for auctionID, auctionData in pairs(auctions) do
		local weight = weighted and auctionData.stack or 1
		
		for i = 1, weight do
			TInsert(priceOrder, auctionID)
		end
	end
	
	if #priceOrder <= 0 then return nil end
	
	TSort(priceOrder, function(a, b) return auctions[a].buyoutUnitPrice < auctions[b].buyoutUnitPrice end)

	local index = MMin(MFloor(position * #priceOrder / 100) + 1, #priceOrder)

	return auctions[priceOrder[index]].buyoutUnitPrice
end

PublicInterface.RegisterPriceStat(ID, NAME, StatFunction, extraDescription)
