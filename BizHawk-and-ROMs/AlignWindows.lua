winapi = require('winapi')

nontetriswindows = winapi.find_all_windows(winapi.make_name_matcher 'Tetris')
winapi.tile_windows(winapi.get_desktop_window(),false,nontetriswindows)

nontetriswindows[1]:set_foreground()

winapi.sleep(200)
consoleWindows = winapi.find_all_windows(winapi.make_name_matcher 'Lua Console')
for i=1, #consoleWindows do 
	if(consoleWindows[i]:__tostring() == "Lua Console") then
		consoleWindows[i]:show(winapi.SW_MINIMIZE)
	end
end

local p = winapi.get_current_process()
p:kill()
