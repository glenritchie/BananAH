-- ***************************************************************************************************************************************************
-- * ModulePriceModels.lua                                                                                                                           *
-- ***************************************************************************************************************************************************
-- * Manages price models                                                                                                                            *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.07.28 / Baanano: First Version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local CopyTableRecursive = InternalInterface.Utility.CopyTableRecursive
local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local Time = Inspect.Time.Server
local UECreate = Utility.Event.Create
local ipairs = ipairs
local next = next
local pairs = pairs
local type = type

local priceModels = {}
local PriceModelRegisteredEvent = UECreate(addonID, "PriceModelRegistered")
local PriceModelUnregisteredEvent = UECreate(addonID, "PriceModelUnregistered")

function PublicInterface.RegisterPriceModel(id, name, modelType, usage, matchers)
	if priceModels[id] then return false end
	
	priceModels[id] =
	{
		id = id,
		name = name,
		modelType = modelType,
		usage = usage,
		matchers = matchers,
	}
	PriceModelRegisteredEvent(id, name)
	
	return true
end

function PublicInterface.UnregisterPriceModel(id)
	if not priceModels[id] then return false end
	
	priceModels[id] = nil
	PriceModelUnregisteredEvent(id)
	
	return true
end

function PublicInterface.GetPriceModels(modelType)
	local ret = {}
	
	for id, info in pairs(priceModels) do
		if not modelType or info.modelType == modelType then
			ret[id] = info.name
		end
	end
	
	return ret
end

function PublicInterface.GetPriceModelType(id)
	return priceModels[id] and priceModels[id].modelType or nil
end

function PublicInterface.GetPriceModelUsage(id)
	return priceModels[id] and CopyTableRecursive(priceModels[id].usage) or nil
end

function PublicInterface.GetPriceModelMatchers(id)
	return priceModels[id] and CopyTableRecursive(priceModels[id].matchers) or nil
end

