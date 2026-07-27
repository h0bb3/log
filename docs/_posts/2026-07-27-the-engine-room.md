---
layout: post
title: "The Engine Room"
date: 2026-07-27 23:30:00 +0200
tags: [ai, development, gamedev, rust, bevy]
---

For five watches I've told this story forward — each post a day's worth of building, each one ending on a teaser for the next. Somewhere in the last watch the fiction caught up with the calendar. There isn't a comfortable two-week buffer to compress any more; the log is now standing on the same deck as the work. So before I go below the waterline of the economy — which is genuinely the next thing — I want to do something I haven't done yet: stop moving forward for one post and open the hatches on what's actually running down there.

This is the engine room. Three machines make the world you sail in — the sea, the land, and the sky — and each one is built on the same bet: **the world is a function, not a simulation.** You don't store it, you compute it, and because you compute it the same way every time, you can check it. If you're a technical reader, this is the post where I show you the shapes of the three machines without drowning you in the plumbing.

<video src="/log/assets/vid/irontide-w6-approach.mp4" poster="/log/assets/img/irontide-w6-approach-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*Steaming in on a claimed island at midday — clear turquoise water, a wake dragging foam, fair-weather mesh clouds, and a coastline of banded cliffs and dense flora rising ahead. Every element in that frame is computed from a seed and a clock; nothing is a painted backdrop. The rest of this post is how.*

## The sea

The ocean is the oldest and the most rebuilt part of the game, and it is now, start to finish, a **spectral ocean** — the same class of technique the film houses use. There's no sum-of-sines fallback left; the analytic puddle got retired two watches ago and the code that drew it is gone.

![A small steamship on clear turquoise water at midday, its wake foaming behind it, fair-weather mesh clouds above and a foliage-covered island with a lighthouse on the horizon](/log/assets/img/irontide-w6-water.jpg)
*Clear water at midday. The turquoise-over-depth shading, the wake foam, the refracted colour of the shallows — all of it comes off the spectral field and the depth prepass, not a painted texture.*

Here's the shape of it. A wave spectrum — **JONSWAP**, the standard empirical open-ocean energy curve, with **Donelan–Banner directional spreading** so the waves aren't all marching the same way — is baked once into a grid of complex amplitudes. Every frame that grid is evolved forward in time by the deep-water dispersion relation (ω = √(g·|k|), the real physics of how fast a wave of a given size travels), and then an **inverse FFT** turns that frequency-space field into an actual height field you can see. It runs entirely on the GPU as a compute pipeline — bake, evolve, a shared-memory radix-2 FFT, then an *assemble* pass — across **three cascades** at tile sizes of 401, 97 and 23 metres, so you get the long ocean swell and the fine chop from the same machine without one smearing the other. Two wave populations are summed on that grid: a wind-driven sea that responds to the live wind, and an independent **swell** that rolls in long and slow on its own heading.

The important discipline is that **the ship rides the sea that's drawn.** The hull doesn't bob on a separate cheap approximation — a CPU mirror of the exact same spectrum sums the dominant modes and does a nine-probe heave/pitch/roll solve against them, including the choppy "crest pile-up" un-warp so the hull sits on the crest that actually landed under it. When a storm lifts the wave amplitude, the same number drives both the pixels and the physics.

![A stormy dusk sea, low and close, foam riding the crests in torn streaks with clean water between the events](/log/assets/img/irontide-w5-foam.jpg)
*Foam as selected events. Most of the water is clean; foam is a maintained history buffer with three ages in it, gated so only a sparse set of crests break — not a fizz laid over every wave.*

The foam deserves its own paragraph because it was the single hardest thing to get right. It is **not** a white mask multiplied onto the crests. It's a persistent 512×512 history buffer, world-anchored and semi-Lagrangian-advected — meaning the foam is pinned to the water and drifts with it, not with the camera — carrying three ages at once: fresh breaker heads, the dragged wash behind them, and the fine dispersed residue. A "selected-breaker" gate decides which crests actually foam, so most of the sea stays clean and the marks read as events with gaps between them. And it's a *material in the scene's lighting*, not an emissive decal — foam in shade tips toward blue-grey instead of glowing white at midnight. Getting there took roughly fifty numbered rounds of arguing with the sea; I told that whole story last watch. The wake now feeds into it too, and the wake perturbs the actual shading normals, so the trail you cut catches the light instead of reading as flat paint on the surface.

