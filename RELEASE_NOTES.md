# Far From Home v2.2.0 - Pockets of Blackwood

Windows x64 playable release.

- Downed enemies can be searched once per body, including after revival and save/load. Some carry small ammo finds; former townspeople carry personal notes recorded in the journal. Dev mode permits searches with full ammunition.
- Each gun has its own downloaded firing and reload sounds. Reload recordings play at natural speed, with matching reload timing.
- Removed the pistol suppressor and added a faster 0.22-second firing interval with held fire.
- Stronger weapon-specific monster flinches, directional impact bursts and collision-aware rifle/shotgun knockback. Shotgun reactions weaken with distance.
- Added surface checks for fallen mummy bodies on stairs.
- Shorter top dialogue panel and lower question menu keep NPC faces visible.
- Removed the chapel basement Hollow encounter while preserving equipment, story interactions and older-save support.
- Smoothed forest banks into the roadside and restored the close road boundary behind the car near the roadside rock. Bullets ignore that boundary to prevent floating impact marks.

## Play

Download FarFromHome-v2.2.0-Windows-x64.zip, extract all files, and run FarFromHome.exe. Keep the EXE and PCK together. Godot is not required.

Press F10 for dev mode, 1/2/3 to equip weapons, R to test reloads, and E while aiming at a downed body to search. Personal notes open in the journal; Tab closes it.

The source ZIP matches the release commit. SHA256SUMS.txt covers the downloadable build and source archives.

## Validation

Automated checks cover corpse loot, note journals, revival and save/load deduplication, dev-mode searches, combat balance, stair corpse support, physical shotgun impact, chapel encounter removal, road collision and bullet clearance, conversation controls, and save/load recovery. Terrain appearance still benefits from player review; no claim of a complete playthrough is made.
