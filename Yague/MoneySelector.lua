-- ***************************************************************************************************************************************************
-- * MoneyDisplay.lua                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * Money frame                                                                                                                                     *
-- ***************************************************************************************************************************************************
-- * 0.4.12/ 2013.09.17 / Baanano: Updated to the new event model                                                                                    *
-- * 0.4.1 / 2012.07.16 / Baanano: Rewritten                                                                                                         *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local MFloor = math.floor
local MMax = math.max
local MMin = math.min
local Panel = PublicInterface.Panel
local SByte = string.byte
local SFormat = string.format
local UICreateFrame = UI.CreateFrame
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

local DEFAULT_COLOR = { 0, 0, 0, }

function PublicInterface.MoneySelector(name, parent)
	local bMoneySelector = UICreateFrame("Frame", name, parent)

	local platinumPanel = Panel(name .. ".PlatinumPanel", bMoneySelector)
	local goldPanel = Panel(name .. ".GoldPanel", bMoneySelector)
	local silverPanel = Panel(name .. ".SilverPanel", bMoneySelector)
	
	local secretLabel = UICreateFrame("Text", name .. ".SecretLabel", bMoneySelector)

	local platinumTexture = UICreateFrame("Texture", bMoneySelector:GetName() .. ".PlatinumTexture", platinumPanel:GetContent())
	local goldTexture = UICreateFrame("Texture", bMoneySelector:GetName() .. ".GoldTexture", goldPanel:GetContent())
	local silverTexture = UICreateFrame("Texture", bMoneySelector:GetName() .. ".SilverTexture", silverPanel:GetContent())
	
	local platinumInput = UICreateFrame("RiftTextfield", name .. ".PlatinumInput", platinumPanel:GetContent())
	local goldInput = UICreateFrame("RiftTextfield", name .. ".GoldInput", goldPanel:GetContent())
	local silverInput = UICreateFrame("RiftTextfield", name .. ".SilverInput", silverPanel:GetContent())

	local enabled = true
	local value, previousValue = 0, 0
	local colorSelector = nil

	local function ResetMoneySelector()
		value = MFloor(value or 0)

		local silver, gold, platinum = value % 100, MFloor(value / 100) % 100, MFloor(value / 10000)

		secretLabel:SetText(SFormat("%d", silver))
		silverInput:SetText((secretLabel:GetText()))
		silverInput:SetWidth(secretLabel:GetWidth() + 10)	

		secretLabel:SetText(SFormat("%d", gold))
		goldInput:SetText((secretLabel:GetText()))
		goldInput:SetWidth(secretLabel:GetWidth() + 10)	

		secretLabel:SetText(SFormat("%d", platinum))
		platinumInput:SetText((secretLabel:GetText()))
		platinumInput:SetWidth(secretLabel:GetWidth() + 10)	
		
		local color = DEFAULT_COLOR
		if colorSelector then
			color = colorSelector(value)
			color[1] = MMax(color[1] * 0.2, 0)
			color[2] = MMax(color[2] * 0.2, 0)
			color[3] = MMax(color[3] * 0.2, 0)
		end
		color[4] = 0.5
		
		silverPanel:GetContent():SetBackgroundColor(unpack(color))
		goldPanel:GetContent():SetBackgroundColor(unpack(color))
		platinumPanel:GetContent():SetBackgroundColor(unpack(color))
		
		if value ~= previousValue then
			previousValue = value
			if bMoneySelector.Event.ValueChanged then
				bMoneySelector.Event.ValueChanged(bMoneySelector, value)
			end
		end
	end
	
	local function GiveFocus(panel, input)
		panel:EventAttach(Event.UI.Input.Mouse.Left.Click,
			function()
				input:SetKeyFocus(true)
			end, panel:GetName() .. ".OnLeftClick")
	end
	
	local function AssignWheelEvents(panel, step)
		panel:EventAttach(Event.UI.Input.Mouse.Wheel.Forward,
			function()
				if enabled then
					local currentValue = bMoneySelector:GetValue()
					bMoneySelector:SetValue(currentValue + step)
				end
			end, panel:GetName() .. ".OnWheelForward")
		
		panel:EventAttach(Event.UI.Input.Mouse.Wheel.Back,
			function()
				if enabled then
					local currentValue = bMoneySelector:GetValue()
					local decrement = step
					while decrement > 1 and decrement > currentValue do decrement = MFloor(decrement / 100) end
					bMoneySelector:SetValue(currentValue - decrement)
				end
			end, panel:GetName() .. ".OnWheelBack")
	end
	
	local function AssignKeyEvents(input, minValue, maxValue, nextInput)
		local lastText, lastCursor, ignoreChange
		
		input:EventAttach(Event.UI.Input.Key.Type,
			function(self, h, key)
				lastText = self:GetText()
				lastCursor = self:GetCursor()
				ignoreChange = not tonumber(key) and SByte(key) and SByte(key) ~= 8
			end, input:GetName() .. ".OnKeyType")
		
		input:EventAttach(Event.UI.Textfield.Change,
			function(self)
				local newText = self:GetText()
				local newValue = tonumber(newText) or 0
				
				if not enabled or ignoreChange or newValue > maxValue or newValue < minValue then
					self:SetText(lastText)
					self:SetCursor(lastCursor)
					return
				end
				
				self:SetText(tostring(newValue))
				
				local platinum = tonumber(platinumInput:GetText()) or 0
				local gold = tonumber(goldInput:GetText()) or 0
				local silver = tonumber(silverInput:GetText()) or 0
				
				bMoneySelector:SetValue(platinum * 10000 + gold * 100 + silver)
				
				if self:GetText() == "0" then
					self:SetCursor(1)
				end
			end, input:GetName() .. ".OnTextfieldChange")
		
		input:EventAttach(Event.UI.Input.Key.Up,
			function(self, h, key)
				if key == "Tab" or key == "Return" or key == "Period" or key == "Space" or key == "Numpad Decimal" then
					if nextInput then
						nextInput:SetKeyFocus(true)
					else
						bMoneySelector:SetKeyFocus(true)
						bMoneySelector:SetKeyFocus(false)
					end
				end
			end, input:GetName() .. ".OnKeyUp")
		
		input:EventAttach(Event.UI.Input.Key.Focus.Gain,
			function()
				if not enabled then
					bMoneySelector:SetKeyFocus(true)
					bMoneySelector:SetKeyFocus(false)
				end
			end, input:GetName() .. ".OnKeyFocusGain")
	end
	
	platinumPanel:SetPoint("TOPLEFT", bMoneySelector, "TOPLEFT", 0, 0)
	platinumPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", -130, 0)
	platinumPanel:SetInvertedBorder(true)
	platinumPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	GiveFocus(platinumPanel, platinumInput)
	AssignWheelEvents(platinumPanel, 10000)
	
	goldPanel:SetPoint("TOPLEFT", bMoneySelector, "TOPRIGHT", -125, 0)
	goldPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", -65, 0)
	goldPanel:SetInvertedBorder(true)
	goldPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	GiveFocus(goldPanel, goldInput)
	AssignWheelEvents(goldPanel, 100)

	silverPanel:SetPoint("TOPLEFT", bMoneySelector, "TOPRIGHT", -60, 0)
	silverPanel:SetPoint("BOTTOMRIGHT", bMoneySelector, "BOTTOMRIGHT", 0, 0)
	silverPanel:SetInvertedBorder(true)
	silverPanel:GetContent():SetBackgroundColor(0, 0, 0, 0.5)
	GiveFocus(silverPanel, silverInput)
	AssignWheelEvents(silverPanel, 1)

	secretLabel:SetVisible(false)

	platinumTexture:SetPoint("BOTTOMRIGHT", platinumPanel:GetContent(), "BOTTOMRIGHT", 0, -2)
	platinumTexture:SetWidth(16)
	platinumTexture:SetHeight(16)
	platinumTexture:SetTextureAsync("Rift", "coins_platinum.png.dds")		
	
	goldTexture:SetPoint("BOTTOMRIGHT", goldPanel:GetContent(), "BOTTOMRIGHT", 0, -2)
	goldTexture:SetWidth(16)
	goldTexture:SetHeight(16)
	goldTexture:SetTextureAsync("Rift", "coins_gold.png.dds")	
	
	silverTexture:SetPoint("BOTTOMRIGHT", silverPanel:GetContent(), "BOTTOMRIGHT", 0, -2)
	silverTexture:SetWidth(16)
	silverTexture:SetHeight(16)
	silverTexture:SetTextureAsync("Rift", "coins_silver.png.dds")

	platinumInput:SetPoint("CENTERRIGHT", platinumPanel:GetContent(), "CENTERRIGHT", -12, 1)
	platinumInput:SetText("")
	AssignKeyEvents(platinumInput, 0, 99999, goldInput)

	goldInput:SetPoint("CENTERRIGHT", goldPanel:GetContent(), "CENTERRIGHT", -12, 1)
	goldInput:SetText("")
	AssignKeyEvents(goldInput, 0, 99, silverInput)

	silverInput:SetPoint("CENTERRIGHT", silverPanel:GetContent(), "CENTERRIGHT", -12, 1)
	silverInput:SetText("")
	AssignKeyEvents(silverInput, 0, 99, nil)

	function bMoneySelector:GetEnabled()
		return enabled
	end

	function bMoneySelector:SetEnabled(newEnabled)
		enabled = newEnabled and true or false
		if not enabled and (silverInput:GetKeyFocus() or goldInput:GetKeyFocus() or platinumInput:GetKeyFocus()) then
			bMoneySelector:SetKeyFocus(true)
			bMoneySelector:SetKeyFocus(false)
		end
	end
	
	function bMoneySelector:GetValue()
		return value
	end

	function bMoneySelector:SetValue(newValue)
		newValue = MMin(MMax(newValue or 0, 0), 999999999)
		if value ~= newValue then
			value = newValue
			ResetMoneySelector()
		end
	end	
	
	function bMoneySelector:SetColorSelector(colorFunction)
		colorSelector = colorFunction
		ResetMoneySelector()
	end
	
	PublicInterface.EventHandler(bMoneySelector, { "ValueChanged" })
	
	ResetMoneySelector()
	
	return bMoneySelector
end