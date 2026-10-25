import math, random, struct, wave
from pathlib import Path
out = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
out.mkdir(parents=True, exist_ok=True)
sr = 44100
rng = random.Random(26)

def write(name, seconds, sample):
    values = []
    for i in range(int(sr * seconds)):
        t = i / sr
        fade = min(1, t / .006, (seconds - t) / .02)
        values.append(sample(t) * max(0, fade))
    peak = max(abs(x) for x in values)
    pcm = b''.join(struct.pack('<h', round(x / peak * 19000)) for x in values)
    with wave.open(str(out / (name + '.wav')), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(sr); f.writeframes(pcm)
    print(name, 'duration', seconds, 'peak', 19000 / 32768)

def summon(t):
    value = 0
    for start, freq in [(0, 523.25), (.09, 659.25), (.18, 783.99)]:
        u = t - start
        if u >= 0:
            value += (math.sin(2*math.pi*freq*u) + .25*math.sin(2*math.pi*2*freq*u))*math.exp(-10*u)*(1-math.exp(-400*u))
    return value

def attack(t):
    noise = rng.uniform(-1,1)
    whoosh = noise * math.exp(-((t-.065)/.04)**2) * .35
    u = max(0, t-.105)
    impact = 0 if t < .105 else math.sin(2*math.pi*(130*u-100*u*u))*math.exp(-28*u)
    return whoosh + impact

def death(t):
    tone = math.sin(2*math.pi*(340*t - 210*t*t))*math.exp(-7*t)
    dust = rng.uniform(-1,1)*.18*math.exp(-10*t)
    return tone + dust

write('summon', .52, summon)
write('attack', .30, attack)
write('death', .55, death)

