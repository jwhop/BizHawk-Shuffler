DEBUG_MODE = false
function addToDebugLog(text)
	if DEBUG_MODE then
		console.log(text)
	end
end

diff = 0
lowTime = 5
highTime = 30
newGame = 0
i = 0
x = 0
romSet = {}
gamePath = ".\\CurrentROMs\\"
settingsPath = "settings.xml"
if userdata.get("countdown") ~= nil then
	countdown = userdata.get("countdown")
else
	countdown = false
end
currentChangeCount = 0
currentGame = 1
c = {}
readOldTime = ""
saveOldTime = 0
savePlayCount = 0

lastTriggerValue = {}
swapForTriggerCounters = {}
flagToSwap = false
hasLoadedFirstGame = false
hasLoadedEventTriggers = false

eventDefinitionsExist = false

inspect = require('inspect')
gameDefs = {}

-- ------------------------------ USEFUL TOOL FUNCTIONS
function splitString(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function memoryForConsole(whichConsole) 
	if whichConsole == "GEN" then
		return "68K RAM"
	end

	if whichConsole == "GB" then
		return "CartRAM"
	end
	
	if whichConsole == "NES" then
		return "WRAM"
	end

	if whichConsole == "SMS" then
		return "Main RAM"
	end

	if whichConsole == "GG" then
		return "Main RAM"
	end

	return memory.getcurrentmemorydomain()
end

function get_ring_file_path_for_current_game()
	return ".\\EventsTemp\\rings_" .. gameinfo.getromname() .. ".txt"
end

function file_exists(filePath)
	local f = io.open(filePath, "rb")
	if f then f:close() end
	return f ~= nil
end
-- ------------------------------ END OF USEFUL TOOL FUNCTIONS

if userdata.get("currentChangeCount") ~= nil then -- Syncs up the last time settings changed so it doesn't needlessly read the CurrentROMs folder again.
	currentChangeCount = userdata.get("currentChangeCount")
end
databaseSize = userdata.get("databaseSize")

function openCurrentTime(rom)
	oldTime = io.open(".\\TimeLogs\\" .. currentGame .. ".txt","a+")
	readOldTimeString = oldTime:read("*line")
	if readOldTimeString ~= nil then
		readOldTime = readOldTimeString
	else
		readOldTime = 0
	end
	oldTime:close()
	saveOldTime = readOldTime
	oldCount = io.open(".\\PlayCount\\" .. currentGame .. ".txt","a+")
	readOldCountString = oldCount:read("*line")
	if readOldCountString ~= nil then
		readOldCount = tonumber(readOldCountString)
	else
		readOldCount = 0
	end
	oldCount:close()
	savePlayCount = readOldCount + 1
	romDatabase = io.open("CurrentGameTime.txt","w")
	romDatabase:write(gameinfo.getromname() .. " play time: " .. saveOldTime)
	romDatabase:close()
	timeDatabase = io.open("CurrentGameSwitchCount.txt","w")
	timeDatabase:write(savePlayCount)
	timeDatabase:close()
	
end
	
	

function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function dirLookup(directory) -- Reads all ROM names in the CurrentROMs folder.
	i = 0
	for directory in io.popen([[dir ".\CurrentROMs" /b]]):lines() do
		if ends_with(directory, ".bin") then
			addToDebugLog("SKIP: " .. directory)
		else
			addToDebugLog("ROM: " .. directory)
			i = i + 1
			userdata.set("rom" .. i,directory)
			romSet[i] = directory
		end
	end
	databaseSize = i
	addToDebugLog("databaseSize is " .. databaseSize .. " roms!")
end

function getSettings(filename) -- Gets the settings saved by the RaceShufflerSetup.exe
	local fp = io.open(filename, "r" ) -- Opens settings.xml
	if fp == nil then 
		return nil
	end
	settingsName = {}
	settingsValue = {}
	newLine = "a"
	newSetting = "a"
	k = 1
	for line in fp:lines() do -- Gets lines from the settings xml.
		newLine = string.match(line,'%l+%u*%l+')
		newSetting = string.match(line,'%p%a+%p(%w+)')
		if newLine ~= "settings" then
			settingsValue["value" .. k] = newSetting
			k = k + 1
		end
			
	end
	fp:close() -- Closes settings.xml
	lowTime = settingsValue["value2"] -- Stores minimum value
	highTime = settingsValue["value3"] -- Stores maximum value
	changedRomCount = tonumber(settingsValue["value6"]) -- Stores value indicating if ROMs have been changed
	if settingsValue["value5"] == "true" then
		countdown = true
	else
		countdown = false
		addToDebugLog("value5 " .. tostring(settingsValue["value5"]))
	end	
end

if databaseSize ~= nil then
	currentGame = userdata.get("currentGame")
	openCurrentTime(rom)
	addToDebugLog("Current Game: " .. currentGame)
	lowTime = userdata.get("lowTime")
	highTime = userdata.get("highTime")
	seed = (userdata.get("seed"))
	math.randomseed(seed)
	math.random()
	if lowTime ~= highTime then
		timeLimit = math.random(lowTime * 60,highTime * 60)
	else
		timeLimit = tonumber(highTime * 60)
	end
else 
	getSettings(settingsPath)
	timeLimit = 5
	dirLookup(directory)
	seed = settingsValue["value4"]
	math.randomseed(seed)
	math.random()
	addToDebugLog("Initial seed " .. seed)
end


i = 0
while i < databaseSize do
	i = i + 1
	romSet[i] = userdata.get("rom" .. i)
end

addToDebugLog("Time Limit " .. timeLimit)

--Commenting delay out until we implement it in the setup bot. Feel free to use it yourself.
--[[


-- Pause after a swap
sound = client.GetSoundOn()
client.SetSoundOn(false)
client.sleep(500)  -- TODO: This should be configurable
client.SetSoundOn(sound)
]]

function cleanup()
	userdata.clear()
	do return end
end

function nextGame(game) -- Changes to the next game and saves the current settings into userdata
	if databaseSize > 0 then
		client.SetSoundOn(false)
		getSettings(settingsPath)
		diff = 0
		if currentChangeCount < changedRomCount then -- Only do dirLookup() if settings have changed
			dirLookup(directory)
			currentChangeCount = changedRomCount
		end
		if databaseSize == 1 then
			dirLookup(directory)
			newGame = romSet[1]
		else
			ranNumber = math.random(1,databaseSize)
			if romSet[ranNumber] ~= nil then
				newGame = romSet[ranNumber]
			else
				dirLookup(directory)
				newGame = userdata.get("rom" .. ranNumber)
				--addToDebugLog("Ran dirLookup()")
			end
			while currentGame == newGame or newGame == nil do
				ranNumber = math.random(1,databaseSize)
				newGame = romSet[ranNumber]
				addToDebugLog("Reroll! " .. ranNumber)
			end
		end
		currentGame = newGame
		userdata.set("first",1)
		savestate.saveslot(1)

		client.openrom(gamePath .. currentGame)

		savestate.loadslot(1)
		addToDebugLog("currentGame " .. currentGame .. " loaded!")
		userdata.set("currentGame",currentGame)
		userdata.set("timeLimit",timeLimit)
		romDatabase = io.open("CurrentROM.txt","w")
		romDatabase:write(gameinfo.getromname())
		romDatabase:close()
		randIncrease = math.random(1,20)
		userdata.set("seed",seed + randIncrease) -- Changes the seed so the next game/time don't follow a pattern.
		userdata.set("currentChangeCount",currentChangeCount)
		userdata.set("databaseSize",databaseSize)
		userdata.set("lowTime",lowTime)
		userdata.set("highTime",highTime)
		userdata.set("consoleID",emu.getsystemid())
		userdata.set("countdown",countdown)
		x = 0
		while x < databaseSize do
			x = x + 1
			userdata.set("rom" .. x, romSet[x])
		end
	end	
end

buffer = 0 -- Sets countdown location. Adding 8 makes it appear correct for the NES.
if emu.getsystemid() == "NES" then
	buffer = 8
end

function startCountdown(count) -- Draws the countdown box and text
	if countdown == true then
		gui.drawBox(client.bufferwidth()/2-60,buffer,client.bufferwidth()-(client.bufferwidth()/2+1-60),15+buffer,"white","black")
		if (diff >= timeLimit - 60) then 
			gui.drawText(client.bufferwidth()/2,buffer,"!.!.!.ONE.!.!.!","red",null,null,null,"center")
		elseif (diff >= timeLimit - 120) then 
			gui.drawText(client.bufferwidth()/2,buffer,"!.!...TWO...!.!","yellow",null,null,null,"center")
		else
			gui.drawText(client.bufferwidth()/2,buffer,"!....THREE....!","lime",null,null,null,"center")
		end
	end
end

if userdata.get("currentChangeCount") ~= null then
	currentChangeCount = userdata.get("currentChangeCount")
else
	currentChangeCount = 0
end

function saveTime(currentRom)
	currentGameTime = io.open(".\\TimeLogs\\" .. currentGame .. ".txt","w")
	if saveOldTime ~= nil then
		newTime = saveOldTime + timeLimit
	else
		newTime = timeLimit
	end
	currentGameTime:write(newTime)
	currentGameTime:close()
	currentGamePlayCount = io.open(".\\PlayCount\\" .. currentGame .. ".txt","w")
	if savePlayCount ~= nil then
		newPlayCount = savePlayCount
	else
		newPlayCount = 1
	end
	currentGamePlayCount:write(newPlayCount)
	currentGamePlayCount:close()
end

function checkForSwapEvent()
	-- memory inaccessible for the NULL system, so only check for swap events
	-- if we're in an active emulator (e.g. Genesis, SNES, GB...), and we're
	-- in a game where we have defined triggers in the "Events" folder
	if emu.getsystemid() ~= "NULL" and hasLoadedEventTriggers then
		if loadedGameDefs["scoreCounters"] == nil then
			return
		end

		-- for each defined trigger (e.g. score, ring count, coin count) for this game, 
		-- calculate if it has changed since last frame
		for key, value in pairs(loadedGameDefs["scoreCounters"]) do	
			bytesToInspect = value["bytes"]
			currentTriggerValue = 0
			multiplicand = 1

			-- Calculate the total based on the defined bytes and base for this trigger
			-- EXAMPLES
			-- if we track bytes {0xFE20, 0xFE21}, and read 0x12 from 0xFE20 and 0x34 from FE21
			--	in base 256, total = (1 * 0x12) + (256 * 0x34)
			--  in base 100, total = (1 * 0x2) + (10 * 0x1) + (100 * 0x4) + (1000 * 0x3)
			--  in base 10, total = (1 * 0x12) + (10 * 0x34)
			for i = 1,8 do
				byteValue = bytesToInspect[i]
				if byteValue ~= nil then
					foundValue = memory.readbyte(byteValue, value["domain"])
					if value["base"] == 100 then
						lowerVal = foundValue % 16
						upperVal = (foundValue - lowerVal) / 16
						foundValue = lowerVal + (upperVal * 10)
					end
					currentTriggerValue = currentTriggerValue + (foundValue * multiplicand)
					multiplicand = multiplicand * value["base"]
				end
			end

			-- initialise the trigger if we haven't done so yet
			if lastTriggerValue[key] == nil then
				lastTriggerValue[key] = 0
			end
			

			-- If the calculated score for this trigger is different enough from the
			-- previous one, fire the "ready to switch!" trigger
			if currentTriggerValue ~= lastTriggerValue[key] then
				addToDebugLog("lastTriggerValue["..key.."] = " .. lastTriggerValue[key])
				ringDifference = currentTriggerValue - lastTriggerValue[key]
				lastTriggerValue[key] = currentTriggerValue

				-- flag to begin counting down the swap timer for this trigger
				-- (immediate if "delay" is set to 0, after a few frames otherwise)
				if currentTriggerValue ~= 0 and ringDifference > value["minChange"] and ringDifference < value["maxChange"] then
					swapForTriggerCounters[key] = 1
					addToDebugLog("flagToSwap set at checkForSwapEvent, ".. key .. " " .. lastTriggerValue[key] .. " -> " .. currentTriggerValue)
				end
			end
		end
	end
end

-- Save the current states of the triggers, so that when we swap
-- back into this game, it does not immediately fire a swap.
-- Call this just before you switch games.
function saveCurrentTriggerStates()
	if emu.getsystemid() ~= "NULL" then
		addToDebugLog("saveCurrentTriggerStates " .. emu.getsystemid())
		addToDebugLog("saveCurrentTriggerStates writing")

		runningString = ""
		for key, value in pairs(lastTriggerValue) do
			if runningString:len() > 0 then
				runningString = runningString .. "/"
			end
			runningString = runningString .. key .. ":" .. tostring(lastTriggerValue[key])
		end

		userdata.set(get_ring_file_path_for_current_game(), runningString)

		addToDebugLog("saveCurrentTriggerStates wrote")
	end
end

if databaseSize == 1 then
	timeLimit = 6000
end

loadedGameDefs = {}
loadedGameDefs["scoreCounters"] = {}

function decodeGameDefs(sourceString)
	allLines = splitString(sourceString, "\n")
	for lineIndex, line in pairs(allLines) do
		addToDebugLog("Decoding shuffler line: " .. line)
		lineSplit = splitString(line, ">")
		-- you can comment out values to track using the "/" character
		if tablelength(lineSplit) > 1 and line:sub(1, 1) ~= "/" then
			-- begin by applying defaults for this trigger
			lastTriggerValue[lineSplit[1]] = 0
			loadedGameDefs["scoreCounters"][lineSplit[1]] = {}
			loadedGameDefs["scoreCounters"][lineSplit[1]]["bytes"] = {}
			loadedGameDefs["scoreCounters"][lineSplit[1]]["base"] = 0x100
			loadedGameDefs["scoreCounters"][lineSplit[1]]["minChange"] = 0
			loadedGameDefs["scoreCounters"][lineSplit[1]]["maxChange"] = 100000000
			loadedGameDefs["scoreCounters"][lineSplit[1]]["delay"] = 0
			loadedGameDefs["scoreCounters"][lineSplit[1]]["domain"] = memoryForConsole(emu.getsystemid())

			-- now decode each phrase
			data = splitString(lineSplit[2], "/")
			for i, dataEntry in pairs(data) do
				entry = splitString(dataEntry, ":")
				if entry[1] == "bytes" then
					bytesSplit = splitString(entry[2], ",")
					for j, byteName in pairs(bytesSplit) do
						loadedGameDefs["scoreCounters"][lineSplit[1]]["bytes"][j] = tonumber("0x" .. byteName)
					end
				end
				if entry[1] == "base" then
					loadedGameDefs["scoreCounters"][lineSplit[1]]["base"] = tonumber(entry[2])
				end
				if entry[1] == "minChange" then
					loadedGameDefs["scoreCounters"][lineSplit[1]]["minChange"] = tonumber(entry[2])
				end
				if entry[1] == "maxChange" then
					loadedGameDefs["scoreCounters"][lineSplit[1]]["maxChange"] = tonumber(entry[2])
				end
				if entry[1] == "delay" then
					loadedGameDefs["scoreCounters"][lineSplit[1]]["delay"] = tonumber(entry[2])
				end
				if entry[1] == "domain" then
					loadedGameDefs["scoreCounters"][lineSplit[1]]["domain"] = entry[2]
				end
			end
		end
	end
	eventDefinitionsExist = true
end

function initialiseEventTriggers()
	addToDebugLog("!!!!!!!!!!!!!!! initialiseEventTriggers begins !!!!!!!!!!!!!!!!!!")

	-- determine the file name for this game. For example, the game "Sonic Forces (JUE) [!]"
	-- running on the Sega Genesis will have its trigger stored at "Events/Sonic Forces GEN.txt"
	romName = gameinfo.getromname()
	romNameWithoutDetails = splitString(romName, "[(")[1]
	romNameWithoutDetails = romNameWithoutDetails:upper() 
	lastLetter = romNameWithoutDetails:sub(romNameWithoutDetails:len(), romNameWithoutDetails:len())
	if lastLetter ~= " " then
		romNameWithoutDetails = romNameWithoutDetails .. " "
	end
	romNameWithoutDetails = romNameWithoutDetails .. emu.getsystemid()
	addToDebugLog("romNameWithoutDetails: " .. romNameWithoutDetails)
	fileNameForShuffleDetails = ".\\Events\\" .. romNameWithoutDetails .. ".txt"

	-- userstateData = userdata.get(fileNameForShuffleDetails)

	-- If we've already cached trigger definitions for this game, use the cached definitions
	-- Otherwise, decode the data saved in the text file if it exists, use it and cache it
	-- Otherwise, default to using the timer
	if userstateData ~= NULL then
		decodeGameDefs(userstateData)
		addToDebugLog("DECODED CACHED SPEC: " .. inspect(loadedGameDefs))
	elseif (file_exists(fileNameForShuffleDetails)) then
		runningDef = ""
		for line in io.lines(fileNameForShuffleDetails) do
			-- prepare a version of this for the cache
			if runningDef:len() > 0 then
				runningDef = runningDef .. "\n"
			end
			runningDef = runningDef .. line
		end
		userdata.set(fileNameForShuffleDetails, runningDef)
		decodeGameDefs(runningDef)

		addToDebugLog("LOADED NEW SPEC: " .. inspect(loadedGameDefs))
	else 
		addToDebugLog("NO FILE AT: " .. fileNameForShuffleDetails)
		eventDefinitionsExist = false
	end

	addToDebugLog("!!!!!!!!!!!!!!! do we have cached trigger states? !!!!!!!!!!!!!!!!!!") 
	-- determine if we already have states cached for these triggers (i.e. from
	-- when we last switched out of this game)
	ringsFilePath = get_ring_file_path_for_current_game()
	if userdata.containskey(ringsFilePath) then
		addToDebugLog("trigger state user data exists at " .. ringsFilePath)
		rawData = userdata.get(ringsFilePath)
		dataSplit = splitString(rawData, "/")
		for i, dataLine in pairs(dataSplit) do
			addToDebugLog("Has loaded trigger state line: " .. dataLine)
			lineSplit = splitString(dataLine, ":")
			if tablelength(lineSplit) > 1 then
				lastTriggerValue[lineSplit[1]] = tonumber(lineSplit[2])
				swapForTriggerCounters[lineSplit[1]] = 0
			end
		end
		hasLoadedEventTriggers = true
	else
		addToDebugLog("No trigger states in user data at " .. ringsFilePath)
		hasLoadedEventTriggers = true
		lastTriggerValue = {}
		swapForTriggerCounters = {}
	end

	addToDebugLog("!!!!!!!!!!!!!!! end of initialiseEventTriggers !!!!!!!!!!!!!!!!!!") 
end

-- SET UP THE EVENT TRACKERS HERE!
initialiseEventTriggers()

while true do -- The main cycle that causes the emulator to advance and trigger a game switch.
	if (diff >= timeLimit - 180 and eventDefinitionsExist == false) then
		startCountdown(count)
	end

	-- The sound gets switched off during a game switch, so switch it on again
	-- if we're satisfied we're back in the game
	if diff == 5 then
		client.SetSoundOn(true)
	end
	-- After the first frame, start checking for swap events being fired
	-- e.g. collecting a ring
	if diff > 0 then 
		checkForSwapEvent()
	end

	-- If no emulator is loaded, swap immediately
	if emu.getsystemid() == "NULL" and diff == 5 then
		flagToSwap = true
		addToDebugLog("flagToSwap set at getsystemid")
	end

	-- If there are no defined events for this game use the timer
	-- to decide when to switch
	if diff > timeLimit and eventDefinitionsExist == false then
		flagToSwap = true
	end	

	-- Check for triggers that have been fired. If they have,
	-- count down until it is swap-time for them
	-- (the "delay" features allows us to tell the difference between
	-- score going up because you stomped an enemy, and score going up
	-- during an end-of-level totaliser)
	nextTriggerCounters = {}
	for key, value in pairs(swapForTriggerCounters) do
		nextTriggerCounters[key] = value
		if value > 0 then
			nextTriggerCounters[key] = value + 1
		end
		if loadedGameDefs["scoreCounters"][key] ~= nil then
			if value > loadedGameDefs["scoreCounters"][key]["delay"] then
				flagToSwap = true
				nextTriggerCounters[key] = 0
			end
		end
	end
	swapForTriggerCounters = nextTriggerCounters

	-- So the user can tell the script is running, log the frame count
	-- every 5 seconds
	diff = diff + 1
	if (diff % 300) == 0 then
		console.log("On frame " .. diff)
	end

	-- Swap to the next game if a swap has been fired!
	if flagToSwap then
		swapForTriggerCounters = {}
		flagToSwap = false
		hasLoadedEventTriggers = false
		saveCurrentTriggerStates()

		saveTime(currentRom)
		nextGame(game)

		hasLoadedFirstGame = true
		shouldLoop = false
	else 
		emu.frameadvance()
	end	
end
