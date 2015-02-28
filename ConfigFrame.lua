-- ***************************************************************************************************************************************************
-- * ConfigFrame.lua                                                                                                                                 *
-- ***************************************************************************************************************************************************
-- * Config tab frame                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.1 / 2012.08.28 / Baanano: Rewritten for 0.4.1                                                                                               *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local BASE_CATEGORY = InternalInterface.Category.BASE_CATEGORY
local BuildConfigFrame = InternalInterface.UI.BuildConfigFrame
local CDetail = InternalInterface.Category.Detail
local CList = InternalInterface.Category.List
local ClearCategoryModels = InternalInterface.PGCConfig.ClearCategoryModels
local DataGrid = Yague.DataGrid
local Dropdown = Yague.Dropdown
local GetAuctionSearchers = LibPGCEx.GetAuctionSearchers
local GetCategoryModels = InternalInterface.PGCConfig.GetCategoryModels
local GetPopupManager = InternalInterface.Output.GetPopupManager
local GetPriceComplex = LibPGCEx.GetPriceComplex
local GetPriceFallbacks = LibPGCEx.GetPriceFallbacks
local GetPriceFallbackExtraDescription = LibPGCEx.GetPriceFallbackExtraDescription
local GetPriceMatchers = LibPGCEx.GetPriceMatchers
local GetPriceMatcherExtraDescription = LibPGCEx.GetPriceMatcherExtraDescription
local GetPriceModels = LibPGCEx.GetPriceModels
local GetPriceSamplers = LibPGCEx.GetPriceSamplers
local GetPriceSamplerExtraDescription = LibPGCEx.GetPriceSamplerExtraDescription
local GetPriceStats = LibPGCEx.GetPriceStats
local GetPriceStatExtraDescription = LibPGCEx.GetPriceStatExtraDescription
local GetRarityColor = InternalInterface.Utility.GetRarityColor
local L = InternalInterface.Localization.L
local MMax = math.max
local MMin = math.min
local MoneySelector = Yague.MoneySelector
local OsTime = os.time
local Panel = Yague.Panel
local RegisterPopupConstructor = Yague.RegisterPopupConstructor
local SFormat = string.format
local SLen = string.len
local SaveCategoryModels = InternalInterface.PGCConfig.SaveCategoryModels
local ScoreColorByIndex = InternalInterface.UI.ScoreColorByIndex
local ShadowedText = Yague.ShadowedText
local Slider = Yague.Slider
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local ipairs = ipairs
local pairs = pairs
local type = type
local unpack = unpack

local function BooleanDotCellType(name, parent)
	local baseCell = UICreateFrame("Frame", name, parent)
	
	local dotTexture = UICreateFrame("Texture", name .. ".DotTexture", baseCell)

	local assignedKey = nil
	local interactable = nil

	dotTexture:SetPoint("CENTER", baseCell, "CENTER")
	dotTexture:SetTextureAsync(addonID, "Textures/DotGrey.png")
	
	function baseCell:SetValue(key, value, width, extra)
		assignedKey = key
		
		local active = value
		if extra and extra.Eval then
			active = extra.Eval(value, key)
		end
		
		if active == nil then
			dotTexture:SetTextureAsync(addonID, "Textures/DotGrey.png")
			interactable = nil
		else
			dotTexture:SetTextureAsync(addonID, active and "Textures/DotGreen.png" or "Textures/DotRed.png")
			interactable = extra and extra.Interactable
		end
	end

	function dotTexture.Event:LeftClick()
		if assignedKey and type(interactable) == "function" then
			interactable(assignedKey)
		end
	end

	return baseCell
end

local function UnsavedChangesPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".UnsavedChangesPopup", parent)
	
	local titleText = ShadowedText(frame:GetName() .. ".TitleText", frame:GetContent())
	local contentText = UICreateFrame("Text", frame:GetName() .. ".ContentText", frame:GetContent())
	local continueButton = UICreateFrame("RiftButton", frame:GetName() .. ".ContinueButton", frame:GetContent())
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())	
	
	frame:SetWidth(420)
	frame:SetHeight(130)
	
	titleText:SetPoint("TOPCENTER", frame:GetContent(), "TOPCENTER", 0, 10)
	titleText:SetFontSize(14)
	titleText:SetFontColor(1, 1, 0.75, 1)
	titleText:SetShadowOffset(2, 2)
	titleText:SetText(L["UnsavedChangesPopup/Title"])
	
	contentText:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 10, 40)
	contentText:SetText(L["UnsavedChangesPopup/ContentText"])
	
	continueButton:SetPoint("BOTTOMRIGHT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	continueButton:SetText(L["UnsavedChangesPopup/ButtonContinue"])
	
	cancelButton:SetPoint("BOTTOMLEFT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	cancelButton:SetText(L["UnsavedChangesPopup/ButtonCancel"])
	
	function frame:SetData(onContinue, onCancel)
		function continueButton.Event:LeftPress()
			onContinue() 
			parent:HidePopup(addonID .. ".UnsavedChanges", frame)
		end

		function cancelButton.Event:LeftPress()
			onCancel() 
			parent:HidePopup(addonID .. ".UnsavedChanges", frame)
		end
	end
	
	return frame
end
RegisterPopupConstructor(addonID .. ".UnsavedChanges", UnsavedChangesPopup)

local function NewModelPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".NewModelPopup", parent)
	
	local titleText = ShadowedText(frame:GetName() .. ".TitleText", frame:GetContent())
	local contentText = UICreateFrame("Text", frame:GetName() .. ".ContentText", frame:GetContent())
	local modelTypeSelector = Dropdown(frame:GetName() .. ".ModelTypeSelector", frame:GetContent())
	local continueButton = UICreateFrame("RiftButton", frame:GetName() .. ".ContinueButton", frame:GetContent())
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())	
	
	frame:SetWidth(420)
	frame:SetHeight(140)
	
	titleText:SetPoint("TOPCENTER", frame:GetContent(), "TOPCENTER", 0, 10)
	titleText:SetFontSize(14)
	titleText:SetFontColor(1, 1, 0.75, 1)
	titleText:SetShadowOffset(2, 2)
	titleText:SetText(L["NewModelPopup/Title"])
	
	contentText:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 10, 40)
	contentText:SetText(L["NewModelPopup/ModelType"])
	
	modelTypeSelector:SetPoint("TOPRIGHT", frame:GetContent(), "TOPRIGHT", -10, 35)
	modelTypeSelector:SetPoint("CENTERLEFT", contentText, "CENTERRIGHT", 10, 0)
	modelTypeSelector:SetTextSelector("displayName")
	modelTypeSelector:SetOrderSelector("order")
	modelTypeSelector:SetValues({
		["simple"] = { displayName = L["General/ModelTypeSimple"], order = 1 },
		["statistical"] = { displayName = L["General/ModelTypeStatistical"], order = 2 },
		["complex"] = { displayName = L["General/ModelTypeComplex"], order = 3 },
		["composite"] = { displayName = L["General/ModelTypeComposite"], order = 4 },
	})
	
	continueButton:SetPoint("BOTTOMRIGHT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	continueButton:SetText(L["NewModelPopup/ButtonContinue"])
	
	cancelButton:SetPoint("BOTTOMLEFT", frame:GetContent(), "BOTTOMCENTER", 0, -10)
	cancelButton:SetText(L["NewModelPopup/ButtonCancel"])
	
	function cancelButton.Event:LeftPress()
		parent:HidePopup(addonID .. ".NewModel", frame)
	end

	function frame:SetData(onContinue)
		function continueButton.Event:LeftPress()
			onContinue((modelTypeSelector:GetSelectedValue())) 
			parent:HidePopup(addonID .. ".NewModel", frame)
		end
	end
	
	return frame
end
RegisterPopupConstructor(addonID .. ".NewModel", NewModelPopup)

local function BuildMatcherFrame(name, parent, matcherID, matcherName, matcherMove)
	local matcherFrame = UICreateFrame("Frame", name, parent)
	
	local matcherTitle = UICreateFrame("Text", name .. ".MatcherTitle", matcherFrame)
	local matcherUnfold = UICreateFrame("Texture", name .. ".MatcherUnfold", matcherFrame)
	local matcherDelete = UICreateFrame("Texture", name .. ".MatcherDelete", matcherFrame)
	local matcherUp = UICreateFrame("Texture", name .. ".MatcherUp", matcherFrame)
	local matcherDown = UICreateFrame("Texture", name .. ".MatcherDown", matcherFrame)
	
	local matcherExtra = GetPriceMatcherExtraDescription(matcherID)
	local configFrame = BuildConfigFrame(name .. ".ConfigFrame", matcherFrame, matcherExtra)
	
	matcherFrame:SetHeight(24)
	
	matcherUnfold:SetPoint("TOPLEFT", matcherFrame, "TOPLEFT")
	matcherUnfold:SetTextureAsync(addonID, "Textures/ArrowDown.png")
	
	matcherDelete:SetPoint("TOPRIGHT", matcherFrame, "TOPRIGHT")
	matcherDelete:SetTextureAsync(addonID, "Textures/DeleteEnabled.png")
	
	matcherDown:SetPoint("TOPRIGHT", matcherDelete, "CENTERLEFT", -5, -3)
	matcherDown:SetTextureAsync(addonID, "Textures/MoveDown.png")
	
	matcherUp:SetPoint("BOTTOMRIGHT", matcherDelete, "CENTERLEFT", -5, 3)
	matcherUp:SetTextureAsync(addonID, "Textures/MoveUp.png")
	
	matcherTitle:SetPoint("CENTERLEFT", matcherUnfold, "CENTERRIGHT", 5, 1)
	matcherTitle:SetFontSize(14)
	matcherTitle:SetText(matcherName)
	
	if configFrame then
		configFrame:SetPoint("TOPLEFT", matcherFrame, "TOPLEFT", 0, 30)
		configFrame:SetPoint("TOPRIGHT", matcherFrame, "TOPRIGHT", 0, 30)
		configFrame:SetVisible(false)
	else
		matcherUnfold:SetVisible(false)
	end
	
	function matcherUnfold.Event:LeftClick()
		if configFrame then
			local unfolded = configFrame:GetVisible()
			configFrame:SetVisible(not unfolded)
			matcherUnfold:SetTextureAsync(addonID, unfolded and "Textures/ArrowDown.png" or "Textures/ArrowUp.png")
			matcherFrame:SetHeight(unfolded and 24 or configFrame:GetBottom() - matcherFrame:GetTop())
		end
	end
	
	function matcherDelete.Event:LeftClick()
		matcherMove(matcherID)
	end
	
	function matcherUp.Event:LeftClick()
		matcherMove(matcherID, -1)
	end
	
	function matcherDown.Event:LeftClick()
		matcherMove(matcherID, 1)
	end
	
	function matcherFrame:GetExtra()
		if configFrame then
			return configFrame:GetExtra()
		end
	end
	
	function matcherFrame:SetExtra(extra)
		if configFrame then
			configFrame:SetExtra(extra)
			if configFrame:GetVisible() then
				matcherUnfold.Event.LeftClick(matcherUnfold) -- FIXME Event model
			end
		end
	end
	
	return matcherFrame
end

local function BuildMatchersFrame(name, parent)
	local frame = UICreateFrame("Frame", name, parent)

	local titleLabel = ShadowedText(name .. ".TitleLabel", frame)
	local startAnchor = UICreateFrame("Frame", name .. ".StartAnchor", frame)
	local endAnchor = UICreateFrame("Frame", name .. ".EndAnchor", frame)
	local matcherButton = UICreateFrame("RiftButton", name .. ".MatcherButton", frame)
	local matcherSelector = Dropdown(name .. ".MatcherSelector", frame)
	
	local allMatchers = GetPriceMatchers()
	local usedMatchers = {}
	local matcherFrames = {}

	local function ResetHeight()
		frame:SetHeight(endAnchor:GetBottom() - frame:GetTop())
	end
	
	local function RecalcMatchers()
		local lastMatcher = startAnchor
		
		local exclude = {}
		for _, matcherID in ipairs(usedMatchers) do
			local matcherFrame = matcherFrames[matcherID]
			
			matcherFrame:SetPoint("TOPLEFT", lastMatcher, "BOTTOMLEFT", 0, 10)
			matcherFrame:SetPoint("TOPRIGHT", lastMatcher, "BOTTOMRIGHT", 0, 10)
			matcherFrame:SetVisible(true)
			
			lastMatcher = matcherFrame
			exclude[matcherID] = true
		end
		
		local unusedMatchers = {}
		for matcherID, matcherName in pairs(allMatchers) do
			if not exclude[matcherID] then
				unusedMatchers[matcherID] = { displayName = matcherName, }
				matcherFrames[matcherID]:SetVisible(false)
			end
		end

		if next(unusedMatchers) then
			matcherButton:ClearAll()
			matcherButton:SetPoint("TOPRIGHT", lastMatcher, "BOTTOMRIGHT", 5, 10)
			matcherButton:SetVisible(true)
		
			matcherSelector:ClearAll()
			matcherSelector:SetPoint("TOPLEFT", lastMatcher, "BOTTOMLEFT", 0, 12)
			matcherSelector:SetPoint("CENTERRIGHT", matcherButton, "CENTERLEFT", -5, 0)
			matcherSelector:SetValues(unusedMatchers)
			matcherSelector:SetVisible(true)
			
			endAnchor:ClearAll()
			endAnchor:SetPoint("TOPLEFT", matcherSelector, "BOTTOMLEFT")
			endAnchor:SetPoint("BOTTOMRIGHT", matcherSelector, "BOTTOMLEFT")
		else
			matcherButton:SetVisible(false)
			matcherSelector:SetVisible(false)
			
			endAnchor:ClearAll()
			endAnchor:SetPoint("TOPLEFT", lastMatcher, "BOTTOMLEFT")
			endAnchor:SetPoint("BOTTOMRIGHT", lastMatcher, "BOTTOMLEFT")
		end
		
		ResetHeight()
	end

	local function MoveMatcher(matcherID, direction)
		local newUsedMatchers = {}
		
		local matcherIndex = nil
		for index, id in ipairs(usedMatchers) do
			if id ~= matcherID then
				TInsert(newUsedMatchers, id)
			else
				matcherIndex = index
			end
		end
		
		if direction and matcherIndex then
			matcherIndex = MMin(MMax(1, matcherIndex + direction), #usedMatchers)
			TInsert(newUsedMatchers, matcherIndex, matcherID)
		end

		usedMatchers = newUsedMatchers
		
		RecalcMatchers()		
	end
	
	for matcherID, matcherName in pairs(allMatchers) do
		local matcherFrame = BuildMatcherFrame(name .. ".Matchers." .. matcherID, frame, matcherID, matcherName, MoveMatcher)
		if matcherFrame then
			matcherFrames[matcherID] = matcherFrame
			matcherFrame.Event.Size = ResetHeight
			matcherFrame:SetVisible(false)
		end
	end
	
	frame:SetLayer(9800)
	
	titleLabel:SetPoint("TOPCENTER", frame, "TOPCENTER")
	titleLabel:SetFontSize(15)
	titleLabel:SetFontColor(1, 1, 0.75, 1)
	titleLabel:SetShadowOffset(2, 2)
	titleLabel:SetText(L["MatcherPopupFrame/Title"])
	
	startAnchor:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 20)
	startAnchor:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 20)
	startAnchor:SetVisible(false)
	
	endAnchor:SetVisible(false)
	
	matcherButton:SetText(L["MatcherPopupFrame/ButtonAdd"])
	
	matcherSelector:SetTextSelector("displayName")
	matcherSelector:SetOrderSelector("displayName")
	
	function matcherButton.Event:LeftPress()
		local matcherID = matcherSelector:GetSelectedValue()
		TInsert(usedMatchers, matcherID)
		RecalcMatchers()
	end

	function frame:GetMatcherConfig()
		local config = {}
		
		for _, matcherID in ipairs(usedMatchers) do
			local matcherFrame = matcherFrames[matcherID]
			local extra = matcherFrame:GetExtra()
			TInsert(config, { id = matcherID, extra = extra, })
		end
		
		return config
	end
	
	function frame:SetMatcherConfig(config)
		config = config or {}
		
		usedMatchers = {}
		for _, matcherConfig in ipairs(config) do
			local matcherID = matcherConfig.id
			if allMatchers[matcherID] then
				local matcherFrame = matcherFrames[matcherID]
				TInsert(usedMatchers, matcherID)
				matcherFrame:SetExtra(matcherConfig.extra)
			end
		end
		
		RecalcMatchers()
	end
	
	RecalcMatchers()

	return frame
