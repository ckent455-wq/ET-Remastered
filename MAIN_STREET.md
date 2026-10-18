# Blackwood Main Street

Blackwood's street is inspired by the storefronts visible in Google Maps Street
View around 410 Main Street, Weston, Missouri (May 2025 imagery), inspected on
October 15, 2026. Reference:
https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=39.4108385,-94.9019948&heading=34.25&pitch=0

The design uses close rows of two-story brick shops, tall upper windows, parapets,
cornices, fabric awnings, a taller cream hotel, sidewalks, historic-style lamps,
and angled parking. It is a fictional adaptation, rather than a surveyed replica.
All building geometry is original and uses the project's existing materials;
Google Maps images are not included as textures or assets.

Abandonment appears through boarded shop windows, torn awnings, faded signs,
weeds, cracked pavement, abandoned cars, closure notices, dim lamps, and fog.
The low-poly geometry and low-resolution materials preserve the PS2 style.

The approach and Main Street now use the user's downloaded
`4pc_lowpoly_roads_glb/road_straight.glb` asphalt mesh, original UVs, yellow dashed
center markings, and white edge markings. Ten scaled pieces share one mesh.
Raised concrete and imported collision are omitted so the existing flat walking
surface, sidewalks, furniture, and door thresholds keep their tested behavior.
Existing cracks, parking stripes, litter, and skid marks sit above the asphalt.

The user's `Horror SFX Free` download supplies a quiet atmospheric bed, occasional
positional creaks and distant calls, an arrival bell from the chapel, and static
at the radio. Indoor wind is quieter; radio static recedes after repair. The pack
also supplies distinct flashlight on/off clicks, a door squeak, drawer and
cabinet opening/closing recordings, and occasional frogs outside. Accents use
cooldowns, stop when gameplay pauses, and reset for a new journey. All new audio
uses the existing M mute control. Selected recordings are converted to small
mono PCM files with controlled peaks and faded edges; the two loops are
crossfaded. Source manifests are beside the imported assets.

The ranger office, pharmacy, general store, hotel rooms, repair workshop, and
radio station remain enterable, with the existing furniture, searchable storage,
weapon pickups, NPCs, and rescue quest. Two additional boarded shops close the
north end of the street. The crash opening remains south of town.

The six alley barriers are fitted to the actual adjacent building edges instead
of using fixed 0.9-metre sections. Each end overlaps its wall by 25 cm, including
the wider gaps beside the sealed shops. Cross rails reinforce the weathered
boards, and continuous collision closes the visible opening. The alley regression
sweeps the real player capsule across 31 points per barrier, including the ends.

Main Street now uses five different vehicles from the local FreeCarPack:
Classic Car_9, N Van_10, Pick Up_11, Police Car N_4, and N_Muscle Car_10.
Each original mesh is centered, flat shaded, and uses its supplied atlas at 256
pixels with muted materials and fitted collision. All parked copies of the
crashed hatchback are removed; that model is used only at the opening accident.
The central road and sidewalks retain clearance. Source records and budgets are
in assets/vehicles/street-vehicles.json.

## Enclosure and drifting fog

Main Street is now 7.6 metres wide, with storefronts brought two metres inward
on each side. Sidewalks, lamps, parking, cars, planters, and Elias's patrol move
with the street. Boarded returns close the gaps between shops. The outer masonry
walls and repeated approach-fence runs have been replaced by a closed forest belt.
Additional local pine and shrub instances enclose the approach; the wreck, sign,
continuous road, and three forest trails retain their walking clearance.

The atmosphere takes its oppressive, obscured sightlines from Silent Hill as a
mood reference. Muted grey-green distance haze hides the far end of the street,
with a shorter flashlight range and subdued ambient/moon lighting. Four CPU
particle emitters share one procedural 64-pixel noise texture and billboard shader,
using 120 slow wisps in total. Particles fade near the eye, fade over their lifetime,
and are clipped out of furnished interiors. Indoor distance fog is reduced so
storage, NPCs, and pickups remain legible. Menus pause the fog animation.

