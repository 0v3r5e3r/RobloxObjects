--[[
##### SETTINGS #####
--]]

local shutdownTime = "03:00 AM"
local timezone = "America/New_York"
local timeBetweenSyncronization = "00:30:00"


--[[
##### BEGIN SCRIPT #####
--]]
local timeURL = "https://worldtimeapi.org/api/timezone/" .. timezone
local HttpService = game:GetService("HttpService")
type Time = {hour:number,minute:number,second:number}
local timeToClose:Time = {}
timeToClose.hour = 0;timeToClose.minute = 0;timeToClose.second = 0
local currentTime:Time = timeToClose -- time of day
local timeToCheck:Time = timeToClose

--[[
 parseTime(time)
 
 given a string in the format "hh:mm:ss" and an optional ("AM/PM") at the end
 parses the string into a Time object {hour:number,minute:number,second:number}
 and returns it.
--]]
local function parseTime(str:string) : Time
	local parts = str:split(" ")
	local h,m,s
	
	-- If PM then all hours will be + 12 (1 PM becomes 13:00)
	if #parts > 1 then if parts[2] == "PM" then h = 12 else h = 0 end else h = 0 end
	local timeString = parts[1]:split(":")
	
	-- Convert hours,minutes,and seconds if they are included
	h += tonumber(timeString[1])
	m = tonumber(timeString[2])
	if(#timeString >= 3) then
		s = tonumber(timeString[3]:split(".")[1])
	else
		s = 0
	end
	
	-- Return values as a Time object
	local t:Time = {}
	t.hour = h
	t.minute = m
	t.second = s
	return t
end

--[[
 fetchTime()
 
 Sends HTTP Get Request to public time API
 Parses and sets our current localtime to the api time
--]]
local function fetchTime()
	local rawString = HttpService:GetAsync(timeURL)
	if not rawString then return end
	
	local jsonData = HttpService:JSONDecode(rawString)
	local datetime = jsonData["datetime"]
	local timeData = datetime:split("T")[2]
	
	currentTime = parseTime(timeData)
end

-- Wait 1 minute and about 10 seconds before starting our checks
-- This ensures we don't shutdown a brand-new server :)
wait(1 * 60 + 10)

-- Initial Setup
fetchTime()
local tmpTime = parseTime(timeBetweenSyncronization)
timeToCheck = {currentTime.hour + tmpTime.hour, currentTime.minute + tmpTime.minute, currentTime.second + tmpTime.second}
timeToClose = parseTime(shutdownTime)
local timeOfLastTick = 0

game:GetService("RunService").Heartbeat:Connect(function()
	
	-- Wait 1 second before we do our time
	if (DateTime.now().UnixTimestampMillis - timeOfLastTick) < 1000 then return end
	timeOfLastTick = DateTime.now().UnixTimestampMillis
	
	-- Update Our Local Time
	currentTime.second += 1
	if(currentTime.second == 60) then currentTime.second = 0 currentTime.minute += 1 end
	if(currentTime.minute == 60) then currentTime.minute = 0 currentTime.hour += 1 end
	
	-- First check if we need to close the server
	if (currentTime.hour == timeToClose.hour)	 then
		if(currentTime.minute < timeToClose.minute + 1) and (currentTime.minute > timeToClose.minute - 1) then
			if(currentTime.second < timeToClose.second + 5) and (currentTime.second > timeToClose.second - 5) then
				print("TIME TO CLOSE THE SERVER")
				game.Players.PlayerAdded:Connect(function(plr) plr:Kick("Server Shutdown") end)
				for _,v in pairs(game.Players:GetPlayers()) do
					v:Kick("Server Shutdown For Updates")
				end
			end
		end
	end
	
	-- Finally check if we should synchronize our local time against the api time
	-- If not the same hour then skip
	if not (currentTime.hour == timeToCheck.hour) then return end
	-- If not the same minute (+/- 1) skip
	if not (currentTime.minute < timeToCheck.minute + 1 and currentTime.minute > timeToCheck.minute - 1) then return end
	-- If not the same second (+/- 5) skip
	if not (currentTime.second < timeToCheck.second + 5 and currentTime.second > timeToCheck.second - 5) then return end
	-- We re-check the time
	fetchTime()
	timeToCheck = {currentTime.hour + tmpTime.hour, currentTime.minute + tmpTime.minute, currentTime.second + tmpTime.second}

end)