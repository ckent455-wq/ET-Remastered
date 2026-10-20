"""Repack the user's healing-item GLB using its supplied compact baked atlas."""
from pathlib import Path
import json
import struct
import argparse

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source',type=Path,default=Path.home()/'Downloads/DEMO_HealingItems_3Dexter/DEMO')
    args=parser.parse_args()
    source=args.source/'Mesh/GLB (Godot)/MedKit_Gdt.glb'
    raw=source.read_bytes()
    length=struct.unpack_from('<I',raw,12)[0]
    document=json.loads(raw[20:20+length])
    binary=raw[28+length:]
    atlas=(args.source/'Texture/DemoBake.png').read_bytes()
    atlas_view=document['images'][0]['bufferView']
    packed=bytearray()
    for index,view in enumerate(document['bufferViews']):
        while len(packed)%4:packed.append(0)
        start=view.get('byteOffset',0)
        payload=atlas if index==atlas_view else binary[start:start+view['byteLength']]
        view['byteOffset']=len(packed)
        view['byteLength']=len(payload)
        packed.extend(payload)
    document['buffers'][0]['byteLength']=len(packed)
    while len(packed)%4:packed.append(0)
    encoded=json.dumps(document,separators=(',',':')).encode()
    encoded+=b' '*(-len(encoded)%4)
    output=Path(__file__).resolve().parents[1]/'assets/healing/healing_items.glb'
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_bytes(struct.pack('<III',0x46546C67,2,28+len(encoded)+len(packed))+struct.pack('<II',len(encoded),0x4E4F534A)+encoded+struct.pack('<II',len(packed),0x004E4942)+packed)
    print(f'{source.name}: {len(raw):,} -> {output.stat().st_size:,} bytes')

if __name__=='__main__':main()
