# Far From Home v2.5.0 - Blackwood Progression and Sebus Hardware

Windows x64 release build exported with the Godot 4.7.2 release template.

- Sebus Hardware now has an inward-opening door and a packed interior of boxes, furniture and scrap. Entry is blocked across the doorway and building footprint. After opening, the player remarks: "I can't get in, it's too cluttered."
- Animated zombie models replace the chapel patrols, workshop creature, cemetery creature and cemetery shadow. Other monster encounters retain their existing models.
- A bottom-left objective reminder checks off completed tasks before showing the next step. Removed the redundant return-to-car instruction box.
- Refined the opening-to-workshop route and John/Aubrey conversations. Workshop fuse directions consistently point to the general store.
- The workshop creature approaches immediately when power is switched on, without an objective announcing the attack.
- Items require the backpack, including after waking in the clinic. Rejected pickups remain available to collect later.
- Added a collectible workshop-table knife using the same quick stabbing attack as the hotel knife. Updated workshop and ranger-station layouts, including the shotgun case and pickup positions.
- Preserved earlier save support, including saves made before the new enemy models and Sebus doorway.

## Play

Download **FarFromHome-v2.5.0-Windows-x64.zip**, extract all files, and run **FarFromHome.exe**. Keep the EXE and PCK together. Godot is not required.

## Validation

Door swing clearance, actual player movement against the shop entrance (walking, strafing, crouching and jumping), dialogue timing, save compatibility, objective progression, animated enemy hitboxes and knife pickups. Source commit and SHA-256 checksums accompany the release.

---

# Far From Home v2.4.0 - Hotel Knife and Blackwood Update

Windows x64 release build exported with the Godot 4.7.2 release template.

- Optional kitchen knife collected physically from Saint George Hotel. Uses two backpack slots, supports rotation and controller weapon cycling, and costs 14 stamina per quick forward stab.
- Improved close-range knife hit detection for hunched creatures. Each stab deals one impact; solid walls and closed doors block attacks. The held flashlight is hidden while the knife is equipped.
- John uses the supplied death recording for knife and gun kills. Its initial quiet lead-in is trimmed, and the sound is preloaded to begin with the killing hit.
- Updated workshop, hotel kitchen and clinic furniture layouts, with editable Godot scenes included. Hotel pickup positions and collisions follow the saved layout; removed kitchen furniture stays removed.
- NPC dialogue emphasizes Blackwood's failing environment and uncertain symptoms. Conversations respond to workshop power, encounters, tunnel discoveries and the chapel signal.
- Workshop power brings local machinery and interference ambience, with changes after the chapel signal is silenced.
- Improved collapse warning at running speed and corrected the red damage flash after leaving Aubrey's bed.
- Flashlight stays hidden during the car opening and until collected from the trunk.
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
