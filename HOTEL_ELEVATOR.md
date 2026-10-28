# Saint George Hotel: second floor and elevator

The rear-left sleeping nook is now a two-stop passenger lift. Use E (or the controller interact button) on the landing call plate, walk fully into the cab, then interact with the cab panel to ride to floor 2 or the lobby. The trip takes roughly six seconds including doors. Looking around remains available during the ride; movement resumes when the doors finish opening. Pausing also pauses the lift and its motor. Save after the doors finish opening.

Floor 2 contains rooms 201–203 with doors that open inward and can be closed from either side. The former downstairs bedroom furniture, its searchable drawer, supplies and dresser key now occupy room 201. Kitchen furniture and the bolted basement entrance remain downstairs.

Implementation: hotel_upper_floor.gd. Original hotel furniture roots keep their indices for the approved editor layout; hotel_layout.gd applies the bedroom translation afterward. The new optional save root supports earlier journeys.

Visual references (reference only; no meshes or photographs copied):
- Vintage Elevator for Game model: https://sketchfab.com/3d-models/vintage-elevator-for-game-office-hospital-2fbce7341f554861955eb3cc6bb532d7
- Ambassador Hotel bronze elevator doors: https://www.thefitzmke.com/post/2018/05/25/tour-through-the-ambassador-hotel-historic-art-deco-details
- Dewberry wood paneling and brass trim: https://www.specialtywoodwork.com/hospitality-services/dewberry-charleston-c

Motor loop and arrival chime are original synthesized sounds. All cab/landing geometry is built locally with existing materials in the game's PS2 style.
