-- ***************************************************************************************************************************************************
-- * Calendar.lua                                                                                                                                    *
-- ***************************************************************************************************************************************************
-- * Calendar control                                                                                                                                *
-- ***************************************************************************************************************************************************
-- * 0.4.12/ 2013.09.17 / Baanano: Updated to the new event model                                                                                    *
-- * 0.4.4 / 2012.01.13 / Baanano: Moved to Yague from BiSCal                                                                                        *
-- ***************************************************************************************************************************************************

local addonInfo, Internal = ...
local addonID = addonInfo.identifier
local PublicInterface = _G[addonID]

local CEAttach = Command.Event.Attach
local EventHandler = PublicInterface.EventHandler
local ITFrame = Inspect.Time.Frame
local MFloor = math.floor
local ODate = os.date
local OTime = os.time
local Panel = PublicInterface.Panel
local ShadowedText = PublicInterface.ShadowedText
local TInsert = table.insert
local UICreateFrame = UI.CreateFrame
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local type = type
local unpack = unpack

Internal.UI = Internal.UI or {}

local DEFAULT_MONTH_FORMAT = "%B %Y"
local DEFAULT_HOUR_FORMAT = "%I:%M %p"
local DEFAULT_START_ON_MONDAY = false
local DEFAULT_MONTH_NAMES = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
local DEFAULT_WEEKDAY_NAMES = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local DEFAULT_UPDATE_FREQUENCY = 30 / 42

