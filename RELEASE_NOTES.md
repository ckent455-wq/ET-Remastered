# Far From Home v2.3.0 - Creature Combat and Crash-Site Update

Windows x64 release build exported with Godot 4.7.2 using the release template, not debug.

- Tougher creatures with faster sustained pursuit, shorter attack windups and less downtime between attacks. Late impacts cannot interrupt an already committed swing.
- Torso shots deal reduced damage, headshots reward careful aim, and targeted leg shots briefly slow pursuers. Wounded creatures alternate short bursts with recovery periods.
- Attacks include a short collision-aware forward step. Close shotgun impacts still provide knockback. Enemy health bars are removed for all monsters.
- Pat has discovery-based cemetery and mausoleum conversations, a shorter key handoff, and optional responses to the shadow figure and disturbed grave. Removed the grandpappy wording.
- New custom teal backpack in the wreck's trunk, with PS2-style rendering, corrected pickup bounds and editable Blender source included.
- Improved hatch lining, fixed rear quarter windows and corrected support-strut lengths. The approved hatch angle is retained.
- Removed the optional detour document from the trunk. Existing save compatibility is retained.
- Includes the v2.2.1 NPC doorway closing fix and earlier weapon audio changes.

## Play

Download **FarFromHome-v2.3.0-Windows-x64.zip**, extract all files, and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

## Validation

Automated combat, animated hitbox, leg-injury, pursuit, save/load, dialogue and car pickup checks. Source commit and SHA-256 checksums are included with the playable build.

## Known issue under investigation

A player reported becoming stuck near a rock during the opening. The exact obstruction has not been identified or reproduced; this release does not claim to fix it.
