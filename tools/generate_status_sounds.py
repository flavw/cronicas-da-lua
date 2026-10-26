"""Original synthesized shield, healing and poison sounds, encoded as Ogg Vorbis."""
import math, random, struct
from pathlib import Path
from audio_encoding import write_ogg

OUT=Path(__file__).resolve().parents[1]/'assets/audio'
SR=44100
rng=random.Random(2610)

def write(name,seconds,sample):
    values=[sample(i/SR)*max(0,min(1,i/SR/.004,(seconds-i/SR)/.025)) for i in range(round(SR*seconds))]
    peak=max(abs(v) for v in values) or 1
    pcm=b''.join(struct.pack('<h',round(v/peak*18000)) for v in values)
    write_ogg(OUT/(name+'.ogg'),pcm,SR)
    print(name,round(seconds,2),'s', (OUT/(name+'.ogg')).stat().st_size,'bytes')

def block(t):
    clang=sum(a*math.sin(2*math.pi*f*t)*math.exp(-d*t) for f,a,d in [(310,1,15),(775,.6,13),(1307,.35,18),(2200,.2,22)])
    return clang+rng.uniform(-1,1)*.4*math.exp(-65*t)

def heal(t):
    return sum((math.sin(2*math.pi*f*(t-start))+.15*math.sin(4*math.pi*f*(t-start)))*math.exp(-7*(t-start))*(1-math.exp(-100*(t-start))) for start,f in [(0,659.25),(.10,830.61),(.20,987.77)] if t>=start)

def poison_apply(t):
    bubbles=sum(.55*math.sin(2*math.pi*(f*(t-start)-550*(t-start)**2))*math.exp(-35*(t-start)) for start,f in [(0,540),(.08,390),(.16,630),(.25,330)] if t>=start)
    return bubbles+.12*rng.uniform(-1,1)*math.exp(-5*t)

def poison_tick(t):
    return math.sin(2*math.pi*(155*t-100*t*t))*math.exp(-12*t)+.22*rng.uniform(-1,1)*math.exp(-18*t)+.18*math.sin(2*math.pi*820*t)*math.exp(-15*t)

for args in [('block',.38,block),('heal',.68,heal),('poison_apply',.44,poison_apply),('poison_tick',.36,poison_tick)]:write(*args)
