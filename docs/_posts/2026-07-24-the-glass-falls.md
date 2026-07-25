---
layout: post
title: "The Glass Falls"
date: 2026-07-24 23:40:00 +0200
tags: [ai, development, gamedev, rust, bevy]
---

I ended the last watch pointing at the one part of the screen that was still a painting: the sky. There was weather in the game, but it was a number on a dial — a storm was a value between 0 and 1 that lived everywhere and nowhere at once. You couldn't sail toward it or away from it, because it had no *where*. Over the next twenty-four hours the agents gave the weather a place, taught the sea to foam like water instead of like a texture, and stopped the islands being circles. It is the most the world has ever changed in a single watch, and almost none of it is a system you can point a unit test at.

The title is a sailor's phrase. When the barometer — the glass — starts dropping, weather is coming, and you have hours, not minutes, to do something about it. That sentence is now literally true in Iron Tide, which is the whole story of this watch in one line.

<video src="/log/assets/vid/irontide-w5-storm-video.mp4" poster="/log/assets/img/irontide-w5-storm-video-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*Steaming through a storm cell: driving rain, a heaving sea that foams like water, a mesh cloud bank overhead, and a barometer reading 975 down in the HUD. A watch ago this was a number on a dial.*

## First light — weather becomes a place

The old weather was a global scalar. One number, `storm_intensity`, shared by the entire ocean. Rain everywhere or rain nowhere. The commit that opens this watch throws that out and replaces it with the sentence I'd been trying to get to for three posts:

> Weather becomes a *place*: storms are local cells you sail around, not a global scalar.

Underneath is a **closed-form storm field** — a deterministic function of `(seed, hour, position)`. There's no simulation ticking away in the background, no saved storm state to corrupt: you hand it where you are and what time it is, and it tells you the wind, the wave height, the rain, the sky colour, and the barometer reading *at that exact spot*. Because it's a pure function of the clock, it's automatically replay-safe and survives save/load for free — the storm that's bearing down on you is derived fresh from the persisted time-of-day, not stored anywhere.

What that buys, in play, is the thing the teaser promised. A storm is now a cell sitting at a place on the water, with a cyclonic wind wheeling around it, drifting on its own track. You can see it from about eight kilometres out: the sky darkens toward its bearing and paints a leaden anvil wall on the horizon — measured at 40% darker toward a cell than away from it. The barometer in the HUD starts to fall. The nav chart marks the cell with a bearing, a distance, and an ETA. And then it's your call — bear away and add hours to the passage, or drive through the shoulder of it and take the beating to save the time. Weather stopped being something that happens *to* the whole world at once and became a feature of the map you navigate around.

![A storm cell overhead — dark sky, driving rain, a low mesh cloud bank, and big peaked waves around a small ship](/log/assets/img/irontide-w5-storm.jpg)
*Inside a cell. The sky, the rain, the wave height, and the light are all sampled from one closed-form field at the ship's position — cross the storm's edge and every one of them changes together.*

The same rewrite dragged three dead things back to life. The **moon** had been written into the sky every frame at zero intensity — literally dark code. Worse, when someone did turn it on, the old crater routine sampled a hash at nine thousand times the angular offset and aliased the moon into a giant white starburst the instant it lit. The new block is a clean soft disc with a smooth phase terminator, low-frequency maria, and a halo that dims under storm cloud. And **cloud shadows** now sweep the whole sea, driven off the same shared uniform as everything else, so a passing cloud drags a real shadow across the water beneath it.

## Forenoon — clouds you can see at a place, lightning that picks a mast

If a storm is a mass of air sitting somewhere, it needs to *look* like a mass sitting somewhere. So the clouds became geometry. A pooled set of lumpy low-poly **mesh clouds** is pinned to each storm cell's centre — which already bakes in the cell's drift — so the cloud bank is a thing you see at a place, building over the storm and moving with it, not a screen-space texture that follows the camera. Over the watch these got a full authored lifecycle: they form, mature, and dissipate rather than blinking in and out.

Then the part I'd most wanted and least believed we'd get cleanly: **lightning that hits a target.** A peak-capped flash lifts the scene brightness 1.8× without ever blowing to white, strobes the cloud, and draws a jagged emissive bolt. Thunder is delayed by `distance / 343` — the actual speed of sound — so a strike two kilometres away cracks and then rumbles a full six seconds later. There's even a small tooling detail I love: a script synthesises three separate thunder sounds — a sharp close crack, a mid boom, a long distant roll — and the game picks which one to play by how far away the strike was, so a storm on the far horizon *telegraphs itself* as rolling thunder from cells up to eight kilometres out before you can see a thing.

![A jagged white lightning bolt striking down at a small ship in a dark, rain-lashed storm sea](/log/assets/img/irontide-w5-lightning.jpg)
*A latched strike. The bolt is a jagged emissive mesh, the flash lifts the whole scene 1.8× without blowing to white, and the thunder that follows is delayed by the real speed of sound.*

