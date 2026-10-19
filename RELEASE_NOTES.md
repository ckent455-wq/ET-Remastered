# Far From Home v1.1.0 - Fuses and Forest Fears

A playable Windows survival-horror preview, built with Godot 4.7.2.

## New since v1.0

- Unarmed combat uses the supplied PSX arms and alternating punches. Fists start hidden: press 0 / R3 while unarmed to raise or lower them. If holding a gun, first press holsters it. Fire / RT punches only with fists raised.
- The Wrapper replaces the upstairs Victorian house monster, with another encounter in the house basement. Each stays on its own floor and remains dead until a new journey.
- The Straw Reaper emerges from cover when you approach the forest boundary behind the cemetery. It navigates around trees, uses corrected idle/walk/attack/fall clips, and keeps its feet grounded.
- Shooting now uses animated head, torso and limb hitboxes rather than the movement capsule. Aimed head shots register across all three enemy rigs, while solid cover still blocks bullets.
- Fourteen native retro prop models replace placeholder clutter across the buildings, including TVs, lockers, clocks, tables, kitchen items and tools. Living-room groups have more clearance, and the enlarged oven cooking surface aligns with its counters.
- The alley workshop terminal uses the downloaded high-voltage cabinet. Find the one-slot cartridge fuse in the general-store drawer, open the cabinet, install the fuse in its interior holder, then flip the switch. Fuse installation starts the monster walking from its existing Main Street spawn; the switch restores power. The seated fuse glows green only when powered.

## Play

Download **FarFromHome-v1.1.0-Windows-x64.zip**, extract the complete ZIP, and run **FarFromHome.exe**. Keep the EXE, PCK and bundled DLLs together. Godot is not required. Player instructions, asset credits, licenses and build information are included, with SHA256SUMS.txt for download verification.

Keyboard: WASD move, mouse look, Space jump, Ctrl crouch, E interact, F flashlight, 0 holster / toggle fists, left mouse fire / punch, I backpack, Tab journal/map, Escape pause. Controller mappings are shown in Controls.

This remains an early preview. Each new journey resets progress; achievements persist. Windows x64 uses ANGLE/Direct3D11 compatibility rendering with a 60 FPS cap and PS2-style presentation. First-time shader preparation may delay startup.
