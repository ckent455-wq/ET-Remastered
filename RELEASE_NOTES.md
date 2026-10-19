# Far From Home v1.2.0 - Beneath Blackwood

A playable Windows survival-horror preview, built with Godot 4.7.2.

## New since v1.1.0

- Three mummy-like Wrapper encounters along the mausoleum route: one near the tunnel entrance, one midway through the passage, and one concealed behind a storage screen in the open Saint George cellar at the far end. They activate separately, pursue and attack physically, respect walls and each other, and cannot follow you through exit portals. They use animated shooting hitboxes and falling death animations, and reset on a new journey.
- Testing mode can be switched on or off with **F10** or the pause-menu button. It skips the opening and grants all weapons, keys, quest items and tools, with unlimited health, ammunition, stamina and flashlight charge. Testing inventory uses a readable equipment list with capacity limits disabled. Turning it off restores your earlier loadout and normal limits; world events are not rewound. Testing is OFF on a normal launch and after Restart Game.
- **Check for Updates** on the main menu checks the public GitHub releases, including published previews. Download Update verifies the release ZIP's SHA-256 digest. Install & Restart checks the packaged executable and data, backs up the installed files, installs the update and relaunches the game. Failed copying restores the prior files. Update checks support mouse, keyboard and controller navigation.

## Play and update

Download **FarFromHome-v1.2.0-Windows-x64.zip**, extract the complete ZIP into a writable folder, and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required. Instructions, credits, licenses, source-commit information and SHA256SUMS.txt are included.

This is the first release with the in-game updater. Players on older releases need to download and extract this ZIP once; subsequent published builds can be installed from Check for Updates. Installation is supported by the exported Windows game. Running the Godot source project allows update checks and leaves the checkout unchanged. Achievements are kept in the game's user-data folder; a backup of the previous build is retained beside the EXE.

WASD move, mouse look, Space jump, Ctrl crouch, E interact, F flashlight, 0 holster / toggle fists, left mouse fire / punch, V or wheel cycle guns, I inventory, Tab journal/map, Escape pause, F10 testing mode. Controller mappings are in Controls.

This remains an early preview. New journeys reset gameplay progress; achievements persist. Windows x64 uses ANGLE/Direct3D11 compatibility rendering with PS2-style presentation and a 60 FPS cap. First-time shader preparation may delay startup.
