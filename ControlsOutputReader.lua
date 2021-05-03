DEBUG_MODE = false

SETTINGS_FILE_PATH = "EventShufflerSettings.txt"

FOLDER_TO_READ = ".\\ControlsOutput\\"

CONTROLS_DICT = {
    GB = {"A", "B", "Up", "Down", "Left", "Right", "Start"},
    GBC = {"A", "B", "Up", "Down", "Left", "Right", "Start"},
    NES = {"A", "B", "Up", "Down", "Left", "Right", "Start"},
    NULL = {"NONE"}
}

SECONDS_BETWEEN_SWITCHES = 1

buffer = 0 -- Sets countdown location. Adding 8 makes it appear correct for the NES.
if emu.getsystemid() == "NES" then
	buffer = 8
end

inspect = require('inspect')

function addToDebugLog(text)
	if DEBUG_MODE then
		console.log(text)
	end
end

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

function file_exists(filePath)
	local f = io.open(filePath, "rb")
	if f then f:close() end
	return f ~= nil
end

function readEventShufflerSettings() 
	if (file_exists(SETTINGS_FILE_PATH)) then
		for line in io.lines(SETTINGS_FILE_PATH) do	
			components = splitString(line, ":")
			if tablelength(components) > 1 then
				if components[1] == "CONTROLS_READER_DEBUG_MODE" then
					DEBUG_MODE = components[2]:upper() == "TRUE"
				end
                if components[1] == "CONTROLS_READER_SECONDS_BETWEEN_SWITCHES" then
                    SECONDS_BETWEEN_SWITCHES = tonumber(components[2])
                    addToDebugLog("   Set SECONDS_BETWEEN_SWITCHES = " .. SECONDS_BETWEEN_SWITCHES)
                end
			end
            addToDebugLog("Reading setup line " .. line)
		end
	else
		console.log("No settings file at " .. SETTINGS_FILE_PATH)
	end
end

function shuffleArray(array)
    clonedArray = {}
    for key, value in pairs(array) do
        clonedArray[key] = value
    end

    outputArray = {}
    while tablelength(clonedArray) > 0 do
        index = math.random(1, tablelength(clonedArray))
        -- console.log("Removing cloned object at index " .. index)
        table.insert(outputArray, clonedArray[index])

        table.remove(clonedArray, index)
    end

    -- console.log("Returning shuffled array: " .. inspect(outputArray))
    return outputArray
end


FRAMES_ON_PER_BUTTON = 10
FRAMES_OFF_PER_BUTTON = 10

readEventShufflerSettings()
FRAMES_BETWEEN_CHOOSE = 60 * SECONDS_BETWEEN_SWITCHES

buttonOnFrames = 0
chooseButtonsFrames = 0

queuedButton = null
activeButton = null

queuedEventCount = 0

controlIndex = 1

math.randomseed(os.time())


activeControls = CONTROLS_DICT[emu.getsystemid()]
activeControls = shuffleArray(activeControls)

function chooseNextButton(rerollCount)
    addToDebugLog("activeControls: " .. inspect(activeControls))

    index = controlIndex --math.random(1, tablelength(activeControls))
    controlIndex = controlIndex + 1
    if controlIndex > tablelength(activeControls) then
        controlIndex = 1
    end
    addToDebugLog("Choose button at index " .. index)
    lastQueuedButton = queuedButton
    if lastQueuedButton == null then
        lastQueuedButton = "NULL"
    end
    queuedButton = activeControls[index]
    addToDebugLog("lastQueuedButton: " .. lastQueuedButton .. ", queuedButton: " .. queuedButton)

    if lastQueuedButton == queuedButton and rerollCount < 20 then
        addToDebugLog("Reroll button choice " .. rerollCount)
        chooseNextButton(rerollCount + 1)
    else
        addToDebugLog("Picked new button: " .. queuedButton)
        chooseButtonsFrames = 0
    end
end

chooseNextButton(0)

function beginButtonPress() 
    addToDebugLog("Pressing button: " .. queuedButton)
    activeButton = queuedButton
end

function showPendingControlsState()
    gui.drawBox(client.bufferwidth()/2-60,buffer,client.bufferwidth()-(client.bufferwidth()/2+1-60),15+buffer,"white","black")
    gui.drawText(client.bufferwidth()/2,buffer,queuedButton,"white",null,null,null,"center")

    timerStartX = client.bufferwidth()/2-60
    timerEndX = client.bufferwidth()-(client.bufferwidth()/2+1-60)
    timerMaxWidth = timerEndX - timerStartX
    timerWidth = (chooseButtonsFrames * timerMaxWidth) / FRAMES_BETWEEN_CHOOSE

    gui.drawBox(timerStartX, buffer+15, timerStartX + timerMaxWidth, 17+buffer, "white", "black")
    gui.drawBox(timerStartX, buffer+15, timerStartX + timerWidth, 17+buffer, "white", "white")
end

function showActiveControlsState()
    colour = "yellow"
    if buttonOnFrames > FRAMES_ON_PER_BUTTON then
        colour = "lime"
    end
    gui.drawBox(client.bufferwidth()/2-60,buffer,client.bufferwidth()-(client.bufferwidth()/2+1-60),15+buffer,colour,"black")
    gui.drawText(client.bufferwidth()/2,buffer,queuedButton,"white",null,null,null,"center")
end

function checkForQueuedButtonEvents()
    -- addToDebugLog("checkForQueuedButtonEvents")

    queuedEventCount = 0
    hasUsedEvent = false

    for i=1,100 do
		eventCountString = string.format("%05d", i)
        filePath = FOLDER_TO_READ .. "event_" .. eventCountString .. ".txt"

        if file_exists(filePath) then
            addToDebugLog("  " .. i .. ": " .. filePath)
            if hasUsedEvent then
                queuedEventCount = queuedEventCount + 1
            else
                shouldSendPress = false
                shouldChangeButton = false

                -- delete this file
                for line in io.lines(filePath) do	
                    wordsInLine = splitString(line, ",")
                    for index, value in pairs(wordsInLine) do
                        if value:upper() == "PRESS" then
                            shouldSendPress = true
                        end
                        if value:upper() == "CHANGE" then
                            shouldChangeButton = true
                        end
                    end
                end

                if shouldSendPress then
                    beginButtonPress()
                end
                if shouldChangeButton then
                    chooseNextButton(0)
                end

                addToDebugLog("Deleting press: ")
                os.remove(filePath)
    
                hasUsedEvent = true
            end
        end
    end
end

while true do
    activeControls = CONTROLS_DICT[emu.getsystemid()]

    for index, keyId in pairs(activeControls) do
        joypad.set({[keyId]=0})
    end

    if activeButton == null then
        buttonOnFrames = 0
        chooseButtonsFrames = chooseButtonsFrames + 1

        if chooseButtonsFrames > FRAMES_BETWEEN_CHOOSE or queuedButton == null then
            chooseNextButton(0)
        end

        showPendingControlsState()

        checkForQueuedButtonEvents()
    else
        if buttonOnFrames <= FRAMES_ON_PER_BUTTON then
            addToDebugLog("Pressing " .. activeButton)
            joypad.set({[activeButton]=1})
        end

        chooseButtonsFrames = 0
        buttonOnFrames = buttonOnFrames + 1

        showActiveControlsState()

        if buttonOnFrames > FRAMES_ON_PER_BUTTON + FRAMES_OFF_PER_BUTTON then
            activeButton = null
        end
    end

    emu.frameadvance()
end