function PublicInterface.GetPrices(callback, item, bidPercentage, models, dontMatch)
	-- 1. Check parameters
	if not item then return false end
	if type(callback) ~= "function" then return false end
	bidPercentage = MMin(type(bidPercentage) == "number" and bidPercentage or 1, 1)
	
	if not models then
		models = PublicInterface.GetPriceModels()
	elseif type(models) ~= "table" then 
		models = { [models] = true } 
	end
	
	-- 2. Find the required models
	local simpleModels = {}
	local statModels = {}
	local complexModels = {}
	local compositeModels = {}
	
	local noModels = true
	for id in pairs(models) do
		local modelInfo = priceModels[id]
		if modelInfo then
			noModels = false
			if modelInfo.modelType == "simple" then
				simpleModels[id] = true
			elseif modelInfo.modelType == "statistical" then
				statModels[id] = true
			elseif modelInfo.modelType == "complex" then
				complexModels[id] = true
			elseif modelInfo.modelType == "composite" then
				compositeModels[id] = true
			end
		end
	end
	if noModels then return false end
	
	-- 3. Expand composite models
	local continueExpansion = next(compositeModels) and true or false
	while continueExpansion do
		continueExpansion = false
		for id, value in pairs(compositeModels) do
			for dependantID in pairs(priceModels[id].usage) do
				local modelInfo = priceModels[dependantID]
				if modelInfo then
					if modelInfo.modelType == "simple" then
						simpleModels[dependantID] = true
					elseif modelInfo.modelType == "statistical" then
						statModels[dependantID] = true
					elseif modelInfo.modelType == "complex" then
						complexModels[dependantID] = true
					elseif modelInfo.modelType == "composite" then
						continueExpansion = continueExpansion or not compositeModels[dependantID]
						compositeModels[dependantID] = true
					end					
				end
			end
		end
	end
	
	-- 4. Set start time
	local startTime = Time()
	
	-- 5. Get auctions and process them
	local function ProcessAuctions(auctions)
		-- 6. Get active & priced auctions
		local activeAuctions = {}
		local pricedAuctions = {}
		for auctionID, auctionData in pairs(auctions) do
			if auctionData.active then
				activeAuctions[auctionID] = auctionData
			end
			if auctionData.buyoutUnitPrice then
				pricedAuctions[auctionID] = auctionData
			end
		end
		
		local prices = {}
		
		-- 7. Get simple prices
		for modelID in pairs(simpleModels) do
			local usage = priceModels[modelID].usage
			local fallbackID = usage.id
			local fallbackExtra = usage.extra
			local fallbackFunction = PublicInterface.GetPriceFallbackFunction(fallbackID)
			if fallbackFunction then
				local bid, buy = fallbackFunction(item, fallbackExtra)
				if buy then
					prices[modelID] = { bid = bid, buy = buy, }
				elseif bid then
					prices[modelID] = { bid = MMax(MFloor(bid * bidPercentage), 1), buy = bid, }
				end
			end
		end
		
		-- 8. Get statistical prices
		for modelID in pairs(statModels) do
			local usage = priceModels[modelID].usage
			local filteredAuctions = pricedAuctions	

			local statID = usage.id
			local statExtra = usage.extra
			local statFunction = PublicInterface.GetPriceStatFunction(statID)
			local filters = usage.filters
			
			if type(statFunction) == "function" then
				local failed = false
				filters = type(filters) == "table" and filters or {}
				
				for _, filterData in ipairs(filters) do
					local filterID = filterData.id
					local filterExtra = filterData.extra
					local filterFunction = PublicInterface.GetPriceSamplerFunction(filterID)
					if type(filterFunction) == "function" then
						filteredAuctions = filterFunction(filteredAuctions, startTime, filterExtra)
					end
					failed = type(filteredAuctions) ~= "table"
				end
				
				if not failed then
					local bid, buy = statFunction(filteredAuctions, statExtra)
					if buy then
						prices[modelID] = { bid = bid, buy = buy, }
					elseif bid then
						prices[modelID] = { bid = MMax(MFloor(bid * bidPercentage), 1), buy = bid, }
					end
				end
			end
		end
		
		-- 9. Get complex prices
		for modelID in pairs(complexModels) do
			local usage = priceModels[modelID].usage
			local complexFunction = PublicInterface.GetPriceComplexFunction(usage)
			if type(complexFunction) == "function" then
				local bid, buy = complexFunction(item, auctions, startTime)
				if buy then
					prices[modelID] = { bid = bid, buy = buy, }
				elseif bid then
					prices[modelID] = { bid = MMax(MFloor(bid * bidPercentage), 1), buy = bid, }
				end			
			end
		end
		
		-- 10. Get composite prices
		local continueCheck = next(compositeModels) and true or false
		while continueCheck do
			continueCheck = false
			for modelID in pairs(compositeModels) do
				if not prices[modelID] then
					local failed = false
					local bid, buy, weight = 0, 0, 0
					for dependantID, dependantWeight in pairs(priceModels[modelID].usage) do
						local dependantPrices = prices[dependantID]
						if dependantPrices and type(dependantWeight) == "number" then
							bid = bid + dependantPrices.bid * dependantWeight
							buy = buy + dependantPrices.buy * dependantWeight
							weight = weight + dependantWeight
						else
							failed = true
						end
					end
					if not failed and weight > 0 then
						prices[modelID] = { bid = MMax(1, MFloor(bid / weight)), buy = MMax(1, MFloor(buy / weight)) }
						continueCheck = true
					end
				end
			end
		end
		
		-- 11. Discard prices added during composite expansion
		local realPrices = {}
		for modelID in pairs(models) do
			realPrices[modelID] = prices[modelID]
		end
		
		-- 12. Perform price matching
		if not dontMatch then
			for modelID, price in pairs(realPrices) do
				local matchers = priceModels[modelID].matchers
				if type(matchers) == "table" then
					price.adjustedBid = price.bid
					price.adjustedBuy = price.buy
					for _, matcher in ipairs(matchers) do
						local matcherID = matcher.id
						local matcherExtra = matcher.extra
						local matchFunction = PublicInterface.GetPriceMatcherFunction(matcherID)
						if type(matchFunction) == "function" then
							local adjustedBid, adjustedBuy = matchFunction(item, price.bid, price.buy, price.adjustedBid, price.adjustedBuy, activeAuctions, matcherExtra)
							if adjustedBuy then
								price.adjustedBuy = adjustedBuy
								price.adjustedBid = MMin(adjustedBid, adjustedBuy)
							elseif adjustedBid then
								price.adjustedBuy = adjustedBid
								price.adjustedBid = MMax(MFloor(adjustedBid * bidPercentage), 1)
							end									
						end
					end
				end
			end
		end
		
		-- 13. Callback the prices
		callback(realPrices)
	end
	LibPGC.GetAllAuctionData(ProcessAuctions, item)
	
	return true
end