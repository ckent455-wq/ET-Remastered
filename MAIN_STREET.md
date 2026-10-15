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
positional creaks and distant calls, an arrival bell from the hotel, and static
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

Validation includes all six entrances, 309 road/sidewalk collision samples,
all twelve storage interactions, NPC patrols and deaths, the crash-to-town walk,
weapon collection, the complete rescue quest, and real-renderer previews.