And lightning can kill you — but only as a story beat, never as a dice roll. This is the line the whole weather-damage system is built around, and the agents held it precisely:

> Weather-only attrition **never** takes hull below the 40–45% floor, never opens the boarding window, never game-overs any hull class. Weather sinking is impossible without **≥ 2 ignored catastrophe warnings.**

So a gale grinds your hull down and frightens you, but it cannot, by itself, sink you. What *can* sink you is a telegraphed catastrophe you ignored twice — a mast-strike fire you didn't put out, a broach at full sail in the teeth of it — which drops the hull to zero and plays a six-second founder: the ship tilts, drops, foams, groans, and hands you a voyage summary. Defeat stays a thing that happens *because of* a decision, not *to* you at random. Every one of those criteria is checkable headless, which is the only reason I trust it: transient things like a lightning flash get a `latch` command so a single screenshot can catch them deterministically.

## Midday — a sea of mist

The other navigation feature of the watch is the one I'm quietly proudest of, because it turns a rendering effect into a reason to slow down. **Fog banks.**

![At dawn, a ship approaches an island whose summit rises out of a low bank of sea mist, its shoreline still drowned in fog](/log/assets/img/irontide-w5-fog.jpg)
*Dawn, fog at three-quarter strength. The mist hugs the sea and thins with height, so the island's summit breaks clear into the sunrise while its shore is still lost — you read the peak long before you can see where to land.*

It's a second closed-form field, independent of the storms — smooth value-noise thresholded into navigable *banks* rather than a uniform haze, so fog has edges you cross. It's time-gated the way real sea fog is: densest around four in the morning, burning off by late afternoon. And it's height-gated, which is the detail that makes it work — the mist hugs the sea surface and thins with altitude, so an island doesn't sit in a grey soup, it *rises out of* one. The peak breaks clear into sunlight while the shore is still drowned. Sail toward a fog bank at dawn and the world closes to a few hundred metres of pale water; then a dark summit lifts above the mist, and only as you get close does the coastline resolve underneath it. The fog is painted onto everything — ocean, terrain, rock, flora, props — so the trees drown *with* the ground instead of hanging bright above a foggy island, which was the bug that made an earlier attempt look like a cardboard cut-out.

## Afternoon — the great equalizer

Weather that you can see and route around is atmosphere. Weather that changes a fight is a mechanic. Combat used to be entirely weather-blind — the player, enemy ships, and harbour batteries all shot with identical accuracy in a flat calm or the teeth of a gale. Now heavy seas heave the deck so no gun crew can hold a line, and a fog bank blinds the gun layers before it ever shortens the range.

The design rule the agents wrote for it is the important part:

> SYMMETRIC by design: everyone's aim degrades, nobody changes behaviour — the "great equalizer", not an escape hatch.

A storm doesn't make the enemy dumber or hand you an exit; it scatters *everyone's* shots, including yours, and shortens the range a target can be engaged at for both sides. The shore batteries — which are otherwise a perfect lead solution and will delete you at range in clear weather — get their entire error budget from the weather at their own position. So a storm is the moment a small ship can slip past a fortified harbour that would obliterate it on a calm day. And it's a pure, unit-tested model where calm weather is the identity function: zero storm, zero fog, and every shot is pinpoint exactly as before. The weather is the only thing that changed, so there's nothing else to blame when a fight feels different.

## The long afternoon — fifty rounds on foam

Now the part that is the most honest picture of what building a game this way actually looks like.

The ocean's *shape* has been right since the spectral rebuild two watches ago — it moves like deep water. But its foam still read as a texture laid on top: a uniform fizz, a Voronoi net, tram-lines along every crest. Fixing that took the single longest sustained grind of the whole project — **something like fifty numbered rounds** of foam architecture over a few days, and the commit log reads like a man arguing with the sea: *travelling foam-front model. Ridge-line injection in the sim. The front deposits the trail. Kill the boat-sized dim blotches. Distance-adaptive band width — close fronts no longer ship-sized. Ragged near fronts — texture bites the band up close.* Round 40. Round 46. Round 51. A couple of rounds were reverted the same day they landed.

What made it eventually converge wasn't a cleverer noise function — it was that the agents wrote themselves an *art brief* first. Before touching the shader they did a reference-frame analysis against a set of real ocean screenshots, and the study reads exactly like an artist's notes:

> Foam is organized into selected events, not applied to every geometric crest. Most ordinary water remains clean. A single event normally contains three readable ages: a fresh high-contrast crest blade; a softer dragged body behind it; fine torn chips visible only nearby. The negative space is as important as the mark. Shapes start, stop, branch, rejoin, and leave large organic holes.

And then, the sentence that governed the whole pass:

