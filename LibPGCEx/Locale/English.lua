﻿local _, InternalInterface = ...

InternalInterface.Localization.RegisterLocale("English",
{
	["Fallbacks/FixedBidPrice"] = "Bid price",
	["Fallbacks/FixedBuyPrice"] = "Buyout price",
	["Fallbacks/FixedName"] = "Fixed",
	["Fallbacks/VendorBidMultiplier"] = "Bid multiplier",
	["Fallbacks/VendorBuyMultiplier"] = "Buyout multiplier",
	["Fallbacks/VendorName"] = "Vendor",
	["Matchers/MinprofitMinProfit"] = "Minimum profit per unit against vendoring the item",
	["Matchers/MinprofitName"] = "Minimum profit",
	["Matchers/SelfundercutName"] = "Competition matcher",
	["Matchers/SelfundercutNoCompetitionAbsolute"] = "Amount to increase price per unit when there is no competition (absolute)",
	["Matchers/SelfundercutNoCompetitionRelative"] = "Amount to increase price per unit when there is no competition (percentage)",
	["Matchers/SelfundercutSelfRange"] = "Match own auctions within range (percentage)",
	["Matchers/SelfundercutUndercutAbsolute"] = "Amount to decrease price per unit when undercutting (absolute)",
	["Matchers/SelfundercutUndercutRange"] = "Undercut auctions within range (percentage)",
	["Matchers/SelfundercutUndercutRelative"] = "Amount to decrease price per unit when undercutting (percentage)",
	["Samplers/PtrimHighTrim"] = "Discard most expensive prices (percentage)",
	["Samplers/PtrimLowTrim"] = "Discard cheapest prices (percentage)",
	["Samplers/PtrimName"] = "Relative Trim",
	["Samplers/PtrimWeighted"] = "Weight auctions by stack size",
	["Samplers/StdevHighDeviation"] = "Max. deviation above average price (tenths of the standard deviation)",
	["Samplers/StdevLowDeviation"] = "Max. deviation below average price (tenths of the standard deviation)",
	["Samplers/StdevName"] = "Standard Deviation",
	["Samplers/StdevWeighted"] = "Weight auctions by stack size",
	["Samplers/TimeDays"] = "Number of days",
	["Samplers/TimeMinSample"] = "Min. sample size",
	["Samplers/TimeName"] = "Time",
	["Searchers/BasicCalling"] = "Calling",
	["Searchers/BasicCategory"] = "Category",
	["Searchers/BasicLevelMax"] = "Max. level",
	["Searchers/BasicLevelMin"] = "Min. level",
	["Searchers/BasicName"] = "Basic",
	["Searchers/BasicPriceMax"] = "Max. price",
	["Searchers/BasicPriceMin"] = "Min. price",
	["Searchers/BasicRarity"] = "Rarity",
	["Searchers/ExtendedBidMax"] = "Max. unit bid",
	["Searchers/ExtendedBidMin"] = "Min. unit bid",
	["Searchers/ExtendedBuyMax"] = "Max. unit buyout",
	["Searchers/ExtendedBuyMin"] = "Min. unit buyout",
	["Searchers/ExtendedCalling"] = "Calling",
	["Searchers/ExtendedCategory"] = "Category",
	["Searchers/ExtendedLevelMax"] = "Max. level",
	["Searchers/ExtendedLevelMin"] = "Min. level",
	["Searchers/ExtendedName"] = "Extended",
	["Searchers/ExtendedRarity"] = "Rarity",
	["Searchers/ExtendedSeller"] = "Seller",
	["Searchers/ExtendedTimeLeft"] = "Max. hours left",
	["Searchers/ResellBidDuration"] = "Max. hours left",
	["Searchers/ResellBidProfit"] = "Bid profit",
	["Searchers/ResellBuyProfit"] = "Buyout profit",
	["Searchers/ResellCategory"] = "Category",
	["Searchers/ResellMinDiscount"] = "Min. discount",
	["Searchers/ResellMinProfit"] = "Min. profit",
	["Searchers/ResellModel"] = "Reference price",
	["Searchers/ResellName"] = "Resell",
	["Searchers/ResellUseBid"] = "Use bid price",
	["Searchers/ResellUseBuy"] = "Use buy price",
	["Searchers/VendorBidDuration"] = "Max. hours left",
	["Searchers/VendorBidProfit"] = "Bid profit",
	["Searchers/VendorBuyProfit"] = "Buyout profit",
	["Searchers/VendorMinProfit"] = "Min. profit",
	["Searchers/VendorName"] = "Vendor",
	["Searchers/VendorUseBid"] = "Use bid price",
	["Searchers/VendorUseBuy"] = "Use buy price",
	["Stats/AvgName"] = "Average",
	["Stats/AvgWeighted"] = "Weight auctions by stack size",
	["Stats/RposName"] = "Relative Position",
	["Stats/RposPosition"] = "Position (percentage)",
	["Stats/RposWeighted"] = "Weight auctions by stack size",
}

)