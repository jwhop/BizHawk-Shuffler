# Tetris, but all at once ( a BizHawk Event Shuffler fork)

A fork of Alistair Aitcheson's fork (https://github.com/alistairaitcheson/BizHawk-Shuffler) of Brossentia's BizHawk Shuffler (https://github.com/brossentia/BizHawk-Shuffler) that triggers game swaps when the player performs in-game actions (e.g. collecting a ring in Sonic games)

Instead of swapping games, this version of the script will spawn a new instance of a game and tile it with your existing games on your desktop.

# Setup
1. Download Bizhawk (https://github.com/TASEmulators/BizHawk/releases/)
2. Download Tetris ROMs (see supported Tetris game list below)
3. Place Tetris ROMs in CurrentROMs folder
4. Place Bizhawk and related folders (EXCEPT for the Gameboy, GBA, N64, NDS, NES, SNES folders) into the 'BizHawk-and-ROMs' folder
5. Open the EmuHawk emulator, go to config ->Customize.., and check "run in background"
6. If you want to control each game together or separately, open EmuHawk, go to Config->Customize, and Check/Uncheck "allow background input"
5. You may have to open each ROM and map controls correctly to how you want 
6. Run Tetris,ButAllAtOnce.bat or Tetris,ButAllAtOnceQuiet.bat in the main folder
7. Have fun! 


# Supported Tetris Games

The following games have events associated with them. I haven't tested different versions of the ROMs, so things might be a bit wonky. 

*Nintendo 64*
- Tetris 64
- The New Tetris
- Magical Tetris Challenge *does not have event for gameover

*SNES*
- Super Tetris 3

*NES*
- Tetris *sometimes does not detect line clear

*Game Boy*
- Tetris

*Game Boy Advance*
- Tetris Worlds

*Nintendo DS*
- Tetris DS


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

- To set up your own tetris game, add one event for line clears and optionally another for a game over. For game over events, you need to go into the event text file and add: /isEnd:True 

# TO DO

- Fix Window Tiling (is a bit broken)
- Add new Tetris games 

# Troubleshooting

If your emulator hangs on a frame, try removing the n64 ROMs from your currentROMs folder. They can be extremely picky to work with.

The program works by tiling windows with the word "tetris" in their header, so if you have any other pages open, it will mess up the tiling (a bit silly, i know, but can't find a workaround yet D:)

# Contact me

jwhopkins.dev@gmail.com
Twitter: http://twitter.com/jwhopkin
