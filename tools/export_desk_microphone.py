"""Run with Blender --background DeskMicrophone.blend --python this_file.py.

Exports the editable model collection without saving or modifying the source blend.
"""
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[1]
model = bpy.data.collections.get('DESK MICROPHONE | Editable model')
if model is None:
    raise RuntimeError('Desk microphone model collection is missing')
bpy.ops.object.mode_set(mode='OBJECT') if bpy.context.object and bpy.context.object.mode != 'OBJECT' else None
bpy.ops.object.select_all(action='DESELECT')
objects = [obj for obj in model.all_objects if obj.type == 'MESH']
if not objects:
    raise RuntimeError('Desk microphone collection contains no meshes')
for obj in objects:
    obj.hide_set(False)
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
output = root / 'assets/microphone/desk_microphone.glb'
bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB',
    use_selection=True, export_yup=True, export_apply=True,
    export_materials='EXPORT', export_cameras=False, export_lights=False)
triangles = 0
for obj in objects:
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    triangles += len(mesh.loop_triangles)
    evaluated.to_mesh_clear()
print('MICROPHONE EXPORTED:', output, len(objects), 'parts;', triangles, 'triangles')
