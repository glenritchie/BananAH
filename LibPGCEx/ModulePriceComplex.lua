-- ***************************************************************************************************************************************************
-- * ModulePriceComplex.lua                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Manages "Price Complex" modules                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.10.27 / Baanano: First Version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local UECreate = Utility.Event.Create
local pairs = pairs

local priceComplex = {}
local PriceComplexRegisteredEvent = UECreate(addonID, "PriceComplexRegistered")
local PriceComplexUnregisteredEvent = UECreate(addonID, "PriceComplexUnregistered")

function PublicInterface.RegisterPriceComplex(id, name, priceFunction)
	if priceComplex[id] then return false end
	
	priceComplex[id] =
	{
		id = id,
		name = name,
		priceFunction = priceFunction,
	}
	PriceComplexRegisteredEvent(id, name)
	
	return true
end

function PublicInterface.UnregisterPriceComplex(id)
	if not priceComplex[id] then return false end
	
	priceComplex[id] = nil
	PriceComplexUnregisteredEvent(id)
	
	return true
end

function PublicInterface.GetPriceComplex()
	local ret = {}
	
	for id, info in pairs(priceComplex) do
		ret[id] = info.name
	end
	
	return ret
end

function PublicInterface.GetPriceComplexFunction(id)
	return priceComplex[id] and priceComplex[id].priceFunction or nil
end
