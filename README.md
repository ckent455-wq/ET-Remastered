# Far From Home — first-person edition

Open project.godot in Godot 4.5 and press F5.

For the playable Windows build, download the ZIP from [GitHub Releases](https://github.com/ckent455-wq/ET-Remastered/releases). Extract it and run FarFromHome.exe. See [PLAYING.md](PLAYING.md) for controls and the opening scenario.

To build Windows, install Godot 4.5.1 and its matching export templates, create builds/windows, and run `godot --headless --path . --export-release Windows builds/windows/FarFromHome.exe`. Then run `python tools/package_windows.py` to create the ZIP and SHA256SUMS.txt in dist. Exported files stay out of Git; playable builds are attached to GitHub releases.

After the engine splash, a short presentation reads "Traingle Studios Presents..." before the game title menu. Enter, Space, or Escape skips the presentation to the menu.

The Far From Home title screen now presents Blackwood as survival horror: a live roadside view, weathered cream lettering, muted rust accents, scanlines, and the Population 3 sign. Enter Blackwood starts a new game; Controls shows the key guide; Quit closes the game. Enter also starts, and M toggles sound. The title camera never changes the player's starting position. The title and pause/end menus no longer use alien or spaceship story text.

Title atmosphere: soft distant lightning appears at irregular 12–21 second intervals after an initial 4–7 second wait. A gentle 7.5-second thunder roll follows each flash by 1.5–2.9 seconds. M mutes the thunder with the other sounds; flashes and pending thunder stop when gameplay starts.

On Windows, this project uses the ANGLE/Direct3D11 compatibility driver and caps rendering at 60 FPS. A native stack sample of a frozen game on this computer showed the main thread spinning inside Intel's `ig11icd64.dll` OpenGL driver. ANGLE avoids that OpenGL driver path while keeping the compatibility renderer and the PS2-style visuals.

After a car accident on Old Mill Road outside Blackwood, you must reach town, search for supplies and weapons, and repair the emergency radio to call for rescue. You start beside the wreck with a flashlight and no guns or ammunition. The damaged hatchback comes from the downloaded FreeCarPack.blend.

A first-person survival horror game with a PS2-inspired 640 x 400 image, nearest-filtered ground texture, low-poly trees, blue-green distance fog, and simple moonlight and flashlight lighting.

## Controls
- Enter: begin / resume / restart
- Mouse: look
- WASD or arrow keys: move
- Shift: sprint (uses stamina)
- Left mouse: fire; right mouse: aim
- 1 / 2 / 3: equip a discovered pistol, rifle, or shotgun; undiscovered weapons stay unavailable
- R: reload; 0: holster (restores the flashlight hand)
- F: flashlight
- E: search/open/close drawers and cabinets, or interact with the note, panel, receiver, or door under the crosshair
- Tab: open / close inventory, objectives, journal, and town map
- Left / right (or A / D) in journal: change pages
- H: use a first-aid kit (+45 vitality, saved if vitality is full)
- Q: use a spare flashlight battery (saved if already charged)
- Hold E near the repaired receiver inside the radio station for four seconds: call for rescue
- E near a townsperson: talk; E / Enter / Escape ends the conversation
- Escape: pause and release the mouse
- M: mute / unmute all game audio

Follow Old Mill Road north from the accident scene into Blackwood. The first objective guides you into town; later markers guide radio repairs. Inspect the wreck with E for context. Find the pistol on the ranger office's front crate, the rifle on the workshop bench, and the shotgun on the millkeeper's desk. Guns and their ammunition are only awarded once per journey when picked up; a new journey removes ownership and restores the world pickups. The alien pulse, glowing landing pad, rescue beam, and return-to-clearing ending have been removed.

## Abandoned town

An additional enterable chapel stands on the west side at the north end of Main Street. It is an original Holy Trinity, Weston-inspired stone church with twin spires, pointed arches, pews, an altar, and a walkable center aisle. It is marked on the journal map. See MAIN_STREET.md for references.


Version 0.2.0 rebuilds Blackwood around a Weston, Missouri-inspired Main Street, with close brick storefronts, a taller hotel, upper windows, awnings, sidewalks, angled parking, boarded shops, and abandoned cars. The downloaded low-poly road kit supplies asphalt geometry and lane markings on the approach and Main Street. See [MAIN_STREET.md](MAIN_STREET.md) for the reference and implementation details.

Six furnished buildings can be entered: ranger office, clinic, general store, mill workshop, millkeeper's house, and a locked radio station. Doors swing open and closed with E; a building door stays open whenever the player is inside that building or standing in its entrance. Step outside to close it. Twelve searchable drawers and cabinets contain the quest items, three first-aid kits, and six flashlight batteries; a couple of containers are empty. Five readable notes are retained in the journal; the second journal page is the town map.

Quest progression:
1. Search the ranger's desk drawer for the radio-station key.
2. Search the drawer beneath the general store's back counter for the fuse.
3. Install it at the workshop panel outside, beside its entrance.
4. Search the powered workshop's signal-coil cabinet.
5. Unlock the radio station and repair its receiver with the signal coil.
6. Stay near the repaired receiver and hold E to call emergency services.

## Townspeople
Three friendly NPCs use the newly downloaded Base Humanoid Mesh: Elias the ranger outside his office, Mara the nurse in the clinic, and Owen the mechanic in the workshop. They have muted clothing variants, skinned patrol animations, collision, and turn toward nearby players. E opens a conversation with useful, quest-aware hints. Conversations pause gameplay and ambience; E / Enter / Escape / Tab closes them.

The source humanoid has 402 triangles. Each variant keeps that count and a 256-pixel version of its supplied UV atlas. Exact source paths are stored in assets/npcs/manifest.json.

The flashlight slowly drains during play. Spare batteries refill it; the powered workshop panel can also recharge it. Drones and their audio are disabled for now. The first-person camera stays at a fixed eye height without head bob. The journal pauses movement and ambient audio. Starting a new journey resets doors, supplies, notes, inventory, workshop power, radio calibration, and flashlight charge.

## Detailed interiors and searching
Eight local model types appear as 74 reused instances: wooden doors, bookshelves, books, floor lamps, curtains, cardboard packing boxes, a teapot, and a sink. Converted meshes contain 348–1,782 triangles and diffuse textures are capped at 256 pixels. Simple vertex lighting, small textures, the original render resolution, and fog preserve the PS2-inspired appearance. Buildings also have painted wall panels, wood trim, rafters, window frames, porch posts, drainpipes, room-specific posters, improved chairs and beds, and paper clutter.

Aim at a drawer front or cabinet and press E. The drawer slides or the cabinet doors swing outward into the room; the first search adds its contents to the pack. E closes it, and reopening a searched container never awards more loot. Prompts identify searched storage; the journal shows the number searched. The coil cabinet stays locked until workshop power is restored. Storage movement and sound pause with the journal or a conversation. All twelve containers and their concealed contents reset for a new journey.

## Files
- first_person.gd: 3D world, crash spawn, first-person controller, and radio rescue
- crash_site.gd: downloaded damaged hatchback, skid marks, debris, headlight, and steam
- weapons.gd: discoverable world weapons, owned inventory, firing, aiming, reloads, and targets
- tools/prepare_crash_car.py: export the downloaded hatchback with a compressed front end
- assets/vehicles/manifest.json: exact source model and geometry budget
- smoke_test_crash_start.gd: real walk from crash to town, unarmed inventory, E pickup, duplication prevention, and reset
- town.gd: town buildings, furniture, doors, raycast interactions, inventory, readable notes, and quest progression
- interiors.gd: local furniture/clutter models, architectural detail, and twelve animated searchable containers
- townspeople.gd: three friendly humanoid NPCs, idle behavior, and quest-aware conversations
- tools/prepare_npc_assets.py: export the local humanoid with lowered arms and three clothing-atlas variants
- assets/npcs/manifest.json: humanoid source path and geometry/texture budgets
- tools/prepare_interior_assets.py: export reduced copies of local models and packed textures without modifying the original files
- assets/interiors/manifest.json: exact source paths, mesh triangle counts, dimensions, and texture budget
- tools/generate_storage_audio.py: create the drawer/cabinet slide-and-clunk cue
- forest.gd: asset placement, clear trails, collision, and shared PS2-style foliage meshes
- tools/prepare_forest_assets.py: Blender conversion of local assets into game-ready GLBs and 256-pixel textures
- tools/prepare_town_assets.py: prepare six local building textures at 256 pixels
- tools/generate_town_audio.py: generate pickup, power-restoration, and calibration cues
- assets/forest/manifest.json: local source folders and exported mesh triangle counts
- hud.gd: interface and console-style overlay
- soundscape.gd: footsteps, flashlight click, forest ambience, and wildlife scheduling
- tools/generate_audio.py: reproduce the original synthesized effects (Python standard library only)
- main.tscn: main scene
- game.gd and top_down_backup.gd: original top-down version retained as reference
- smoke_test_3d.gd: headless checks for the new version
- smoke_test_audio.gd: checks for sound triggers, movement cadence, wildlife, mute, pause/resume, and cleanup
- smoke_test_forest.gd: forest population, textures, foliage materials, collision, and player-capsule clearance along the three trails
- smoke_test_town.gd: full quest, interaction occlusion, locked doors, entrance clearance, indoor reachability, consumables, readable notes, rescue gating, and reset
- smoke_test_storage.gd: local models and retro budgets, concealed loot, drawer/cabinet movement, pause, power lock, exact rewards, duplicate prevention, and reset
- smoke_test_townspeople.gd: studio intro/skip, no ship parts, real NPC targeting/dialogue, dialogue pause, inside/threshold protection for all six building doors, outside closure, and town-only rescue
- tools/smoke_test_rendered.gd: real-renderer stability test covering the title screen, live physics/audio, town, furniture, storage, journal/map, rescue, and restart; use with the Windows display driver, not headless
- tools/sample_frozen_thread.py: read-only Windows native stack sampler; takes a process ID and thread ID and always resumes the sampled thread

## Forest detail
The world contains 180 varied pine trees, 210 shrubs, and 85 rocks. Pine trunks and branches come from the local pine asset; shared crossed foliage cards use its needle atlas. Three local shrub meshes and three faceted rock shapes provide variation. Trees and larger rocks have collision, while the central clearing, pickup sites, and three trails stay clear.

The PS2-inspired treatment uses 256 x 256 diffuse textures, cutout foliage, simple vertex lighting, shared materials and foliage meshes, and distance culling at 64 meters. The existing 640 x 400 display and blue-green fog remain.

## Sound

The downloaded Horror SFX Free pack adds quiet atmospheric sound, contextual building creaks and distant calls, an arrival bell, frogs, and localized radio static. The static recedes after radio repair, and wind quiets indoors. Distinct recorded on/off clicks, door squeaks, and drawer/cabinet opening and closing sounds replace the earlier interaction cues. Accents have long cooldowns and stop outside gameplay; all new audio follows the existing mute control.

The flashlight uses a local switch-click recording. Five leaf-crunch footstep variations follow distance travelled, with louder, quicker steps during sprinting. Wind and rustling leaves loop softly; owl, night-bird, and insect calls play from random nearby locations every 10–24 seconds. Escape pauses the soundscape; M mutes all sound, including effects.
Town doors use a local creak recording positioned at the doorway. Pickups, restored power, and radio calibration have short synthesized cues.
Drawers and cabinets use a short positional slide-and-clunk cue, also controlled by M and pause.

## Local assets
- assets/vehicles/abandoned_*.glb: Classic Car_9, N Van_10, Pick Up_11, Police Car N_4, and N_Muscle Car_10 from the local Downloads/Blend/Blend/FreeCarPack.blend, with original geometry, flat shading, and textures capped at 256 pixels. Parked models are intact and use muted materials; source records and budgets are in assets/vehicles/street-vehicles.json. The original source is unchanged.
- assets/flashlight/flashlight.glb and flashlight_albedo.png: original 530-triangle local Unity flashlight from My project (2)/Assets/Flashlight/Misc/Flashlight.FBX, centered to 34 cm with a 256-pixel copy of the supplied albedo and matte PS2-style materials. Source records are in assets/flashlight/source.json; originals are unchanged.
- assets/atmosphere/overcast_sky.png: reduced and desaturated copy of Downloads/lonely_road_afternoon_puresky_8k.exr. A procedural cloud ceiling overlays it in cloud_sky.gdshader. Two original low-poly hill rings use the existing ground texture. See MAIN_STREET.md for details.
- assets/audio/horror/*.wav: selected recordings from the user-provided Downloads/Horror SFX Free pack, converted to mono 22050 Hz with controlled peaks and edge fades/crossfades. Original filenames and hashes are retained in assets/audio/horror/sources.json. No author or license document was included in the downloaded archive.
- assets/roads/road_straight.glb and associated textures: user-provided Downloads/4pc_lowpoly_roads_glb. Original asphalt geometry and UVs are retained with matte PS2-style materials. Raised concrete and generated collision are omitted. See assets/roads/sources.json. No author or license document was included in the downloaded archive.
- assets/forest.jpg: copied from Downloads/forrest_ground_01_2k.blend/textures/forrest_ground_01_diff_2k.jpg. No license accompanied the source folder; verify it before distributing.
- assets/font.ttf: Text Me One from Downloads/text_me_one, SIL Open Font License (assets/OFL.txt).
- assets/audio/flashlight.wav: local recording `830459__shaunhillyard__flashlight-click-on.wav` from Downloads; credited to shaunhillyard by the source filename. No license accompanied the local file.
- assets/audio/door.wav: local recording `460542__coosemek__door-creak.wav` from Downloads; credited to coosemek by the source filename. No license accompanied the local file.
- assets/audio/pickup.wav, power.wav, radio.wav: original synthesized cues generated by tools/generate_town_audio.py.
- assets/audio/drawer.wav: original synthesized slide-and-clunk cue generated by tools/generate_storage_audio.py.
- assets/interiors/*.glb: reduced copies of local shelf, lamp, books, curtain, and wooden-door models in Documents/assets/models, plus the cardboard box, TeapotSilver001, and Sink003 models in Downloads. Source paths and budgets are recorded in assets/interiors/manifest.json. Packed diffuse textures were extracted into 256-pixel copies; original files were not changed. Searchable cabinetry and architectural trim are built by interiors.gd using local material textures.
- assets/npcs/*.glb and *_atlas.png: copies of Downloads/Base Humanoid Mesh/Base Humanoid Mesh/Humanoid.blend and NonOverlapping.png, with relaxed arm poses and muted clothing colors. Original source files were not modified.
- assets/vehicles/crashed_hatchback.glb: a 2,810-triangle damaged copy of Hatchback Car_15 from Downloads/Blend/Blend/FreeCarPack.blend, with textures capped at 256 pixels. The source file was not changed; no license file was included in the local download.
- Other assets/audio WAVs are original synthesized effects generated by tools/generate_audio.py.
- assets/forest/pine_b.glb and pine_c.glb: reduced trunk/branch geometry from Downloads/pine_tree_01_1k.blend/pine_tree_01_1k.blend; original bark, trunk, and twig textures reduced to 256 pixels. The crown meshes are generated using the local twig atlas.
- assets/forest/bush_e.glb, bush_f.glb, bush_g.glb: reduced LOD3 shrub meshes from Downloads/othonna_cerarioides_2k.blend/othonna_cerarioides_2k.blend, with its diffuse and alpha textures.
- assets/forest/rock_*.glb: generated faceted rock shapes using the local Downloads/rock_surface_1k.blend/textures/rock_surface_diff_1k.jpg texture.
- assets/forest/ground_ps2.png: reduced copy of the original local forest-ground texture.
- Original .blend files and source texture files were not changed. No license files accompanied these local forest asset folders.
- assets/town/*.png: local weathered wood, brick, plaster, flooring, slate roof, and rusty metal diffuse textures reduced to 256 pixels. Exact source paths are recorded in assets/town/sources.json. Building and furniture geometry is generated by town.gd; no original source files were modified.

Validation: headless Godot scene load and checks for the unarmed crash opening, removed alien mechanics, radio rescue, defeat, and restart.
Audio checks: flashlight input, walking/running, blocked/airborne silence, animal timing and placement, mute, pause/resume, restart, and audio bus cleanup.
Forest checks: population counts, original textures retained at 256 pixels, foliage cutouts, trunk collision, and 123 player-capsule route samples. Rendered previews: preview-forest-0.png and preview-forest-1.png.
Town checks: six buildings, real E targeting, interaction blocked by walls, locked station door, 78 player-capsule entrance samples, reachable/visible indoor items and notes, key/fuse/coil progression, medical kits and batteries, radio-gated rescue, and full quest reset. Rendered town/interior/journal/map previews: preview-town-0.png through preview-town-4.png.
Storage checks: twelve containers, eight local model types, all imported meshes and textures within retro budgets, loot concealed until search, animated drawers and cabinet doors, pause/resume, powered coil lock, exact supply counts, repeated/rapid search duplication prevention, and new-journey reset. Interior previews: preview-interior-0.png through preview-interior-4.png.
New checks: presentation auto-advance/skip, no obsolete collection objective, three NPCs and real E conversations, pause behavior, inside/outside door rules for both building orientations, outward cabinet-panel positions, and rescue with the town quest alone. Presentation/NPC/dialogue/cabinet/menu previews: preview-townspeople-0.png through preview-townspeople-4.png.


Camera regression: `smoke_test_camera.gd` walks into all 12 containers, opens and closes storage at close range, and checks stationary view stability and eye height while movement is blocked. It also checks that drone entities and drone audio are absent.

Recent town additions: the weathered two-post "Blackwood / Population 3" sign sits fully beside the approach road, with a vegetation clearance around it. Elias patrols outside the ranger office; Mara walks the clinic aisle; Owen walks the workshop floor. The 402-triangle humanoids have skinned walk cycles. NPCs stop within conversation range, collide with solid scenery, and pause in menus and dialogue.

Weapons use the locally downloaded Polyy Guns Pack 2 (CC0; license included in assets/weapons), reduced to 2,200 triangles each with textures capped at 256 pixels. Firing uses collision rays, ammunition, reloads, muzzle flashes and bounded impact marks; the workshop yard has four metal targets. Shooting an NPC triggers a skinned collapse and death animation; dead NPCs stop moving and talking until a new journey. Gun recoil moves only the weapon model; the camera remains steady. The flashlight hand is hidden with an equipped weapon.

New checks: smoke_test_patrols.gd validates walking, collision bodies, proximity stops, dialogue pauses and reset. smoke_test_weapons.gd validates target hits, ammunition, reload conservation, paused reloads, switching, holstering, arm visibility, menu guards and camera stability. tools/preview_latest.gd captures the sign, each weapon and a walking NPC using the real renderer.

NPC death check: smoke_test_npc_death.gd shoots all three characters using real weapon rays, verifies collapse and persistent settled poses, pause behavior, removed conversation/collision blockers, full quest completion after the deaths, and revival on a new journey. The road sign reads Blackwood / Population 3.