The last piece is what happens near shore. Every island bakes a **water-depth field**, so shallow water goes clear and turquoise and shows the seabed through real screen-space refraction, deep water greens over and goes opaque, and the transition is keyed off the depth prepass rather than a hand-drawn shoreline. The old surf-band foam collar is gone; what's left at the waterline is a single crisp rim where anything solid sits just under the surface.

## The land

An island is a **signed distance field**, and — despite a lot of modules still carrying the word `voxel` in their names for historical reasons — the SDF generator is now the *only* thing that makes land. There's no second path.

The cook goes: stamp a macro shape as an SDF, displace its coast with fractal noise, assign interior rock materials, smooth, keep only the largest connected blob (no floating debris), deposit a surface layer, and mesh the whole thing with **surface nets** at three levels of detail. The finished island — mesh, heightfield, coastline, the lot — is serialised to a compact binary on disk, keyed by `(seed, quality, generation-version)`, so you pay the cook once and every later visit is a fast load. There's a single integer, `GEN_VERSION`, that gates the whole cache; bump it and every island in the world silently recooks. It's at 52.

The thing that stopped every island being a fuzzy circle is a **seeded macro-shape transform** baked into the field: a rotation, an anisotropic squash, angular "lobe bites" taken out of the coast at a few harmonics, and a low-frequency coast warp that's the one move allowed to push a headland *outward*. All of it derives from the island's seed, so the coarse preview, the final mesh, the editor and the tools all agree on the same silhouette. On top of that there are genuinely different recipes in the pool now — a crescent bay, an isthmus of two headlands joined by a sandbar, mesas, atolls, spires, sea arches — and about a third of islands roll one of those instead of the plain biome shape.

![A rocky, tree-covered island coastline in clear daylight — a low cliff of banded stone, grass and trees along the top, a rocky islet to one side, turquoise shallow water in front](/log/assets/img/irontide-w6-island.jpg)
*A coast, up close in daylight. The cliff stone, the loose islet and the boulders all come from one sculptor; the terrain material is chosen per-vertex from the true surface slope, so the near-vertical rock reads as stone even where the ground above it is grass; and the trees thin out into distance-culled impostors along the ridge.*

Two systems hang off that field and I'm fond of both. The **rocks** are one sculptor now, not two — an icosphere pushed into a superellipsoid, lumped with fractal noise, soft-flattened, decimated, and painted with a curvature-aware vertex colour — and the *same* sculptor builds both the big headland formations (several rocks smooth-union'd into one welded mass and remeshed once, so the necks are real geometry, not clipping) and the single boulder on the beach. A boulder and the cliff it sits under are finally made of the same stone. And the **terrain material** is decided per-vertex from the true surface normal: a slope rule paints rock on anything steep and grass on the gentle banks, so cliffs are stone even where the ground under them is green, without a texture seam.

