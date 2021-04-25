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

lastRings = {}
swapForTriggerCounters = {}
flagToSwap = false
hasLoadedFirstGame = false
hasLoadedRings = false

ringDefExists = false

inspect = require('inspect')
gameDefs = {}

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
			console.log("SKIP: " .. directory)
		else
			console.log("ROM: " .. directory)
			i = i + 1
			userdata.set("rom" .. i,directory)
			romSet[i] = directory
		end
	end
	databaseSize = i
	console.log("databaseSize is " .. databaseSize .. " roms!")
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
		console.log("value5 " .. tostring(settingsValue["value5"]))
	end	
end

if databaseSize ~= nil then
	currentGame = userdata.get("currentGame")
	openCurrentTime(rom)
	console.log("Current Game: " .. currentGame)
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
	console.log("Initial seed " .. seed)
end


i = 0
while i < databaseSize do
	i = i + 1
	romSet[i] = userdata.get("rom" .. i)
end

console.log("Time Limit " .. timeLimit)

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
				--console.log("Ran dirLookup()")
			end
			while currentGame == newGame or newGame == nil do
				ranNumber = math.random(1,databaseSize)
				newGame = romSet[ranNumber]
				console.log("Reroll! " .. ranNumber)
			end
		end
		currentGame = newGame
		userdata.set("first",1)
		savestate.saveslot(1)

		client.openrom(gamePath .. currentGame)

		savestate.loadslot(1)
		console.log("currentGame " .. currentGame .. " loaded!")
		userdata.set("currentGame",currentGame)
		userdata.set("timeLimit",timeLimit)
		romDatabase = io.open("CurrentROM.txt","w")
		romDatabase:write(gameinfo.getromname())
		romDatabase:close()
		--console.log(emu.getsystemid())
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

function checkRingCount()
	-- if diff % 120 == 0 then
	-- 	console.log("checkRingCount " .. ", ".. get_ring_file_path_for_current_game() .. ", " .. emu.getsystemid() .. ", " .. tostring(hasLoadedRings))
	-- end
	if emu.getsystemid() ~= "NULL" and hasLoadedRings then
		if loadedGameDefs["scoreCounters"] == nil then
			return
		end
		-- console.log("checkRingCount begins: " .. lastRings)
		for key, value in pairs(loadedGameDefs["scoreCounters"]) do
			-- console.log("scoreCounters : key = " .. key)
			-- console.log("scoreCounters : value = " .. inspect(value))
			
			bytesToInspect = value["bytes"]
			-- console.log("scoreCounters : bytesToInspect = " .. inspect(bytesToInspect))

			currentRings = 0
			multiplicand = 1
			for i = 1,8 do
				byteValue = bytesToInspect[i]
				if byteValue ~= nil then
					-- console.log("bytesToInspect : i = " .. i .. ", byteValue = " .. byteValue)
					foundValue = memory.readbyte(byteValue, value["domain"])
					if value["base"] == 100 then
						lowerVal = foundValue % 16
						upperVal = (foundValue - lowerVal) / 16
						foundValue = lowerVal + (upperVal * 10)
					end
					currentRings = currentRings + (foundValue * multiplicand)
					multiplicand = multiplicand * value["base"]
				end
			end

			-- if diff % 120 == 0 then
			-- 	console.log("currentRings: " .. currentRings)
			-- end

			if lastRings[key] == nil then
				lastRings[key] = 0
			end
			
			if currentRings ~= lastRings[key] then
				console.log("lastRings["..key.."] = " .. lastRings[key])
				ringDifference = currentRings - lastRings[key]
				lastRings[key] = currentRings

				if currentRings ~= 0 and ringDifference > value["minChange"] and ringDifference < value["maxChange"] then
					-- flagToSwap = true
					swapForTriggerCounters[key] = 1
					console.log("flagToSwap set at checkRingCount, ".. key .. " " .. lastRings[key] .. " -> " .. currentRings)
				end
			end
		end
	end
end

function saveCurrentRings()
	if emu.getsystemid() ~= "NULL" then
		console.log("saveCurrentRings " .. emu.getsystemid())
		console.log("saveCurrentRings writing")
		-- fileToWrite = io.open(get_ring_file_path_for_current_game(),"w")
		-- for key, value in pairs(lastRings) do
		-- 	fileToWrite:write(key .. ":" .. tostring(lastRings[key]), "\n")
		-- end
		-- fileToWrite:close()

		runningString = ""
		for key, value in pairs(lastRings) do
			if runningString:len() > 0 then
				runningString = runningString .. "/"
			end
			runningString = runningString .. key .. ":" .. tostring(lastRings[key])
		end

		userdata.set(get_ring_file_path_for_current_game(), runningString)

		console.log("saveCurrentRings wrote")
	end