> Foam is a material in the scene's lighting, not an emissive white decal. A foam implementation that stays equally white at noon, dusk, and under cloud is wrong even if its mask is attractive.

![A stormy dusk sea seen low and close — foam riding the crests in torn streaks with clean water between the events](/log/assets/img/irontide-w5-foam.jpg)
*The payoff of the grind: foam as selected events with real gaps between them, riding the crests and dragging into torn residue behind — not a uniform fizz laid over every wave.*

That's the thing I keep relearning. The agents are lethally effective once the target is *measurable* — "the foam band must narrow with distance," "residue in shade falls toward blue-grey" — and they flail when it's "make it prettier." Fifty rounds is what it costs to turn "prettier" into a list of measurable statements, one revert at a time. The watch ended by **retiring the analytic ocean path entirely** — the old sum-of-sines fallback is gone, the spectral sea with its new layered, age-tinted, wave-driven foam is now the only ocean the game has. There is no going back to the puddle.

## Evening — the world stops being placeholder

While the sky and the sea were being rebuilt, the land quietly stopped looking generated.

The islands were the tell. Every one of them charted as a near-identical fuzzy circle, because every recipe's waterline was a centred apron disc and a ±12% size jitter just reads as *copies*. The fix is a **seeded macro shape transform** baked into each island — a rotation, an anisotropic squash, angular lobe bites taken out of the coast, a macro warp — so no two islands share a silhouette any more, plus two genuinely new shapes: a crescent bay island and an isthmus of two headlands joined by a sandbar. In the same pass the old voxel island generator was retired, leaving the SDF generator as the sole source of land, and the grounding collision was rebuilt to bake a 512-resolution heightfield so the sea floor you run aground on matches the cliffs you can see, to sub-voxel accuracy. The nav chart caught up too: an island is now drawn as its **real traced coastline**, not a dot.

The rocks became one system instead of two — a procedural stylized rock sculptor feeding both the big landscape formations and the small scattered props through a single visual pipeline, so a boulder on the beach and the headland it sits under are finally made of the same stone. And the last of the old canopy-shell blob — the green lump that used to stand in for foliage — was replaced with real flora and an under-canopy gloom, with the grass chunked and distance-culled so it's dense underfoot near the shore and gone by the time it would cost you anything.

None of that is glamorous and none of it has a teaser to honour. It's the unglamorous half of the watch: the systems that were "good enough to prototype with" being made actually good, one seeded transform and one unified pipeline at a time.

## What the watch taught

Two things, pulling in opposite directions, which is the usual shape of it.

The first is that **the closed-form field is the right primitive for a world this size.** Both the storms and the fog are pure functions of `(seed, hour, position)` — no simulation state, no save file, no desync, deterministic and replayable and headless-verifiable. That's what let the agents build a weather system with real teeth — lightning that sinks you, fog that hides an island, storms that decide a fight — and still assert every bit of it in a test. When the world is a function, you can check the world.

The second is the fifty rounds of foam, which is the exact opposite lesson and just as true. Some of the most important things in a game — does the sea look like water, does a storm feel dangerous, does foam read as foam — have no assert, and the only way through is to turn the felt thing into a measurable one and then grind, with reverts, until the numbers and the eye agree. The agents did the grinding tirelessly, which is their gift. Writing the art brief that made the grinding *converge* was the human hour that mattered most in the whole watch.

## The numbers

| Metric | Value |
|---|---|
| Fictional hours | 24 |
| Commits | 92 |
| Busiest burst | 35 commits |
| Rust code | ~271,000 → ~296,000 lines across 53 crates |
| WGSL shader code | 98 → 109 files (~28,200 lines) |
| Issue tracker | up to #1651 |
| Rounds to get ocean foam right | ~50 (a couple reverted same-day) |
| How far a storm now telegraphs | ~8 km (sky wall + falling barometer) |
| Thunder delay | `distance / 343` — the real speed of sound |
| Weather-only hull floor | 40–45% (a gale frightens you; it can't sink you) |

## Where this lands

The sky is a place now. A storm sits somewhere on the water with a wall of cloud over it and lightning in it; you watch the glass fall and decide whether to run. Fog rolls in at dawn and islands rise out of it. The sea foams like water and the land has stopped repeating itself. For the first time the whole frame — sky, sea, and shore — is pulling in the same direction, and none of the three is obviously the weak one.

Which means the next thing to fix isn't a *look* at all. The world is finally convincing enough that the thin part is what you *do* in it. The economy is still a spreadsheet with a coat of paint; a voyage is still mostly sailing from a place that sells low to a place that buys high. It's time the trading was as alive as the weather.

**Next: I go below the waterline of the economy — supply and demand that actually move, ports that remember you, news that ripples through prices, and a reason to choose one cargo over another beyond the number in the ledger.**
