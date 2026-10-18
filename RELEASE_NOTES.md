# Far From Home v0.9.0

A new Windows playable preview of ET Remastered / Far From Home, built with Godot 4.7.2.

- Opening sequence: the main menu fades to black, eyes blink open toward the sky, and the crash dialogue plays while the player is on the ground. Press E to stand up before collecting the backpack, flashlight and detour sheet.
- Saint George Hotel basement: discover the passage inside the locked Whitcomb mausoleum, walk the underground tunnel, then unbolt the hotel basement door from below to open a shortcut. The temporary mausoleum testing unlock is disabled; normal key and progression requirements apply.
- A shadowy cemetery apparition watches from between the graves and vanishes when approached.
- Restoring workshop power prepares a one-time Main Street ambush. The creature is already waiting out of sight; it attacks when the player exits the alley, after the townspeople finish running into their buildings and closing the doors. It remains dead after being killed. Extra pistol ammo is available inside the workshop.
- NPC shelter uses continuous running and real doorway interactions instead of teleporting.
- Lower background wind and a spatial horror scream just before the road tree falls. Scream attribution is included in assets/audio/SCREAM_SOURCE.txt.
- Road continues into the fog behind the crash, with an invisible travel barrier aligned with the roadside rock.
- Cleaned up small world captions and floating nameplates while retaining readable notes, UI and principal signs.
- Crash-car dashboard fits inside the hood; both yellow headlights and red tail lights blink together. Police roof lights alternate red and blue.
- Adult standing eye height of 1.65 m, with matching player collision and preserved crouch behavior.
- Includes the backpack, dialogue, Victorian house, restrained wallpaper stains, realistic paper notes, and other v0.8.0 features.

## Play

Download FarFromHome-v0.9.0-Windows-x64.zip, extract the entire archive, and run FarFromHome.exe. Keep the executable and PCK together. Godot is not required to play. The Source ZIP contains the editable Godot project.

WASD moves; mouse looks; E interacts; I opens the draggable backpack; Tab opens the journal; F toggles the flashlight; Escape pauses and offers Restart Game. Press E to stand after the opening dialogue. See the included README for full controls.

This is an early preview. Progress resets for each new journey. First-time shader compilation can briefly pause rendering. Asset credits and supplied license records are included.

## Validation

Targeted checks cover the wake/menu transition, standing and car tutorial, car-door close/reopen, falling-tree scream timing and damage, hotel tunnel gates and return routes, road barrier, monster combat and one-time death, NPC running and door closure, car-light synchronization, stairs and landing movement, and crouch/low-ceiling safety. Visual previews were checked for the major additions. Full gameplay remains manually tested by the player.
