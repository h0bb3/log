# Iron Tide gameplay capture

High-performance video capture for the Iron Tide devlog. Records the running
game at its **true framerate** and produces clean, web/Reddit-safe mp4 clips.

## Why this exists (read once)

The obvious tool, `ffmpeg -f x11grab`, does a synchronous GPU→CPU framebuffer
readback for every frame. On this Intel-Arc / Mesa box that readback saturates
around **14 fps** *and* steals frame time from the game, so a game rendering
20–30 fps lands as a 12–14 fps slideshow. Lowering the capture rate, shrinking
the window, or using a cheaper encoder does not move it — the ceiling is the
readback, not the encode.

The fix is to capture **through the compositor** instead. GNOME Shell's Mutter
already composites every frame on the GPU and can hardware-encode a region via
PipeWire — no extra readback. Measured head-to-head on the same moving-water
scene:

| backend | real motion captured | notes |
|---|---|---|
| `ffmpeg -f x11grab` | **13.8 fps** | throttles the game; 41 MB lossless intermediate |
| GNOME `ScreencastArea` | **20.5 fps** | matches the game's own fps; ~2 fps overhead; 3.4 MB h264 |

So the compositor path captures essentially every frame the game presents. The
remaining ceiling is the game itself (release build, `render_scale 0.5`, full
water/reflections ≈ 20–30 fps depending on scene), not the capture.

## The load-bearing gotcha

GNOME ties the recording's lifetime to the **D-Bus sender**. If the process
that called `ScreencastArea` exits, the recording aborts with *"Sender has
vanished"* and `StopScreencast` returns false with no file. Two separate
`gdbus call` one-liners (start; sleep; stop) therefore **cannot work** — the
start caller is already gone. `it-screencast.py` is one long-lived process that
holds the bus connection across start → wait → stop for exactly this reason.

## Files

- **`it-screencast.py`** — the D-Bus driver. Records a rect `X Y W H` for
  `SECONDS` and prints the file GNOME wrote. Not usually called directly.
- **`it-capture.sh`** — the orchestrator. Finds/positions the game window,
  computes its root-absolute rect, records via the driver, then crops the HUD
  and transcodes to a clean h264 mp4.

## Prerequisites

- An **unlocked** GNOME session on **X11** (`echo $XDG_SESSION_TYPE` → `x11`).
  A locked or DPMS-blanked screen records **black** — the script refuses to run
  if `loginctl` reports the session locked, and it disables DPMS/blanking on
  start. If you step away mid-shoot, disable auto-lock first:
  `gsettings set org.gnome.desktop.screensaver lock-enabled false`
- The game running with its agent API on `:7730`.
- `python3-gi` (PyGObject), `ffmpeg`, `xdotool`, `xwininfo`.

## Usage

```bash
# 6-second clip, default 30 fps, HUD strip cropped, compass tape kept:
tools/capture/it-capture.sh my-clip 6 --outdir docs/assets/vid

# force the window size first; keep the raw compositor mp4 (no crop/transcode):
tools/capture/it-capture.sh raw-clip 8 --size 1152x720 --raw
```

Options: `--fps N` · `--size WxH` · `--crop-bottom PX` (default 88, the HUD
command bar) · `--crop-top PX` (default 0 — keep the compass tape) · `--raw` ·
`--outdir DIR` · `--api URL`. The script prints the **real deduplicated
framerate** that landed so you can reject a bad take on the spot.

## Driving the scene

Set up the shot over the agent API / dev console **before** and **during** the
recording. For a static scene, set it, then capture. For a scene that changes
mid-shot (a turn, a throttle change), background the capture and issue console
commands alongside it:

```bash
API=http://127.0.0.1:7730
C(){ curl -s -X POST $API/console -H 'Content-Type: application/json' -d "{\"line\":\"$1\"}" >/dev/null; }

C "debug enemies off"                 # halt hostiles so the shoot isn't interrupted
C "weather manual on"; C "weather state moderate"; C "weather amplitude 0.75"
C "time set 12"                        # NB: pins the clock but it still advances — re-issue before each take
C "ship mode steam"; C "ship heading 40"; C "ship throttle 0.8"

tools/capture/it-capture.sh turn 9 --outdir docs/assets/vid &
sleep 4; C "ship heading 300"          # a hard turn 4 s into the 9 s clip
wait
```

Notes learned the hard way:
- Capture from a **`--release`** build. A debug build renders 1–10 fps and no
  capture backend can invent frames that were never drawn.
- `weather state` needs a lowercase enum (`storm`, not `Storm`) and the manual
  override must be on, or it decays back to `Moderate` within ~90 s.
- Heading θ (compass) → world direction `(sin θ, −cos θ)`; sails into a headwind
  brake the engine, so furl them (`set_sail_throttle 0`) for steam runs.
- `debug island` teleports ~600 m off the nearest island; wait ~25 s for async
  terrain, and pre-warm the chunks by sailing in once before the real take.

## Finishing for the blog

Embed clips in a post with an autoplaying muted loop:

```html
<video src="/log/assets/vid/my-clip.mp4"
       poster="/log/assets/img/my-clip-poster.jpg"
       controls autoplay loop muted playsinline
       style="width:100%;height:auto"></video>
```

Poster frame: `ffmpeg -ss 3 -i my-clip.mp4 -frames:v 1 -q:v 4 my-clip-poster.jpg`.
A social cut for Reddit/X: concat several clips with `ffmpeg -filter_complex
"...concat=n=N:v=1:a=0"` and keep it under ~10 MB.
