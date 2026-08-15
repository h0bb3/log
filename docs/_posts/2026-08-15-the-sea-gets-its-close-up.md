---
layout: post
title: "The Sea Gets Its Close-Up"
date: 2026-08-15 21:30:00 +0200
tags: [ai, development, gamedev, rust, bevy, aigamedev]
---

It's been over two weeks since the last post — the longest quiet stretch since this log started. Not because nothing happened. Because *everything* happened, and one of the things that happened was ripping the ocean itself out and rebuilding it, and I didn't want to write "the water looks better, trust me" without being able to show it moving.

Last post ended with a promise: *the map stops being where the game is played.* Two weeks later the sea has things floating in it worth steering for, a harpoon to take them with, a hull that genuinely floats instead of pretending to, and a completely rebuilt water surface — new spectral resolution, new whitecaps, real wind-blown spray. The agent shot a fresh reel of all of it, at the helm and behind the camera, same as before. Watch it with sound on; the music and the storm are the game's own audio.

<video src="/log/assets/vid/irontide-ocean-reel.mp4" poster="/log/assets/img/irontide-ocean-reel-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*One day at sea, four scenes: steaming through a moderate afternoon swell, a slow orbit at golden hour, harpooning glowing tidegleam at dusk, and a storm with the new wind-borne spray. Shot in-engine by the agent on its own capture rig.*

## Things worth leaving the map for

The teaser wasn't rhetorical. A route you can plot on the chart is a route the chart can sail for you; the sea only matters if it holds things the chart can't see. So the fortnight's first arc was filling the water.

**The harpoon got real.** It started as a click — point at a tidegleam bloom, cargo appears. That's a spreadsheet wearing a boat costume. It took five rewrites to become a *thing that happens in the world*: the harpoon now flies a real arc from an actual gun mount (whichever one bears on the target — if none does, you turn the ship), trailing a rope that uncoils from a spiral as it goes. Hits reel the catch back through the water to the hull. Misses fly out, splash, and bob there, mocking you. If your hold is full, the catch bobs too, released at your stern for whoever comes next. None of this is faster than the old click. All of it is better, because now there's a *throw*, and a throw can be watched, missed, and gotten good at.

![The harpoon rope uncoiling mid-flight at dusk](/log/assets/img/irontide-harpoon-rope.jpg)
*The rope uncoiling behind the harpoon, mid-flight. Five iterations: a click, a tether, a spiral, a physical fly-out, and finally this.*

**The water holds salvage now.** All floating pickups — crystals, crates, cargo — went through one unified floating-objects system. Fleeing traders jettison cargo to buy their escape (chase or take the bribe: a decision). Sunk ships spill their manifests. A radio call gives you salvage as a range and a bearing — something to *steer by*, not a map marker. And if you come alongside flotsam at dead-slow, under two knots, your hull just takes it aboard: no clicking, no menu, seamanship as the interface.

## The boat became a boat

Under all of this sits the fortnight's quietest big change: the ship no longer *follows* the waves — it **floats**. The old motion was a kinematic chaser: sample the wave height, glue the hull to it. It looked fine right up until it didn't — big seas, wakes, close passes. The new solver computes displacement forces against the live wave field: the hull presses into water, the water presses back, and pitch, heave, and roll fall out of the physics instead of being faked from samples. The NPC ships now ride the same live wave field too — they follow the surface under their hulls instead of sitting bolted flat at sea level — so everything on the water moves like it belongs to the same sea. Bow spray scales with how hard the hull actually punches the sea.

## The ocean confession

Now the part I'd have preferred to skip, which is exactly why it's the longest section.

For months, the spectral ocean ran its wave simulation at a resolution a research document had called *"the sweet spot"* — a number that arrived with no derivation, no profiling, nothing. It got baked into shader structure, then into code comments, and from there every later investigation inherited it as ground truth. Nobody re-checked it, including me, including the agent — *especially* the agent, which will happily cite a confident comment as evidence, because a comment is data and doubt is not.

Where it finally bit: **whitecaps**. Foam on a crest isn't painted on — it's derived from how sharply the water surface folds, which is a much finer signal than the wave shape itself. Ask for foam detail the simulation literally cannot resolve, and no amount of tuning downstream can put it back. We spent a solid week tuning anyway — dozens of iterations, some of them approved and then drifted past — before a post-mortem traced the whole thing to that one unverified constant. The week's whitecap branch got parked, unmerged. The post-mortem was worth more than the code.

Then we rebuilt it properly. The wave field now runs at **four times the resolution per axis — sixteen times the spectral information** — across all three cascades (swell, chop, ripple, with deliberately coprime tile sizes so they never visibly repeat). On top of the new field: whitecaps re-derived per sea state instead of one global gain, and a proper **sea-spray system** — particles born on live crests, torn off by the wind, lit by the scene. The internal toggle for the new look is literally called the *movie* ocean, because that was the acceptance test we finally wrote down: would a stranger, shown a frame of our water next to a frame of film-quality reference footage, say they're from the same world? Prose verdicts void; side-by-sides or it didn't happen; and never, ever judge water from a single frame — every defect that matters is a defect of *motion*.

Three new rules went into the engineering contract in blood: any constant without a derivation is a guess and must be labeled as one; a resolution sized for a signal is not sized for the signal's derivatives; and acceptance screenshots come from the player's camera, not a drone 55 metres up where every sin is forgiven.

The storm section of the reel is the payoff. That spray blowing off the crests is anchored to actual moving wave peaks, leaning with the actual wind.

## Also, the guns grew up

Shorter arc, same fortnight: the three gun types stopped being one gun with three hats. Calibre, scatter, range, and barrel count are now per-weapon truths — a carronade argues differently than a long gun — the rigs are authored as real articulated models swapped per deck socket, and the design doc now says what the mechanics already knew: boarding is a rope, and guns are not interchangeable. The sea also got a voice this window — a proper thunder overhaul, hull-crash and sail-shred impacts, crew wails, and a foghorn that sounds once, as a ship goes down, which I regret to report is the best sound in the game.

## The vertical cut

Phone version, same rules as last time — a true centre crop of the footage, not letterboxing:

<video src="/log/assets/vid/irontide-ocean-reel-vertical.mp4" poster="/log/assets/img/irontide-ocean-reel-vertical-poster.jpg" controls autoplay loop muted playsinline style="width:56%;height:auto;display:block;margin:0 auto"></video>
*The same day at sea, cut for a pocket. The chase cam keeps the ship centre-frame, so the crop keeps the story.*

## The numbers

| Metric | Value |
|---|---|
| Commits since last post | 119 |
| Harpoon rewrites until it felt thrown | 5 |
| Wave-field resolution | ×4 per axis, ×16 information, all 3 cascades |
| Whitecap-tuning branch parked unmerged | 1 (the post-mortem shipped instead) |
| New rules written in blood | 3 — label guesses, size for derivatives, judge from the deck |
| Ship motion | displacement forces on the live wave field; NPC hulls ride the same sea |
| Reel | shot + cut by the agent in-engine: 4 scenes, 2 formats, game audio |
| Generated-image assets | still zero |

## Where this lands

The pattern under the fortnight: every fake got replaced by the thing it was faking. A click became a thrown rope. A height-glued hull became displacement. A tuned-up foam texture became sixteen times the simulation. Each time, the fake had been *cheaper* — that was never the question. The question was which fakes the player's eye forgives, and on a screen that is eighty percent water, the answer for the sea turned out to be: none of them.

**Next: the guns are distinct, the crews have experience, and the raiders lead their shots. Time to find out if a fight on this water can be worth the powder.**