end

local function BuildFilterFrame(name, parent, filterID, filterName, filterMove)
	local filterFrame = UICreateFrame("Frame", name, parent)
	
	local filterTitle = UICreateFrame("Text", name .. ".FilterTitle", filterFrame)
	local filterUnfold = UICreateFrame("Texture", name .. ".FilterUnfold", filterFrame)
	local filterDelete = UICreateFrame("Texture", name .. ".FilterDelete", filterFrame)
	local filterUp = UICreateFrame("Texture", name .. ".FilterUp", filterFrame)
	local filterDown = UICreateFrame("Texture", name .. ".FilterDown", filterFrame)
	
	local filterExtra = GetPriceSamplerExtraDescription(filterID)
	local configFrame = BuildConfigFrame(name .. ".ConfigFrame", filterFrame, filterExtra)
	
	filterFrame:SetHeight(24)
	
	filterUnfold:SetPoint("TOPLEFT", filterFrame, "TOPLEFT")
	filterUnfold:SetTextureAsync(addonID, "Textures/ArrowDown.png")
	
	filterDelete:SetPoint("TOPRIGHT", filterFrame, "TOPRIGHT")
	filterDelete:SetTextureAsync(addonID, "Textures/DeleteEnabled.png")
	
	filterDown:SetPoint("TOPRIGHT", filterDelete, "CENTERLEFT", -5, -3)
	filterDown:SetTextureAsync(addonID, "Textures/MoveDown.png")
	
	filterUp:SetPoint("BOTTOMRIGHT", filterDelete, "CENTERLEFT", -5, 3)
	filterUp:SetTextureAsync(addonID, "Textures/MoveUp.png")
	
	filterTitle:SetPoint("CENTERLEFT", filterUnfold, "CENTERRIGHT", 5, 1)
	filterTitle:SetFontSize(14)
	filterTitle:SetText(filterName)
	
	if configFrame then
		configFrame:SetPoint("TOPLEFT", filterFrame, "TOPLEFT", 0, 30)
		configFrame:SetPoint("TOPRIGHT", filterFrame, "TOPRIGHT", 0, 30)
		configFrame:SetVisible(false)
	else
		filterUnfold:SetVisible(false)
	end
	
	function filterUnfold.Event:LeftClick()
		if configFrame then
			local unfolded = configFrame:GetVisible()
			configFrame:SetVisible(not unfolded)
			filterUnfold:SetTextureAsync(addonID, unfolded and "Textures/ArrowDown.png" or "Textures/ArrowUp.png")
			filterFrame:SetHeight(unfolded and 24 or configFrame:GetBottom() - filterFrame:GetTop())
		end
	end
	
	function filterDelete.Event:LeftClick()
		filterMove(filterID)
	end
	
	function filterUp.Event:LeftClick()
		filterMove(filterID, -1)
	end
	
	function filterDown.Event:LeftClick()
		filterMove(filterID, 1)
	end
	
	function filterFrame:GetExtra()
		if configFrame then
			return configFrame:GetExtra()
		end
	end
	
	function filterFrame:SetExtra(extra)
		if configFrame then
			configFrame:SetExtra(extra)
			if configFrame:GetVisible() then
				filterUnfold.Event.LeftClick(filterUnfold) -- FIXME Event model
			end
		end
	end
	
	return filterFrame
end

local function BuildFiltersFrame(name, parent)
	local frame = UICreateFrame("Frame", name, parent)

	local titleLabel = ShadowedText(name .. ".TitleLabel", frame)
	local startAnchor = UICreateFrame("Frame", name .. ".StartAnchor", frame)
	local endAnchor = UICreateFrame("Frame", name .. ".EndAnchor", frame)
	local filterButton = UICreateFrame("RiftButton", name .. ".FilterButton", frame)
	local filterSelector = Dropdown(name .. ".FilterSelector", frame)
	
	local allFilters = GetPriceSamplers()
	local usedFilters = {}
	local filterFrames = {}

	local function ResetHeight()
		frame:SetHeight(endAnchor:GetBottom() - frame:GetTop())
	end
	
	local function RecalcFilters()
		local lastFilter = startAnchor
		
		local exclude = {}
		for _, filterID in ipairs(usedFilters) do
			local filterFrame = filterFrames[filterID]
			
			filterFrame:SetPoint("TOPLEFT", lastFilter, "BOTTOMLEFT", 0, 10)
			filterFrame:SetPoint("TOPRIGHT", lastFilter, "BOTTOMRIGHT", 0, 10)
			filterFrame:SetVisible(true)
			
			lastFilter = filterFrame
			exclude[filterID] = true
		end
		
		local unusedFilters = {}
		for filterID, filterName in pairs(allFilters) do
			if not exclude[filterID] then
				unusedFilters[filterID] = { displayName = filterName, }
				filterFrames[filterID]:SetVisible(false)
			end
		end

		if next(unusedFilters) then
			filterButton:ClearAll()
			filterButton:SetPoint("TOPRIGHT", lastFilter, "BOTTOMRIGHT", 5, 10)
			filterButton:SetVisible(true)
		
			filterSelector:ClearAll()
			filterSelector:SetPoint("TOPLEFT", lastFilter, "BOTTOMLEFT", 0, 12)
			filterSelector:SetPoint("CENTERRIGHT", filterButton, "CENTERLEFT", -5, 0)
			filterSelector:SetValues(unusedFilters)
			filterSelector:SetVisible(true)
			
			endAnchor:ClearAll()
			endAnchor:SetPoint("TOPLEFT", filterSelector, "BOTTOMLEFT")
			endAnchor:SetPoint("BOTTOMRIGHT", filterSelector, "BOTTOMLEFT")
		else
			filterButton:SetVisible(false)
			filterSelector:SetVisible(false)
			
			endAnchor:ClearAll()
			endAnchor:SetPoint("TOPLEFT", lastFilter, "BOTTOMLEFT")
			endAnchor:SetPoint("BOTTOMRIGHT", lastFilter, "BOTTOMLEFT")
		end
		
		ResetHeight()
	end

	local function MoveFilter(filterID, direction)
		local newUsedFilters = {}
		
		local filterIndex = nil
		for index, id in ipairs(usedFilters) do
			if id ~= filterID then
				TInsert(newUsedFilters, id)
			else
				filterIndex = index
			end
		end
		
		if direction and filterIndex then
			filterIndex = MMin(MMax(1, filterIndex + direction), #usedFilters)
			TInsert(newUsedFilters, filterIndex, filterID)
		end

		usedFilters = newUsedFilters
		
		RecalcFilters()		
	end
	
	for filterID, filterName in pairs(allFilters) do
		local filterFrame = BuildFilterFrame(name .. ".Filters." .. filterID, frame, filterID, filterName, MoveFilter)
		if filterFrame then
			filterFrames[filterID] = filterFrame
			filterFrame.Event.Size = ResetHeight
			filterFrame:SetVisible(false)
		end
	end
	
	frame:SetLayer(9900)
	
	titleLabel:SetPoint("TOPCENTER", frame, "TOPCENTER")
	titleLabel:SetFontSize(15)
	titleLabel:SetFontColor(1, 1, 0.75, 1)
	titleLabel:SetShadowOffset(2, 2)
	titleLabel:SetText(L["FilterPopupFrame/Title"])
	
	startAnchor:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 20)
	startAnchor:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 20)
	startAnchor:SetVisible(false)
	
	endAnchor:SetVisible(false)
	
	filterButton:SetText(L["FilterPopupFrame/ButtonAdd"])
	
	filterSelector:SetTextSelector("displayName")
	filterSelector:SetOrderSelector("displayName")
	
	function filterButton.Event:LeftPress()
		local filterID = filterSelector:GetSelectedValue()
		TInsert(usedFilters, filterID)
		RecalcFilters()
	end

	function frame:GetFilterConfig()
		local config = {}
		
		for _, filterID in ipairs(usedFilters) do
			local filterFrame = filterFrames[filterID]
			local extra = filterFrame:GetExtra()
			TInsert(config, { id = filterID, extra = extra, })
		end
		
		return config
	end
	
	function frame:SetFilterConfig(config)
		config = config or {}
		
		usedFilters = {}
		for _, filterConfig in ipairs(config) do
			local filterID = filterConfig.id
			if allFilters[filterID] then
				local filterFrame = filterFrames[filterID]
				TInsert(usedFilters, filterID)
				filterFrame:SetExtra(filterConfig.extra)
			end
		end
		
		RecalcFilters()
	end
	
	RecalcFilters()

	return frame
end

