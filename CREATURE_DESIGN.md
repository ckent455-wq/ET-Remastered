# Creature combat direction

Research: Hideki Kamiya and Noboru Sugimura's 1998 interview (https://shmuplations.com/residentevil2/) emphasizes danger at close range and renewed threats once players become familiar with an area. Capcom's 2018 design discussion (https://blog.playstation.com/archive/2018/07/20/how-capcoms-powerful-re-engine-rebuilt-resident-evil-2s-leon-kennedy-claire-redfield-and-raccoon-city/) emphasizes dread in each zombie encounter.

Our adaptation uses Blackwood's existing signal story, not Resident Evil's virus mythology. The signal keeps damaged bodies moving; torso wounds are inefficient, deliberate head hits are effective, and mechanically injured legs temporarily hinder movement. This is the combat design rationale, not a new explanatory dialogue reveal.

Torso damage: 0.8x base. Head: 1.75x. Legs: 0.65x. Accumulating 28 leg damage causes a three-second limp at 48% movement speed. Seven seconds of resistance prevent repeated leg shots from holding an enemy helpless indefinitely. Below 40% health, creatures exert themselves for 1.15 seconds in each 4.5-second cycle, then recover. Wounded bursts do not override a limp.

Shared pursuit attacks take a short collision-aware step during early windup. Range and line-of-sight checks still decide whether a strike connects. No damage through doors, invulnerability phases, or visible health bars. Normal death, corpse searching, quest defeat flags, and scripted scares stay intact. New combat timers are saved with the existing enemy dictionaries and reset on a new journey.

Playtest ammunition economy and the cemetery reaper with pistol, rifle, and shotgun. Automated checks verify mechanics; they do not establish subjective difficulty.
