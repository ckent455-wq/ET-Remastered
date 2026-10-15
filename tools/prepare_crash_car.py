"""Adapt the downloaded FreeCarPack hatchback as a small damaged PS2 prop."""
import bpy
import json
import math
from pathlib import Path
from mathutils import Matrix, Vector
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'vehicles'
OUT.mkdir(exist_ok=True)
source = Path(r'C:\Users\jkern\Downloads\Blend\Blend\FreeCarPack.blend')
bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False)
car = bpy.data.objects['Hatchback Car_15']
parts = [car] + [o for o in car.children_recursive if o.type == 'MESH']
world = {o.name: [o.matrix_world @ v.co for v in o.data.vertices] for o in parts}
coords = [p for points in world.values() for p in points]
low = Vector(tuple(min(p[i] for p in coords) for i in range(3)))
high = Vector(tuple(max(p[i] for p in coords) for i in range(3)))
center = Vector(((low.x+high.x)/2, (low.y+high.y)/2, low.z))
scale = 4.1 / (high.y-low.y)
rotation = Matrix.Rotation(math.pi, 3, 'Z')
for obj in parts:
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
    for vertex, p in zip(obj.data.vertices, world[obj.name]):
        co = rotation @ ((p-center)*scale)
        # A compressed nose and skewed front fender suggest the recent impact.
        damage = max(0, min(1, (co.y-1.15)/.9))
        co.y -= damage*.30
        co.z -= damage*.10
        co.x += damage*.06
        vertex.co = co
    for face in obj.data.polygons:
        face.use_smooth = False
    for slot in obj.material_slots:
        material = slot.material
        if not material or not material.use_nodes:
            continue
        for node in material.node_tree.nodes:
            if node.type == 'BSDF_PRINCIPLED':
                node.inputs['Metallic'].default_value = 0
                node.inputs['Roughness'].default_value = 1
                node.inputs['Emission Strength'].default_value = 0
            if node.type == 'TEX_IMAGE' and node.image:
                if max(node.image.size) > 256:
                    node.image.scale(256,256)
                node.interpolation = 'Closest'
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = car
bpy.ops.export_scene.gltf(filepath=str(OUT/'crashed_hatchback.glb'), export_format='GLB', use_selection=True, export_animations=False, export_cameras=False, export_lights=False)
triangles = sum(sum(len(f.vertices)-2 for f in obj.data.polygons) for obj in parts)
(OUT/'manifest.json').write_text(json.dumps({'source':str(source),'model':car.name,'triangles':triangles,'texture_limit':256,'length_m':4.1,'adaptation':'compressed front end; flat shading'},indent=2))
print('CRASH CAR', triangles, 'triangles', flush=True)