local function BuildModelFrame(name, parent, modelID, modelName, modelDrop)
	local frame = UICreateFrame("Frame", name, parent)

	local modelDelete = UICreateFrame("Texture", name .. ".ModelDelete", frame)
	local modelTitle = UICreateFrame("Text", name .. ".ModelTitle", frame)
	local modelSlider = Slider(name .. ".ModelSlider", frame)
	
	frame:SetHeight(24)
	
	modelDelete:SetPoint("TOPLEFT", frame, "TOPLEFT")
	modelDelete:SetTextureAsync(addonID, "Textures/DeleteEnabled.png")	
	
	modelTitle:SetPoint("CENTERLEFT", modelDelete, "CENTERRIGHT", 5, 1)
	modelTitle:SetFontSize(14)
	modelTitle:SetText(modelName)
	
	modelSlider:SetPoint("RIGHT", frame, "RIGHT")
	modelSlider:SetPoint("CENTERLEFT", modelTitle, "CENTERLEFT", 200, -2)
	modelSlider:SetRange(1, 20)

	function modelDelete.Event:LeftClick()
		modelDrop(modelID)
	end	
	
	function frame:SetModelName(modelName)
		modelTitle:SetText(modelName or "")
	end
	
	function frame:GetValue()
		return (modelSlider:GetPosition())
	end
	
	function frame:SetValue(value)
		modelSlider:SetPosition(value)
	end
	
	return frame
end

local function SimplePriceModelPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".SimplePriceModelPopup", parent)
	
	local nameLabel = ShadowedText(frame:GetName() .. ".NameLabel", frame:GetContent())
	local namePanel = Panel(frame:GetName() .. ".NamePanel", frame:GetContent())
	local nameField = UICreateFrame("RiftTextfield", frame:GetName() .. ".NameField", namePanel:GetContent())
	
	local fallbackSelector = Dropdown(frame:GetName() .. ".FallbackSelector", frame:GetContent())
	
	local usageFrame = UICreateFrame("Frame", frame:GetName() .. ".UsageFrame", frame:GetContent())
	local matcherFrame = BuildMatchersFrame(frame:GetName() .. ".MatcherFrame", frame:GetContent())
	
	local saveButton = UICreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame:GetContent())
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())
	
	local wasEnabled = false
	
	local allFallbacks = GetPriceFallbacks()
	local fallbacks = {}
	local fallbackFrames = {}
	for fallbackID, fallbackName in pairs(allFallbacks) do
		fallbacks[fallbackID] = { displayName = fallbackName }
		
		local fallbackFrame = BuildConfigFrame(usageFrame:GetName() .. fallbackID, usageFrame, GetPriceFallbackExtraDescription(fallbackID))
		fallbackFrame:SetPoint("TOPLEFT", usageFrame, "TOPLEFT")
		fallbackFrame:SetPoint("TOPRIGHT", usageFrame, "TOPRIGHT")
		fallbackFrame:SetVisible(false)
		
		fallbackFrames[fallbackID] = fallbackFrame
	end
	
	local function GetModelInfo()
		local name = nameField:GetText()
		local fallbackID = fallbackSelector:GetSelectedValue()
		local fallbackExtra = fallbackFrames[fallbackID]:GetExtra()
		local usage = { id = fallbackID, extra = fallbackExtra }
		local matchers = matcherFrame:GetMatcherConfig()
		
		return { name = name, modelType = "simple", usage = usage, matchers = matchers, enabled = wasEnabled, original = false, own = true }
	end
	
	local function ResetHeight()
		frame:SetHeight(cancelButton:GetBottom() + 15 - frame:GetTop())
	end
	
	local function RecalcFallbacks()
		local fallbackID = fallbackSelector:GetSelectedValue()
		
		for id, fallbackFrame in pairs(fallbackFrames) do
			if id == fallbackID then
				fallbackFrame:SetVisible(true)
				usageFrame:SetHeight(fallbackFrame:GetBottom() - usageFrame:GetTop())
			else
				fallbackFrame:SetVisible(false)
			end
		end
		
		ResetHeight()
	end
	
	local function ResetSaveButton()
		saveButton:SetEnabled(nameField:GetText() ~= "")
	end
	
	frame:SetWidth(800)
	
	nameLabel:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 25, 15)
	nameLabel:SetFontSize(14)
	nameLabel:SetFontColor(1, 1, 0.75, 1)
	nameLabel:SetShadowOffset(2, 2)
	nameLabel:SetText(L["SimpleModelPopup/Name"])
	
	namePanel:SetPoint("CENTERLEFT", nameLabel, "CENTERRIGHT", 10, 0)
	namePanel:SetPoint("TOPRIGHT", frame:GetContent(), "TOPRIGHT", -25, 12)
	namePanel:SetInvertedBorder(true)
	namePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	nameField:SetPoint("CENTERLEFT", namePanel:GetContent(), "CENTERLEFT", 2, 1)
	nameField:SetPoint("CENTERRIGHT", namePanel:GetContent(), "CENTERRIGHT", -2, 1)
	nameField:SetText("")
	
	fallbackSelector:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 15, 50)
	fallbackSelector:SetPoint("BOTTOMRIGHT", frame:GetContent(), "TOPRIGHT", -15, 80)
	fallbackSelector:SetTextSelector("displayName")
	fallbackSelector:SetOrderSelector("displayName")
	fallbackSelector:SetValues(fallbacks)
	
	usageFrame:SetPoint("TOPLEFT", fallbackSelector, "BOTTOMLEFT", 0, 10)
	usageFrame:SetPoint("TOPRIGHT", fallbackSelector, "BOTTOMRIGHT", 0, 10)
	
	matcherFrame:SetPoint("TOPLEFT", usageFrame, "BOTTOMLEFT", 0, 10)
	matcherFrame:SetPoint("TOPRIGHT", usageFrame, "BOTTOMRIGHT", 0, 10)
	
	saveButton:SetPoint("TOPCENTER", matcherFrame, 1/3, 1, 0, 10)
	saveButton:SetText(L["SimpleModelPopup/ButtonSave"])
	saveButton:SetEnabled(false)
	
	cancelButton:SetPoint("TOPCENTER", matcherFrame, 2/3, 1, 0, 10)
	cancelButton:SetText(L["SimpleModelPopup/ButtonCancel"])
	
	function namePanel.Event:LeftClick()
		nameField:SetKeyFocus(true)
	end

	function nameField.Event:KeyFocusGain()
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end

	function nameField.Event:TextfieldChange()
		ResetSaveButton()
	end
	
	function fallbackSelector.Event:SelectionChanged()
		RecalcFallbacks()
	end
	
	function matcherFrame.Event:Size()
		ResetHeight()
	end
	
	function cancelButton.Event:LeftPress()
		parent:HidePopup(addonID .. ".SimplePriceModel", frame)
	end

	function frame:SetData(modelInfo, onSave)
		nameField:SetText(modelInfo.name or "")
		local usage = modelInfo.usage
		if allFallbacks[usage.id] then
			fallbackSelector:SetSelectedKey(usage.id)
			fallbackFrames[usage.id]:SetExtra(usage.extra)
		end
		matcherFrame:SetMatcherConfig(modelInfo.matchers)
		wasEnabled = modelInfo.enabled

		function saveButton.Event:LeftPress()
			onSave(GetModelInfo())
			parent:HidePopup(addonID .. ".SimplePriceModel", frame)
		end
		
		ResetSaveButton()
	end
	
	RecalcFallbacks()
	
	return frame
end
RegisterPopupConstructor(addonID .. ".SimplePriceModel", SimplePriceModelPopup)

local function StatisticalPriceModelPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".StatisticalPriceModelPopup", parent)
	
	local nameLabel = ShadowedText(frame:GetName() .. ".NameLabel", frame:GetContent())
	local namePanel = Panel(frame:GetName() .. ".NamePanel", frame:GetContent())
	local nameField = UICreateFrame("RiftTextfield", frame:GetName() .. ".NameField", namePanel:GetContent())
	
	local statSelector = Dropdown(frame:GetName() .. ".StatSelector", frame:GetContent())

	local usageFrame = UICreateFrame("Frame", frame:GetName() .. ".UsageFrame", frame:GetContent())
	local filterFrame = BuildFiltersFrame(frame:GetName() .. ".FilterFrame", frame:GetContent())
	local matcherFrame = BuildMatchersFrame(frame:GetName() .. ".MatcherFrame", frame:GetContent())
	
	local saveButton = UICreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame:GetContent())
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())
	
	local wasEnabled = false
	
	local allStats = GetPriceStats()
	local stats = {}
	local statFrames = {}
	for statID, statName in pairs(allStats) do
		stats[statID] = { displayName = statName }
		
		local statFrame = BuildConfigFrame(usageFrame:GetName() .. statID, usageFrame, GetPriceStatExtraDescription(statID))
		statFrame:SetPoint("TOPLEFT", usageFrame, "TOPLEFT")
		statFrame:SetPoint("TOPRIGHT", usageFrame, "TOPRIGHT")
		statFrame:SetVisible(false)
		
		statFrames[statID] = statFrame
	end
	
	local function GetModelInfo()
		local name = nameField:GetText()
		local statID = statSelector:GetSelectedValue()
		local statExtra = statFrames[statID]:GetExtra()
		local filters = filterFrame:GetFilterConfig()
		local usage = { id = statID, extra = statExtra, filters = filters }
		local matchers = matcherFrame:GetMatcherConfig()
		
		return { name = name, modelType = "statistical", usage = usage, matchers = matchers, enabled = wasEnabled, original = false, own = true }
	end
	
	local function ResetHeight()
		frame:SetHeight(cancelButton:GetBottom() + 15 - frame:GetTop())
	end
	
	local function RecalcStats()
		local statID = statSelector:GetSelectedValue()
		
		for id, statFrame in pairs(statFrames) do
			if id == statID then
				statFrame:SetVisible(true)
				usageFrame:SetHeight(statFrame:GetBottom() - usageFrame:GetTop())
			else
				statFrame:SetVisible(false)
			end
		end
		
		ResetHeight()
	end
	
	local function ResetSaveButton()
		saveButton:SetEnabled(nameField:GetText() ~= "")
	end
	
	frame:SetWidth(800)
	
	nameLabel:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 25, 15)
	nameLabel:SetFontSize(14)
	nameLabel:SetFontColor(1, 1, 0.75, 1)
	nameLabel:SetShadowOffset(2, 2)
	nameLabel:SetText(L["StatisticalModelPopup/Name"])
	
	namePanel:SetPoint("CENTERLEFT", nameLabel, "CENTERRIGHT", 10, 0)
	namePanel:SetPoint("TOPRIGHT", frame:GetContent(), "TOPRIGHT", -25, 12)
	namePanel:SetInvertedBorder(true)
	namePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	nameField:SetPoint("CENTERLEFT", namePanel:GetContent(), "CENTERLEFT", 2, 1)
	nameField:SetPoint("CENTERRIGHT", namePanel:GetContent(), "CENTERRIGHT", -2, 1)
	nameField:SetText("")
	
	statSelector:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 15, 50)
	statSelector:SetPoint("BOTTOMRIGHT", frame:GetContent(), "TOPRIGHT", -15, 80)
	statSelector:SetTextSelector("displayName")
	statSelector:SetOrderSelector("displayName")
	statSelector:SetValues(stats)
	
	usageFrame:SetPoint("TOPLEFT", statSelector, "BOTTOMLEFT", 0, 10)
	usageFrame:SetPoint("TOPRIGHT", statSelector, "BOTTOMRIGHT", 0, 10)
	
	filterFrame:SetPoint("TOPLEFT", usageFrame, "BOTTOMLEFT", 0, 10)
	filterFrame:SetPoint("TOPRIGHT", usageFrame, "BOTTOMRIGHT", 0, 10)
	
	matcherFrame:SetPoint("TOPLEFT", filterFrame, "BOTTOMLEFT", 0, 10)
	matcherFrame:SetPoint("TOPRIGHT", filterFrame, "BOTTOMRIGHT", 0, 10)
	
	saveButton:SetPoint("TOPCENTER", matcherFrame, 1/3, 1, 0, 10)
	saveButton:SetText(L["StatisticalModelPopup/ButtonSave"])
	saveButton:SetEnabled(false)
	
	cancelButton:SetPoint("TOPCENTER", matcherFrame, 2/3, 1, 0, 10)
	cancelButton:SetText(L["StatisticalModelPopup/ButtonCancel"])
	
	function namePanel.Event:LeftClick()
		nameField:SetKeyFocus(true)
	end

	function nameField.Event:KeyFocusGain()
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end

	function nameField.Event:TextfieldChange()
		ResetSaveButton()
	end
	
	function statSelector.Event:SelectionChanged()
		RecalcStats()
	end
	
	function filterFrame.Event:Size()
		ResetHeight()
	end
	
	function matcherFrame.Event:Size()
		ResetHeight()
	end
	
	function cancelButton.Event:LeftPress()
		parent:HidePopup(addonID .. ".StatisticalPriceModel", frame)
	end

	function frame:SetData(modelInfo, onSave)
		nameField:SetText(modelInfo.name or "")
		local usage = modelInfo.usage
		if allStats[usage.id] then
			statSelector:SetSelectedKey(usage.id)
			statFrames[usage.id]:SetExtra(usage.extra)
		end
		filterFrame:SetFilterConfig(modelInfo.usage.filters)
		matcherFrame:SetMatcherConfig(modelInfo.matchers)
		wasEnabled = modelInfo.enabled

		function saveButton.Event:LeftPress()
			onSave(GetModelInfo())
			parent:HidePopup(addonID .. ".StatisticalPriceModel", frame)
		end
		
		ResetSaveButton()
	end
	
	RecalcStats()
	
	return frame
