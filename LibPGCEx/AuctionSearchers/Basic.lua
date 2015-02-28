-- ***************************************************************************************************************************************************
-- * AuctionSearchers/Basic.lua                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * Basic auction searcher                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.10 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local L = InternalInterface.Localization.L

local ID = "basic"
local NAME = L["Searchers/BasicName"]
local ONLINE_CAPABLE = false
local DEFAULT_CALLING = nil
local DEFAULT_RARITY = "sellable"
local DEFAULT_CATEGORY = ""
local MIN_LEVEL = 0
local MAX_LEVEL = 60

local extraDescription =
{
	Online = ONLINE_CAPABLE,
	calling =
	{
		name = L["Searchers/BasicCalling"],
		value = "calling",
		defaultValue = DEFAULT_CALLING,
	},
	rarity =
	{
		name = L["Searchers/BasicRarity"],
		value = "rarity",
		defaultValue = DEFAULT_RARITY,
	},
	levelMin =
	{
		name = L["Searchers/BasicLevelMin"],
		value = "integer",
		minValue = MIN_LEVEL,
		maxValue = MAX_LEVEL,
		defaultValue = MIN_LEVEL,
	},
	levelMax =
	{
		name = L["Searchers/BasicLevelMax"],
		value = "integer",
		minValue = MIN_LEVEL,
		maxValue = MAX_LEVEL,
		defaultValue = MAX_LEVEL,
	},
	category =
	{
		name = L["Searchers/BasicCategory"],
		value = "category",
		defaultValue = DEFAULT_CATEGORY,
	},
	priceMin =
	{
		name = L["Searchers/BasicPriceMin"],
		value = "money",
		defaultValue = 0,
	},	
	priceMax =
	{
		name = L["Searchers/BasicPriceMax"],
		value = "money",
		defaultValue = 0,
	},
	NativeFixed =
	{
		role = nil,
		rarity = nil,
		levelMin = nil,
		levelMax = nil,
		category = nil,
		priceMin = nil,
		priceMax = nil,
	},
	NativeMapping =
	{
		role = "calling",
		rarity = "rarity",
		levelMin = "levelMin",
		levelMax = "levelMax",
		category = "category",
		priceMin = "priceMin",
		priceMax = "priceMax",
	},
	Layout =
	{ 
		{ "calling", "rarity", "category", nil },
		{ "levelMin", "levelMax", "priceMin", "priceMax",  },
		columns = 4,
	},
	ExtraInfo = { },
}

local function SearchFunction(nativeAuctions, extra)
	return nativeAuctions
end

PublicInterface.RegisterAuctionSearcher(ID, NAME, SearchFunction, extraDescription)
