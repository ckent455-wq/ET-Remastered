# Far From Home v1.3.1 - Clearer Instructions and Door Fixes

Playable Windows x64 survival-horror preview, built with Godot 4.7.2.

## Changes since v1.3.0

- Tutorial instructions and feedback use larger dialogue-style boxes with a black background, cream border, wrapped pixel text and more reading time. Gameplay continues while instructions are visible.
- Interaction instructions say "E TO OPEN" and "E TO TAKE". Controller prompts use the corresponding controller button. Yellow prompts that duplicate the current tutorial instruction are hidden.
- Building and chapel doors swing inward. You can open and close doors from either side, including closing them after leaving. Doorway interaction targets remain reachable while doors are open.
- Removed the restriction that kept doors open while the player was inside, including the chapel and mausoleum. Manual building-door interactions no longer fail because of the old broad doorway-occupancy check; NPC routines retain their occupancy checks.
- Regression checks cover the complete open-enter-close-open-exit-close sequence through interaction prompts for all seven building doors, along with inward swing and closing from inside.

## Play

Download **FarFromHome-v1.3.1-Windows-x64.zip**, extract it completely, and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required. Read README.md for controls and testing mode. Source, asset credit records, build information and SHA256 checksums accompany this release.

All v1.3.0 road, trunk-pickup, hotel-window and coffin-scare changes are included. The in-game Check for Updates feature supports this preview. Existing achievements persist; new journeys reset gameplay progress. This remains a development preview.
