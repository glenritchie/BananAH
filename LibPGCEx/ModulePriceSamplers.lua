-- ***************************************************************************************************************************************************
-- * ModulePriceSamplers.lua                                                                                                                         *
-- ***************************************************************************************************************************************************
-- * Manages "Price Sampler" modules                                                                                                                 *
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

local priceSamplers = {}
local PriceSamplerRegisteredEvent = UECreate(addonID, "PriceSamplerRegistered")
local PriceSamplerUnregisteredEvent = UECreate(addonID, "PriceSamplerUnregistered")

function PublicInterface.RegisterPriceSampler(id, name, sampleFunction, extraDescription)
	if priceSamplers[id] then return false end
	
	priceSamplers[id] =
	{
		id = id,
		name = name,
		sampleFunction = sampleFunction,
		extraDescription = extraDescription,
	}
	PriceSamplerRegisteredEvent(id, name)
	
	return true
end

function PublicInterface.UnregisterPriceSampler(id)
	if not priceSamplers[id] then return false end
	
	priceSamplers[id] = nil
	PriceSamplerUnregisteredEvent(id)
	
	return true
end

function PublicInterface.GetPriceSamplers()
	local ret = {}
	
	for id, info in pairs(priceSamplers) do
		ret[id] = info.name
	end
	
	return ret
end

function PublicInterface.GetPriceSamplerFunction(id)
	return priceSamplers[id] and priceSamplers[id].sampleFunction or nil
end

function PublicInterface.GetPriceSamplerExtraDescription(id)
	return priceSamplers[id] and CopyTableRecursive(priceSamplers[id].extraDescription) or nil
end
