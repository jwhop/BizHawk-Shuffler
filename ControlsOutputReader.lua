DEBUG_MODE = false

FOLDER_TO_READ = ".\\ControlsOutput\\"

CONTROLS_DICT = {
    GB = {"A", "B", "Up", "Down", "Left", "Right", "Start"},
    GBC = {"A", "B", "Up", "Down", "Left", "Right", "Start"},
    NES = {"A", "B", "Up", "Down", "Left", "Right", "Start"},
    NULL = {"NONE"}
}

buffer = 0 -- Sets countdown location. Adding 8 makes it appear correct for the NES.
if emu.getsystemid() == "NES" then
	buffer = 8
end


math.randomseed(os.time())

activeControls = CONTROLS_DICT[emu.getsystemid()]

inspect = require('inspect')

function addToDebugLog(text)
	if DEBUG_MODE then
		console.log(text)
	end
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

FRAMES_ON_PER_BUTTON = 20
FRAMES_OFF_PER_BUTTON = 10

FRAMES_BETWEEN_CHOOSE = 60 * 5

buttonOnFrames = 0
chooseButtonsFrames = 0

queuedButton = null
activeButton = null

queuedEventCount = 0

function chooseNextButton(rerollCount)
    addToDebugLog("activeControls: " .. inspect(activeControls))

    index = math.random(1, tablelength(activeControls))
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
                -- delete this file
                addToDebugLog("Deleting press: ")
                os.remove(filePath)
    
                beginButtonPress()
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
            chooseButtonsFrames = 0
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

        if buttonOnFrames > FRAMES_ON_PER_BUTTON then
            activeButton = null
        end
    end

    emu.frameadvance()
end