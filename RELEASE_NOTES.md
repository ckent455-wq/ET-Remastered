# Far From Home v1.9.0 - Relentless

A playable Windows x64 survival-horror preview, exported with the Godot 4.7.2 release template.

## Changes since v1.8.0

- Monsters retain pursuit after spotting the player instead of forgetting them after a short timeout. They can force unlocked town, chapel and mausoleum doors, follow the Victorian staircase and use opened basement passages. Locked progression routes and untriggered reveals stay protected. Pursuit survives saving and loading.
- Stronger combat: ordinary creatures have 132 health, mummies 144 and the cemetery reaper 180. Headshots deal 1.5x damage. Stagger requires accumulated impact and has a recovery resistance period; ordinary hits no longer automatically cancel attacks. Monsters hit harder.
- Shotgun pellets are processed as one impact per creature per blast. Damage is full through five meters and falls to 25% at fifteen meters. The rifle remains more powerful than the pistol.
- Earlier enemy-health values in compatible saves scale proportionally to the new maximum, preserving wounds and deaths.
- Reworked the Victorian cellar using PSX Modular House Interior Pack assets: brick bays and an arch, concrete ceiling, utility shelving, pallets and abandoned laundry/storage clutter. Corrected foundation corners and brick tiling, removed a clipping decorative shovel, and moved the collectible shovel against the rear wall beside the pallets.
- Corrected cellar atmosphere so outdoor fog does not wash out its interior lighting.
- Cleaner controls screen with grouped actions, aligned bindings and input-aware controller labels.
- Starts in a resizable window with minimize and maximize controls. F11 or Alt+Enter toggles fullscreen.

## Play

Download **FarFromHome-v1.9.0-Windows-x64.zip**, extract the entire archive and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

Testing mode is OFF by default. F10 enables unlimited supplies and health for exploration; leave it off when judging combat difficulty.

Includes player instructions, asset and engine credits, source commit information and SHA256 checksums.
