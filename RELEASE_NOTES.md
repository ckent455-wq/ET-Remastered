# Far From Home v1.0

A Windows playable preview of ET Remastered / Far From Home, built with Godot 4.7.2.

- Controller support for movement, look, combat, menus, dialogue, journal and backpack arrangement. Prompts switch automatically between keyboard/mouse and Xbox, PlayStation or Nintendo layouts. Disconnecting the active controller pauses gameplay.
- Optional grave cache: collect the rusted shovel from the workshop, then hold interact at the disturbed cemetery grave. Digging uncovers an actual recessed grave with soil walls, roots, a coffin model, six pistol rounds and a readable note. The shovel occupies three backpack slots. The temporary starting-shovel grant is removed.
- Cemetery creature waits beside the fence, scurries behind the mausoleum as you approach, and triggers a brief reaction once the building hides it.
- A preplaced upstairs creature ambushes the player through the Victorian house bedroom doorway. It supports normal combat, remains dead after being killed, and resets on a new journey.
- Invisible boundaries keep players out of the woods across from the crash, with room to leave the roadside shoulder.
- NPC names updated throughout dialogue, journal records, notes and prompts: Pat the ranger, Aubrey the nurse, and John the mechanic.
- All earlier crash opening, hotel tunnel, workshop ambush, NPC shelter, inventory and lighting improvements remain included. The mausoleum uses its normal key and quest requirements.

## Play

Download **FarFromHome-v1.0-Windows-x64.zip**, extract the entire ZIP, and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required. The Source ZIP contains the editable Godot project.

Keyboard: WASD moves, mouse looks, E interacts (hold to dig), I opens the backpack, Tab opens the journal/map, F toggles the flashlight, Escape pauses and offers Restart Game. Controller mappings are shown in Controls and the included README.

This is an early preview. Each new journey resets progress. First-time shader compilation may briefly pause rendering. Asset credits and licenses are included.

## Validation

Targeted checks passed for controller input and prompt switching, grave digging and reward/reset behavior, real below-ground collision and escape, reachable buried items, the upstairs ambush path/combat/reset, and updated NPC names. The recent crash tutorial and car-door checks also passed. Visual previews were inspected for the grave, coffin, shovel, controller UI and upstairs encounter. Controller checks used simulated input; a physical controller was not connected during verification. A full playthrough remains manually tested by the player.
