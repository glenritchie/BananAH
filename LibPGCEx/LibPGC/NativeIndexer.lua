-- ***************************************************************************************************************************************************
-- * Indexers/NativeIndexer.lua                                                                                                                      *
-- ***************************************************************************************************************************************************
-- * Search tree that allows to index the auctionDB in the same way that the native auction searcher                                                 *
-- ***************************************************************************************************************************************************
-- * 0.4.4 / 2012.08.12 / Baanano: Fixed minor category bugs                                                                                         *
-- * 0.4.1 / 2012.07.10 / Baanano: Moved to LibPGC                                                                                                   *
-- * 0.4.0 / 2012.05.31 / Baanano: Rewritten AuctionTree.lua                                                                                         *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local Release = LibScheduler.Release
local pairs = pairs

InternalInterface.Indexers = InternalInterface.Indexers or {}

function InternalInterface.Indexers.BuildNativeIndexer()
	local nativeIndexer = {}
	
	nativeIndexer.auctionIDs = {}
	nativeIndexer.searchTree = {}
	
	function nativeIndexer:AddAuction(itemType, auctionID, callings, rarity, level, category, name, price)
		name = name:upper()
		
		for calling, flag in pairs(callings) do
			if flag then
				self.searchTree[calling] = self.searchTree[calling] or {}
				self.searchTree[calling][rarity] = self.searchTree[calling][rarity] or {}
				self.searchTree[calling][rarity][level] = self.searchTree[calling][rarity][level] or {}
				self.searchTree[calling][rarity][level][category] = self.searchTree[calling][rarity][level][category] or {}
				self.searchTree[calling][rarity][level][category][name] = self.searchTree[calling][rarity][level][category][name] or {}
				self.searchTree[calling][rarity][level][category][name][price] = self.searchTree[calling][rarity][level][category][name][price] or {}
				self.searchTree[calling][rarity][level][category][name][price][auctionID] = itemType
			end
		end
		
		self.auctionIDs[auctionID] = itemType
	end
	
	function nativeIndexer:RemoveAuction(auctionID, callings, rarity, level, category, name, price)
		if not self.auctionIDs[auctionID] then return end
		
		name = name:upper()
		
		for calling, flag in pairs(callings) do
			if flag then
				self.searchTree[calling][rarity][level][category][name][price][auctionID] = nil
			end
		end
		
		self.auctionIDs[auctionID] = nil
	end
	
	function nativeIndexer:Search(calling, rarity, levelMin, levelMax, category, priceMin, priceMax, name)
		local results = {}
		
		name = name and name:upper() or nil
		
		for callingName, callingSubtree in pairs(self.searchTree) do
			if not calling or calling == callingName then
				for rarityName, raritySubtree in pairs(callingSubtree) do
					if not rarity or rarity <= rarityName then
						for level, levelSubtree in pairs(raritySubtree) do
							if (not levelMin or level >= levelMin) and (not levelMax or level <= levelMax) then
								for categoryName, categorySubtree in pairs(levelSubtree) do
									if not category or categoryName:sub(1, category:len()) == category then
										for itemName, nameSubtree in pairs(categorySubtree) do
											if not name or itemName:find(name) then
												for price, priceSubtree in pairs(nameSubtree) do
													if (not priceMin or price >= priceMin) and (not priceMax or price <= priceMax) then
														for auctionID, itemType in pairs(priceSubtree) do
															results[auctionID] = itemType
														end
													end
													Release()
												end
											end
											Release()
										end
									end
									Release()
								end
							end
							Release()
						end
					end
					Release()
				end
			end
			Release()
		end
		
		return results
	end
	
	function nativeIndexer:GetItemTypes(auctionIDs)
		local results = {}

		for auctionID in pairs(auctionIDs) do
			results[auctionID] = self.auctionIDs[auctionID]
		end
		
		return results
	end
	
	return nativeIndexer
end
