---
layout: post
title: "The Agent Points the Camera"
date: 2026-07-28 15:40:00 +0200
tags: [ai, development, gamedev, rust, bevy, aigamedev]
---

I said the economy was next. It still is. But on the way there I tried to cut a trailer for this game, and discovered something that turned into a post of its own: **the AI agent that builds this game couldn't film it.** Not "filmed it badly" — *couldn't*. So it spent a couple of days building itself a camera department, and then it shot the thing below. Every framing, every move, every frame of it was set up and recorded by the agent, over an HTTP console it also wrote.

<video src="/log/assets/vid/irontide-trailer.mp4" poster="/log/assets/img/irontide-trailer-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*The trailer. No human hand touched the camera — it's a script of console commands: hold golden hour, orbit the ship, breach a leviathan and frame it, freeze a lightning strike, roll the recorder. The AI agent directed and shot it against an API it built for exactly this.*

If you've read this log before you know the premise: Iron Tide is built with an AI agent loop — the agent writes the code, plays the game, files its own bugs, fixes them. This is the first time the loop closed around the *marketing*.

## The problem: a game engine is not a film camera

Here's what happened the first time I asked the agent to make a reel. It drove the ship in a straight line, screen-recorded the window, and handed me eight seconds of a boat going forward. It was fine. It was also dull, and when I looked at *why*, every reason was the same reason: the agent had no director's tools. Specifically, it hit six walls:

1. **The camera could only teleport.** There was a free-fly camera, but over the API you could only *snap* it to a pose — `camera pos x y z`, done. No dolly, no orbit, no move-over-three-seconds. Every shot was a locked tripod or the default chase-cam.
2. **The clock wouldn't hold still.** A full in-game day runs in about two and a half real minutes, so by the time the agent framed a golden-hour shot, it was midnight. You could freeze time — but freezing time also froze the *ship*, so you couldn't have a moving shot at a chosen hour.
3. **The sea monster was unfilmable.** There's a deep-sea leviathan that surfaces rarely. The agent could force one to spawn, but it appeared 24 metres down and 90 metres away, its position wasn't in the API at all, and it never breached. You cannot frame what you cannot find.
4. **Lightning lasted 0.16 seconds.** The storms have real latched lightning — a jagged bolt and a scene-wide flash. At any capture rate below ~60fps the bolt falls *between* frames. The agent fired a dozen strikes and caught zero.
5. **The HUD was in every frame.** Screenshots came out clean, but *video* went through the desktop compositor, which grabs the whole window — compass, status bar, toasts. Every clip had to be cropped, losing the framing.
6. **The recorder died when the screen locked.** The only way to capture video was the OS screen-recorder, which records a black rectangle the moment the machine auto-locks. During a long shoot — say, while a shader recompiles — the screen locks, and you get nothing.

None of these is a *game* bug. They're the difference between a simulation and a camera. So the agent filed six issues under one epic — "make cinematic reels cheap to produce, headless" — and built the fixes.

## The fix: the agent builds a camera department

Six features, two pull requests, all merged. In plain terms, the agent gave itself:

- **A camera it can move.** `camera move` dollies from the current pose to a target over a duration with easing; `camera orbit` sweeps around a point, looking at it. It runs on real time, so it keeps moving *even when the simulation is paused* — you can crane across a frozen sea.
- **A clock it can hold.** `time hold 18` pins the *visual* time-of-day — sun, sky, light — at any hour, while the simulation keeps running underneath. Golden hour that stays golden while the ship sails.
- **A monster it can direct.** `debug monster <x> <z> surface` spawns the leviathan exactly where a shot needs it and *breaches* it at the waterline instead of hiding it in the deep. Every creature now reports its position, species and depth in the API, and `camera lookat creature` frames the nearest one.
- **Lightning it can freeze.** `debug lightning strike … hold 4` keeps the bolt and the flash on screen for four seconds instead of a sixth of one — long enough to land on any capture — and forces it bright and in-frame.
- **A clean lens.** `ui hide` drops the entire HUD, so the recording is only the world.
- **A recorder that doesn't care about the screen.** `capture rec start 30` writes the game's own internal render target — the clean, HUD-free image, the same one the screenshot endpoint serves — to a PNG frame sequence at a fixed rate. It's deterministic, it needs no compositor, and it works with the screen *locked*, because it never touches the window.

And one switch to tie the mundane parts together: `capture on` — a "safe to film" mode that stops the boiler burning coal, calls off the storm and combat damage, and shoos the pirates away, so a long take can't be interrupted by the ship running out of fuel or catching fire mid-shot.

Every one of these is a console verb, which means it's an API call, which means it's *scriptable*. The trailer up top is not a recording of me flying a camera. It's a list of those verbs, run in order, while the recorder rolled.

## The part that's actually the point

Here's why I think this belongs on r/aigamedev and not just in a devlog.

The interesting thing isn't that an AI wrote some camera code. It's the *shape* of the loop. The agent was given a goal it couldn't reach with its current tools ("make a good trailer"), it diagnosed *why* — six specific, unglamorous capability gaps — wrote them up as issues, implemented them across two reviewed-and-merged PRs with tests and a clean lint gate, verified each one at runtime (spawn a leviathan → confirm it surfaces in the API → frame it → screenshot it; fire a held strike → catch the bolt 1.5 seconds later; record 30fps for 2 seconds → get exactly 60 clean frames), and *then used the tools it built* to produce the artifact it was originally asked for. The trailer is the agent's self-portrait, shot with a camera it forged because the one it had wouldn't do.

I want to be precise about the human/AI split, because that's the honest interesting bit. I set the direction and the taste — what the trailer should feel like, which shots, art direction. The agent did the engineering and the execution: the API design, the Rust/Bevy systems, the tests, the shot scripting, the capture, the assembly. The art is stylized and hand-reasoned — WGSL shaders and low-poly meshes, no generated-image assets anywhere. This isn't "type a prompt, get a game." It's a human director and a very fast, very literal camera crew that will also, if you ask nicely, rebuild the camera.

## The numbers

| Metric | Value |
|---|---|
| The wall | six capability gaps between a *simulation* and a *camera* |
| The fix | 1 epic, 6 issues, 2 PRs, all merged to `main` |
| New director's verbs | `camera move`/`orbit`, `time hold`, `debug monster … surface`, `debug lightning … hold`, `ui hide`, `capture rec`, `capture on` |
| Recorder output | the game's clean internal render target — HUD-free, deterministic, works with the screen **locked** |
| Runtime-verified | leviathan surfaced + framed, held bolt caught 1.5s after firing, a 30fps/2s take wrote exactly 60 frames |
| Human's job | direction + taste; **the agent did the API, the systems, the tests, the shoot** |
| Generated-image assets | zero — stylized WGSL + low-poly, hand-reasoned |

## Where this lands

The trailer exists, and the thing I keep turning over is that the most useful feature the agent shipped this week wasn't in the *game* at all — it was a way for the agent to *see* the game and show it to you. The next reel isn't an afternoon of me flying a camera; it's a script, and the agent runs it.

The economy is still next. Supply and demand that actually move, ports that remember you, news that ripples through prices. But now, when that lands, the agent can film it itself.

**Next: I go below the waterline of the economy — and the agent shoots the results.**
