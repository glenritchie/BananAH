-- ***************************************************************************************************************************************************
-- * ModulePriceFallbacks.lua                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * Manages "Price Fallback" modules                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.24 / Baanano: First Version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive
local UECreate = Utility.Event.Create
local pairs = pairs

local priceFallbacks = {}
local PriceFallbackRegisteredEvent = UECreate(addonID, "PriceFallbackRegistered")
local PriceFallbackUnregisteredEvent = UECreate(addonID, "PriceFallbackUnregistered")

function PublicInterface.RegisterPriceFallback(id, name, priceFunction, extraDescription)
	if priceFallbacks[id] then return false end
	
	priceFallbacks[id] =
	{
		id = id,
		name = name,
		priceFunction = priceFunction,
		extraDescription = extraDescription,
	}
	PriceFallbackRegisteredEvent(id, name)
	
	return true
end

function PublicInterface.UnregisterPriceFallback(id)
	if not priceFallbacks[id] then return false end
	
	priceFallbacks[id] = nil
	PriceFallbackUnregisteredEvent(id)
	
	return true
end

function PublicInterface.GetPriceFallbacks()
	local ret = {}
	
	for id, info in pairs(priceFallbacks) do
		ret[id] = info.name
	end
	
	return ret
end

function PublicInterface.GetPriceFallbackFunction(id)
	return priceFallbacks[id] and priceFallbacks[id].priceFunction or nil
end

function PublicInterface.GetPriceFallbackExtraDescription(id)
	return priceFallbacks[id] and CopyTableRecursive(priceFallbacks[id].extraDescription) or nil
end
