# Far From Home v2.0.0 - Voices in Blackwood

Windows x64 release build exported with Godot 4.7.2 using the release template, not the debug template. Published as a stable release.

## Changes since v1.9.0

- New required opening progression: leave the crash and head toward Blackwood. Past the cemetery gate, vision dims, movement staggers, walking and footsteps slow, and the player drops to their knees before blacking out. The collapse takes priority over the tree scare.
- Seamless transition from darkness to blinking eyes in the pharmacy medical bed. Aubrey treats the player's head wound and introduces herself. No restart screen or title card interrupts the rescue; the injury border and bedside camera stay consistent into dialogue.
- Gear can remain in the car. After treatment, a persistent prompt identifies the missing backpack and/or flashlight and directs the player to the trunk. Collecting one updates the prompt. Early pickup does not avoid the rescue; the first spare bandage is available after treatment.
- Aubrey remembers the bedside introduction, including in existing rescue saves. Later conversations show her questions. Rescue state, belongings and journal notes persist through saving and loading.
- Rewritten notes and dialogue trace the outbreak to the station radio speaking by itself. The chapel amplifier spread its voices, driving residents mad, transforming townspeople and waking the dead. Familiar voices persuaded listeners to keep broadcasting.
- New conversation with John about the first broadcast; revised operator log, clinic observations, chapel book, workshop log, Ada's letter, cellar procedure, journal evidence leads and ending. Older collected journal entries refresh when loaded.
- Clear isolation procedure: cut the chapel MAIN ISOLATOR to break the powered return loop, repair the station, select BYPASS GREEN for direct county, and request rescue without sirens.
- Replaced the station placeholder with John's custom vintage radio, finished in Blender and adapted to the game's matte PS2-style materials and texture filtering.
- Downloaded static and distorted voices play from the receiver. Proximity increases volume and intensity. Voices use irregular dropouts, pitch drift and phrase jumps; both layers respect pause and story shutdown.
- Includes v1.9.0's persistent monster pursuit, revised combat balance, Victorian cellar, grouped controls screen and resizable window.

## Play

Download **FarFromHome-v2.0.0-Windows-x64.zip**, extract the entire archive and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

Start a **new journey** to experience the revised opening. Existing saves retain their progress; the rescue will not replay once completed. Testing mode is OFF by default. F10 skips the normal opening and provides exploration supplies; leave it OFF when testing the opening or combat.

Includes player instructions, release notes, credits, engine and supplied asset license records, source commit information and SHA256 checksums. The separate source ZIP contains the matching game source.
