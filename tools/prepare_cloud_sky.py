"""Small, overcast PS2 sky derived from the user's local panorama."""
import bpy,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/atmosphere'
OUT.mkdir(parents=True,exist_ok=True)
source=Path(r'C:\Users\jkern\Downloads\lonely_road_afternoon_puresky_8k.exr')
image=bpy.data.images.load(str(source),check_existing=False)
image.scale(512,256)
pixels=list(image.pixels)
values=sorted(math.log1p(max(0,pixels[i]*.2126+pixels[i+1]*.7152+pixels[i+2]*.0722)) for i in range(len(pixels)//2,len(pixels),4))
black=values[int(len(values)*.04)]
white=values[int(len(values)*.96)]
print('SKY LOG LUMINANCE RANGE',black,white,flush=True)
# Preserve photographic cloud structure; remove the bright blue afternoon tint.
for i in range(0,len(pixels),4):
 r,g,b=pixels[i:i+3]
 luminance=max(0,r*.2126+g*.7152+b*.0722)
 tone=max(0,min(1,(math.log1p(luminance)-black)/max(white-black,0.001)))
 # Dark clouds with a muted grey-green cast; no HDR sun bloom.
 value=0.13+0.37*tone
 pixels[i:i+4]=[value*.94,value,value*.97,1.0]
image.pixels=pixels
image.filepath_raw=str(OUT/'overcast_sky.png')
image.file_format='PNG'
image.save()
(OUT/'sky-source.json').write_text(json.dumps({'source':str(source),'output':'overcast_sky.png','size':[512,256],'adaptation':'tone-mapped, desaturated, darkened panoramic clouds; original unchanged'},indent=2)+'\n')
print('SKY SAVED',OUT/'overcast_sky.png',flush=True)
