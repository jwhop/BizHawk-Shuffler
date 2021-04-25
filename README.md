# BizHawk Event Shuffler

A fork of Brossentia's BizHawk shuffler that triggers game swaps when the player performs in-game actions (e.g. collecting a ring in Sonic games)

Games with events defined in the "Events" folder will switch when said event is triggered. All other games will obey the same switch-after-a-random-time-period rules as in Brossentia's original shuffler.

# Defining Events

To add your own events for a game, create a file with the file name `[game name] [console ID].txt` in the "Events" folder, where:
- `[game name]` is the name of the ROM as defined by BizHawk, up to but not including a `[` or `(` character. (Find names from the Lua console by typing in `gameinfo.getromname()`)
- `[console ID]` is the ID of the console as defined by BizHawk (Found from the Lua console by typing in `emu.getsystemid()`)

Event triggers are given as lines of the form
`[trigger name]>bytes:[comma separated hex values]/domain:[name of memory domain]/base:[10,100 or 256]/delay:[frame count]/minChange:[int]/maxChange[int]`
Fields after the `>` can be in any order. If not set then the fields will use default parameters.

- `trigger name` (e.g. `rings`) - an internal name for what counter has changed
- `bytes` (e.g. `FE20,FE21,FE22`) - which bytes to calculate the value from (lowest first)
- `domain` (e.g. `68K RAM`. Default varies by console) - which RAM state to look in (Found from the Lua console by typing in `memory.getmemorydomainlist()`)
- `base` (default = `256`) If `256`, each byte gives a hex value between `#00` and `#FF`. If `100` values are decimal, so the value `#99` represents the number 99 rather than the number 153). If `10` values are all between `#00` and `#09`.
- `delay` (default = `0`) The number of frames between the most recent event and the switch triggering. Used, for example, to differentiate between the score going up because you got a coin, and the score going up because of an end-of-level totaliser.
- `minChange` (default = `0`) If the value changes less than this in one frame then do not switch.
- `maxChange` (default = `1000000000`) If the value changes more than this in one frame then do not switch. 

# Setup
A script and setup program to randomize games being played in BizHawk! Currently, players can slip ROMs into the CurrentROMs folder and have the play order generated by a Lua script. The setup program generates a seed, sets the min/max times of each game played before switching, and an option to include a countdown.

This version works specifically with a developmental build of BizHawk. Future official releases should also work with it. Confirmed version that works: https://drive.google.com/file/d/12FpGfv52C22pNm3Pcb-o5W8-ybis3lX1/view?usp=sharing

BizHawk versions 2.5.3 and later should work fine.

Should be simple to get working! To use the shuffler, do the following:

1. Put ROMs into a "CurrentROMs" folder located in the same folder as EventShuffler.lua. You may leave ROMs in a .zip, but do not leave them in a folder.
2. Delete the "DeleteMe" files in the two ROM folders.
3. Run RaceShufflerSetup.exe to set your seed, your min/max time, and whether or not you want an on-screen three-second countdown for the upcoming swap.
4. Open Bizhawk.
5. Open a ROM for each console (NES, SNES, etc.) you're using, and map controls for them.
6. Go to Tools > Lua, then load the EventShuffler.lua script. (SoloShuffler.lua to run Brossentia's original script)
5. Enjoy!

If you wish to change the min/max times, add/remove games during playthrough, add a countdown on the screen, and randomize the seed (recommended), open the RaceShufflerSetup.exe.

Please note: If you move from 2 ROMs down to 1, only switch while playing the final game. Otherwise, the shuffler will stay on the one you just completed. I'll be fixing this later!

The file "CurrentROM.txt" will automatically change when moving to a new ROM. Feel free to use this for your OBS layout.

Future builds will hopefully have the following:

1. Ability to determine a swap order rather than having games shuffled.
2. Auto-remove DeleteMe files.
2. Add source code to this repository for the setup program.