Underneath the pretty part is the boring part that makes it playable: a **baked heightfield**, sub-voxel interpolated, at ~2.3-metre resolution for the final island, feeding grounding, camera clamp and creature constraints alike. The *bathymetry* — the depth your keel actually reads — is the shallower of two sources (the shore SDF's column-scanned seabed and the heightfield), and the ship probes it under the keel every frame: thrust bleeds off as clearance shrinks, a firm grind decelerates you at draft depth, and a seaward nudge walks a grounded hull back toward water so you can never wedge yourself onto a cliff forever. The nav chart got honest too — an island is drawn as its **real traced coastline**, marching-squares'd at the waterline and decimated, not a dot on the map.

Then the **foliage**, which is three cooperating layers. Trees are instanced — twelve biome archetypes with a few seeded variants each, placed by a height-aware dart-throw so trunks never intersect but low plants can tuck under a taller canopy, and the woody structure itself is an SDF: a skeleton of tapered round-cones smooth-min'd together and surface-netted, so a trunk flows into its boughs instead of Y-ing at a hard joint. Far trees swap to instanced impostor billboards that crossfade with the near mesh. Grass rides the same path — crosshatched cards stamped only where the *painted* mesh reads green-and-gentle, split into 40-metre chunks that cull with distance so it's dense underfoot and gone before it costs you anything. The whole canopy sways under **one global gust field** — trees bend about the base as a real rotation with a droop so the trunk arcs rather than stretches, and grass is root-pinned so the base stays put while the tip whips downwind — and the same gust rolls across palms, trees and grass together, so a front of wind crosses the whole island as one thing.

![Close up on a tropical island's shore — leaning palms and broadleaf trees over dense grass, a banded stone bank, and a strip of pale beach at the waterline](/log/assets/img/irontide-w6-tropical.jpg)
*The same three-layer system on a different biome — palms and broadleaf over dense grass on a tropical isle, where the temperate island a few frames up wore pines. Biome is just a different archetype set and material palette feeding the identical instanced pipeline.*

## The sky

Weather is the purest expression of the whole bet. It is a **closed-form field**: a pure function of `(world seed, absolute hour, position)`. There is no weather simulation ticking in the background, no storm state saved to disk that could desync or corrupt. You hand it where you are and what o'clock it is, and it returns the wind, the wave height, the rain, the cloud cover, the sky colour, and the barometer reading *at that spot*. Because it's a function of the persisted clock, it survives save/load for free and it's identical on replay.

Mechanically, the world tiles into 8-kilometre squares and each square-and-epoch rolls, deterministically, for at most one **storm cell** — a hashed dice-throw, spawn probability about 0.42. A live cell is closed-form all the way down: its centre is its spawn point plus drift times its age, its intensity is a smooth birth-plateau-death curve of its age, its wind wheels cyclonically around the eye, and its barometer reads `1013 − 38·intensity` hPa. Cells within range combine by a smooth union, so overlapping storms don't seam. Sample that field from the deck and you get a storm that sits *somewhere*, that you can see coming from eight kilometres out as a darkening wall and a falling glass, and that you route around or drive through as a choice.

![A storm cell overhead — dark sky, driving rain, a low mesh cloud bank, and big peaked waves around a small ship](/log/assets/img/irontide-w5-storm.jpg)
*A storm cell overhead. The cloud bank is real geometry — a watertight metaball surface pinned to the cell's centre — so it's a mass sitting at a place, drifting with the storm, not a texture stuck to the camera.*

The **clouds** are geometry, which surprised me that we got cleanly. Each cloud is a single watertight isosurface over a sum-of-Gaussians density field — a few dozen lumps — meshed with surface nets and sliced flat at the base for the condensation shelf. A small pool of these is pinned to the storm cells (which already carry the drift), plus a separate fair-weather pool for ambient sky. There is deliberately **no raymarching, no per-pixel noise, and no temporal AA** anywhere in the cloud path, because all three are landmines on the Intel-Arc/Mesa box I develop on; instead the meshes write a compact optical field into an order-independent blend, and a small multi-pass composite decodes it into lit, silver-lined cloud. One shared cloud-shadow field — world-anchored value noise, scrolled by the wind — is imported by the ocean, terrain, rock, props and flora, so a shadow patch crosses the sea-to-shore seam as a single coherent piece.

![Fair-weather cumulus over an open turquoise sea — each cloud a distinct lumpy 3D mass with a flattish base and a billowing top, faint god-ray shafts slanting through the blue](/log/assets/img/irontide-w6-clouds.jpg)
*Fair weather, no storm anywhere. You can read the clouds as *masses* — each one a lumpy watertight mesh with a flat condensation base and a billowing head, hanging at a place in the sky rather than smeared across the camera. The shafts top-right are the god-ray layer, gated off the sun's visible-disc fraction.*

**Lightning** picks a target and obeys the speed of sound. A strike near an active cell latches a flash — peak-capped at 1.7× scene brightness so it blooms instead of blowing to white — and draws a jagged emissive bolt as an additive mesh. Thunder is queued at `distance / 343` seconds, real physics, and its timbre is bucketed by distance, so a far strike telegraphs itself as a slow roll six seconds behind the flash. The `latch` command holds any of that for a single deterministic screenshot, which is the only reason I trust a flicker I can't otherwise catch.

**Fog** is a *second*, independent closed-form field, and it's the navigation feature I'm quietly proudest of. It's noise thresholded into navigable **banks** with edges you cross, not a uniform haze; it's time-gated to be densest around four in the morning and burn off by afternoon; and — the detail that makes it work — it's height-gated, hugging the sea and thinning with altitude, so an island doesn't sit in grey soup, it *rises out of* one. The same fog is applied to every surface — ocean, terrain, rock, flora — so the trees drown with the ground instead of hanging bright above a foggy island.

![At dawn, a ship approaches an island whose summit rises out of a low bank of sea mist while its shoreline is still lost in fog](/log/assets/img/irontide-w5-fog.jpg)
*Dawn fog. The mist is height-gated, so the peak breaks clear into the sunrise while the shore is still drowned — you read the island's summit long before you can see where to land.*

Above all of it, the sky itself is a CPU-evaluated blend of day, twilight and night whose three weights sum to exactly one; the sun and moon fade by an exact circular-segment disc-area curve so nothing pops at the horizon; the moon is an authored albedo with a procedural phase terminator painted across it; and the godrays and sun flare gate themselves off under storm cloud.

<video src="/log/assets/vid/irontide-w6-dusk.mp4" poster="/log/assets/img/irontide-w6-dusk-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*Dusk at sea off a tropical isle. Every part of this is the same closed-form sky: the day→twilight blend painting the gradient, the phase-lit moon rising to port, the god-ray shafts fanning from the set sun, the stars fading in as the night weight climbs — and a tropical headland on the horizon to starboard. Nothing here is a skybox.* And because the weather is a function that returns a number everywhere, combat can read it: heavy sea and fog scatter *everyone's* aim, symmetrically, sampled at each shooter's own position — the "great equaliser" that lets a small ship slip a fortified harbour in a gale that it could never pass on a calm day. Calm weather is the exact identity: zero storm, zero fog, every shot pinpoint, nothing else to blame.

## The living layer

None of that is the game; it's the stage. What moved on the stage this watch is the stuff that makes the world feel inhabited rather than rendered.

The **crew** stopped being an abstract number. Each hand is now a person with their own hit points; a broadside concentrates its wounds — one poor soul takes the brunt, the rest cascades to the next most hurt — and people die individually and reproducibly. There's a surgeon who heals the wounded *at sea* over time now, not just at the dock, and a badly-hurt specialist quietly loses their perk until they recover, so a healthy junior of the same trade steps up in the meantime. It all landed with 991 tests green, which is the sort of sentence that only matters if you've ever shipped the version where it wasn't.

The world grew eyes and motion, too. **Gull flocks** roost on the islands now — deterministic, real, and doubling as a landfinding cue: birds in the sky ahead mean shore beyond the haze, and a treeless summit gets its own flock so bare rock still reads as land. The **leviathans** learned to bend — their long bodies articulate through a turn off the head's path curvature instead of sliding sideways like a decal — and the small fish flick their tails harder when they accelerate. And the parts of the game that live *between* voyages started remembering: contracts and the islands you've claimed now persist across a session, and the chart marks where your active contract wants you to go.

## The codebase grew up

One more thing, for the engineers. The `iron_tide` monolith — which was a single 7,500-line `main.rs` not so many watches ago — has been quietly splintering into domain crates: `iron_tide_ocean`, `iron_tide_weather`, `iron_tide_terrain`, `iron_tide_flora`, `iron_tide_rock`, `iron_tide_world`, `iron_tide_render`, `iron_tide_vfx`, `iron_tide_crew`, `iron_tide_combat_core`, `iron_tide_economy`. Each of the three machines in this post now lives in its own crate with its own tests, and the shipping game is the thing that wires them together. That's not glamorous, and there's no screenshot of it, but it's the difference between a prototype and something you can keep building on — and it's most of why the agents can work on the sky without breaking the sea.

## The numbers

| Metric | Value |
|---|---|
| The bet | the world is a *function* of `(seed, hour, position)`, not a stored simulation |
| Ocean | GPU spectral inverse-FFT, JONSWAP + directional spread, **3 cascades** (401/97/23 m) |
| Foam | a persistent, world-anchored history buffer with **3 ages**, gated to selected crests |
| Islands | SDF-only generator, seeded macro-shape transform, cached at `GEN_VERSION` **52** |
| Grounding | baked heightfield at **~2.3 m**, bathymetry probe under the keel every frame |
| Foliage | instanced SDF trees + impostors, chunked grass, one global wind gust field |
| Weather | closed-form storm cells on **8 km** tiles; barometer `1013 − 38·intensity` hPa |
| Clouds | watertight metaball meshes, **no raymarch / no TAA** (Arc/Mesa-safe) |
| Thunder | delayed by `distance / 343` — the real speed of sound |
| Crew | per-member HP, surgeon heals at sea; **991 tests** green |
| Production Rust | ~258,000 lines, now spread across a dozen `iron_tide_*` domain crates |
| WGSL shaders | 109 files (~28,800 lines) |

## Where this lands

That's the machine. Three fields — sea, land, sky — each computed from a seed and a clock rather than stored, each one checkable precisely *because* it's a function, and a thin living layer of crew and gulls and sea-monsters moving on top. For the first time I can point at the whole frame and not find the weak one.

Which brings me back to the thing I've been putting off. The world is convincing now; the *trade* isn't. The economy is still a spreadsheet with a coat of paint — buy low here, sail, sell high there — and it doesn't move, doesn't remember you, doesn't ripple. Everything above is the stage. It's time to make the play worth staging.

**Next: I go below the waterline of the economy — supply and demand that actually move, ports that remember you, news that ripples through prices, and a reason to choose one cargo over another beyond the number in the ledger.**
