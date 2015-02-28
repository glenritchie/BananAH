-- ***************************************************************************************************************************************************
-- * Utility.lua                                                                                                                                     *
-- ***************************************************************************************************************************************************
-- * Defines helper functions                                                                                                                        *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.10.30 / Baanano: Copied from BananAH                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local pairs = pairs
local type = type

InternalInterface.Utility = InternalInterface.Utility or {}

-- ***************************************************************************************************************************************************
-- * CopyTableSimple                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Returns a shallow copy of a table, without its metatable                                                                                        *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.CopyTableSimple(sourceTable)
	local copy = {}
	if type(sourceTable) == "table" then
		for key, value in pairs(sourceTable) do 
			copy[key] = value 
		end
	end
	return copy
end

-- ***************************************************************************************************************************************************
-- * CopyTableRecursive                                                                                                                              *
-- ***************************************************************************************************************************************************
-- * Returns a deep copy of a table, without its metatable                                                                                           *
-- ***************************************************************************************************************************************************
function InternalInterface.Utility.CopyTableRecursive(sourceTable)
	local copy = {}
	if type(sourceTable) == "table" then
		for key, value in pairs(sourceTable) do
			copy[key] = type(value) == "table" and InternalInterface.Utility.CopyTableRecursive(value) or value
		end
	end
	return copy
end