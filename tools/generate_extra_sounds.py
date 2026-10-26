from audio_encoding import write_ogg
import math, random, struct
from pathlib import Path
out = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
out.mkdir(parents=True, exist_ok=True)
sr = 44100
rng = random.Random(2606)

def write(name, seconds, sample):
    values = []
    for i in range(int(sr*seconds)):
        t = i/sr
        envelope = max(0, min(1, t/.008, (seconds-t)/.04))
        values.append(sample(t)*envelope)
    peak = max(abs(v) for v in values)
    pcm = b''.join(struct.pack('<h', round(v/peak*19500)) for v in values)
    write_ogg(out / (name + '.ogg'), pcm, sr)
    print(name, seconds, 'seconds')

def magic(t):
    swirl = math.sin(2*math.pi*(320*t+680*t*t))*math.exp(-4*t)
    shimmer = .25*math.sin(2*math.pi*1520*t)*math.exp(-7*max(0,t-.16))*(1-math.exp(-35*t))
    air = rng.uniform(-1,1)*.10*math.exp(-((t-.22)/.15)**2)
    return swirl+shimmer+air

def victory(t):
    notes = [(0,523.25),(.18,659.25),(.36,783.99),(.58,1046.5)]
    value = 0
    for start,freq in notes:
        u=t-start
        if u>=0:
            value += (math.sin(2*math.pi*freq*u)+.25*math.sin(4*math.pi*freq*u)+.12*math.sin(6*math.pi*freq*u))*math.exp(-3.6*u)*(1-math.exp(-110*u))
    for freq in [261.63,329.63,392.00]:
        value += .3*math.sin(2*math.pi*freq*t)*math.exp(-1.8*t)*(1-math.exp(-40*t))
    return value

def castle(t):
    boom = math.sin(2*math.pi*(85*t-34*t*t))*math.exp(-9*t)
    stone = rng.uniform(-1,1)*.38*math.exp(-24*t)
    ring = .18*math.sin(2*math.pi*430*t)*math.exp(-7*t)
    return boom+stone+ring

write('magic', .65, magic)
write('victory', 1.85, victory)
write('castle', .58, castle)