end

if databaseSize == 1 then
	timeLimit = 6000
end

loadedGameDefs = {}
loadedGameDefs["scoreCounters"] = {}

function initialiseAlistairStuff()
	console.log("!!!!!!!!!!!!!!! which game are we in? !!!!!!!!!!!!!!!!!!")

	romName = gameinfo.getromname()
	romNameWithoutDetails = splitString(romName, "[(")[1]
	romNameWithoutDetails = romNameWithoutDetails:upper() 
	lastLetter = romNameWithoutDetails:sub(romNameWithoutDetails:len() - 1, romNameWithoutDetails:len())
	if lastLetter ~= " " then
		romNameWithoutDetails = romNameWithoutDetails .. " "
	end
	romNameWithoutDetails = romNameWithoutDetails .. emu.getsystemid()
	console.log("romNameWithoutDetails: " .. romNameWithoutDetails)

	fileNameForShuffleDetails = ".\\Events\\" .. romNameWithoutDetails .. ".txt"
	if (file_exists(fileNameForShuffleDetails)) then
		-- shuffleDetailsSrc = io.open(fileNameForShuffleDetails, "r")
		for line in io.lines(fileNameForShuffleDetails) do
			console.log("Has loaded shuffler line: " .. line)
			lineSplit = splitString(line, ">")
			if tablelength(lineSplit) > 1 then
				lastRings[lineSplit[1]] = 0
				loadedGameDefs["scoreCounters"][lineSplit[1]] = {}
				loadedGameDefs["scoreCounters"][lineSplit[1]]["bytes"] = {}
				loadedGameDefs["scoreCounters"][lineSplit[1]]["base"] = 0x100
				loadedGameDefs["scoreCounters"][lineSplit[1]]["minChange"] = 0
				loadedGameDefs["scoreCounters"][lineSplit[1]]["maxChange"] = 100000000
				loadedGameDefs["scoreCounters"][lineSplit[1]]["delay"] = 0
				loadedGameDefs["scoreCounters"][lineSplit[1]]["domain"] = memoryForConsole(emu.getsystemid())

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
		console.log("LOADED SPEC: " .. inspect(loadedGameDefs))
		ringDefExists = true
	else 
		console.log("NO FILE AT: " .. fileNameForShuffleDetails)
	end

	console.log("!!!!!!!!!!!!!!! do we have rings? !!!!!!!!!!!!!!!!!!") 

	ringsFilePath = get_ring_file_path_for_current_game()
	if userdata.containskey(ringsFilePath) then
		console.log("rings user data exists at " .. ringsFilePath)
		rawData = userdata.get(ringsFilePath)
		dataSplit = splitString(rawData, "/")
		for i, dataLine in pairs(dataSplit) do
			console.log("Has loaded rings line: " .. dataLine)
			lineSplit = splitString(dataLine, ":")
			if tablelength(lineSplit) > 1 then
				lastRings[lineSplit[1]] = tonumber(lineSplit[2])
				swapForTriggerCounters[lineSplit[1]] = 0
			end
		end
		hasLoadedRings = true
		-- console.log("lastRings: " .. inspect(lastRings))
	else
		console.log("No rings user data at " .. ringsFilePath)
		hasLoadedRings = true
		lastRings = {}
		swapForTriggerCounters = {}
	end

	console.log("!!!!!!!!!!!!!!! end of Alistair stuff !!!!!!!!!!!!!!!!!!") 
end

initialiseAlistairStuff()

while true do -- The main cycle that causes the emulator to advance and trigger a game switch.
	if (diff >= timeLimit - 180) then
		startCountdown(count)
	end
	checkRingCount()
	if emu.getsystemid() == "NULL" and diff == 5 then
		flagToSwap = true
		console.log("flagToSwap set at getsystemid")
	end

	if diff > timeLimit and ringDefExists == false then
		flagToSwap = true
	end	

	nextTriggerCounters = {}
	-- console.log("swapForTriggerCounters = " .. inspect(swapForTriggerCounters))
	for key, value in pairs(swapForTriggerCounters) do
		-- console.log("swapForTriggerCounters: " .. key .. " = " .. value)
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

	diff = diff + 1
	if (diff % 300) == 0 then
		console.log("On frame " .. diff)
	end

	if flagToSwap then
		swapForTriggerCounters = {}
		flagToSwap = false
		hasLoadedRings = false
		saveCurrentRings()

		saveTime(currentRom)
		nextGame(game)

		hasLoadedFirstGame = true
		shouldLoop = false
	else 
		emu.frameadvance()
	end	
end
