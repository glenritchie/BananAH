-- ***************************************************************************************************************************************************
-- * AutocompleteTextfield.lua                                                                                                                       *
-- ***************************************************************************************************************************************************
-- * Autocomplete Textfield                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * 0.4.12/ 2013.09.17 / Baanano: Updated to the new event model                                                                                    *
-- * 0.4.6 / 2013.02.20 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local MMax = math.max
local Panel = PublicInterface.Panel
local TInsert = table.insert
local TSort = table.sort
local UICreateFrame = UI.CreateFrame
local ipairs = ipairs
local pairs = pairs
local type = type

function PublicInterface.AutocompleteTextfield(name, parent)
	local frame = Panel(name, parent)
	local frameContent = frame:GetContent()
	local textbox = UICreateFrame("RiftTextfield", name .. ".Textbox", frameContent)
	local textComplete = UICreateFrame("Text", name .. ".TextComplete", frameContent)
	
	local matchingValues = {}
	local ignoreCase = false
	local offset = 0
	local lastReportedText = nil
	
	local function TryComplete(text)
		text = "^" .. text:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
		if ignoreCase then
			text = text:upper()
		end
		
		local matches = {}
		for _, match in ipairs(matchingValues) do
			local matchAgainst = ignoreCase and match:upper() or match
			if matchAgainst:find(text) then
				TInsert(matches, match)
			end
		end
		
		if #matches <= 0 then return nil end
		return matches[(offset % #matches) + 1]
	end
	
	local function ResetTextComplete()
		local text = textbox:GetText()
		textComplete:SetText(text)
		local width = textComplete:GetWidth()
		
		textComplete:SetPoint("BOTTOMLEFT", textbox, "BOTTOMLEFT", width - 4.5, -0.75)
		local complete = TryComplete(text)
		
		if not complete then
			textComplete:SetText("")
		else
			textComplete:SetText(complete:sub(text:len() + 1))
		end
		
		if lastReportedText ~= text then
			lastReportedText = text
			if frame.Event.TextChanged then
				frame.Event.TextChanged(frame, lastReportedText)
			end
		end
	end
	
	frameContent:SetBackgroundColor(0, 0, 0, 0.75)
	frame:SetInvertedBorder(true)
	
	textbox:SetPoint("CENTERLEFT", frameContent, "CENTERLEFT", 5, 1)
	textbox:SetPoint("CENTERRIGHT", frameContent, "CENTERRIGHT", -5, 1)
	
	textComplete:SetFontColor(.5, .5, .4, 1)
	textComplete:SetVisible(false)
	
	frame:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			textbox:SetKeyFocus(true)
		end, frame:GetName() .. ".OnLeftClick")

	textbox:EventAttach(Event.UI.Textfield.Change,
		function()
			ResetTextComplete()
		end, textbox:GetName() .. ".OnTextfieldChange")

	textbox:EventAttach(Event.UI.Input.Key.Focus.Gain,
		function()
			textComplete:SetVisible(true)
		end, textbox:GetName() .. ".OnKeyFocusGain")
	
	textbox:EventAttach(Event.UI.Input.Key.Focus.Loss,
		function()
			textComplete:SetVisible(false)
		end, textbox:GetName() .. ".OnKeyFocusLoss")
	
	textbox:EventAttach(Event.UI.Input.Key.Type,
		function(self, h, key)
			local text = textbox:GetText()
			if key == "\9" then
				offset = offset + 1
				textbox:SetCursor(text:len())
				ResetTextComplete()
			elseif key == "\13" then
				local complete = TryComplete(text)
				if complete then
					textbox:SetText(complete)
					textbox:SetCursor(complete:len())
					ResetTextComplete()
				end
				if frame.Event.EnterPressed then
					frame.Event.EnterPressed(frame)
				end			
			elseif key ~= "" then
				offset = 0
			end
		end, textbox:GetName() .. ".OnKeyType")

	PublicInterface.EventHandler(frame, { "TextChanged", "EnterPressed" })
	
	function frame:GetText()
		return textbox:GetText()
	end
	
	function frame:SetText(text)
		text = type(text) == "string" and text or ""
		if textbox:GetText() ~= text then
			textbox:SetText(text)
			offset = 0
			ResetTextComplete()
		end
	end
	
	function frame:GetMatchingTexts()
		local copy = {}
		for _, text in ipairs(matchingValues) do
			TInsert(copy, text)
		end
		return copy
	end
	
	function frame:SetMatchingTexts(matchingTexts)
		local newMatchingValues = {}
		if type(matchingTexts) == "table" then
			for key, value in pairs(matchingTexts) do
				if type(key) == "string" and value then
					TInsert(newMatchingValues, key)
				elseif type(value) == "string" then
					TInsert(newMatchingValues, value)
				end
			end
		end
		TSort(newMatchingValues)
		
		for index = MMax(#matchingValues, #newMatchingValues), 1, -1 do
			if matchingValues[index] ~= newMatchingValues[index] then
				matchingValues = newMatchingValues
				offset = 0
				ResetTextComplete()
				break
			end
		end
	end
	
	function frame:GetIgnoreCase()
		return ignoreCase
	end
	
	function frame:SetIgnoreCase(ignore)
		ignore = ignore and true or false
		if ignore ~= ignoreCase then
			ignoreCase = ignore
			offset = 0
			ResetTextComplete()
		end
	end
	
	return frame
end
