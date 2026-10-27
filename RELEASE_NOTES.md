# Far From Home v2.4.0 - Hotel Knife and Blackwood Update

Windows x64 release build exported with the Godot 4.7.2 release template.

- Optional kitchen knife collected physically from Saint George Hotel. Uses two backpack slots, supports rotation and controller weapon cycling, and costs 14 stamina per quick forward stab.
- Improved close-range knife hit detection for hunched creatures. Each stab deals one impact; solid walls and closed doors block attacks. The held flashlight is hidden while the knife is equipped.
- John uses the supplied death recording for knife and gun kills. Its initial quiet lead-in is trimmed, and the sound is preloaded to begin with the killing hit.
- Updated workshop, hotel kitchen and clinic furniture layouts, with editable Godot scenes included. Hotel pickup positions and collisions follow the saved layout; removed kitchen furniture stays removed.
- NPC dialogue emphasizes Blackwood's failing environment and uncertain symptoms. Conversations respond to workshop power, encounters, tunnel discoveries and the chapel signal.
- Workshop power brings local machinery and interference ambience, with changes after the chapel signal is silenced.
- Improved collapse warning at running speed and corrected the red damage flash after leaving Aubrey's bed.
- Earlier saves without the optional knife remain supported. No hand or sleeve is attached to the knife.

## Play

Download **FarFromHome-v2.4.0-Windows-x64.zip**, extract all files, and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

Press **E** to collect the hotel knife, **4** to equip it, and the attack button to stab. It can also be equipped through the backpack or controller weapon cycling.

## Validation

Knife pickup, capacity, stamina, forward animation, damage, cover, controller cycling, save/load, John death audio, gun hitboxes, room layouts and town progression checks. Source commit and SHA-256 checksums accompany the release.

## Known issue

The previously reported opening obstruction near a rock remains unreproduced.

---

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
