"""Original 32-bar fantasy instrumental. Requires numpy and ffmpeg; produces only Ogg."""
from pathlib import Path
import subprocess
import numpy as np

SR=44100
BEAT=60/84
BAR=4*BEAT
SECONDS=32*BAR
N=round(SECONDS*SR)
mix=np.zeros((N,2),dtype=np.float32)
rng=np.random.default_rng(260026)

def note(midi,start,duration,amp,voice='harp',pan=0):
    t=np.arange(round(duration*SR),dtype=np.float32)/SR
    f=440*2**((midi-69)/12)
    if voice=='harp':
        y=sum(a*np.sin(2*np.pi*f*h*t)*np.exp(-t*(2+h*.22)) for h,a in [(1,1),(2,.3),(3,.14),(5,.05)])
        y*=1-np.exp(-t*180)
    elif voice=='flute':
        phase=2*np.pi*f*t+.025*np.sin(2*np.pi*5.1*t)
        y=(np.sin(phase)+.13*np.sin(phase*2)+.035*np.sin(phase*3))
        y*=np.minimum(1,t/.11)*np.minimum(1,(duration-t)/.22)
        y*=.92+.08*np.sin(2*np.pi*3.2*t)
    elif voice=='pad':
        y=(np.sin(2*np.pi*f*t)+.24*np.sin(2*np.pi*f*2*t)+.15*np.sin(2*np.pi*f*1.0018*t))
        y*=np.minimum(1,t/.65)*np.minimum(1,(duration-t)/.85)
    else:
        y=np.sin(2*np.pi*(f*t+7*(1-np.exp(-t*22))))*np.exp(-t*16)
        y+=rng.normal(0,.04,len(t))*np.exp(-t*35)
        y*=np.minimum(1,t/.004)
    y*=amp
    # Wrap releases across the loop seam, keeping the last chord's natural tail.
    indices=(round(start*SR)+np.arange(len(t)))%N
    np.add.at(mix[:,0],indices,y*np.sqrt((1-pan)/2))
    np.add.at(mix[:,1],indices,y*np.sqrt((1+pan)/2))

chords=[[50,57,62,65,69],[46,53,58,62,65],[48,55,60,65,69],[48,55,60,64,67],
        [50,57,62,65,69],[46,53,58,62,65],[43,50,55,58,62],[45,52,57,61,64]]
motif=[[(74,1),(77,.5),(76,.5),(72,1),(69,1)],
       [(70,1.5),(74,.5),(77,1),(74,1)],
       [(72,1),(69,1),(65,1),(69,1)],
       [(67,1.5),(72,.5),(76,1),(72,.8)],
       [(74,1),(69,.5),(72,.5),(77,1),(76,.8)],
       [(74,1.5),(70,.5),(69,1),(65,.8)],
       [(67,1),(70,1),(74,1.5)],
       [(73,1.5),(76,.5),(69,1.5)]]
arp=[0,2,1,3,2,4,3,1]
for bar in range(32):
    chord=chords[bar%8]
    for step,k in enumerate(arp):
        note(chord[k]+(12 if bar>=16 and step in [3,6] else 0),bar*BAR+step*BEAT/2,1.8,.09,'harp',-.35)
    for i,pitch in enumerate(chord[:4]):
        note(pitch-12,bar*BAR, BAR+1.25,.038 if i else .055,'pad',.2+(i%2)*.25)
    position=.15 if bar%4==0 else .05
    # Sparse middle section keeps the loop comfortable during longer games.
    if not (16<=bar<24 and bar%2==1):
        for pitch,beats in motif[bar%8]:
            note(pitch+(0 if bar<16 else -12),bar*BAR+position*BEAT,max(.25,beats*BEAT*.9),.075,'flute',-.05)
            position+=beats
    for beat in [0,2]:note(31,bar*BAR+beat*BEAT,.42,.045,'drum',.05)

# A short stereo room, wrapped so the reverb does not stop at the loop boundary.
dry=mix.copy()
for delay,gain in [(.13,.13),(.27,.11),(.43,.08),(.71,.045)]:
    mix+=np.roll(dry[:,::-1],round(delay*SR),axis=0)*gain
mix-=mix.mean(axis=0)
mix=np.tanh(mix*1.15)
mix*=.78/np.max(np.abs(mix))
# Close the tiny final-sample offset without fading the musical phrase out.
seam=round(.02*SR)
blend=np.linspace(0,1,seam,dtype=np.float32)
blend=blend*blend*(3-2*blend)
mix[-seam:]+=blend[:,None]*(mix[0]-mix[-1])
pcm=np.round(mix*32767).astype('<i2').tobytes()
out=Path(__file__).resolve().parents[1]/'assets/audio/aldeia_ao_amanhecer.ogg'
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','s16le','-ar',str(SR),'-ac','2','-i','pipe:0','-c:a','libvorbis','-q:a','4',str(out)],input=pcm,check=True)
print(f'{out.name}: {SECONDS:.2f}s, 84 BPM, stereo Ogg; peak={np.max(np.abs(mix)):.3f}, seam={np.max(np.abs(mix[0]-mix[-1])):.5f}; {out.stat().st_size} bytes')
