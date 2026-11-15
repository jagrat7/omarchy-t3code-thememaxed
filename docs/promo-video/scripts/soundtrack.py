import json
import subprocess

grid = json.load(open("data/beat-grid.json"))
snapshot = json.load(open("data/snapshot-2026-11-15.json"))
bar_frames = grid["bar_seconds"] * 30


def at(bar, beats=0):
    return round((bar + beats / 4) * bar_frames) / 30


start = grid["bars"][snapshot["music"]["startBar"]]["start"]
duration = at(16)
clicks = [at(bar, 1) for bar in (2, 4, 6)]
whooshes = [max(0, at(bar) - 0.2) for bar in range(8, 15)]

graph = [
    f"[0:a]atrim=start={start:.4f}:duration={duration:.4f},asetpts=PTS-STARTPTS,afade=t=out:st={duration - 1.6:.4f}:d=1.6[m]",
    f"[1:a]volume=0.55,asplit={len(clicks)}" + "".join(f"[c{i}]" for i in range(len(clicks))),
    f"[2:a]volume=0.5,asplit={len(whooshes)}" + "".join(f"[w{i}]" for i in range(len(whooshes))),
]
inputs = ["[m]"]
for name, times in (("c", clicks), ("w", whooshes)):
    for i, t in enumerate(times):
        ms = round(t * 1000)
        graph.append(f"[{name}{i}]adelay={ms}|{ms}[{name}d{i}]")
        inputs.append(f"[{name}d{i}]")
graph.append("".join(inputs) + f"amix=inputs={len(inputs)}:normalize=0:duration=first[out]")

subprocess.run(
    ["ffmpeg", "-y", "-loglevel", "error", "-i", "audio/track.mp3", "-i", "audio/tick.wav", "-i", "audio/whoosh.wav",
     "-filter_complex", ";".join(graph), "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_f32le", "out/soundtrack.wav"],
    check=True,
)
