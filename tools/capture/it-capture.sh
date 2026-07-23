#!/usr/bin/env bash
#
# it-capture.sh — high-performance gameplay capture for the Iron Tide devlog.
#
# Positions the game window, records it through the GNOME compositor (no
# x11grab readback penalty — see it-screencast.py), then optionally crops the
# HUD strip and transcodes to a clean, web/Reddit-safe h264 mp4.
#
# Prereqs: an UNLOCKED GNOME/X11 session, the game running with its agent API
# on :7730, and: python3-gi, ffmpeg, xdotool, xwininfo.
#
# Usage:
#   it-capture.sh <out-basename> <seconds> [options]
# Options:
#   --fps N            capture framerate (default 30)
#   --size WxH         resize the game window first (default: leave as-is)
#   --crop-bottom PX   crop PX off the bottom before transcode (HUD strip; default 88)
#   --crop-top PX      crop PX off the top too (compass tape; default 0 — keep it)
#   --raw              keep the compositor mp4, skip crop/transcode
#   --outdir DIR       where finished files go (default: current dir)
#   --api URL          agent API base (default http://127.0.0.1:7730)
#
# Drive the scene (heading/throttle/weather/time) over the agent API in another
# shell, or background console POSTs alongside this call for mid-shot changes.
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DISPLAY="${DISPLAY:-:0}"

OUT_BASE="${1:?usage: it-capture.sh <out-basename> <seconds> [options]}"; shift
SECS="${1:?usage: it-capture.sh <out-basename> <seconds> [options]}"; shift
FPS=30; SIZE=""; CROP_B=88; CROP_T=0; RAW=0; OUTDIR="$PWD"; API="http://127.0.0.1:7730"
while [ $# -gt 0 ]; do case "$1" in
  --fps) FPS="$2"; shift 2;;
  --size) SIZE="$2"; shift 2;;
  --crop-bottom) CROP_B="$2"; shift 2;;
  --crop-top) CROP_T="$2"; shift 2;;
  --raw) RAW=1; shift;;
  --outdir) OUTDIR="$2"; shift 2;;
  --api) API="$2"; shift 2;;
  *) echo "unknown option: $1" >&2; exit 2;;
esac; done
mkdir -p "$OUTDIR"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- preflight: keep the session awake; a locked screen records black -------
xset -dpms >/dev/null 2>&1 || true
xset s off  >/dev/null 2>&1 || true
if command -v loginctl >/dev/null 2>&1; then
  sess=$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}' | head -1)
  locked=$(loginctl show-session "$sess" -p LockedHint 2>/dev/null | cut -d= -f2)
  [ "$locked" = "yes" ] && { echo "ERROR: session is LOCKED — unlock it, screencast records black while locked." >&2; exit 1; }
fi

# --- find + place the game window -------------------------------------------
PID=$(pgrep -x iron_tide | head -1) || true
[ -z "${PID:-}" ] && { echo "ERROR: iron_tide is not running." >&2; exit 1; }
WID=$(xdotool search --pid "$PID" --onlyvisible 2>/dev/null | tail -1)
[ -z "${WID:-}" ] && WID=$(xdotool search --pid "$PID" 2>/dev/null | tail -1)
[ -z "${WID:-}" ] && { echo "ERROR: no window for iron_tide pid $PID." >&2; exit 1; }
if [ -n "$SIZE" ]; then xdotool windowsize "$WID" "${SIZE%x*}" "${SIZE#*x}"; sleep 2; fi
xdotool windowactivate "$WID" >/dev/null 2>&1 || true
xdotool windowraise "$WID"    >/dev/null 2>&1 || true
sleep 1

# xdotool X/Y is frame-relative for reparented windows — use xwininfo for the
# ROOT-absolute rect the compositor grabs. Round dims to even for yuv420p.
info=$(xwininfo -id "$WID")
X=$(awk '/Absolute upper-left X/{print $4}' <<<"$info")
Y=$(awk '/Absolute upper-left Y/{print $4}' <<<"$info")
W=$(awk '/^  Width:/{print $2}'  <<<"$info"); W=$((W - W%2))
H=$(awk '/^  Height:/{print $2}' <<<"$info"); H=$((H - H%2))
echo "capturing win $WID  rect ${W}x${H}+${X}+${Y}  ${SECS}s @ ${FPS}fps"

# --- record through the compositor ------------------------------------------
RAWFILE=$(python3 "$HERE/it-screencast.py" "$TMP/rec" "$X" "$Y" "$W" "$H" "$SECS" "$FPS" 2>/dev/null | head -1)
[ -f "$RAWFILE" ] || { echo "ERROR: no output file from screencast (locked screen? sender died?)." >&2; exit 1; }

# --- report the real (deduplicated) framerate that landed -------------------
k=$(ffmpeg -hide_banner -loglevel info -i "$RAWFILE" -vf mpdecimate -f null - 2>&1 | grep -oE 'frame= *[0-9]+' | tail -1 | grep -oE '[0-9]+')
d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$RAWFILE")
python3 -c "print(f'captured: {$k} unique frames / {$d:.1f}s = {$k/$d:.1f} fps real motion')"

if [ "$RAW" = 1 ]; then
  cp "$RAWFILE" "$OUTDIR/$OUT_BASE.mp4"
  echo "wrote $OUTDIR/$OUT_BASE.mp4 (raw compositor output)"
  exit 0
fi

# --- crop HUD + transcode to a clean web mp4 --------------------------------
srcw=$(ffprobe -v error -select_streams v:0 -show_entries stream=width  -of csv=p=0 "$RAWFILE")
srch=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$RAWFILE")
cw=$srcw; ch=$(( srch - CROP_T - CROP_B )); ch=$((ch - ch%2)); cy=$CROP_T
# libx264 for the offline transcode: cheap, one-time, maximally compatible. The
# performance win is in the capture, not here — no hardware encoder needed.
ffmpeg -hide_banner -loglevel error -y -i "$RAWFILE" \
  -vf "crop=${cw}:${ch}:0:${cy}" \
  -c:v libx264 -preset slow -crf 22 -pix_fmt yuv420p -an -movflags +faststart "$OUTDIR/$OUT_BASE.mp4"
echo "wrote $OUTDIR/$OUT_BASE.mp4  (${cw}x${ch}, libx264, $(stat -c%s "$OUTDIR/$OUT_BASE.mp4") bytes)"
