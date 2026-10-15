"""Copy selected local downloads; retain source hashes and make small mono SFX."""
import array
import hashlib
import json
import shutil
import wave
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / 'Downloads'
SOUND_ROOT = DOWNLOADS / 'Horror SFX Free' / 'Horror SFX Free'
SOUNDS = {
    'eerie_bed': 'Ambient/Creepy_ambience_5.wav',
    'house_creak': 'Ambient/Old House_creeky metal and wood_ambiance_7.wav',
    'distant_call': 'Ambient/Distant Yell_Echo and Reverb_2.wav',
    'metal_moan': 'Ambient/Mechanical Moan and Creaking.wav',
    'bell': 'Ambient/Bell_low.wav',
    'radio_static': 'Ambient/Radio_static.wav',
    'frogs': 'Ambient/Frogs.wav',
    'glass_tap': 'Ambient/Glass_random tapping.wav',
    'door_creak': 'House & Office/Door_squeeky_2.wav',
    'drawer_open': 'House & Office/Drawer_open.wav',
    'drawer_close': 'House & Office/Drawer_close_2.wav',
    'cabinet_open': 'House & Office/Drawer_squeeky_open_2.wav',
    'cabinet_close': 'House & Office/Cabinet_shut.wav',
    'flashlight_on': 'Character/Flashlight on.wav',
    'flashlight_off': 'Character/Flashlight off.wav',
}

def convert(source, destination, loop=False):
    with wave.open(str(source)) as wav:
        assert wav.getsampwidth() == 2
        channels, rate = wav.getnchannels(), wav.getframerate()
        samples = array.array('h', wav.readframes(wav.getnframes()))
    mono = [sum(samples[i:i+channels])/channels for i in range(0,len(samples),channels)]
    target_rate = 22050
    count = int(len(mono)*target_rate/rate)
    output = []
    for i in range(count):
        position = i*rate/target_rate
        a = min(int(position),len(mono)-1)
        b = min(a+1,len(mono)-1)
        output.append(mono[a]*(1-(position-a))+mono[b]*(position-a))
    if loop:
        overlap = min(int(target_rate*0.65),len(output)//8)
        for i in range(overlap):
            t = i/max(1,overlap-1)
            output[len(output)-overlap+i] = output[len(output)-overlap+i]*(1-t)+output[i]*t
        output = output[overlap:]
    else:
        fade = min(220,len(output)//4)
        for i in range(fade):
            output[i] *= i/fade
            output[-i-1] *= i/fade
    peak = max(abs(v) for v in output) or 1
    gain = min(4, 24575/peak)
    pcm = array.array('h',(int(max(-32767,min(32767,v*gain))) for v in output))
    with wave.open(str(destination),'wb') as wav:
        wav.setparams((1,2,target_rate,0,'NONE','not compressed'))
        wav.writeframes(pcm.tobytes())
    return round(len(output)/target_rate,3)

def main():
    audio = PROJECT/'assets/audio/horror'
    roads = PROJECT/'assets/roads'
    audio.mkdir(parents=True,exist_ok=True)
    roads.mkdir(parents=True,exist_ok=True)
    manifest = []
    for name, relative in SOUNDS.items():
        source = SOUND_ROOT/relative
        duration = convert(source,audio/(name+'.wav'),name in ['eerie_bed','radio_static'])
        manifest.append({'asset':name+'.wav','source':relative,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'seconds':duration,'conversion':'mono PCM16, 22050 Hz; peak capped at -2.5 dB; short edge fades or loop crossfade'})
    (audio/'sources.json').write_text(json.dumps({'pack':'Horror SFX Free','source':'User-provided local download; no author/license document included in archive','files':manifest},indent=2)+'\n')
    for name in ['road_straight.glb','asphalt.png']:
        shutil.copyfile(DOWNLOADS/'4pc_lowpoly_roads_glb'/name,roads/name)
    (roads/'sources.json').write_text(json.dumps({'pack':'4pc_lowpoly_roads_glb','source':'User-provided local download; no author/license document included in archive','files':['road_straight.glb','asphalt.png'],'adaptation':'Original mesh/UVs retained; omit raised concrete and generated collision, scale to street widths, matte vertex-shaded materials.'},indent=2)+'\n')
    print('Imported',len(manifest),'sound effects and the downloaded straight road model')

if __name__ == '__main__':
    main()
