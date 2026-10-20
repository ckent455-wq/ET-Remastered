"""Split a hinged front driver door from the user's existing low-poly police car.

Clip the lower door skin at its panel boundaries. Preserve the A/B pillars and
windshield on the body; move the complete side window and rubber seals together.
"""
from pathlib import Path
import copy,json,math,struct
ROOT=Path(__file__).resolve().parents[1]
HINGE=(-0.77,0.62,-0.54)

def main():
 raw=(ROOT/'assets/vehicles/abandoned_police.glb').read_bytes()
 length=struct.unpack_from('<I',raw,12)[0]
 doc=json.loads(raw[20:20+length]);binary=bytearray(raw[28+length:])
 def read(index):
  a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
  size={'SCALAR':1,'VEC2':2,'VEC3':3}[a['type']];kind={5126:'f',5123:'H',5125:'I'}[a['componentType']]
  fmt='<'+kind*size
  return [struct.unpack_from(fmt,binary,v.get('byteOffset',0)+a.get('byteOffset',0)+j*v.get('byteStride',struct.calcsize(fmt))) for j in range(a['count'])]
 def accessor(values,size):
  while len(binary)%4:binary.append(0)
  offset=len(binary)
  for value in values:binary.extend(struct.pack('<'+'f'*size,*value))
  view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(binary)-offset,'target':34962})
  a={'bufferView':view,'componentType':5126,'count':len(values),'type':{2:'VEC2',3:'VEC3'}[size]}
  if size==3:a.update(min=[min(p[k] for p in values) for k in range(3)],max=[max(p[k] for p in values) for k in range(3)])
  index=len(doc['accessors']);doc['accessors'].append(a);return index
 def triangles(poly):return [(poly[0],poly[i],poly[i+1]) for i in range(1,len(poly)-1)]
 def split(poly,axis,sign,limit):
  inside=[];outside=[]
  for i,a in enumerate(poly):
   b=poly[(i+1)%len(poly)];da=sign*a[0][axis]-limit;db=sign*b[0][axis]-limit
   (inside if da>=-1e-8 else outside).append(a)
   if (da>=-1e-8)!=(db>=-1e-8):
    t=da/(da-db);v=tuple(tuple(x+(y-x)*t for x,y in zip(u,w)) for u,w in zip(a,b))
    inside.append(v);outside.append(v)
  return inside,outside
 def marker(tri,point):
  uv=[sum(v[2][k] for v in tri)/3 for k in range(2)]
  return math.dist(uv,point)<0.006
 glass_material=copy.deepcopy(doc['materials'][0]);glass_material['name']='PoliceWindowGlass';glass_material['alphaMode']='BLEND';glass_material['doubleSided']=False;glass_material['pbrMetallicRoughness']['baseColorFactor']=[1,1,1,0.16]
 glass_id=len(doc['materials']);doc['materials'].append(glass_material)
 liner_id=len(doc['materials']);doc['materials'].append({'name':'PoliceDoorInnerLiner','doubleSided':True,'pbrMetallicRoughness':{'baseColorFactor':[0.12,0.15,0.14,1],'metallicFactor':0,'roughnessFactor':1}})
 body={};door={};lower=[]
 def add(bucket,material,poly):
  if len(poly)>=3:bucket.setdefault(material,[]).extend(triangles(poly))
 for primitive in doc['meshes'][4]['primitives']:
  positions=read(primitive['attributes']['POSITION']);normals=read(primitive['attributes']['NORMAL']);uvs=read(primitive['attributes']['TEXCOORD_0']);indices=read(primitive['indices']);mat=primitive.get('material',0)
  for i in range(0,len(indices),3):
   tri=[(positions[indices[i+k][0]],normals[indices[i+k][0]],uvs[indices[i+k][0]]) for k in range(3)]
   # This source includes separate opaque reverse faces behind the blue glass.
   # Both faces must be transparent and belong to the same moving assembly.
   window=all(v[0][0]<-0.55 and v[0][1]>=0.835 and -0.54<=v[0][2]<=0.205 for v in tri)
   # Atlas colors are also used by painted hood/trunk panels. Only the
   # geometrically bounded driver window may become transparent.
   is_glass=window and (marker(tri,(0.149841,0.467916)) or marker(tri,(0.092421,0.547191)))
   assigned=glass_id if is_glass else mat
   if window and (is_glass or marker(tri,(0.092421,0.039223))):add(door,assigned,tri);continue
   # Only the outward-facing lower side skin, never the windshield or roof.
   if not all(v[0][0]<-0.67 for v in tri):
    add(body,assigned,tri);continue
   candidate=tri
   for plane in [(1,1,0.38),(1,-1,-0.845),(2,1,-0.54),(2,-1,-0.145)]:
    candidate,remainder=split(candidate,*plane) if candidate else ([],[])
    add(body,assigned,remainder)
   add(door,assigned,candidate)
   if mat==0 and len(candidate)>=3:lower.extend(triangles(candidate))
 # No fixed body panel may inherit the window's transparent material.
 assert glass_id not in body, 'Transparency leaked onto the fixed car body'
 assert glass_id in door, 'Driver window glass must remain in the moving door'
 # A fitted lining and edge caps follow the exact outer skin, inset 5.5 cm.
 def inner(vertex):return ((vertex[0][0]+0.055,vertex[0][1],vertex[0][2]),tuple(-n for n in vertex[1]),(0,0))
 edges={}
 for tri in lower:
  door.setdefault(liner_id,[]).append(tuple(inner(v) for v in reversed(tri)))
  for i,a in enumerate(tri):
   b=tri[(i+1)%3];key=tuple(sorted([tuple(round(c,5) for c in a[0]),tuple(round(c,5) for c in b[0])]))
   if key in edges:edges[key]=None
   else:edges[key]=(a,b)
 for edge in edges.values():
  if edge:
   a,b=edge;add(door,liner_id,[a,b,inner(b),inner(a)])
 def mesh(bucket,moving=False):
  primitives=[]
  for material,faces in bucket.items():
   verts=[v for tri in faces for v in tri]
   pos=[tuple(v[0][k]-(HINGE[k] if moving else 0) for k in range(3)) for v in verts]
   norm=[tuple(c/max(math.sqrt(sum(n*n for n in v[1])),1e-8) for c in v[1]) for v in verts]
   primitives.append({'attributes':{'POSITION':accessor(pos,3),'NORMAL':accessor(norm,3),'TEXCOORD_0':accessor([v[2] for v in verts],2)},'material':material,'mode':4})
  return {'name':'DriverDoor' if moving else 'PoliceBody','primitives':primitives}
 doc['meshes'][4]=mesh(body)
 door_index=len(doc['meshes']);doc['meshes'].append(mesh(door,True))
 node_index=len(doc['nodes']);doc['nodes'].append({'name':'DriverDoor','mesh':door_index,'translation':HINGE})
 doc['scenes'][0]['nodes'].append(node_index)
 doc['buffers'][0]['byteLength']=len(binary)
 while len(binary)%4:binary.append(0)
 encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*(-len(encoded)%4)
 output=ROOT/'assets/vehicles/abandoned_police_openable.glb'
 output.write_bytes(struct.pack('<III',0x46546C67,2,28+len(encoded)+len(binary))+struct.pack('<II',len(encoded),0x4E4F534A)+encoded+struct.pack('<II',len(binary),0x004E4942)+binary)
 print(f'Prepared {output.name}: {sum(len(v) for v in door.values())} door triangles; native pillars and glass retained')

if __name__=='__main__':main()