end
RegisterPopupConstructor(addonID .. ".StatisticalPriceModel", StatisticalPriceModelPopup)

local function ComplexPriceModelPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".ComplexPriceModelPopup", parent)
	
	local nameLabel = ShadowedText(frame:GetName() .. ".NameLabel", frame:GetContent())
	local namePanel = Panel(frame:GetName() .. ".NamePanel", frame:GetContent())
	local nameField = UICreateFrame("RiftTextfield", frame:GetName() .. ".NameField", namePanel:GetContent())
	
	local complexSelector = Dropdown(frame:GetName() .. ".ComplexSelector", frame:GetContent())
	
	local matcherFrame = BuildMatchersFrame(frame:GetName() .. ".MatcherFrame", frame:GetContent())
	
	local saveButton = UICreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame:GetContent())
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())
	
	local wasEnabled = false
	
	local function GetModelInfo()
		local name = nameField:GetText()
		local complexID = complexSelector:GetSelectedValue()
		local matchers = matcherFrame:GetMatcherConfig()
		
		return { name = name, modelType = "complex", usage = complexID, matchers = matchers, enabled = wasEnabled, original = false, own = true }
	end
	
	local function ResetHeight()
		frame:SetHeight(cancelButton:GetBottom() + 15 - frame:GetTop())
	end
	
	local function ResetSaveButton()
		saveButton:SetEnabled(nameField:GetText() ~= "" and (complexSelector:GetSelectedValue()) ~= nil)
	end
	
	frame:SetWidth(800)
	
	nameLabel:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 25, 15)
	nameLabel:SetFontSize(14)
	nameLabel:SetFontColor(1, 1, 0.75, 1)
	nameLabel:SetShadowOffset(2, 2)
	nameLabel:SetText(L["ComplexModelPopup/Name"])
	
	namePanel:SetPoint("CENTERLEFT", nameLabel, "CENTERRIGHT", 10, 0)
	namePanel:SetPoint("TOPRIGHT", frame:GetContent(), "TOPRIGHT", -25, 12)
	namePanel:SetInvertedBorder(true)
	namePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	nameField:SetPoint("CENTERLEFT", namePanel:GetContent(), "CENTERLEFT", 2, 1)
	nameField:SetPoint("CENTERRIGHT", namePanel:GetContent(), "CENTERRIGHT", -2, 1)
	nameField:SetText("")
	
	complexSelector:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 15, 50)
	complexSelector:SetPoint("BOTTOMRIGHT", frame:GetContent(), "TOPRIGHT", -15, 80)
	complexSelector:SetTextSelector("displayName")
	complexSelector:SetOrderSelector("displayName")
	local allComplex = GetPriceComplex()
	local complex = {}
	for complexID, complexName in pairs(allComplex) do
		complex[complexID] = { displayName = complexName }
	end
	complexSelector:SetValues(complex)
	
	matcherFrame:SetPoint("TOPLEFT", complexSelector, "BOTTOMLEFT", 0, 10)
	matcherFrame:SetPoint("TOPRIGHT", complexSelector, "BOTTOMRIGHT", 0, 10)
	
	saveButton:SetPoint("TOPCENTER", matcherFrame, 1/3, 1, 0, 10)
	saveButton:SetText(L["ComplexModelPopup/ButtonSave"])
	saveButton:SetEnabled(false)
	
	cancelButton:SetPoint("TOPCENTER", matcherFrame, 2/3, 1, 0, 10)
	cancelButton:SetText(L["ComplexModelPopup/ButtonCancel"])
	
	function namePanel.Event:LeftClick()
		nameField:SetKeyFocus(true)
	end

	function nameField.Event:KeyFocusGain()
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end

	function nameField.Event:TextfieldChange()
		ResetSaveButton()
	end
	
	function complexSelector.Event:SelectionChanged()
		ResetSaveButton()
	end
	
	function matcherFrame.Event:Size()
		ResetHeight()
	end
	
	function cancelButton.Event:LeftPress()
		parent:HidePopup(addonID .. ".ComplexPriceModel", frame)
	end

	function frame:SetData(modelInfo, onSave)
		nameField:SetText(modelInfo.name or "")
		local usage = modelInfo.usage
		complexSelector:SetSelectedKey(usage)
		matcherFrame:SetMatcherConfig(modelInfo.matchers)
		wasEnabled = modelInfo.enabled

		function saveButton.Event:LeftPress()
			onSave(GetModelInfo())
			parent:HidePopup(addonID .. ".ComplexPriceModel", frame)
		end

		ResetSaveButton()
	end
	
	ResetHeight()
	
	return frame
end
RegisterPopupConstructor(addonID .. ".ComplexPriceModel", ComplexPriceModelPopup)

local function CompositePriceModelPopup(parent)
	local frame = Yague.Popup(parent:GetName() .. ".CompositePriceModelPopup", parent)
	
	local nameLabel = ShadowedText(frame:GetName() .. ".NameLabel", frame:GetContent())
	local namePanel = Panel(frame:GetName() .. ".NamePanel", frame:GetContent())
	local nameField = UICreateFrame("RiftTextfield", frame:GetName() .. ".NameField", namePanel:GetContent())

	local startAnchor = UICreateFrame("Frame", frame:GetName() .. ".StartAnchor", frame:GetContent())
	local endAnchor = UICreateFrame("Frame", frame:GetName() .. ".EndAnchor", frame:GetContent())
	local addButton = UICreateFrame("RiftButton", frame:GetName() .. ".AddButton", frame:GetContent())	
	local modelSelector = Dropdown(frame:GetName() .. ".ModelSelector", frame:GetContent())
	
	local matcherFrame = BuildMatchersFrame(frame:GetName() .. ".MatcherFrame", frame:GetContent())
	
	local saveButton = UICreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame:GetContent())
	local cancelButton = UICreateFrame("RiftButton", frame:GetName() .. ".CancelButton", frame:GetContent())
	
	local wasEnabled = false
	
	local availableModels = {}
	local usedModels = {}
	local modelFrames = {}
	
	local function GetModelInfo()
		local name = nameField:GetText()
		local usage = { }
		for _, modelID in ipairs(usedModels) do
			local modelFrame = modelFrames[modelID]
			usage[modelID] = modelFrame:GetValue()
		end
		local matchers = matcherFrame:GetMatcherConfig()
		
		return { name = name, modelType = "composite", usage = usage, matchers = matchers, enabled = wasEnabled, original = false, own = true }
	end
	
	local function ResetHeight()
		frame:SetHeight(cancelButton:GetBottom() + 15 - frame:GetTop())
	end
	
	local function ResetSaveButton()
		saveButton:SetEnabled(nameField:GetText() ~= "" and #usedModels > 0)
	end
	
	local function RecalcModels()
		local lastModel = startAnchor
		
		local exclude = {}
		for _, modelID in ipairs(usedModels) do
			local modelFrame = modelFrames[modelID]
			
			modelFrame:SetPoint("TOPLEFT", lastModel, "BOTTOMLEFT", 0, 10)
			modelFrame:SetPoint("TOPRIGHT", lastModel, "BOTTOMRIGHT", 0, 10)
			modelFrame:SetVisible(true)
			
			lastModel = modelFrame
			exclude[modelID] = true
		end
		
		local unusedModels = {}
		for modelID, modelName in pairs(availableModels) do
			if not exclude[modelID] then
				unusedModels[modelID] = { displayName = modelName, }
				modelFrames[modelID]:SetVisible(false)
			end
		end

		if next(unusedModels) then
			addButton:ClearAll()
			addButton:SetPoint("TOPRIGHT", lastModel, "BOTTOMRIGHT", 5, 10)
			addButton:SetVisible(true)
		
			modelSelector:ClearAll()
			modelSelector:SetPoint("TOPLEFT", lastModel, "BOTTOMLEFT", 0, 12)
			modelSelector:SetPoint("CENTERRIGHT", addButton, "CENTERLEFT", -5, 0)
			modelSelector:SetValues(unusedModels)
			modelSelector:SetVisible(true)
			
			endAnchor:ClearAll()
			endAnchor:SetPoint("TOPLEFT", modelSelector, "BOTTOMLEFT")
			endAnchor:SetPoint("BOTTOMRIGHT", addButton, "BOTTOMRIGHT")
		else
			addButton:SetVisible(false)
			modelSelector:SetVisible(false)
			
			endAnchor:ClearAll()
			endAnchor:SetPoint("TOPLEFT", lastModel, "BOTTOMLEFT")
			endAnchor:SetPoint("BOTTOMRIGHT", lastModel, "BOTTOMRIGHT")
		end

		ResetSaveButton()
		
		ResetHeight()
	end
	
	local function DropModel(modelID)
		local newUsedModels = {}
		
		for _, id in ipairs(usedModels) do
			if id ~= modelID then
				TInsert(newUsedModels, id)
			end
		end

		usedModels = newUsedModels
		
		RecalcModels()	
	end
	
	local function SetModels(models)
		availableModels = {}
		usedModels = {}
		
		for modelID, modelInfo in pairs(models) do
			availableModels[modelID] = modelInfo.name
			if not modelFrames[modelID] then
				modelFrames[modelID] = BuildModelFrame(frame:GetName() .. ".Models." .. modelID, frame:GetContent(), modelID, modelInfo.name, DropModel)
			end
		end
		
		for modelID, modelFrame in pairs(modelFrames) do
			modelFrame:SetVisible(false)
			modelFrame:SetModelName(availableModels[modelID])
			modelFrame:SetValue(1)
		end
	end

	frame:SetWidth(800)
	
	nameLabel:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 25, 15)
	nameLabel:SetFontSize(14)
	nameLabel:SetFontColor(1, 1, 0.75, 1)
	nameLabel:SetShadowOffset(2, 2)
	nameLabel:SetText(L["CompositeModelPopup/Name"])
	
	namePanel:SetPoint("CENTERLEFT", nameLabel, "CENTERRIGHT", 10, 0)
	namePanel:SetPoint("TOPRIGHT", frame:GetContent(), "TOPRIGHT", -25, 12)
	namePanel:SetInvertedBorder(true)
	namePanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)
	
	nameField:SetPoint("CENTERLEFT", namePanel:GetContent(), "CENTERLEFT", 2, 1)
	nameField:SetPoint("CENTERRIGHT", namePanel:GetContent(), "CENTERRIGHT", -2, 1)
	nameField:SetText("")
	
	startAnchor:SetPoint("TOPLEFT", frame:GetContent(), "TOPLEFT", 15, 50)
	startAnchor:SetPoint("BOTTOMRIGHT", frame:GetContent(), "TOPRIGHT", -15, 50)
	startAnchor:SetVisible(false)
	
	endAnchor:SetVisible(false)
	
	addButton:SetText(L["CompositeModelPopup/ButtonAdd"])
	
	modelSelector:SetTextSelector("displayName")
	modelSelector:SetOrderSelector("displayName")
	
	matcherFrame:SetPoint("TOPLEFT", endAnchor, "BOTTOMLEFT", 0, 10)
	matcherFrame:SetPoint("TOPRIGHT", endAnchor, "BOTTOMRIGHT", 0, 10)
	
	saveButton:SetPoint("TOPCENTER", matcherFrame, 1/3, 1, 0, 10)
	saveButton:SetText(L["CompositeModelPopup/ButtonSave"])
	saveButton:SetEnabled(false)
	
	cancelButton:SetPoint("TOPCENTER", matcherFrame, 2/3, 1, 0, 10)
	cancelButton:SetText(L["CompositeModelPopup/ButtonCancel"])
	
	function namePanel.Event:LeftClick()
		nameField:SetKeyFocus(true)
	end

	function nameField.Event:KeyFocusGain()
		local length = SLen(self:GetText())
		if length > 0 then
			self:SetSelection(0, length)
		end
	end

	function nameField.Event:TextfieldChange()
		ResetSaveButton()
	end
	
	function addButton.Event:LeftPress()
		local modelID = modelSelector:GetSelectedValue()
		TInsert(usedModels, modelID)
		RecalcModels()
	end
	
	function matcherFrame.Event:Size()
		ResetHeight()
	end
	
	function cancelButton.Event:LeftPress()
		parent:HidePopup(addonID .. ".CompositePriceModel", frame)
	end

	function frame:SetData(models, modelInfo, onSave)
		SetModels(models)

		nameField:SetText(modelInfo.name or "")
		local usage = modelInfo.usage
		for modelID, modelValue in pairs(usage) do
			if availableModels[modelID] then
				TInsert(usedModels, modelID)
				local modelFrame = modelFrames[modelID]
				modelFrame:SetValue(modelValue)
			end
		end
		RecalcModels()

		matcherFrame:SetMatcherConfig(modelInfo.matchers)
		wasEnabled = modelInfo.enabled
		function saveButton.Event:LeftPress()
			onSave(GetModelInfo())
			parent:HidePopup(addonID .. ".CompositePriceModel", frame)
		end
	end
	
	RecalcModels()
	
	return frame
