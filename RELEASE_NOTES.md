# Far From Home v1.8.0 - Nowhere to Hide

Windows x64 release build exported with Godot 4.7.2 using the release template, not the debug template.

## Changes since v1.7.0

- Rotate backpack items with R. On a controller, pick an item up with Square/X, rotate with Triangle/Y, and place with Square/X or cancel with Circle/B.
- Rotated footprints obey backpack boundaries and occupied slots. Invalid drops preserve the original layout. Item orientation is saved and restored; older saves default to unrotated items.
- R still reloads during gameplay; rotation only applies while the backpack is open.
- Rifle and shotgun inventory icons now fill their slots, with transparent margins removed and clearer rendering in either orientation.
- Pursuing town monsters pound loudly on unlocked building doors for several seconds before forcing them open and entering.
- Mummies take longer and push unlocked hinged doors inward slowly. Locked doors and bolted passages remain barriers.
- Heavy spatial pounding comes from the actual door and repeats during the attempt. Menus pause it appropriately; gameplay dialogue preserves ongoing audio.
- Players can manually close forced doors. NPC routines cannot immediately cancel an active breach.

## Play

Download **FarFromHome-v1.8.0-Windows-x64.zip**, extract the entire ZIP and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

Includes controls, credits, asset and engine licenses, source commit and SHA256 checksums. All current source is also available in the repository and the separate source ZIP.