The existing ANGLE compatibility renderer is retained. Godot's reference for
[CPU particles](https://docs.godotengine.org/en/4.5/classes/class_cpuparticles3d.html)
describes the emitter used here; this effect does not require Forward+ volumetric fog.
`smoke_test_fog.gd` checks the particle budget, indoor/outdoor density, camera,
pause/resume, and enclosure. `tools/preview_fog.gd` verifies visible particle
contribution in a real rendered frame and captures approach, street, and interior views.

## Distant hills, clouds, and local flashlight

Two low-poly hill rings frame the horizon beyond the playable area. Their combined
768 triangles use subdued height-based haze and the existing ground texture, with
no movement collision. The cameras can see the backdrop while forest distance
culling remains unchanged. Hill silhouettes remain faintly visible above the
dense street fog.

The hill contours and terrain texture now have stronger separation from the sky.
A lower saddle ahead of Main Street exposes the second ridge from normal eye
level. The forest perimeter rises into wooded ground below the hills.

`forest_boundary.gd` builds a closed twelve-section perimeter around all existing
routes and the town, using five staggered rows with 845 low-poly pine instances,
two overlapping shrub rows, and rising root/bramble banks. Shared MultiMeshes keep
the foliage draw calls bounded. The collision belt overlaps at its corners and
sits within the visible thicket, before the old coordinate limits. The outer rows
extend sixteen metres beyond the first trees. The boundary has no exits.
`smoke_test_forest_boundary.gd` checks 252 perimeter crossings and six real player
capsule sweeps; existing route, entrance and quest tests are retained.

The overcast sky combines a reduced, desaturated 512 x 256 copy of the local
`Downloads/lonely_road_afternoon_puresky_8k.exr` panorama with a static procedural
cloud ceiling. Planar cloud projection avoids polar stretching. The ambient-light
source remains a fixed colour, so the sky does not brighten the horror lighting.
The source panorama is unchanged; its copy and source record are in assets/atmosphere.

The original 530-triangle flashlight was found at
`My project (2)/Assets/Flashlight/Misc/Flashlight.FBX`. Its mesh and supplied albedo
are retained, centered to a 34 cm prop, given flat normals and matte materials,
and reduced to a 256-pixel texture. It replaces the placeholder cylinder. The arm
and hand geometry are removed; only the flashlight appears. F switches the beam
immediately while the model lowers and disappears, or raises back into view,
over 0.3 seconds. Rapid toggles reverse smoothly; menus pause the motion.
Charge, sound, weapon hiding, holstering, and restart behavior
are retained. The source FBX and textures are unchanged. See assets/flashlight/source.json.

`smoke_test_landscape.gd` checks the sky, geometry budget, lack of terrain collision,
and flashlight controls/visibility. `tools/preview_landscape.gd` captures the
clouds, hill silhouettes, flashlight, interiors, and title using the real renderer.

Validation includes all six entrances, 309 road/sidewalk collision samples,
all twelve storage interactions, NPC patrols and deaths, the crash-to-town walk,
weapon collection, the complete rescue quest, and real-renderer previews.


## Chapel and continuous town entry

The chapel stands on a wooded hill northeast of Main Street, centered
at (29, 9, -141). The west shop is restored. Chapel Road begins at the north
end of Main Street and bends uphill through the forest to a level forecourt.
Its sloped collision supports the full nine metre climb and return journey. Its stonework, twin spires, pointed arches, and rose window are
inspired by Holy Trinity Catholic Church in Weston, Missouri, using the parish's
official exterior and interior photos as reference:
https://holytrinitycatholic.org/photoalbums/holy-trinity-church
https://holytrinitycatholic.org/parish-history

This is an original, fictional PS2-style adaptation. No parish photographs are
included as textures. It has a procedural 128-pixel stone texture, local roof and
wood materials, a recessed open entrance, eight pews, an altar, a wooden cross,
and dim candle lighting. The center aisle is walkable. Indoor fog and sound apply
inside, the chapel is marked on the journal map, and the forest boundary curves
around its footprint. The six existing quest buildings and progression are intact.

The flare joining Old Mill Road to Main Street had its triangle winding reversed,
so its top could be culled. It now faces upward and overlaps the two asphalt
sections by eight centimetres, with connecting edge lines and a faded center dash.
`smoke_test_church_street.gd` checks five unique parked models, the road join,
51 chapel entrance/aisle capsule samples, and church ambience. Rendered previews
are produced by tools/preview_church_street.gd.

The enclosed forest boundary follows the hill route, with raised tree roots and
continuous tall collision through the thicket. The journal map includes Chapel Road
and the relocated chapel. Two hillside mist emitters bring the bounded fog total
to 164 particles; church interiors still exclude drifting mist.
`smoke_test_chapel_hill.gd` walks the full route up and down with normal player
physics, including the chapel aisle. `tools/preview_chapel_hill.gd` captures the climb.

Chapel Road now ends eight metres before the entrance at (29, 9, -126),
with a narrow bent stone footpath across a grassy forecourt to the doors.
The paired wooden doors start closed with solid entrance collision. E opens
both leaves outward; closing requires the player to stand clear and outside.
Restart restores the closed state.

The world HUD retains health, a flashlight charge bar, recovering stamina,
and equipped weapon ammunition. Location, objective, radio status and supplies
are in the journal; feedback messages expire after six seconds. The flashlight
starts at 45% and uses 0.5% per second while on (90 seconds initially, 200 seconds
for a new cell). Turning it off or opening a menu stops drain. At zero it shuts
off and cannot restart until a collected battery is fitted with Q. Batteries
remain in searchable town storage. The workshop panel no longer recharges it.
`smoke_test_chapel_survival.gd` checks physical doors, E targeting, outward opening,
safe closing, battery exhaustion, collection/consumption, and reset behavior.


## Chapel cellar quest

Two modest stone planting beds reuse the downloaded bush models beside the
entrance. Warm lanterns and a weathered bench frame the porch, with the path
and church doorway kept clear.

Searching the powered workshop signal-coil cabinet now also gives the chapel
cellar key. The locked wooden door at the chapel's back right first unlocks
with E, then E descends to a furnished cellar interior through a short fade.
The cellar is a separate enclosed interior below the chapel, with stone walls,
wooden beams, local shelf/books/crate assets, a workbench, a spare flashlight
battery and a visible return stair flight. E at its upper door returns upstairs.
Negative-height player movement is allowed within this enclosed cellar only.
Indoor fog and creak ambience follow the cellar.

The workbench holds a spare emergency-radio tuning unit. The radio receiver
requires BOTH this unit and the workshop signal coil; a failed repair keeps
any already collected parts. A successful repair consumes both. Rescue remains
gated on the repaired radio and proximity to its receiver. The field journal,
maintenance log, ranger log and NPC hints describe the extra step. New journeys
relock the cellar and restore its key, pickups and entrance decorations.

`smoke_test_church_quest.gd` walks the nave, approaches the locked door, checks
power/key gating, uses actual E targeting to unlock/enter/collect/leave, walks
the cellar and return stairs, finishes the two-part rescue quest and checks reset.
`tools/preview_church_cellar.gd` renders entrance planting, the locked door,
cellar workbench, stairs and revised journal.


## Chapel Road cleanup

The uphill road now rounds the original route corners with sampled quadratic
curves. Asphalt sections share cross-sections instead of overlapping separate
straight pieces, so bends have continuous edges and consistent texture scale.
A half-metre gravel shoulder blends into the hillside. Restrained worn edge
paint replaces the segmented box markings and short center dashes.

The upper approach gains height earlier and levels into the forecourt, keeping
the tightest bend walkable across the lane. Terrain follows the curved route
at one-metre resolution, with corrected upward-facing triangles. The forecourt
footpath is a continuous gentle curve; asphalt still stops eight metres before
the chapel doors. The journal map follows the sampled road curve.

`smoke_test_chapel_road.gd` checks identical adjacent mesh edges, upward-facing
triangles and normal player walks up/down both sides of the lane. The existing
full hill/chapel walk also passes. `tools/preview_chapel_road.gd` renders road
entry, bends and the chapel approach (the overview lowers fog only for inspection).


## Cellar darkness and police lightbar

The cellar now excludes the moon and title lightning, uses a dark camera
Environment and minimal world ambient while inside, and restores surface
lighting on exit. Compatibility rendering needs explicit directional visibility
control as well as light layers. The workbench lamp is removed; a faint short-range
stair light remains. The radio unit and spare battery have non-emissive materials,
and cellar labels are shaded. Cellar stone uses pixel lighting so the flashlight
beam reveals walls and the workbench without illuminating the whole room.

The parked police model's existing roof bar receives fitted emissive red/blue
lenses, two short-range shadowless colored lights, and small soft lens halos.
Intensity varies gently over several seconds instead of strobing. Asphalt uses
pixel lighting to show the local color spill. Exterior ambience and sound remain
unchanged. `smoke_test_atmospheric_lighting.gd` checks darkness isolation,
upstairs restoration and bounded police lights. The lighting preview verifies
that the cellar view is dark with the flashlight off and readable with it on.


## Crow on the Blackwood sign

The installed Living Birds pack was found in `My project (2)/Assets/living birds`.
Its original crow FBX (726 triangles), crowDiffuse texture, watch/sing/ruffle
animation tracks and both crow recordings are used. The source files remain
unchanged. The game copy has a 256-pixel matte albedo, a compact native animation
library and 22050 Hz mono calls. Source paths and hashes are in assets/crow/source.json.

A single crow perches on the upper left of the town sign, with feet aligned to
the sloping board. It idles, occasionally ruffles its feathers, and caws as the
player first approaches. Further calls alternate the two recordings at 14?24
second intervals while nearby. Sound is spatial, range-limited and uses the
existing game mute bus. Title/journal/pause states stop animation and pause calls;
a new journey restores the perched greeting. No bird collision obstructs the road.

`smoke_test_sign_crow.gd` checks placement, original animation clips, texture
budget, both audio assets, approach/range gating, pause/resume/mute and restart.
`tools/preview_sign_crow.gd` renders its perch and calling pose at the town entrance.


## Crow audibility, damage and achievement

Crow calls now play at -4 dB with a 12-metre reference distance and 36-metre
range, and the first approach cue triggers within 18 metres. This replaces the
previous -17 dB/four-metre settings that were easily masked by the wind. The
rendered verification captures actual crow output on the game bus at the entrance
approach, checking nonzero audible peak/RMS rather than just the play trigger.

The crow has a fitted bullet collider. A gun hit plays the original Living Birds
death clip, stops calling, and drops the body off the sign. Corpses cannot retrigger
hits or calls; menus pause the fall. New journeys restore the live perched crow.

The first kill unlocks "Wow, what an asshole" with an eight-second toast. Achievements
save locally in user://achievements.cfg, survive new journeys/app restarts, and
appear in the field journal. Repeated kills do not unlock it again. Verification
uses separate temporary achievement profiles, leaving the player's profile untouched.
`smoke_test_crow_death.gd` checks actual pistol ray hits, the fall, persistent reload,
no duplicate unlocks and reset. `tools/preview_crow_death.gd` verifies real audio
output, rendered death and the exact popup text.


## Crow proximity flight and return

Within 3.3 metres of the sign, a live crow switches to the original Living Birds
wing-flap animation and follows a curved escape over the open approach road.
It leaves view for 24?36 seconds. A return starts only when the player is at least
seven metres from the perch; waiting under the sign keeps it away. It flies back,
plays the original landing clip and resumes watching and calling. Approaching
during its return sends it away again. Menus pause every stage.

The flying crow remains shootable. Killing it stops its flight and prevents
return for that journey; achievements retain their existing persistent behavior.
New journeys restore the live perched crow. `smoke_test_crow_flight.gd` checks
proximity, delayed/camping-safe return, interrupted landing, pause, calls,
shootable flight, death and reset. `tools/preview_crow_flight.gd` verifies the
original wing/landing clips and the clear route in the game renderer.


Achievement notification fix: a save that already contained crow_killer previously
silently skipped the popup on later kills. Unlocking now always displays the exact
achievement title for eight seconds after a live crow is killed. The first event
says ACHIEVEMENT UNLOCKED; already-earned events say ACHIEVEMENT. Saved progress
remains a single entry. The gun-hit test now reloads a saved unlock before a second
actual kill, and the rendered preview supports --already-unlocked to verify this
case without modifying the player's progress.

Apartment interiors: the user's cached Brick Project Studio Apartment Kit supplies
24 converted furniture/household models and 85 placements across the six buildings.
The millkeeper's rooms have a bedroom, sitting area and kitchenette; the clinic has
beds and waiting seats; the offices have desks, computer equipment and chairs;
the shop has a break table and the radio room has a lounge. Original searchable
drawers/cabinets and quest items remain accessible. Large furniture has collision.
Source provenance and dimensions are in assets/apartment/manifest.json. Source
files remain unchanged; exports use flat shading, matte materials, 256px albedos
and fewer than 2,500 triangles each. Staged source files under builds are excluded
from Godot import and Git. Rebuild tools: extract_apartment_kit.py and
prepare_apartment_assets.py (Blender). smoke_test_apartment_interiors.gd checks
model presence and budgets; town, storage and patrol tests verify circulation and
progression. tools/preview_apartment_interiors.gd captures all six rooms.

Photo-led interior redesign (October 16):
- Living/seating reference: https://www.ikea.com/nl/nl/p/jarnvag-vloerkleed-laagpolig-ornamentenpatroon-beige-donkerbeige-50624246/
- Bedroom reference: https://www.ikea.com/at/de/rooms/bedroom/gallery/dein-kleines-ruhiges-aufgeraeumtes-schlafzimmer-pubd9bdace0/
- Clinic reference: https://hoshino-ent.jp/clinic.html
- Shop reference: https://www.aboutbritain.com/BlistsHill.htm

These photographs guide furniture relationships and functional room planning;
the game's existing assets remain the actual geometry and textures. Sofas face
coffee tables within full-size rugs; storage is against walls; beds have bedside
access; waiting chairs form a row; shop counters and merchandise shelves read as
retail fixtures. The house has a new bedroom divider, continuous kitchen and a
pendant above its dining table. The clinic uses tiled flooring and a suspended
privacy curtain. Repeated floor litter, stacked boxes, oversize legacy shelves
and unrelated colorful paintings were removed. Interior brick is covered with
plaster and low wall paneling; lower ceilings, skirting, bulletin boards, framed
landscapes, clocks and restrained lighting finish the rooms. Furniture colors
use muted timber, brown upholstery and sage clinical fabric. Existing searchable
storage and quest positions remain functional; 13 renderer views cover the
layouts, with quest, storage, camera and patrol regression checks.

Abandonment pass: interior_decay.gd adds authored damage and departure stories
after furnishing, without changing quest/storage state. Each building has a
roof-leak patch, ceiling water ring, streaked wall damp, mold along the skirting,
a shallow stained puddle and fallen plaster. The Compatibility-safe cutout shader
interior_stains.gdshader uses quantized procedural noise with irregular edges.
Damage is concentrated at leaks rather than spread evenly over every surface.
The house has an open suitcase, discarded place setting and a broken dining
chair. Clinic supplies and a blanket have spilled beside the treatment bay.
The store has broken shelf timber and ceramics; the workshop has a split table
and a broken chair. Ranger paperwork, skewed seating and filing supplies show a
rushed evacuation; the radio room has a packed bag, scattered records and fallen
lamp. Selected intact chairs are hidden and their collision disabled when replaced.
Small debris is visual-only to preserve steady close-range camera movement.
All new dressing is static, with no additional per-frame script processing.
smoke_test_interior_decay.gd checks all six rooms, 30 stain patches, distinct story
props and the absence of small-debris collision. Town/quest, storage, NPC patrol
and camera regressions pass; the 13-view renderer preview covers the changes.

Chapel pursuit/collision repair: horizontal enemy probes used to classify uphill
terrain as an obstacle and steer the creatures downhill. Probes now allow floor
normals and account for the elevation ahead. chapel_enemy_paths.gd builds a small
physics-sampled route graph after the forest exists, avoiding trunks, boulders
and church walls. Both woodland creatures follow routes to the court and can
attack a player standing there; watching a stalker no longer freezes it in place.
The terrain now blends into the road shoulders and the nine-metre plateau. The
court's redundant raised collision slab was removed, leaving one continuous
walking surface. smoke_test_hill_pursuit.gd verifies actual attacks from both
hiding places, smoke_test_chapel_court.gd walks both court edges in both directions,
and the full-width Chapel Road climb/descent and cellar quest checks pass.
Mouse wheel and V cycle only owned guns; the pickup message and controls page
show the controls. smoke_test_weapon_cycle.gd checks real input, both directions,
wrap, holster, skipped undiscovered guns, reload cancellation and menu guards.

## Explorable Victorian house

Added an original two-story house in the marked lot beside the antiques shop, with the porch and front door facing Main Street. The house uses existing local town wood/plaster/roof textures and apartment-kit sofa, chairs, table, beds, wardrobe, dresser, bookcase, and debris. Broken porch rails, missing roof patches, exposed rafters, and worn trim establish long-term decay.

Reference images were found through an image search for weathered Victorian houses, including https://oldhousesunder50k.com/fixer-upper-victorian-for-sale/ and https://www.asasbriarcliff.com/hartwell-ga . Photos inform proportions and details; the game uses original geometry and local assets.

Route checks cover the porch approach, doorway, stairs, rooms, actual player movement onto the upper landing, safe door behavior while inside, and new-journey door reset. The woodland boundary and hill grading make room for the house without obstructing the church road.