end
RegisterPopupConstructor(addonID .. ".CompositePriceModel", CompositePriceModelPopup)

local function GeneralSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".GeneralSettings", parent)
	
	local showMapIconCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".ShowMapIconCheck", frame)
	local showMapIconText = UICreateFrame("Text", frame:GetName() .. ".ShowMapIconText", frame)
	local autoOpenCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".AutoOpenCheck", frame)
	local autoOpenText = UICreateFrame("Text", frame:GetName() .. ".AutoOpenText", frame)
	local autoCloseCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".AutoCloseCheck", frame)
	local autoCloseText = UICreateFrame("Text", frame:GetName() .. ".AutoCloseText", frame)
	local pauseQueueCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".PauseQueueCheck", frame)
	local pauseQueueText = UICreateFrame("Text", frame:GetName() .. ".PauseQueueText", frame)
	
	frame:SetVisible(false)
	
	showMapIconCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	showMapIconCheck:SetChecked(InternalInterface.AccountSettings.General.ShowMapIcon)
	
	showMapIconText:SetPoint("CENTERLEFT", showMapIconCheck, "CENTERRIGHT", 5, 0)
	showMapIconText:SetFontSize(14)
	showMapIconText:SetText(L["ConfigGeneral/MapIconShow"])
	
	autoOpenCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 55)
	autoOpenCheck:SetChecked(InternalInterface.AccountSettings.General.AutoOpen)
	
	autoOpenText:SetPoint("CENTERLEFT", autoOpenCheck, "CENTERRIGHT", 5, 0)
	autoOpenText:SetFontSize(14)
	autoOpenText:SetText(L["ConfigGeneral/AutoOpenWindow"])
	
	autoCloseCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 85)
	autoCloseCheck:SetChecked(InternalInterface.AccountSettings.General.AutoClose)
	
	autoCloseText:SetPoint("CENTERLEFT", autoCloseCheck, "CENTERRIGHT", 5, 0)
	autoCloseText:SetFontSize(14)
	autoCloseText:SetText(L["ConfigGeneral/AutoCloseWindow"])
	
	pauseQueueCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 130)
	pauseQueueCheck:SetChecked(InternalInterface.AccountSettings.General.QueuePausedOnStart)
	
	pauseQueueText:SetPoint("CENTERLEFT", pauseQueueCheck, "CENTERRIGHT", 5, 0)
	pauseQueueText:SetFontSize(14)
	pauseQueueText:SetText(L["ConfigGeneral/PausePostingQueue"])
	
	function showMapIconCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.ShowMapIcon = self:GetChecked()
		if not MINIMAPDOCKER then
			InternalInterface.UI.MapIcon:SetVisible(InternalInterface.AccountSettings.General.ShowMapIcon)
		end
	end
	
	function autoOpenCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.AutoOpen = self:GetChecked()
	end
	
	function autoCloseCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.AutoClose = self:GetChecked()
	end
	
	function pauseQueueCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.General.QueuePausedOnStart = self:GetChecked()
	end
	
	return frame
end

local function SearchSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".GeneralSettings", parent)
	
	local defaultSearcherText = UICreateFrame("Text", frame:GetName() .. ".DefaultSearcherText", frame)
	local defaultSearcherDropdown = Dropdown(frame:GetName() .. ".DefaultSearcherDropdown", frame)

	local defaultSearchModeText = UICreateFrame("Text", frame:GetName() .. ".DefaultSearchModeText", frame)
	local defaultSearchModeDropdown = Dropdown(frame:GetName() .. ".DefaultSearchModeDropdown", frame)

	frame:SetVisible(false)
	
	defaultSearcherText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	defaultSearcherText:SetFontSize(14)
	defaultSearcherText:SetText(L["ConfigSearch/DefaultSearcher"])
	
	defaultSearcherDropdown:SetPoint("CENTERLEFT", defaultSearcherText, "CENTERLEFT", 200, 0)
	defaultSearcherDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 5)
	defaultSearcherDropdown:SetTextSelector("displayName")
	defaultSearcherDropdown:SetOrderSelector("displayName")
	
	local searchers = GetAuctionSearchers()
	for id, name in pairs(searchers) do searchers[id] = { displayName = name } end
	local defaultSearcher = InternalInterface.AccountSettings.Search.DefaultSearcher
	defaultSearcherDropdown:SetValues(searchers)
	if searchers[defaultSearcher] then defaultSearcherDropdown:SetSelectedKey(defaultSearcher) end
	
	defaultSearchModeText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 50)
	defaultSearchModeText:SetFontSize(14)
	defaultSearchModeText:SetText(L["ConfigSearch/DefaultSearchMode"])
	
	defaultSearchModeDropdown:SetPoint("CENTERLEFT", defaultSearchModeText, "CENTERLEFT", 200, 0)
	defaultSearchModeDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 45)
	defaultSearchModeDropdown:SetTextSelector("displayName")
	defaultSearchModeDropdown:SetOrderSelector("order")
	local defaultSearchMode = InternalInterface.AccountSettings.Search.DefaultOnline and "online" or "offline"
	defaultSearchModeDropdown:SetValues({
		["online"] = { displayName = L["Misc/SearchModeOnline"], order = 1, },
		["offline"] = { displayName = L["Misc/SearchModeOffline"], order = 2, },
	})
	defaultSearchModeDropdown:SetSelectedKey(defaultSearchMode)
	
	function defaultSearcherDropdown.Event:SelectionChanged(searcher)
		InternalInterface.AccountSettings.Search.DefaultSearcher = searcher
	end
	
	function defaultSearchModeDropdown.Event:SelectionChanged(searchMode)
		InternalInterface.AccountSettings.Search.DefaultOnline = searchMode == "online" and true or false
	end
	
	return frame
end

local function PostingSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".PostingSettings", parent)

	local rarityFilterText = UICreateFrame("Text", frame:GetName() .. ".RarityFilterText", frame)
	local rarityFilterDropdown = Dropdown(frame:GetName() .. ".RarityFilterDropdown", frame)
	local defaultBidPercentageText = UICreateFrame("Text", frame:GetName() .. ".DefaultBidPercentageText", frame)
	local defaultBidPercentageSlider = Slider(frame:GetName() .. ".DefaultBidPercentageSlider", frame)
	local defaultBindPricesCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".DefaultBindPricesCheck", frame)
	local defaultBindPricesText = UICreateFrame("Text", frame:GetName() .. ".DefaultBindPricesText", frame)
	local undercutAbsoluteText = UICreateFrame("Text", frame:GetName() .. ".UndercutAbsoluteText", frame)
	local undercutAbsoluteSelector = MoneySelector(frame:GetName() .. ".UndercutAbsoluteSelector", frame)
	local undercutRelativeText = UICreateFrame("Text", frame:GetName() .. ".UndercutRelativeText", frame)
	local undercutRelativeSlider = Slider(frame:GetName() .. ".UndercutRelativeSlider", frame)
	local autoPauseCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".AutoPauseCheck", frame)
	local autoPauseText = UICreateFrame("Text", frame:GetName() .. ".AutoPauseText", frame)

	frame:SetVisible(false)

	rarityFilterText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	rarityFilterText:SetFontSize(14)
	rarityFilterText:SetText(L["ConfigPost/RarityFilter"])
	
	rarityFilterDropdown:SetPoint("CENTERLEFT", rarityFilterText, "CENTERLEFT", 400, 0)
	rarityFilterDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 5)
	rarityFilterDropdown:SetTextSelector("displayName")
	rarityFilterDropdown:SetOrderSelector("order")
	rarityFilterDropdown:SetColorSelector(function(key, value) return { GetRarityColor(value.rarity) } end)
	local defaultRarity = InternalInterface.AccountSettings.Posting.RarityFilter
	rarityFilterDropdown:SetValues({
		{ displayName = L["General/Rarity1"], order = 1, rarity = "sellable", },
		{ displayName = L["General/Rarity2"], order = 2, rarity = "common", },
		{ displayName = L["General/Rarity3"], order = 3, rarity = "uncommon", },
		{ displayName = L["General/Rarity4"], order = 4, rarity = "rare", },
		{ displayName = L["General/Rarity5"], order = 5, rarity = "epic", },
		{ displayName = L["General/Rarity6"], order = 6, rarity = "relic", },
		{ displayName = L["General/Rarity7"], order = 7, rarity = "transcendent", },
		{ displayName = L["General/RarityQuest"], order = 8, rarity = "quest", },	
	})
	rarityFilterDropdown:SetSelectedKey(defaultRarity)

	defaultBidPercentageText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 90)
	defaultBidPercentageText:SetFontSize(14)
	defaultBidPercentageText:SetText(L["ConfigPost/BidPercentage"])
	
	defaultBidPercentageSlider:SetPoint("CENTERRIGHT", frame, "TOPRIGHT", -10, 90)
	defaultBidPercentageSlider:SetPoint("CENTERLEFT", defaultBidPercentageText, "CENTERLEFT", 400, 0)
	defaultBidPercentageSlider:SetRange(1, 100)
	defaultBidPercentageSlider:SetPosition(InternalInterface.AccountSettings.Posting.Config.BidPercentage)

	defaultBindPricesCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 130)
	defaultBindPricesCheck:SetChecked(InternalInterface.AccountSettings.Posting.Config.BindPrices)
	
	defaultBindPricesText:SetPoint("CENTERLEFT", defaultBindPricesCheck, "CENTERRIGHT", 5, 0)
	defaultBindPricesText:SetFontSize(14)
	defaultBindPricesText:SetText(L["ConfigPost/DefaultBindPrices"])

	undercutAbsoluteText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 210)
	undercutAbsoluteText:SetFontSize(14)
	undercutAbsoluteText:SetText(L["ConfigPost/UndercutAbsolute"])
	
	undercutAbsoluteSelector:SetPoint("CENTERRIGHT", frame, "TOPRIGHT", -10, 210)
	undercutAbsoluteSelector:SetPoint("CENTERLEFT", undercutAbsoluteText, "CENTERLEFT", 400, 0)
	undercutAbsoluteSelector:SetHeight(30)
	undercutAbsoluteSelector:SetValue(InternalInterface.AccountSettings.Posting.AbsoluteUndercut)

	undercutRelativeText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 250)
	undercutRelativeText:SetFontSize(14)
	undercutRelativeText:SetText(L["ConfigPost/UndercutPercentage"])
	
	undercutRelativeSlider:SetPoint("CENTERRIGHT", frame, "TOPRIGHT", -10, 250)
	undercutRelativeSlider:SetPoint("CENTERLEFT", undercutRelativeText, "CENTERLEFT", 400, 0)
	undercutRelativeSlider:SetRange(0, 100)
	undercutRelativeSlider:SetPosition(InternalInterface.AccountSettings.Posting.RelativeUndercut)

	autoPauseCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 330)
	autoPauseCheck:SetChecked(InternalInterface.AccountSettings.Posting.AutoPostPause)
	
	autoPauseText:SetPoint("CENTERLEFT", autoPauseCheck, "CENTERRIGHT", 5, 0)
	autoPauseText:SetFontSize(14)
	autoPauseText:SetText(L["ConfigPost/AutoPostPause"])

	function rarityFilterDropdown.Event:SelectionChanged(rarity)
		InternalInterface.AccountSettings.Posting.RarityFilter = rarity
	end

	function defaultBidPercentageSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.Posting.Config.BidPercentage = position
	end
	
	function defaultBindPricesCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Posting.Config.BindPrices = self:GetChecked()
	end

	function undercutAbsoluteSelector.Event:ValueChanged(newValue)
		InternalInterface.AccountSettings.Posting.AbsoluteUndercut = newValue
		if newValue > 0 then
			undercutRelativeSlider:SetPosition(0)
		end
	end

	function undercutRelativeSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.Posting.RelativeUndercut = position
		if position > 0 then
			undercutAbsoluteSelector:SetValue(0)
		end
	end
	
	function autoPauseCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Posting.AutoPostPause = self:GetChecked()
	end

	return frame
end

