# Far From Home v2.0.1 - Back on Your Feet

Stable Windows x64 release build exported with Godot 4.7.2 using the release template, not the debug template.

## Fixes since v2.0.0

- Removed the obsolete backpack requirement from world interactions. Players can leave the pharmacy, open and close unlocked doors, talk to survivors, read notes, search storage and collect items before retrieving gear. Actual key locks and inventory capacity rules remain active.
- Ada's letter can also be collected without the backpack requirement blocking the interaction. Missing gear stays in the car and the return-to-trunk objective remains until recovered.
- Added the player's line, "Oh fuck, im light headed...", when the screen starts dimming. It displays for two seconds, then clears.
- Extended the fully black unconscious pause to 5.5 seconds. During the last three seconds, bottom-center dots count down from three to two to one before the blinking pharmacy wake-up.
- Caption and dots render above the blackout without bringing up a restart screen. Aubrey's bedside introduction and the continuous injury border remain intact.

## Play

Download **FarFromHome-v2.0.1-Windows-x64.zip**, extract the entire archive and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

Existing v2.0.0 saves retain progress. If you were stuck in the pharmacy without your gear, load that save and the doors and interactions now work. Start a new journey to see the complete revised blackout sequence. Keep Testing Mode OFF when testing the opening.

Includes player instructions, release notes, credits, engine and supplied asset license records, source commit information and SHA256 checksums. The separate source ZIP matches the playable build.