local function CreateDayFrame(name, parent, evenAppearance)
	local dayFrame = UICreateFrame("Frame", name, parent)
	
	local dayTexture = UICreateFrame("Texture", dayFrame:GetName() .. ".DayTexture", dayFrame)
	local dayText = ShadowedText(dayFrame:GetName() .. ".DayText", dayFrame)
	local moreTexture = UICreateFrame("Texture", dayFrame:GetName() .. ".MoreTexture", dayFrame)
	local hourText = ShadowedText(dayFrame:GetName() .. ".HourText", dayFrame)
	
	local counter = 0
	local events = {}
	local hourFormat = DEFAULT_HOUR_FORMAT
	local onSelect = nil
	
	local function RefreshEvent()
		counter = counter % #events
		if counter == counter then
			dayTexture:SetTextureAsync(unpack(events[counter + 1].overlay))
			hourText:SetVisible(true)
			hourText:SetText(ODate(hourFormat, events[counter + 1].timestamp))
		else
			dayTexture:SetTextureAsync(addonID, "dummy")
			hourText:SetVisible(false)
			counter = 0
		end
	end

	dayFrame:SetBackgroundColor(1, 1, 1, (evenAppearance and 0.01 or 0) + 0.14)
	
	dayTexture:SetPoint("TOPLEFT", dayFrame, "TOPLEFT", 1, 1)
	dayTexture:SetPoint("BOTTOMRIGHT", dayFrame, "BOTTOMRIGHT", -1, -1)
	dayTexture:SetBackgroundColor(0, 0, 0, 0.2)
	dayTexture:SetLayer(5)
	
	dayText:SetPoint("TOPRIGHT", dayTexture, "TOPRIGHT", -2, 2)
	dayText:SetFontSize(10)
	dayText:SetFontColor(0.8, 0.9, 1)
	dayText:SetBackgroundColor(0, 0, 0, 0.85)
	dayText:SetLayer(10)
	
	moreTexture:SetPoint("TOPLEFT", dayTexture, "TOPLEFT", 2, 2)
	moreTexture:SetPoint("BOTTOMRIGHT", dayTexture, "TOPLEFT", 18, 18)
	moreTexture:SetTextureAsync("Rift", "vfx_ui_mob_tag_heal_mini.png.dds")
	moreTexture:SetBackgroundColor(0, 0, 0, 0.5)
	moreTexture:SetLayer(10)
	moreTexture:SetVisible(false)
	
	hourText:SetPoint("BOTTOMCENTER", dayTexture, "BOTTOMCENTER", 0, -2)
	hourText:SetFontSize(10)
	hourText:SetFontColor(0.8, 0.9, 1)
	hourText:SetBackgroundColor(0, 0, 0, 0.85)
	hourText:SetLayer(10)
	hourText:SetVisible(false)
	
	dayFrame:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if type(onSelect) == "function" then
				onSelect()
			end
		end, dayFrame:GetName() .. ".OnLeftClick")
	
	moreTexture:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if type(onSelect) == "function" then
				onSelect()
			end
			counter = counter + 1
			RefreshEvent()
		end, moreTexture:GetName() .. ".OnLeftClick")
	
	
	function dayFrame:SetValue(day, faded, selected, dayEvents, selectFunction)
		dayText:SetText(tostring(day))
		
		dayFrame:SetBackgroundColor(1, 1, 1, selected and 0.25 or (evenAppearance and 0.01 or 0) + 0.14)
		dayFrame:SetAlpha(faded and 0.25 or 1)
		
		events = {}
		if dayEvents then
			for eventID, eventData in pairs(dayEvents) do
				TInsert(events, { timestamp = eventData.timestamp, overlay = eventData.overlay })
			end
		end
		
		moreTexture:SetVisible(#events > 1)
		
		RefreshEvent()
		
		onSelect = selectFunction
	end
	
	function dayFrame:AdvanceCounter()
		counter = counter + 1
		RefreshEvent()
	end
	
	function dayFrame:SetHourFormat(newHourFormat)
		hourFormat = newHourFormat
		RefreshEvent()
	end
	
	return dayFrame
end

function PublicInterface.Calendar(name, parent)
	local frame = UICreateFrame("Frame", name, parent)
	
	local titleText = ShadowedText(name .. ".TitleText", frame)
	local prevButton = UICreateFrame("Texture", name .. ".PrevButton", frame)
	local nextButton = UICreateFrame("Texture", name .. ".NextButton", frame)
	local monthPanel = Panel(name .. ".MonthPanel", frame)
	local monthContent = monthPanel:GetContent()
	local dayHeaders = {}
	local monthDays = {}

	local calendarData = nil
	local selectedDate = ODate("*t")
	local titleFormat = DEFAULT_MONTH_FORMAT
	local startOnMonday = DEFAULT_START_ON_MONDAY
	local monthNames = DEFAULT_MONTH_NAMES
	local weekdayNames = DEFAULT_WEEKDAY_NAMES
	local updateFrequency = DEFAULT_UPDATE_FREQUENCY
	
	local function DateFormatter(formatString, timestamp)
		local weekdayName = weekdayNames[tonumber(ODate("%w", timestamp)) + 1]
		local monthName = monthNames[tonumber(ODate("%m", timestamp))]
		
		formatString = formatString:gsub("%%A", weekdayName)
		formatString = formatString:gsub("%%B", monthName)

		return ODate(formatString, timestamp)
	end
	
	local function GetMidnightSelectedDate()
		return OTime({ year = selectedDate.year, month = selectedDate.month, day = selectedDate.day, hour = 0, min = 0, sec = 0 })
	end
	
	local function ResetDate()
		local day, month, year = selectedDate.day, selectedDate.month, selectedDate.year
		local offset = ODate("*t", OTime({ year = year, month = month, day = 1 })).wday - (startOnMonday and 2 or 1)
		local numDays = ODate("*t", OTime({ year = year, month = month + 1, day = 0 })).day
		
		if offset < 0 then offset = offset + 7 end
		if offset == 0 and numDays == 28 then offset = 7 end
		
		titleText:SetText(DateFormatter(titleFormat, OTime(selectedDate)))
		
		for index, dayFrame in ipairs(monthDays) do
			local frameTimestamp = OTime({ year = year, month = month, day = index - offset, hour = 0, min = 0, sec = 0 })
			
			local dayEvents = {}
			if calendarData then
				for eventID, eventData in pairs(calendarData) do
					if eventData.timestamp >= frameTimestamp and eventData.timestamp < frameTimestamp + 24 * 60 * 60 then
						dayEvents[eventID] = eventData
					end
				end
			end			
			
			dayFrame:SetValue(ODate("*t", frameTimestamp).day, index <= offset or index > offset + numDays, index == day + offset, dayEvents, function() frame:SetSelectedDate(frameTimestamp) end)
		end
	end
	
	local function ResetWeekdays()
		for index = 1, 7 do
			local adjustedIndex = index
			if startOnMonday then
				adjustedIndex = adjustedIndex == 7 and 1 or adjustedIndex + 1
			end
			dayHeaders[index]:SetText(weekdayNames[adjustedIndex])
		end
	end
	
	titleText:SetPoint("CENTER", frame, "BOTTOMCENTER", 0, -12)
	titleText:SetFontSize(15)
	titleText:SetFontColor(0.75, 0.75, 0.5)
	titleText:SetShadowOffset(2, 2)
	
	prevButton:SetPoint("CENTERLEFT", frame, "BOTTOMLEFT", 5, -12)
	prevButton:SetPoint("BOTTOMCENTER", frame, "BOTTOMLEFT", 17, -1)
	prevButton:SetTextureAsync(addonID, "Textures/MovePrevious.png")
	
	nextButton:SetPoint("CENTERRIGHT", frame, "BOTTOMRIGHT", -5, -12)
	nextButton:SetPoint("BOTTOMCENTER", frame, "BOTTOMRIGHT", -17, -1)
	nextButton:SetTextureAsync(addonID, "Textures/MoveNext.png")
	
	monthPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 20)
	monthPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -30)
	monthPanel:SetInvertedBorder(true)
	
	for index = 1, 7 do
		local dayHeader = ShadowedText(name .. ".DayHeader" .. index, frame)
		dayHeader:SetPoint("CENTER", monthContent, index / 7 - 1 / 14 , 0, 0, -14)
		dayHeaders[index] = dayHeader
	end
	
	for index = 1, 42 do
		local row = MFloor((index - 1) / 7) + 1
		local column = ((index - 1) % 7) + 1
		
		local dayFrame = CreateDayFrame(monthPanel:GetName() .. ".Days." .. index, monthContent, index % 2 == 0)
		dayFrame:SetPoint("TOPLEFT", monthContent, (column - 1) / 7, (row - 1) / 6)
		dayFrame:SetPoint("BOTTOMRIGHT", monthContent, column / 7, row / 6)
		
		monthDays[index] = dayFrame
	end
	
	monthContent:SetBackgroundColor(0, 0.0625, 0.125, 0.5)
	
	prevButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			local prevMonth = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month, day = 0 })).month
			selectedDate = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month - 1, day = selectedDate.day }))
			while selectedDate.month ~= prevMonth do
				selectedDate = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month, day = selectedDate.day - 1 }))
			end

			if frame.Event.DateChanged then
				frame.Event.DateChanged(frame, GetMidnightSelectedDate())
			end

			ResetDate()
		end, prevButton:GetName() .. ".OnLeftClick")
	
	nextButton:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			local nextMonth = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month, day = 32 })).month
			selectedDate = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month + 1, day = selectedDate.day }))
			while selectedDate.month ~= nextMonth do
				selectedDate = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month, day = selectedDate.day - 1 }))
			end

			if frame.Event.DateChanged then
				frame.Event.DateChanged(frame, GetMidnightSelectedDate())
			end

			ResetDate()
		end, nextButton:GetName() .. ".OnLeftClick")
	
	monthPanel:EventAttach(Event.UI.Input.Mouse.Wheel.Forward,
		function()
			selectedDate = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month, day = selectedDate.day - 7 }))
			
			if frame.Event.DateChanged then
				frame.Event.DateChanged(frame, GetMidnightSelectedDate())
			end
			
			ResetDate()
		end, monthPanel:GetName() .. ".OnWheelForward")
	
	monthPanel:EventAttach(Event.UI.Input.Mouse.Wheel.Back,
		function()
			selectedDate = ODate("*t", OTime({ year = selectedDate.year, month = selectedDate.month, day = selectedDate.day + 7 }))

			if frame.Event.DateChanged then
				frame.Event.DateChanged(frame, GetMidnightSelectedDate())
			end

			ResetDate()
		end, monthPanel:GetName() .. ".OnWheelBack")
	
	function frame:SetData(data)
		calendarData = data
		ResetDate()
	end
	
	function frame:SetSelectedDate(date)
		selectedDate = ODate("*t", date)
		
		if frame.Event.DateChanged then
			frame.Event.DateChanged(frame, GetMidnightSelectedDate())
		end
		
		ResetDate()
	end
	
	function frame:GetSelectedDate()
		return GetMidnightSelectedDate()
	end
	
	function frame:SetMonthFormat(newFormat)
		titleFormat = newFormat
		ResetDate()
	end
	
	function frame:SetHourFormat(newFormat)
		for index, dayFrame in ipairs(monthDays) do
			dayFrame:SetHourFormat(newFormat)
		end
	end
	
	function frame:SetStartOnMonday(start)
		startOnMonday = start and true or false
		ResetDate()
		ResetWeekdays()
	end
	
	function frame:SetMonths(months)
		monthNames = months
		ResetDate()
	end
	
	function frame:SetWeekdays(weekdays)
		weekdayNames = weekdays
		ResetWeekdays()
	end
	
	function frame:SetUpdateFrequency(frequency)
		updateFrequency = frequency
	end
	
	frame:EventAttach(Event.UI.Input.Mouse.Cursor.In, function() end, "Dummy")
	frame:EventAttach(Event.UI.Input.Mouse.Wheel.Back, function() end, "Dummy")
	
	local nextIndex = 1
	local lastUpdate = ITFrame()
	local function OnUpdate()
		if updateFrequency then
			local update = ITFrame()
			if update > lastUpdate + updateFrequency then
				lastUpdate = update
				monthDays[nextIndex]:AdvanceCounter()
				nextIndex = (nextIndex % #monthDays) + 1
			end
		end
	end
	CEAttach(Event.System.Update.Begin, OnUpdate, addonID .. ".CalendarControl." .. name .. ".OnUpdate")
	
	ResetDate()
	ResetWeekdays()
	
	EventHandler(frame, { "DateChanged" })
	
	return frame
end
