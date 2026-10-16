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

The chapel replaces the sealed west shop at the north end of Main Street, centered
at (-13.5, 0, -85). Its stonework, twin spires, pointed arches, and rose window are
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
