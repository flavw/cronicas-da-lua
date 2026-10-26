"""Encode mono PCM directly to Ogg Vorbis; requires ffmpeg in PATH."""
import subprocess
from pathlib import Path

def write_ogg(path: Path, pcm: bytes, sample_rate: int = 44100):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','s16le',
                    '-ar',str(sample_rate),'-ac','1','-i','pipe:0','-c:a','libvorbis',
                    '-q:a','4',str(path)],input=pcm,check=True)
