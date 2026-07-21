---
layout: post
title: "The Deep End"
date: 2026-07-21
tags: [ai, development, gamedev, rust, bevy]
---

I ended the last watch with a promise — *the sea gets deeper* — and then spent the next twenty-four hours making good on it in the most literal way I could: I had the agents tear out the ocean and rebuild it from the wave up. Not tune it. Not repaint it. Replace the whole thing, from analytic waves to a real spectral sea synthesised on the GPU.

It fought back for the entire watch. It rendered flat, then inside-out, then floated the ship at the wrong height, then cracked apart at the horizon. Somewhere in the middle of that, almost as a palate cleanser, the agents turned on their own codebase and filed and fixed two hundred commits' worth of their own mistakes. And by nightfall the islands had gone green. Long day.

![The new spectral ocean stretching out to a forested island on the horizon](/log/assets/img/irontide-w3-ocean.jpg)
*The sea gets deeper: last week's stack of sine waves is gone, replaced by a spectral ocean synthesised on the GPU every frame — long swell under short chop under fine ripple, none of it repeating. And on the horizon, islands that have started to grow forests.*

## First light — a new ocean, born flat

Last week's sea was a stack of sine waves — cheap, cheerful, and about as deep as a puddle no matter how it looked. The replacement is the real thing: an ocean spectrum sampled in frequency space and turned into a heightfield by an **inverse FFT on the GPU** every frame — the Tessendorf method, the same family of maths behind the water in films. It gives you a sea that actually interferes with itself: long swell under short chop under fine ripple, none of it repeating.

The first time it ran, the ocean was dead flat.

Not broken-flat — *subtly* flat. The waves were there in the data, the normals shimmered, the foam picked out crests that existed only in the shading. But the surface itself didn't move. The diagnosis, once it landed, is one of my favourite commit titles of the whole project:

> THE wave bug: stop dividing the inverse-FFT by N² (geometry was micron-scale)

The synthesis was being divided by N² — the normalisation you use for a round-trip *there-and-back* FFT, not for a one-way synthesis — which shrank every wave by a factor of about sixty-five thousand. The ocean was, in the agent's words, *"a flat mesh with a pixel shader"*: all the visible detail coming from the slope-based normals, the actual geometry displaced by microns. What finally cracked it was the oldest trick there is — hard-code a known sine wave into the vertex shader. The mesh heaved. So the displacement *path* worked; the *data* was three orders of magnitude too small. You cannot reason your way to that. You have to make the surface lie to you on purpose until it tells the truth.

## Forenoon — the sea turns inside out

With the waves the right size, the storm came up — and the ocean turned into a landscape of *"rolling hills with steep valleys,"* flat-topped mesas with sharp trenches between them, and the ship *"got overrun by water."*

The waves were inverted. A choppy-wave FFT carries a sign convention — the textbook writes it one way, this pipeline needs the other — and with the sign flipped, the sharp part of each wave pointed down instead of up. The tell that settled it was numeric, not visual: a real sea is skewed *positive* — sharp crests, round troughs — so the surface's height skewness has to come out above zero. It was coming out negative. Flip the `i`, and the sea stood back up the right way.

![A spectral storm at dusk — big peaked crests and driving rain around a pitching sloop](/log/assets/img/irontide-w3-storm.jpg)
*The same ocean in a storm at dusk: bigger, meaner, peaked crests with the rain sheet driving across them. Getting one sign right turned "rolling hills with steep valleys" back into weather you'd actually fear.*

## Afternoon — exactly half

Then the ship stopped sitting *in* the water. It hung in the air over the troughs and got buried under the crests; the floating crates did the same; the fish, memorably, *hovered over the wave valleys like they were paved.* Everything that floats was reading the wrong height.

This one took a while because it was invisible to the obvious test. The buoyancy runs on the CPU — a second, cheaper copy of the ocean that the physics can sample — and every earlier calibration had compared that CPU copy to *itself*, never to the actual thing on screen. When someone finally lined the CPU field up against the GPU render, the answer was almost insultingly clean: the CPU field was **exactly half** the amplitude of the rendered sea. The GPU's full-plane FFT sums each wave with its mirror-image partner and gets a factor of two for free; the CPU sum had only ever counted one side. The fix was a single constant — a Hermitian gain of 2.0 — and the number it produced matched, to two significant figures, the fudge factor the human director had already dialled in *by hand and by eye* weeks earlier: "buoy scale 2.1." The maths and the eyeball had been right about the same number the whole time.