local function AuctionsSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".AuctionsSettings", parent)

	local allowLeftCancelCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".AllowLeftCancelCheck", frame)
	local allowLeftCancelText = UICreateFrame("Text", frame:GetName() .. ".AllowLeftCancelText", frame)

	local filterCharacterCheck = UICreateFrame("RiftCheckbox", frame:GetName() .. ".FilterCharacterCheck", frame)
	local filterCharacterText = UICreateFrame("Text", frame:GetName() .. ".FilterCharacterText", frame)
	
	local filterCompetitionText = UI.CreateFrame("Text", frame:GetName() .. ".FilterCompetitionText", frame)
	local filterCompetitionSelector = Dropdown(frame:GetName() .. ".FilterCompetitionSelector", frame)
	
	local filterBelowText = UI.CreateFrame("Text", frame:GetName() .. ".FilterBelowText", frame)
	local filterBelowSlider = Slider(frame:GetName() .. ".FilterBelowSlider", frame)

	local filterScoreTitle = UICreateFrame("Text", frame:GetName() .. ".FilterScoreTitle", frame)
	local filterFrame = UICreateFrame("Frame", frame:GetName() .. ".FilterFrame", frame)
	
	local filterScoreNilCheck = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScoreNilCheck", filterFrame)
	local filterScoreNilText = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScoreNilText", filterFrame)
	local filterScore1Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore1Check", filterFrame)
	local filterScore1Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore1Text", filterFrame)
	local filterScore2Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore2Check", filterFrame)
	local filterScore2Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore2Text", filterFrame)
	local filterScore3Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore3Check", filterFrame)
	local filterScore3Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore3Text", filterFrame)
	local filterScore4Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore4Check", filterFrame)
	local filterScore4Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore4Text", filterFrame)
	local filterScore5Check = UICreateFrame("RiftCheckbox", filterFrame:GetName() .. ".FilterScore5Check", filterFrame)
	local filterScore5Text = UICreateFrame("Text", filterFrame:GetName() .. ".FilterScore5Text", filterFrame)
	
	frame:SetVisible(false)

	allowLeftCancelCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	allowLeftCancelCheck:SetChecked(InternalInterface.AccountSettings.Auctions.BypassCancelPopup)
	
	allowLeftCancelText:SetPoint("CENTERLEFT", allowLeftCancelCheck, "CENTERRIGHT", 5, 0)
	allowLeftCancelText:SetFontSize(14)
	allowLeftCancelText:SetText(L["ConfigSelling/BypassCancelPopup"])
	
	filterCharacterCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 70)
	filterCharacterCheck:SetChecked(InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter)
	
	filterCharacterText:SetPoint("CENTERLEFT", filterCharacterCheck, "CENTERRIGHT", 5, 0)
	filterCharacterText:SetFontSize(14)
	filterCharacterText:SetText(L["ConfigSelling/FilterRestrictCharacter"])

	filterCompetitionText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 120)
	filterCompetitionText:SetFontSize(14)
	filterCompetitionText:SetText(L["ConfigSelling/FilterCompetition"])
	
	filterBelowText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 170)
	filterBelowText:SetFontSize(14)
	filterBelowText:SetText(L["ConfigSelling/FilterBelow"])

	filterScoreTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 220)
	filterScoreTitle:SetFontSize(14)
	filterScoreTitle:SetText(L["ConfigSelling/FilterScore"])
	
	filterCompetitionSelector:SetPoint("CENTERLEFT", filterCompetitionText, "CENTERLEFT", 200, 0)
	filterCompetitionSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 115)
	filterCompetitionSelector:SetTextSelector("displayName")
	filterCompetitionSelector:SetOrderSelector("order")
	filterCompetitionSelector:SetValues({
		{ displayName = L["General/CompetitionName1"], order = 1, },
		{ displayName = L["General/CompetitionName2"], order = 2, },
		{ displayName = L["General/CompetitionName3"], order = 3, },
		{ displayName = L["General/CompetitionName4"], order = 4, },
		{ displayName = L["General/CompetitionName5"], order = 5, },
	})
	filterCompetitionSelector:SetSelectedKey(InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter)

	filterBelowSlider:SetPoint("CENTERRIGHT", frame, "TOPRIGHT", -10, 170)
	filterBelowSlider:SetPoint("CENTERLEFT", filterBelowText, "CENTERLEFT", 200, 0)
	filterBelowSlider:SetRange(0, 20)
	filterBelowSlider:SetPosition(InternalInterface.AccountSettings.Auctions.DefaultBelowFilter)

	filterFrame:SetPoint("CENTERLEFT", filterScoreTitle, "CENTERLEFT", 200, 0)
	filterFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 205)
	
	filterScoreNilCheck:SetPoint("CENTERLEFT", filterFrame, 0, 0.5)
	filterScoreNilCheck:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[1] or false)
	filterScore1Check:SetPoint("CENTERLEFT", filterFrame, 1 / 6, 0.5)
	filterScore1Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[2] or false)
	filterScore2Check:SetPoint("CENTERLEFT", filterFrame, 2 / 6, 0.5)
	filterScore2Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[3] or false)
	filterScore3Check:SetPoint("CENTERLEFT", filterFrame, 3 / 6, 0.5)
	filterScore3Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[4] or false)
	filterScore4Check:SetPoint("CENTERLEFT", filterFrame, 4 / 6, 0.5)
	filterScore4Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[5] or false)
	filterScore5Check:SetPoint("CENTERLEFT", filterFrame, 5 / 6, 0.5)
	filterScore5Check:SetChecked(InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[6] or false)
	
	filterScoreNilText:SetPoint("CENTERLEFT", filterScoreNilCheck, "CENTERRIGHT", 5, 0)
	filterScoreNilText:SetText(L["General/ScoreName0"])
	filterScore1Text:SetPoint("CENTERLEFT", filterScore1Check, "CENTERRIGHT", 5, 0)
	filterScore1Text:SetText(L["General/ScoreName1"])
	filterScore2Text:SetPoint("CENTERLEFT", filterScore2Check, "CENTERRIGHT", 5, 0)
	filterScore2Text:SetText(L["General/ScoreName2"])
	filterScore3Text:SetPoint("CENTERLEFT", filterScore3Check, "CENTERRIGHT", 5, 0)
	filterScore3Text:SetText(L["General/ScoreName3"])
	filterScore4Text:SetPoint("CENTERLEFT", filterScore4Check, "CENTERRIGHT", 5, 0)
	filterScore4Text:SetText(L["General/ScoreName4"])
	filterScore5Text:SetPoint("CENTERLEFT", filterScore5Check, "CENTERRIGHT", 5, 0)
	filterScore5Text:SetText(L["General/ScoreName5"])
	
	function allowLeftCancelCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.BypassCancelPopup = self:GetChecked()
	end
	
	function filterCharacterCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.RestrictCharacterFilter = self:GetChecked()
	end
	
	function filterCompetitionSelector.Event:SelectionChanged()
		InternalInterface.AccountSettings.Auctions.DefaultCompetitionFilter = (self:GetSelectedValue())
	end
	
	function filterBelowSlider.Event:PositionChanged(position)
		InternalInterface.AccountSettings.Auctions.DefaultBelowFilter = position
	end

	function filterScoreNilCheck.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[1] = self:GetChecked()
	end
	
	function filterScore1Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[2] = self:GetChecked()
	end
	
	function filterScore2Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[3] = self:GetChecked()
	end
	
	function filterScore3Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[4] = self:GetChecked()
	end
	
	function filterScore4Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[5] = self:GetChecked()
	end
	
	function filterScore5Check.Event:CheckboxChange()
		InternalInterface.AccountSettings.Auctions.DefaultScoreFilter[6] = self:GetChecked()
	end
	
	return frame
end

