-- ***************************************************************************************************************************************************
-- * ModulePriceMatchers.lua                                                                                                                         *
-- ***************************************************************************************************************************************************
-- * Manages "Price Matcher" modules                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.29 / Baanano: First Version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive
local UECreate = Utility.Event.Create
local pairs = pairs

local priceMatchers = {}
local PriceMatcherRegisteredEvent = UECreate(addonID, "PriceMatcherRegistered")
local PriceMatcherUnregisteredEvent = UECreate(addonID, "PriceMatcherUnregistered")

function PublicInterface.RegisterPriceMatcher(id, name, matchFunction, extraDescription)
	if priceMatchers[id] then return false end
	
	priceMatchers[id] =
	{
		id = id,
		name = name,
		matchFunction = matchFunction,
		extraDescription = extraDescription,
	}
	PriceMatcherRegisteredEvent(id, name)
	
	return true
end

function PublicInterface.UnregisterPriceMatcher(id)
	if not priceMatchers[id] then return false end
	
	priceMatchers[id] = nil
	PriceMatcherUnregisteredEvent(id)
	
	return true
end

function PublicInterface.GetPriceMatchers()
	local ret = {}
	
	for id, info in pairs(priceMatchers) do
		ret[id] = info.name
	end
	
	return ret
end

function PublicInterface.GetPriceMatcherFunction(id)
	return priceMatchers[id] and priceMatchers[id].matchFunction or nil
end

function PublicInterface.GetPriceMatcherExtraDescription(id)
	return priceMatchers[id] and CopyTableRecursive(priceMatchers[id].extraDescription) or nil
end