There's a workflow footnote here I can't resist. Partway through this hunt, one analysis agent produced a confident, tidy reimplementation of the whole spectrum on the CPU and declared the ratio was two — *for the wrong reason*, off by a subtle truncation error. Two other agents were running purely as adversarial reviewers, and both of them refused to sign off and picked the reimplementation apart. An agent got it right; another agent got it wrong; and the process caught the wrong one before it reached me. That's the part of this I still find slightly uncanny.

And they caught themselves the other way, too. The regression test guarding the wave-sign fix turned out to be *statistically underpowered* — the faint skewness signal it checked was sitting inside the sampling noise of its own too-small grid, so it had been passing on luck rather than proof. The agents noticed, and re-ran it on a grid big enough to actually mean something.

## The other watch — two hundred small correctnesses

I keep telling you the ocean was the headline. It was. But threaded straight through the same day is the least glamorous and possibly most instructive thing that happened all week: the agents turned on their own code and, across roughly **two hundred commits**, fixed, pinned and un-broke it — almost every one a single tiny issue on its own branch, with a test and a green clippy line before it merged.

A big share was performance the agents *themselves* had regressed — the death by a thousand per-frame cuts that AI-written code is especially prone to, because each line looks innocent in isolation. The interaction atlas was cloning a fresh megabyte onto the heap every single frame, *even when the whole system was switched off*. The market was recomputing supply and demand across every port sixty times a second, for price drift no human could perceive between frames. The performance profiler was counting the UI cost twice and cheerfully reporting a breakdown that summed past 100% of the frame. And my favourite — a safety cap that did precisely nothing:

> The safety bailout was `if attempts > 16 { continue; }`, but `continue` re-enters the SAME loop, so the cap accomplished nothing.

The other big share was correctness, and this is where it got genuinely impressive. The unsinkable "ghost ship" from a few weeks back — crew hits zero, the game refuses to end, you sail on as a crewless revenant — was finally hunted down and then *proven* gone, not with a couple of tests but by brute force: a search of **3.37 million** starting states and an exhaustive sweep of **3.19 billion** transitions, confirming no surviving unsinkable state anywhere in the machine. A boarding-loot formula was quietly computing an add as a multiply — `100 + 100*60 = 6100` gold for a scuttled pirate, while the genuinely loot-heavy targets paid nothing. And a whole family of "the game is lying to me" bugs got fixed by making the game *admit the rule*: a small system now writes a captain's-log line and a toast whenever a rule fires silently — "Speed capped — harvesting" instead of a throttle that just refuses and makes you file a bug against yourself.

And some of it was simply the kind of thing you fix at 2 a.m.:

> Stop the game stealing OS focus every frame — alt-tab works again

> Fix mojibake (—/°/× double-encoded) in UI panel text — 30 instances across four files

None of that is in a trailer. All of it is the flywheel: agents are extraordinary at work that has a *checkable* right answer — a lint, a doc that disagrees with the code, a buffer uploaded twice, a state machine you can exhaustively search — and this was a whole day of them grinding that seam while the ocean cooked.

## Dusk — a horizon that holds, and a colour

Back to the sea. Two problems left before it was shippable.

The first was that the new ocean is drawn with a level-of-detail scheme — fine mesh near the ship, coarse toward the horizon — and the rings kept **cracking apart** as you sailed, thin seams of sky showing through the water. Two reviewer agents had earlier "proven" the scheme watertight by reasoning about it in the abstract. They were wrong, and the note left for the next agent is a lesson I'd carve over the door:

> verify CDLOD by tracing concrete world coordinates at a concrete worst-case ship offset — abstract reasoning is worthless here.

The second was colour. A spectral ocean gives you motion for free but not mood; out of the box it's grey. The surface-colour pass put in a deep saturated blue, a depth ramp so the water darkens with the waves, real sun glint surviving all the way through the new HDR pipeline into the bloom, and a fade so the seabed dissolves into the deep instead of showing you the mesh edge. And it forced an art-direction decision that had been creeping up for days: the sea had become *too physically real* to pull off the flat, graphic Wind Waker look I'd half-imagined. So we said it out loud and aimed somewhere achievable — Sea of Thieves — and wrote down the rule that governs every ocean change from here:

> judge ocean work by felt impact, not just accuracy.

Because the ocean is what you're looking at roughly eighty per cent of the time. It has to be two things at once — beautiful, and terrifying — and neither of those is something a test can tell me I've hit.

![Golden-hour sun setting over the deep blue spectral sea, ship silhouetted, islands on the horizon](/log/assets/img/irontide-w3-golden.jpg)
*Colour is the last thing you add. A saturated blue, a depth ramp that darkens with the waves, and real sun-glint surviving the new HDR pipeline all the way into the bloom — judged, in the end, by felt impact, not accuracy.*

## Nightfall — the islands go green

The last stretch of the watch left the water alone and went ashore. The islands had been *"reading as smooth green blobs"* — clean cones and domes with rule-painted bands, or as the commit put it, *"this is math"* — so they got a deliberately stylised, *"twisted / chiseled / banged-up"* look and a set of **stylised rocks built from the convex hull of a cloud of jittered points**, faceted and chunky and pointedly not photoreal. Each archetype got its own profile so they stop looking like siblings. And after someone finally put a number on it — peaks of 145 to 270 metres beside a ten-metre mast, *towering over the ship by twelve to twenty-five times* — the islands were scaled down about the waterline to a believable height, beaches left where they were.

Then the big one: foliage. A staged canopy-and-palm system went in across an evening of very honest commit messages — a canopy draped over the terrain contour, ellipsoid tree crowns, beach-facing palms, trunks anchoring the canopy edges so it stops reading as a floating green blob, billboard palms for distant islands. Every step has its failure logged right next to it: the canopy came out too orange and had to be de-oranged; a texture called "macro noise," meant to be soft low-frequency modulation, turned out to be *literal halftone dots* and was stippling the grass with a regular polka pattern; and shrinking the islands had quietly dropped every beach *below* the height band the palm-placement code allowed, so the palms all fled inland to a green ring you never see from the sea and left the beaches bare until it was caught. The very last commit of the whole watch is the one that caps it: cramming palms onto a dense island at the highest setting hit *five to seven thousand palms per island* with no distance culling, and crashed the game clean out of memory. The day ended, fittingly, on a bug the agents made by growing the world too lush.

![A stylised forested island with a lighthouse across the deep spectral sea](/log/assets/img/irontide-w3-island.jpg)
*Ashore, sort of: a stylised island under its new forest, a lighthouse on the headland, seen across the deep sea. By the end of the watch the islands had beaches, palms that lean toward the water, and canopy that reads from a mile out.*

## What the watch taught

The ocean rewrite is the biggest single bet the project has made so far, and it's also the least checkable. Nothing about "the storm should feel dangerous" survives contact with an assert. The whole ocean day was human-in-the-loop in a way the rest of the work isn't — me watching a surface and saying *deeper, meaner, more,* the agents translating that into a sign flip or a gain constant or a colour ramp, and neither of us able to prove the result except by looking at it.

And then, running underneath, the exact opposite: two hundred commits of work with crisp right answers, which the agents closed out almost without me. That's the real shape of this whole experiment in one day — agents own the checkable, I own the *felt*, and the interesting, expensive, valuable ground is the seam where a felt thing ("too flat," "too grey," "overrun by water") has to be turned into a checkable one ("skewness must be positive," "gain is exactly 2.0") before an agent can finish it.

## The numbers

| Metric | Value |
|---|---|
| Fictional hours | 24 |
| Commits | 376 |
| Busiest burst | 121 commits |
| Rust code | ~214,000 → ~236,000 lines across ~48 crates |
| WGSL shader code | 74 → 80 files (~22,700 lines) — the ocean rewrite's compute shaders |
| Issue tracker | #337 → #782 |
| The ocean, off-by | 65,000× (flat), then inverted, then exactly ½ |
| Hand-dialled vs derived buoyancy | 2.1 (by eye) vs 2.0 (by maths) |

## Where this lands

The sea has a floor now. It moves like water that knows how deep it is, it takes the light, and it can turn genuinely nasty in a storm. What it can't yet do is let you *see* into it — walk a sloop up to a beach and the shallows are still an opaque blue wall right where they should be turning clear and green over the sand.

That's next. **Next: I make the deep sea shallow — clear water at the beaches, the seabed showing through — and find out the hard way that a ship's wake can carve a canyon into the sea that never heals.**
