#!/usr/bin/env python3
"""Record a screen rectangle via the GNOME Shell Screencast D-Bus API.

This is the *high-performance* capture backend for Iron Tide gameplay video:
GNOME's compositor (Mutter) records the framebuffer through PipeWire and
hardware-encodes it, so there is NO per-frame GPU->CPU readback the way
`ffmpeg -f x11grab` does. On this Intel-Arc/Mesa box x11grab tops out around
14 fps and steals frame time from the game; this path captures the game's true
framerate (~20-30+ fps) with ~2 fps of overhead.

THE LOAD-BEARING GOTCHA: GNOME ties the recording's lifetime to the D-Bus
*sender*. If the process that called ScreencastArea exits, the recording aborts
with "Sender has vanished" and StopScreencast returns false with no file. So a
single process MUST hold the bus connection open for start -> wait -> stop.
That is the entire reason this is one long-lived Python process and not two
`gdbus call` one-liners.

Output: GNOME picks the container/codec from Mutter's configured pipeline
(h264 mp4 on this box). Pass the file template WITHOUT an extension.

Usage:
    it-screencast.py OUT_TEMPLATE X Y W H SECONDS [FPS] [draw-cursor]
Prints the actual filename GNOME wrote, on stdout, as the first line.
"""
import sys
import time
import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib  # noqa: E402


def main() -> int:
    if len(sys.argv) < 7:
        sys.stderr.write(__doc__)
        return 2
    tmpl = sys.argv[1]
    x, y, w, h = (int(sys.argv[i]) for i in range(2, 6))
    secs = float(sys.argv[6])
    fps = int(sys.argv[7]) if len(sys.argv) > 7 else 30
    cursor = len(sys.argv) > 8 and sys.argv[8] not in ("0", "false", "no")

    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    proxy = Gio.DBusProxy.new_sync(
        bus,
        Gio.DBusProxyFlags.NONE,
        None,
        "org.gnome.Shell.Screencast",
        "/org/gnome/Shell/Screencast",
        "org.gnome.Shell.Screencast",
        None,
    )
    opts = {
        "framerate": GLib.Variant("i", fps),
        "draw-cursor": GLib.Variant("b", cursor),
    }
    args = GLib.Variant("(iiiisa{sv})", (x, y, w, h, tmpl, opts))
    ok, fname = proxy.call_sync(
        "ScreencastArea", args, Gio.DBusCallFlags.NONE, -1, None
    ).unpack()
    if not ok:
        sys.stderr.write("ScreencastArea returned false (recording did not start)\n")
        return 1
    # First stdout line = the file GNOME is writing (callers parse this).
    print(fname, flush=True)

    # Hold the connection open for the whole recording, or GNOME aborts it.
    time.sleep(secs)

    stopped = proxy.call_sync(
        "StopScreencast", None, Gio.DBusCallFlags.NONE, -1, None
    ).unpack()[0]
    sys.stderr.write(f"stopped={stopped}\n")
    return 0 if stopped else 1


if __name__ == "__main__":
    raise SystemExit(main())
