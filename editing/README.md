# Rearrange the workshop

Open workshop_layout.tscn in Godot. Expand Furniture and select a named furniture root. The room shell is a cutaway reference; gameplay keeps its full walls and ceiling.

W: move. E: rotate. R: scale. F: focus selected furniture. Use the colored gizmo handles; keep furniture on the floor and leave the door and central aisle clear. Ctrl+S saves the layout. Run the game again with F6 only if you want this layout preview; F5 launches the full game. The layout itself is a static editing scene, without a playable character.

Restarting the game applies saved furniture root positions, rotations and scales to the original objects, including their collision and attached cabinet interactions. Existing saved journeys also receive the layout on load. Moving meshes inside a furniture root is a preview-only change: select and move the named root under Furniture. Loose tabletop props can be selected together with their table if you want to move them together. Do not rename the Furniture group or delete its runtime metadata.

The generator refuses to overwrite this scene once it exists, so your arrangement is retained. Only existing furniture root transforms are applied; duplication or deletion in this editor scene does not add or remove gameplay objects.

New_Table_Position_Me is an additional solid table already connected to gameplay. Select that root to position it independently of the original workbench.

Hotel: open hotel_layout.tscn. Its Furniture group has the hotel's movable furnishings and storage roots. Save and restart with F5 to apply changes. Workshop and hotel placements are independent.


Clinic: open clinic_layout.tscn. Move roots under Furniture. Patient_Bed contains Wake, NurseStand and BedExit markers which follow it automatically. Keep those markers clear of walls and furniture. Cabinet interactions and collision move with their roots. Save and restart with F5.

## Ranger station

Open `ranger_layout.tscn`. Move or rotate the roots under Furniture so their collisions and storage areas travel with them. Pickups are under RoomShell_REFERENCE. Save with Ctrl+S; restart the game to apply saved changes. Keep the scene root, metadata and reference structure intact.
