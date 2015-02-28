-- ***************************************************************************************************************************************************
-- * PopupManager.lua                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * Popup Manager                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * 0.4.12/ 2013.09.19 / Baanano: Updated to the new event model                                                                                    *
-- * 0.4.1 / 2012.08.23 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local ipairs = ipairs
local pairs = pairs
local pcall = pcall

local popupConstructors = {}

function PublicInterface.PopupManager(name, parent)
	local mainFrame = UICreateFrame("Frame", name, parent)

	local visible = false
	local popupPool = {}
	
	local function ResetVisibility()
		if visible then
			for id, idPool in pairs(popupPool) do
				for _, popupFrame in ipairs(idPool) do
					if popupFrame:GetVisible() then
						mainFrame:SetVisible(true)
						return
					end
				end
			end
		end
		mainFrame:SetVisible(false)
	end
	
	mainFrame:SetAllPoints()
	mainFrame:SetLayer(999999)
	mainFrame:SetVisible(visible)
	
	local function eventSink() end
	mainFrame:EventAttach(Event.UI.Input.Mouse.Left.Click, eventSink, "dummy")
	mainFrame:EventAttach(Event.UI.Input.Mouse.Wheel.Forward, eventSink, "dummy")
	
	local parentSetVisible = parent.SetVisible
	function parent:SetVisible(parentVisible)
		visible = parentVisible
		parentSetVisible(parent, visible)
		ResetVisibility()
	end
	
	function mainFrame:ShowPopup(id, ...)
		if id and popupConstructors[id] then
			popupPool[id] = popupPool[id] or {}
			
			local popup = nil
			for _, popupFrame in ipairs(popupPool[id]) do
				if not popupFrame:GetVisible() then
					popup = popupFrame
					break
				end
			end
			
			if not popup then
				popup = popupConstructors[id](mainFrame)
				popup:SetPoint("CENTER", mainFrame, "CENTER", #popupPool[id] % 10, #popupPool[id] % 10)
				TInsert(popupPool[id], popup)
			end
			
			popup:SetVisible(true)
			pcall(popup.SetData, popup, ...)
			ResetVisibility()
			
			return popup
		end
	end
	
	function mainFrame:HidePopup(id, popup)
		if id and popupPool[id] then
			for _, popupFrame in ipairs(popupPool[id]) do
				if popupFrame == popup then
					popupFrame:SetVisible(false)
					ResetVisibility()
					break
				end
			end
		end
	end
	
	return mainFrame
end

function PublicInterface.RegisterPopupConstructor(id, constructor)
	if id then
		popupConstructors[id] = constructor
	end
end