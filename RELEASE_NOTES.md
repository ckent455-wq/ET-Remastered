# Far From Home v0.6.0 - The Blackwood Signal

A playable Windows survival-horror preview with three woodland creatures, a radio-signal mystery, scavenged ammunition and a repaired hilltop chapel.

## Play

Download **FarFromHome-v0.6.0-Windows-x64.zip**, extract the whole folder and run **FarFromHome.exe**. Keep the EXE, PCK and bundled DLLs together. Godot is not required. Player instructions, credits, licenses and build information are included; SHA256SUMS.txt verifies the download.

## New since v0.5.0

- Three animated creatures hide in the chapel woods, emerge from cover, pursue the player around trees and attack. Visible active creatures have health bars. Defeated creatures return to their hiding places after two minutes of active gameplay; menus pause the timer.
- Notes, conversations and journal evidence connect weeks of sleep loss, memory trouble and physical changes to the chapel radio carrier. The creatures are transformed former residents. Repair the station and use its physical BYPASS switch: GREEN reaches county directly; AMBER still routes through the compromised repeater. Both endings remain playable without mandatory document collection.
- The pistol pickup has only three loaded rounds and no spare ammunition. Nine collectible cartons supply separate pistol, rifle and shotgun reserves. Collect with E and reload with R. Ammo collected before finding a weapon is retained; all reserve ammunition must be scavenged.
- The shotgun is in a keyed, opening crate at the back of the ranger office. Find its key lying flat on the hotel bedroom dresser.
- The service rifle is in the locked chapel cellar and deals twice the pistol's damage. Mouse wheel or V cycles owned weapons; 1-3 selects them directly.
- Rebuilt the church with one continuous shell and ceiling, correctly fitted entrance doors, grounded pews and a roof-trimmed bell tower. Removed hillside triangles beneath the wooden floor to eliminate floor z-fighting.
- The cellar uses an existing church door prefab with its correct material on both faces. Opening it takes the player straight downstairs in one interaction. Returning upstairs shuts the door without relocking it.
- Corrected refrigerator orientation and retained the quiet survival HUD, flashlight batteries, environmental audio, abandoned interiors and crow behavior.

## Preview scope

Windows 10/11 x64; ANGLE/Direct3D11 compatibility rendering; 60 FPS cap; PS2-style 640 x 400 presentation. Journey progress resets on a new game; achievements persist. Drones remain disabled. Start unarmed at the crash, scavenge in Blackwood, recover the radio parts and call for rescue.

Validation covers the crash opening, world interactions and reachability, weapons and ammunition, enemy pursuit/attacks/respawn, story and both radio endings, church geometry and floor collision, keyed cellar/lockbox, and standalone Windows build startup.
