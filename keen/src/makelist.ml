<DEFAULT
COMPILE=gcc -O2 -c %SRCFILE% -o %MODULE%.%OBJ_EXT%
LPREFIX=gcc -o %EXEFILE%
LSUFFIX=-lSDL -lSDLmain -lstdc++
OUTPUT=keen

>>
main.c
sanity.c
game.c
gamedo.c
gamepdo.c
gamepdo_wm.c
editor/editor.c
editor/autolight.c
console.c
fileio.c
maploader.c
map.c
graphics.c
palette.c
fonts.c
misc.c
misc_ui.c
graphicmaker.c
ini.c
intro.c
menumanager.c
menu_options.c
menu_keysetup.c
menu_savegames.c
menu_custommap.c
editor/menu_editor.c
customepisode.c
savegame.c
twirly.c
sgrle.c
lprintf.c
vgatiles.c
latch.c
lz.c
message.c
cinematics/seqcommon.c
cinematics/e1ending.c
cinematics/e3ending.c
cinematics/blowupworld.c
cinematics/mortimer.c
cinematics/TBC.c
FinaleScreenLoader.c
globals.c
ai/yorp.c
ai/garg.c
ai/vort.c
ai/butler.c
ai/tank.c
ai/door.c
ai/ray.c
ai/icecannon.c
ai/teleport.c
ai/rope.c
ai/walker.c
ai/tankep2.c
ai/platform.c
ai/platvert.c
ai/vortelite.c
ai/se.c
ai/baby.c
ai/earth.c
ai/foob.c
ai/ninja.c
ai/meep.c
ai/sndwave.c
ai/mother.c
ai/fireball.c
ai/balljack.c
ai/nessie.c
ai/autoray.c
ai/gotpoints.c
sdl/keydrv.c
sdl/snddrv.c
sdl/timedrv.c
sdl/viddrv.c
scale2x/scalebit.c
scale2x/scale2x.c
scale2x/scale3x.c
scale2x/pixel.c
platform.cpp
<<

<MS
COMPILE=cl.exe -nologo -MD -W3 -GX -Zi -D "WIN32" -D"MSVC" -D"TARGET_WIN32" -D "_WINDOWS" -D "_MBCS" -D main=SDL_main -Fp"%OUTPUT%.pch" -YX -FD -Fo"%MODULE%.obj" -c %SRCFILE%
LPREFIX=link.exe kernel32.lib user32.lib gdi32.lib SDL.lib SDLmain.lib -DEBUG -nologo -subsystem:windows -incremental:yes -pdb:"spc.pdb" -machine:I386 -out:"%EXEFILE%" -pdbtype:sept
LSUFFIX=
OBJ_EXT=obj
OUTPUT=keen.exe
