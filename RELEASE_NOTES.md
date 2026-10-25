# Far From Home v2.2.1 - Door Closing Fix

Windows x64 release build exported with Godot 4.7.2 using the release template, not debug.

- Doors close fully, including collision, when an NPC is standing in the doorway.
- NPCs cannot immediately reopen a door you just closed while you remain nearby. Their normal door routines resume after you leave the doorway area.
- You can still reopen the door yourself. Monster pounding and forced entry continue to work.
- Includes all v2.2.0 features and weapon audio changes.

## Play

Download **FarFromHome-v2.2.1-Windows-x64.zip**, extract all files and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

Includes controls, asset and engine licenses, source commit and checksums. Source code is available in the repository and the separate source archive.

## Validation

Checked NPC doorway overlap and closure, NPC reopening prevention, player reopening, monster forced entry, and full enter/close/exit/close cycles across building doors.