local function ScoreSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".PriceScoreSettings", parent)
	
	local defaultPriceScorerText = UICreateFrame("Text", frame:GetName() .. ".DefaultPriceScorerText", frame)
	local defaultPriceScorerDropdown = Dropdown(frame:GetName() .. ".DefaultPriceScorerDropdown", frame)
	local colorNilSample = Panel(frame:GetName() .. ".ColorNilSample", frame)
	local color1Sample = Panel(frame:GetName() .. ".Color1Sample", frame)
	local color2Sample = Panel(frame:GetName() .. ".Color2Sample", frame)
	local color3Sample = Panel(frame:GetName() .. ".Color3Sample", frame)
	local color4Sample = Panel(frame:GetName() .. ".Color4Sample", frame)
	local color5Sample = Panel(frame:GetName() .. ".Color5Sample", frame)
	local colorNilText = UICreateFrame("Text", frame:GetName() .. ".ColorNilText", frame)
	local color1Text = UICreateFrame("Text", frame:GetName() .. ".Color1Text", frame)
	local color2Text = UICreateFrame("Text", frame:GetName() .. ".Color2Text", frame)
	local color3Text = UICreateFrame("Text", frame:GetName() .. ".Color3Text", frame)
	local color4Text = UICreateFrame("Text", frame:GetName() .. ".Color4Text", frame)
	local color5Text = UICreateFrame("Text", frame:GetName() .. ".Color5Text", frame)
	local color1Limit = Slider(frame:GetName() .. ".Color1Limit", frame)
	local color2Limit = Slider(frame:GetName() .. ".Color2Limit", frame)
	local color3Limit = Slider(frame:GetName() .. ".Color3Limit", frame)
	local color4Limit = Slider(frame:GetName() .. ".Color4Limit", frame)
	local samplePanel = Panel(frame:GetName() .. ".SamplePanel", frame)
	local color1SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color1SamplePanel", samplePanel:GetContent())
	local color2SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color2SamplePanel", samplePanel:GetContent())
	local color3SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color3SamplePanel", samplePanel:GetContent())
	local color4SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color4SamplePanel", samplePanel:GetContent())
	local color5SamplePanel = UICreateFrame("Frame", frame:GetName() .. ".Color5SamplePanel", samplePanel:GetContent())

	local propagateFlag = false
	
	local function ResetDefaultPriceScorer()
		local priceModels = GetPriceModels() -- TODO Move to category config and use BananAH ones instead of LibPGCEx ones
		for id, name in pairs(priceModels) do priceModels[id] = { displayName = name } end
		local defaultScorer = InternalInterface.AccountSettings.Scoring.ReferencePrice
		defaultPriceScorerDropdown:SetValues(priceModels)
		if priceModels[defaultScorer] then
			defaultPriceScorerDropdown:SetSelectedKey(defaultScorer)
		end
	end
	
	local function ResetColorSample()
		color1SamplePanel:ClearAll()
		color2SamplePanel:ClearAll()
		color3SamplePanel:ClearAll()
		color4SamplePanel:ClearAll()

		local limit1, limit2, limit3, limit4 = color1Limit:GetPosition(), color2Limit:GetPosition(), color3Limit:GetPosition(), color4Limit:GetPosition()
		local content = samplePanel:GetContent()
		local width = content:GetWidth()

		color1SamplePanel:SetPoint("TOPLEFT", content, "TOPLEFT")
		color1SamplePanel:SetPoint("BOTTOMRIGHT", content, limit1 / 999, 1)

		color2SamplePanel:SetPoint("TOPLEFT", content, limit1 / 999, 0)
		color2SamplePanel:SetPoint("BOTTOMRIGHT", content, limit2 / 999, 1)

		color3SamplePanel:SetPoint("TOPLEFT", content, limit2 / 999, 0)
		color3SamplePanel:SetPoint("BOTTOMRIGHT", content, limit3 / 999, 1)

		color4SamplePanel:SetPoint("TOPLEFT", content, limit3 / 999, 0)
		color4SamplePanel:SetPoint("BOTTOMRIGHT", content, limit4 / 999, 1)

		color5SamplePanel:SetPoint("TOPLEFT", content, limit4 / 999, 0)
		color5SamplePanel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT")
		
		InternalInterface.AccountSettings.Scoring.ColorLimits = { limit1, limit2, limit3, limit4 }
	end
	
	frame:SetVisible(false)

	defaultPriceScorerText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 10)
	defaultPriceScorerText:SetFontSize(14)
	defaultPriceScorerText:SetText(L["ConfigScore/ReferencePrice"])
	
	defaultPriceScorerDropdown:SetPoint("CENTERLEFT", defaultPriceScorerText, "CENTERLEFT", 200, 0)
	defaultPriceScorerDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 3)
	defaultPriceScorerDropdown:SetTextSelector("displayName")
	
	colorNilSample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 90)
	colorNilSample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 120)
	colorNilSample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(nil)))
	colorNilSample:SetInvertedBorder(true)
	
	color1Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 140)
	color1Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 170)
	color1Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(1)))
	color1Sample:SetInvertedBorder(true)
	
	color2Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 190)
	color2Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 220)
	color2Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(2)))
	color2Sample:SetInvertedBorder(true)
	
	color3Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 240)
	color3Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 270)
	color3Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(3)))
	color3Sample:SetInvertedBorder(true)
	
	color4Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 290)
	color4Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 320)
	color4Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(4)))
	color4Sample:SetInvertedBorder(true)
	
	color5Sample:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 340)
	color5Sample:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", 40, 370)
	color5Sample:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(5)))
	color5Sample:SetInvertedBorder(true)
	
	colorNilText:SetPoint("CENTERLEFT", colorNilSample, "CENTERRIGHT", 10, 0)
	colorNilText:SetFontSize(14)
	colorNilText:SetText(L["General/ScoreName0"])
	
	color1Text:SetPoint("CENTERLEFT", color1Sample, "CENTERRIGHT", 10, 0)
	color1Text:SetFontSize(14)
	color1Text:SetText(L["General/ScoreName1"])
	
	color2Text:SetPoint("CENTERLEFT", color2Sample, "CENTERRIGHT", 10, 0)
	color2Text:SetFontSize(14)
	color2Text:SetText(L["General/ScoreName2"])
	
	color3Text:SetPoint("CENTERLEFT", color3Sample, "CENTERRIGHT", 10, 0)
	color3Text:SetFontSize(14)
	color3Text:SetText(L["General/ScoreName3"])
	
	color4Text:SetPoint("CENTERLEFT", color4Sample, "CENTERRIGHT", 10, 0)
	color4Text:SetFontSize(14)
	color4Text:SetText(L["General/ScoreName4"])
	
	color5Text:SetPoint("CENTERLEFT", color5Sample, "CENTERRIGHT", 10, 0)
	color5Text:SetFontSize(14)
	color5Text:SetText(L["General/ScoreName5"])
	
	color1Limit:SetPoint("TOPLEFT", color1Sample, "BOTTOMRIGHT", 200, 0)
	color1Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 190)
	color1Limit:SetRange(0, 999)
	color1Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[1])
	
	color2Limit:SetPoint("TOPLEFT", color2Sample, "BOTTOMRIGHT", 200, 0)
	color2Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 240)
	color2Limit:SetRange(0, 999)
	color2Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[2])
	
	color3Limit:SetPoint("TOPLEFT", color3Sample, "BOTTOMRIGHT", 200, 0)
	color3Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 290)
	color3Limit:SetRange(0, 999)
	color3Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[3])
	
	color4Limit:SetPoint("TOPLEFT", color4Sample, "BOTTOMRIGHT", 200, 0)
	color4Limit:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 340)
	color4Limit:SetRange(0, 999)
	color4Limit:SetPosition(InternalInterface.AccountSettings.Scoring.ColorLimits[4])
	
	samplePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 390)
	samplePanel:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -10, 420)
	samplePanel:GetContent():SetBackgroundColor(unpack(ScoreColorByIndex(nil)))
	
	color1SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(1)))
	color2SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(2)))
	color3SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(3)))
	color4SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(4)))
	color5SamplePanel:SetBackgroundColor(unpack(ScoreColorByIndex(5)))
	
	function defaultPriceScorerDropdown.Event:SelectionChanged()
		local index = self:GetSelectedValue()
		InternalInterface.AccountSettings.Scoring.ReferencePrice = index
	end

	
	function color1Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color2Limit:SetPosition(MMax(position, color2Limit:GetPosition()))
			color3Limit:SetPosition(MMax(color2Limit:GetPosition(), color3Limit:GetPosition()))
			color4Limit:SetPosition(MMax(color3Limit:GetPosition(), color4Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	function color2Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color1Limit:SetPosition(MMin(color1Limit:GetPosition(), position))
			color3Limit:SetPosition(MMax(position, color3Limit:GetPosition()))
			color4Limit:SetPosition(MMax(color3Limit:GetPosition(), color4Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	function color3Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color2Limit:SetPosition(MMin(color2Limit:GetPosition(), position))
			color1Limit:SetPosition(MMin(color1Limit:GetPosition(), color2Limit:GetPosition()))
			color4Limit:SetPosition(MMax(position, color4Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	function color4Limit.Event:PositionChanged(position)
		if not propagateFlag then
			propagateFlag = true
			color3Limit:SetPosition(MMin(color3Limit:GetPosition(), position))
			color2Limit:SetPosition(MMin(color2Limit:GetPosition(), color3Limit:GetPosition()))
			color1Limit:SetPosition(MMin(color1Limit:GetPosition(), color2Limit:GetPosition()))
			propagateFlag = false
			ResetColorSample()
		end
	end
	
	ResetDefaultPriceScorer()
	ResetColorSample()
	
	return frame
end

local function PriceSettings(parent)
	local frame = UICreateFrame("Frame", parent:GetName() .. ".PriceSettings", parent)
	
	local topSelector, topControls = BuildConfigFrame(frame:GetName() .. ".TopSelector", frame, 
		{
			category =
			{
				name = L["ConfigPrice/ItemCategory"],
				nameFontSize = 14,
				value = "category",
				defaultValue = "",
			},
			inheritance = 
			{
				name = L["ConfigPrice/CategoryConfig"],
				nameFontSize = 14,
				value = "selectOne",
				textSelector = "name",
				orderSelector = "order",
				values =
				{
					["inherit"] = { name = L["ConfigPrice/CategoryInherit"], order = 1 },
					["own"] = { name = L["ConfigPrice/CategoryOwn"], order = 2 },
				},
				defaultValue = "inherit",
			},
			Layout =
			{ 
				{ "category" },
				{ "inheritance" },
				columns = 1,
			},		
		})
	local saveButton = UICreateFrame("RiftButton", frame:GetName() .. ".SaveButton", frame)
	
	local postFrame = UICreateFrame("Frame", frame:GetName() .. ".PostFrame", frame)
	local stackSelector, stackControls = BuildConfigFrame(postFrame:GetName() .. ".StackSelector", postFrame,
		{
			stackSize =
			{
				name = L["ConfigPrice/DefaultStackSize"],
				nameFontSize = 14,
				value = "integer",
				minValue = 1,
				maxValue = 100,
				defaultValue = 100,
			},
			maxAuctions =
			{
				name = L["ConfigPrice/DefaultMaxAuctions"],
				nameFontSize = 14,
				value = "integer",
				minValue = 1,
				maxValue = 999,
				defaultValue = 999,
			},
			Layout =
			{
				{ "stackSize" },
				{ "maxAuctions" },
				columns = 1,
			},
		})
	local postSelector, postControls = BuildConfigFrame(postFrame:GetName() .. ".StackSelector", postFrame,
		{
			duration =
			{
				name = L["ConfigPrice/DefaultDuration"],
				nameFontSize = 14,
				value = "integer",
				minValue = 48,
				maxValue = 48,
				defaultValue = 48,
			},
			Layout =
			{
				{ "duration" },
				columns = 1,
			},
		})
	local incompleteStackLabel = ShadowedText(postFrame:GetName() .. ".IncompleteStackLabel", postFrame)
	local incompleteStackCheck = UICreateFrame("RiftCheckbox", postFrame:GetName() .. ".IncompleteStackCheck", postFrame)
	local priceGrid = DataGrid(postFrame:GetName() .. ".PriceModelGrid", postFrame)
	local controlFrame = UICreateFrame("Frame", postFrame:GetName() .. ".ControlFrame", priceGrid:GetContent())
	local deleteButton = UICreateFrame("RiftButton", postFrame:GetName() .. ".DeleteButton", controlFrame)
	local editButton = UICreateFrame("RiftButton", postFrame:GetName() .. ".EditButton", controlFrame)
	local newButton = UICreateFrame("RiftButton", postFrame:GetName() .. ".NewButton", controlFrame)
	local matchPanel = Panel(postFrame:GetName() .. ".MatchPanel", controlFrame)
	local matchCheck = UICreateFrame("RiftCheckbox", postFrame:GetName() .. ".MatchCheck", matchPanel:GetContent())
	local matchText = UICreateFrame("Text", postFrame:GetName() .. ".MatchLabel", matchPanel:GetContent())
	
	local currentCategory = topControls.category:GetSelectedValue()
	local currentDefaultModel = nil
	local currentFallbackModel = nil
	local modelDeleted = false

	local function CheckInheritEnabled()
		local enable = currentCategory ~= BASE_CATEGORY
		
		local models = priceGrid:GetData()
		for modelID, modelInfo in pairs(models) do
			if modelInfo.own then
				enable = false
				break
			end
		end
		
		topControls.inheritance:SetEnabled(enable)
	end
	
	local function GetSavedSettings(category)
		return category and InternalInterface.AccountSettings.Posting.CategoryConfig[category] or nil
	end
	
	local function SetSavedSettings(category, settings)
		InternalInterface.AccountSettings.Posting.CategoryConfig[category] = settings
		
		if settings then
			local preserve = {}
			local new = {}

			local models = priceGrid:GetData()
			for modelID, modelInfo in pairs(models) do
				if modelInfo.own then
					if modelInfo.original then
						preserve[modelID] = true
					else
						new[modelID] = { name = modelInfo.name, modelType = modelInfo.modelType, usage = modelInfo.usage, matchers = modelInfo.matchers }
						modelInfo.original = true
					end
				end
			end
			SaveCategoryModels(category, preserve, new)
			modelDeleted = false
			priceGrid:RefreshFilter()
		else
			ClearCategoryModels(category)
		end
	end
	
	local function GetEditSettings()
		if (topControls.inheritance:GetSelectedValue()) == "inherit" then return nil end
		
		local blackList = {}
		local models = priceGrid:GetData()
		for modelID, modelInfo in pairs(models) do
			if not modelInfo.enabled then
				blackList[modelID] = true
			end
		end
		
		return
		{
			DefaultReferencePrice = currentDefaultModel,
			FallbackReferencePrice = currentFallbackModel,
			ApplyMatching = matchCheck:GetChecked(),
			StackSize = stackControls.stackSize:GetPosition(),
			AuctionLimit = stackControls.maxAuctions:GetPosition(),
			PostIncomplete = incompleteStackCheck:GetChecked(),
			Duration = MMin(postControls.duration:GetPosition() / 12, 3),
			BlackList = blackList,
		}
	end
	
	local function SetEditSettings(settings, inherited)
		topControls.inheritance:SetSelectedKey(inherited and "inherit" or "own")

		currentDefaultModel = settings.DefaultReferencePrice
		currentFallbackModel = settings.FallbackReferencePrice
		
		matchCheck:SetChecked(settings.ApplyMatching)
		stackControls.stackSize:SetPosition(settings.StackSize)
		stackControls.maxAuctions:SetPosition(settings.AuctionLimit)
		incompleteStackCheck:SetChecked(settings.PostIncomplete)
		postControls.duration:SetPosition(45 + settings.Duration) -- HACK

		local models = GetCategoryModels(currentCategory)
		local blackList = settings.BlackList or {}
		for model, modelInfo in pairs(models) do
			modelInfo.enabled = not blackList[model]
			modelInfo.original = true
		end
		modelDeleted = false
		priceGrid:SetData(models, nil, CheckInheritEnabled)
	end
	
	local function CompareSettings(settings1, settings2)
		if settings1 == nil or settings2 == nil then
			return settings1 == settings2
		end
		
		if settings1.DefaultReferencePrice ~= settings2.DefaultReferencePrice or
	       settings1.FallbackReferencePrice ~= settings2.FallbackReferencePrice or
	       settings1.ApplyMatching ~= settings2.ApplyMatching or
	       settings1.StackSize ~= settings2.StackSize or
	       settings1.AuctionLimit ~= settings2.AuctionLimit or
	       settings1.PostIncomplete ~= settings2.PostIncomplete or
	       settings1.Duration ~= settings2.Duration then
			return false
		end
		
		for modelID in pairs(settings1.BlackList) do
			if not settings2.BlackList[modelID] then return false end
		end
		for modelID in pairs(settings2.BlackList) do
			if not settings1.BlackList[modelID] then return false end
		end
		
		local editModels = priceGrid:GetData() or {}
		for modelID, modelInfo in pairs(editModels) do
			if not modelInfo.original then return false end
		end
		
		if modelDeleted then return false end
		
		return true
	end
	
	local function OpenEditor(manager, modelID, modelType, modelInfo, onSave)
		if modelType == "simple" then
			manager:ShowPopup(addonID .. ".SimplePriceModel", modelInfo, onSave)
		elseif modelType == "statistical" then
			manager:ShowPopup(addonID .. ".StatisticalPriceModel", modelInfo, onSave)
		elseif modelType == "complex" then
			manager:ShowPopup(addonID .. ".ComplexPriceModel", modelInfo, onSave)
		elseif modelType == "composite" then
			local allModels = priceGrid:GetData()
			local availableModels = {}
			for id, info in pairs(allModels) do
				if id ~= modelID and (info.modelType ~= "composite" or not info.usage[modelID]) then
					availableModels[id] = { name = info.name }
				end
			end
			manager:ShowPopup(addonID .. ".CompositePriceModel", availableModels, modelInfo, onSave)
		end
	end
	
	local function UpdateButtons()
		local modelID, modelInfo = priceGrid:GetSelectedData()
		
		editButton:SetEnabled(modelInfo and modelInfo.own and true or false)
		
		local deleteable = modelInfo and modelInfo.own and modelID:sub(1, 3) == "bah" and true or false
		deleteable = deleteable and modelID ~= currentDefaultModel and modelID ~= currentFallbackModel
		if deleteable then
			local allCategories = CList()
			for category in pairs(allCategories) do
				if category ~= currentCategory then
					local categoryConfig = InternalInterface.AccountSettings.Posting.CategoryConfig[category] or {}
					if modelID == categoryConfig.DefaultReferencePrice or modelID == categoryConfig.FallbackReferencePrice then
						deleteable = false
						break
					end
				end
			end
		end
		deleteButton:SetEnabled(deleteable)
	end
	
	local function ModifyModel(modelID, modelInfo)
		local allModels = priceGrid:GetData()
		allModels[modelID] = modelInfo
		priceGrid:SetData(allModels, nil, CheckInheritEnabled)
	end
	
	local function IsOriginal(value, key)
		if not value.own then return nil end
		return value.original
	end
	
	local function IsDefaultModel(value, key)
		if not value.enabled then return nil end
		return key == currentDefaultModel
	end
	
	local function IsFallbackModel(value, key)
		if value.modelType ~= "simple" or not value.enabled then return nil end
		return key == currentFallbackModel
	end
	
	local function EnabledInteract(key)
		local data = priceGrid:GetData()
		if key and data and data[key] and key ~= currentDefaultModel and key ~= currentFallbackModel then
			data[key].enabled = not data[key].enabled
		end
		priceGrid:RefreshFilter()
	end
	
	local function DefaultInteract(key)
		currentDefaultModel = key
		UpdateButtons()
		priceGrid:RefreshFilter()
	end
	
	local function FallbackInteract(key)
		currentFallbackModel = key
		UpdateButtons()
		priceGrid:RefreshFilter()
	end

	saveButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, 25)
	saveButton:SetText(L["ConfigPrice/ButtonSave"])
	
	topSelector:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 5)
	topSelector:SetPoint("RIGHT", saveButton, "LEFT")

	postFrame:SetPoint("TOPLEFT", topSelector, "BOTTOMLEFT", 0, 20)
	postFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, -5)
	
	stackSelector:SetPoint("TOPLEFT", postFrame, "TOPLEFT")
	stackSelector:SetPoint("TOPRIGHT", postFrame, "TOPRIGHT")
	
	stackControls.stackSize:AddPostValue(L["Misc/StackSizeMaxKeyShortcut"], "+", L["Misc/StackSizeMax"])
	
	stackControls.maxAuctions:AddPostValue(L["Misc/AuctionLimitMaxKeyShortcut"], "+", L["Misc/AuctionLimitMax"])
	
	postSelector:SetPoint("BOTTOMLEFT", postFrame, "BOTTOMLEFT")
	postSelector:SetPoint("BOTTOMRIGHT", postFrame, "BOTTOMRIGHT")

	postControls.duration:AddPreValue("1", 12, "12")
	postControls.duration:AddPreValue("2", 24, "24")
	
	incompleteStackLabel:SetPoint("TOPRIGHT", stackSelector, "BOTTOMRIGHT", -5, 2)
	incompleteStackLabel:SetFontSize(13)
	incompleteStackLabel:SetText(L["PostFrame/LabelIncompleteStack"])	
	
	incompleteStackCheck:SetPoint("CENTERRIGHT", incompleteStackLabel, "CENTERLEFT", -5, 0)
	
	priceGrid:SetPadding(1, 1, 1, 38)
	priceGrid:SetHeadersVisible(true)
	priceGrid:SetRowHeight(20)
	priceGrid:SetRowMargin(0)
	priceGrid:SetUnselectedRowBackgroundColor({0.2, 0.2, 0.2, 0.25})
	priceGrid:SetSelectedRowBackgroundColor({0.6, 0.6, 0.6, 0.25})	
	priceGrid:SetPoint("TOPLEFT", stackSelector, "BOTTOMLEFT", 0, 30)
	priceGrid:SetPoint("BOTTOMRIGHT", postSelector, "TOPRIGHT", 0, -10)
	priceGrid:AddColumn("own", "", BooleanDotCellType, 20, 0, nil, false, { Eval = IsOriginal, })
	priceGrid:AddColumn("name", L["ConfigPrice/ColumnReferencePrice"], "Text", 140, 2, "name", true, { Alignment = "left", Formatter = "none", })
	priceGrid:AddColumn("enabled", L["ConfigPrice/ColumnActive"], BooleanDotCellType, 60, 0, "enabled", false, { Interactable = EnabledInteract, })
	priceGrid:AddColumn("default", L["ConfigPrice/ColumnDefault"], BooleanDotCellType, 60, 0, nil, false, { Eval = IsDefaultModel, Interactable = DefaultInteract, })
	priceGrid:AddColumn("fallback", L["ConfigPrice/ColumnFallback"], BooleanDotCellType, 60, 0, nil, false, { Eval = IsFallbackModel, Interactable = FallbackInteract, })
	priceGrid:SetOrder("name", false)
	priceGrid:GetInternalContent():SetBackgroundColor(0.05, 0, 0.05, 0.25)
	
	controlFrame:SetPoint("TOPLEFT", priceGrid:GetContent(), "BOTTOMLEFT", 3, -36)
	controlFrame:SetPoint("BOTTOMRIGHT", priceGrid:GetContent(), "BOTTOMRIGHT", -3, -2)
	
	deleteButton:SetPoint("CENTERRIGHT", controlFrame, "CENTERRIGHT", 0, 0)
	deleteButton:SetText(L["ConfigPrice/ButtonDelete"])
	deleteButton:SetEnabled(false)

	editButton:SetPoint("CENTERRIGHT", deleteButton, "CENTERLEFT", 10, 0)
	editButton:SetText(L["ConfigPrice/ButtonEdit"])
	editButton:SetEnabled(false)	

	newButton:SetPoint("CENTERRIGHT", editButton, "CENTERLEFT", 10, 0)
	newButton:SetText(L["ConfigPrice/ButtonNew"])
	
	matchPanel:SetPoint("BOTTOMLEFT", controlFrame, "BOTTOMLEFT", 0, -2)
	matchPanel:SetPoint("TOPRIGHT", newButton, "TOPLEFT", -3, 2)
	matchPanel:SetInvertedBorder(true)
	matchPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.75)

	matchCheck:SetPoint("CENTERLEFT", matchPanel:GetContent(), "CENTERLEFT", 5, 0)

	matchText:SetPoint("CENTERLEFT", matchCheck, "CENTERRIGHT", 5, 0)	
	matchText:SetText(L["ConfigPrice/ApplyMatching"])
	
	topSelector:SetLayer(9999)
	
	if currentCategory ~= BASE_CATEGORY then
		currentCategory = BASE_CATEGORY
		topControls.category:SetSelectedKey(BASE_CATEGORY)
	end
	SetEditSettings(GetSavedSettings(currentCategory))
	
	function topControls.category.Event:SelectionChanged(category)
		if category ~= currentCategory then
			local function ContinueChange()
				currentCategory = category
				local settings = nil
				while not settings do
					settings = GetSavedSettings(category)
					if not settings then
						local detail = CDetail(category)
						category = detail and detail.parent or BASE_CATEGORY
					end
				end
				SetEditSettings(settings, category ~= currentCategory)
				CheckInheritEnabled()
			end
			
			local function CancelChange()
				topControls.category:SetSelectedKey(currentCategory)
			end
			
			local equal = CompareSettings(GetEditSettings(), GetSavedSettings(currentCategory))
			local manager = GetPopupManager()
			
			if not equal and manager then
				manager:ShowPopup(addonID .. ".UnsavedChanges", ContinueChange, CancelChange)
			else
				ContinueChange()
			end
		end
	end
	
	function topControls.inheritance.Event:SelectionChanged(inheritance)
		postFrame:SetVisible(inheritance == "own")
	end
	
	function saveButton.Event:LeftPress()
		SetSavedSettings(currentCategory, GetEditSettings())
	end

	function priceGrid.Event:SelectionChanged()
		UpdateButtons()
	end
	
	function newButton.Event:LeftPress()
		local manager = GetPopupManager()
		if manager then
			local modelID = "bah" .. OsTime()
			local onSave = function(info) ModifyModel(modelID, info) end
			local modelInfo = { id = modelID, name = "", matchers = {}, enabled = true, original = false, own = true }
			manager:ShowPopup(addonID .. ".NewModel", 
				function(modelType)
					modelInfo.modelType = modelType
					modelInfo.usage = modelType == "complex" and "" or {}
					OpenEditor(manager, modelID, modelType, modelInfo, onSave) 
				end)
		end
	end
	
	function editButton.Event:LeftPress()
		local manager = GetPopupManager()
		local modelID, modelInfo = priceGrid:GetSelectedData()
		if manager and modelID and modelInfo then
			local modelType = modelInfo.modelType
			local onSave = function(info) ModifyModel(modelID, info) end
			OpenEditor(manager, modelID, modelType, modelInfo, onSave)
		end
	end
	
	function deleteButton.Event:LeftPress()
		local modelID = priceGrid:GetSelectedData()
		if modelID then
			local allModels = priceGrid:GetData()
			allModels[modelID] = nil
			priceGrid:SetData(allModels, nil, CheckInheritEnabled)
			modelDeleted = true
		end
	end

	return frame
end

local function LoadConfigScreens(parent)
	local screens = {}
	
	screens["general"] = { title = L["ConfigFrame/CategoryGeneral"], frame = GeneralSettings(parent), order = 0 }
	screens["search"] = { title = L["ConfigFrame/CategorySearch"], frame = SearchSettings(parent), order = 100 }
	screens["post"] = { title = L["ConfigFrame/CategoryPost"], frame = PostingSettings(parent), order = 200 }
	screens["selling"] = { title = L["ConfigFrame/CategorySelling"], frame = AuctionsSettings(parent), order = 300 }
	--screens["tracking"] = { title = L["ConfigFrame/CategoryTracking"], frame = nil, order = 400 }
	--screens["map"] = { title = L["ConfigFrame/CategoryMap"], frame = nil, order = 500 }
	--screens["history"] = { title = L["ConfigFrame/CategoryHistory"], frame = nil, order = 600 }
	screens["pricing"] = { title = L["ConfigFrame/CategoryPricing"], frame = PriceSettings(parent), order = 1000 }
	screens["scoring"] = { title = L["ConfigFrame/CategoryScoring"], frame = ScoreSettings(parent), order = 2000 }
	
	return screens
end

function InternalInterface.UI.ConfigFrame(name, parent)
	local configFrame = UICreateFrame("Frame", name, parent)
	local configSelector = DataGrid(name .. ".ConfigSelector", configFrame)
	local configDisplay = UICreateFrame("Mask", name .. ".ConfigDisplay", configFrame)
	
	local lastShownFrame = nil
	
	local function FontSizeSelector(value, key)
		local data = configSelector:GetData()
		local info = data and key and data[key] or nil
		local order = info and info.order or 0
		return order % 100 == 0 and 16 or 12
	end
	
	local function ColorSelector(value, key)
		local data = configSelector:GetData()
		local info = data and key and data[key] or nil
		if not info or (not info.frame and not info.children) then return { 0.5, 0.5, 0.5 } end
		local order = info and info.order or 0
		return order % 100 == 0 and { 1, 1, 0.75} or { 1, 1, 1 }
	end	
	
	configSelector:SetRowHeight(26)
	configSelector:SetSelectedRowBackgroundColor({0.4, 0.4, 0.4, 0.25})
	configSelector:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 5, 5)
	configSelector:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMLEFT", 295, -5)
	configSelector:AddColumn("title", nil, "Text", 200, 1, "title", false, { FontSize = FontSizeSelector, Color = ColorSelector })
	configSelector:AddColumn("order", nil, "Text", 0, 0, "order", true)
	configSelector:GetInternalContent():SetBackgroundColor(0, 0, 0.05, 0.5)

	configDisplay:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 300, 10)
	configDisplay:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -5, -10)

	function configSelector.Event:SelectionChanged(selectedKey, selectedValue)
		if not selectedKey then return end
		
		local newFrame = selectedValue.frame or (selectedValue.children and selectedValue.children[1].frame or nil)
		
		if lastShownFrame then
			lastShownFrame:SetVisible(false)
		end
		
		lastShownFrame = newFrame

		if lastShownFrame then
			lastShownFrame:SetAllPoints()
			lastShownFrame:SetVisible(true)
		end
	end	
	
	configSelector:SetData(LoadConfigScreens(configDisplay))
	
	return configFrame
end