-- ***************************************************************************************************************************************************
-- * ModulePriceStats.lua                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * Manages "Price Stat" modules                                                                                                                    *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.26 / Baanano: First Version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive
local UECreate = Utility.Event.Create
local pairs = pairs

local priceStats = {}
local PriceStatRegisteredEvent = UECreate(addonID, "PriceStatRegistered")
local PriceStatUnregisteredEvent = UECreate(addonID, "PriceStatUnregistered")

function PublicInterface.RegisterPriceStat(id, name, statFunction, extraDescription)
	if priceStats[id] then return false end
	
	priceStats[id] =
	{
		id = id,
		name = name,
		statFunction = statFunction,
		extraDescription = extraDescription,
	}
	PriceStatRegisteredEvent(id, name)
	
	return true
end

function PublicInterface.UnregisterPriceStat(id)
	if not priceStats[id] then return false end
	
	priceStats[id] = nil
	PriceStatUnregisteredEvent(id)
	
	return true
end

function PublicInterface.GetPriceStats()
	local ret = {}
	
	for id, info in pairs(priceStats) do
		ret[id] = info.name
	end
	
	return ret
end

function PublicInterface.GetPriceStatFunction(id)
	return priceStats[id] and priceStats[id].statFunction or nil
end

function PublicInterface.GetPriceStatExtraDescription(id)
	return priceStats[id] and CopyTableRecursive(priceStats[id].extraDescription) or nil
end
