# Far From Home v1.6.0 - Remember the Road

Playable Windows x64 survival-horror preview, built with Godot 4.7.2.

## Changes since v1.5.0

- Added a three-slot SAVE / LOAD screen to the pause menu, with LOAD JOURNEY on the title and death screens. Slots show location, health and timestamp. Supports mouse, keyboard and controller navigation.
- Saves preserve player position (including underground rooms), health, flashlight, equipment and ammunition, quest and journal progress, searched supplies, locks and doors, NPCs, enemies and scripted events.
- Overwriting a save or loading over a paused journey requires confirmation. Each overwritten slot keeps its previous verified save as a backup; damaged primary saves can recover that backup. Invalid or incompatible saves leave the current journey intact. Saves are local to the Windows user, outside the install folder.
- Saving becomes available after collecting the opening backpack. Testing-mode equipment and incomplete opening/scare sequences cannot be saved into a normal journey.
- Fixed the chapel cellar key pickup inside the mausoleum: its interaction target now follows the visible model after shelf dressing. Loading an existing save also repairs the old misplaced target, so the chapel can be unlocked without starting over.
- The death screen now offers loading a saved journey, and returning to the title menu no longer resumes a dead player.

## Play

Download **FarFromHome-v1.6.0-Windows-x64.zip**, extract it completely, and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

Use **Esc > SAVE / LOAD** to save. Load from the title menu or death screen (**L** on keyboard, **Y/Triangle** on supported controllers). The included README explains controls and save restrictions.

This is a development preview. Asset credits, engine licenses, build information and SHA256 checksums accompany the download. The in-game update checker supports this release.
