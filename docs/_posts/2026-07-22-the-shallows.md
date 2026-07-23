---
layout: post
title: "The Shallows"
date: 2026-07-22 23:45:00 +0200
tags: [ai, development, gamedev, rust, bevy]
---

Last watch ended with a promise and a threat: clear water at the beaches, and a wake that carves a canyon into the sea and never heals. Both landed inside the next twenty-four hours, along with a shipyard, a radio, a keel that finally knows how deep the water is, and — my favourite thing in the whole watch — the moment the agents turned around, audited the entire codebase, and filed two hundred and eleven bugs against their own work.

This is the first watch with moving pictures in the log. Stills have been quietly lying for me for three posts now: a screenshot of an ocean is a screenshot of a *painting* of an ocean. So everything below that moves, moves.

<video src="/log/assets/vid/irontide-w4-approach.mp4" poster="/log/assets/img/irontide-w4-approach-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*Steaming in on a lighthouse island. The band of turquoise around the shore is the whole point of this watch — that's water you can see through, over sand, and it wasn't there yesterday.*

## First light — the shallows go clear

The problem was easy to state and had already been closed three times: sail up to a beach and the water stayed an opaque blue wall right where real water goes clear and green over the sand. Three earlier rounds had each "fixed" it and each been wrong, because each of them treated it as a *look* — move the foam, retint the surface, warm up the sand — when it was a stack of four unrelated causes, three of which were upstream of anything you could see.

The fourth attempt actually took the shader apart:

1. A flat opaque teal tint was being painted over the shore *by horizontal distance from land*, burying the seabed exactly where the water is clearest.
2. The refraction tint underneath was a fixed turquoise, so even a hand's depth of water crushed the colour of the sand.
3. The surface itself was near-opaque everywhere — alpha 0.78 to 0.97 — so there was nothing to see through in the first place.
4. And the shore foam was drawn on a completely different rule, so wherever you *did* win some transparency, foam covered it back up.

The fix that stuck was structural rather than cosmetic. The flat distance-based tint came out entirely, and everything left standing — the refraction tint, the surface alpha, the foam — now keys on the **same** number: the real water column depth, read from the depth prepass, not from the wave height. Shallow flats go transparent (alpha down to 0.13) and drop the foam; steep coasts where deep water meets rock stay opaque and keep it. Because it's one gate, the transparency and the foam can never fight each other again. Three cosmetic attempts, one structural one — that ratio shows up over and over in this project.

![A sloop stopped dead at a cliff face in clear turquoise shallows, bow foam breaking against the rock](/log/assets/img/irontide-w4-cliff.jpg)
*The same water, close up — and the other half of the day's work. That hull is not gently coasting into the rock; it has stopped at the contour, on its own, because it now knows its own draft.*

## Forenoon — the canyon that never healed

Then the wake. The report from the deck was three separate complaints that turned out to be one bug:

> "anchor and it remains depressed for unforeseeable time"

> "wake doesn't rotate with the ship"

> "crate wake travels with the ship"

The ship carves its wake into a texture — an interaction atlas where each texel stores how far the sea is pushed down there, and every frame the whole thing decays back toward neutral. Neutral is 128. The decay was written as `(r + (128 - r) * rate) as u8`.

Read that again with the runtime decay rate in it, about 0.03 per frame. Any texel within about thirty-three units of neutral computes a step *smaller than one* — and `as u8` in Rust truncates. The step is discarded. The texel freezes off-neutral **forever**.

So every wake track in the game decayed smoothly down to roughly 95 and then simply stopped, and stayed there, as a permanent −0.39 m trench in the ocean. All three complaints fall straight out of that: the standing crescent wall behind an anchored ship is a frozen track. The wake that "doesn't rotate" is old frozen track lying along headings you sailed minutes ago. The ghost ring that "travels with the ship" is a fresh scar frozen at every place you stopped.

The best line in the diagnosis is the one that answers the question I'd actually asked:

> The bug is old, but today's depth lift (and the recent foam collar work) made the scars deep enough to dominate the seascape — which is why "it worked perfectly some days ago".

It had never worked. It had been invisible. Someone made the water displacement deeper for entirely unrelated reasons and, in doing so, turned a two-centimetre permanent artefact into a canyon.

The fix is one line of rounding plus a floor: guarantee at least one unit of progress toward neutral whenever quantisation would stall. The regression test is the part I like — carve a saturated five-second track using the *real* per-frame update, stop, decay at the *exact* runtime rate, and assert every texel returns to exactly 128. It was verified to fail against the old code first ("texel froze at R=126"), which is the only way a regression test earns its name. The whole affair took seven pull requests — a heading-basis fix, a depth lift, this truncation, and then four more chasing jitter, ghost stamps and foam direction out of the same texture.

<video src="/log/assets/vid/irontide-w4-wake.mp4" poster="/log/assets/img/irontide-w4-wake-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*A hard turn at golden hour. The wake swings with the stern and then closes behind — the sea heals in about ten seconds and is properly flat by twenty-seven. For most of this project's life it never healed at all.*

## Midday — a ship you can outgrow

Underneath the water work, the ship stopped being scenery and started being *equipment*.

Until this watch there was one hull. Now there are five, on a ladder from sloop to galleon, and the class actually drives the numbers — cargo, crew, hull points, sail, turn rate — through a single tested derive layer, so there's exactly one place where "what is a corvette" is defined. You buy the next one at a shipyard tab that shows the stat deltas against your current hull, coloured by direction, with the gate you haven't met named in plain language when you can't afford it. Fittings — engine, guns, harvester — became slots you buy, sell and swap, and they carry across a hull change, with the overflow sold automatically.

And the world got the same treatment. Every NPC used to spawn as one silhouette and one stat block, which the agent's own commit message diagnosed better than I would have: the sea read as a **Brigantine monoculture**, and threat was unreadable at spyglass range. Now hull class rolls by role — merchants sail fat brigantines and galleons, patrols get corvettes and frigates, pirates run sloops and corvettes with a rare (~8%) frigate as a named threat. You can tell what's coming at you by its shape now.

<video src="/log/assets/vid/irontide-w4-steaming.mp4" poster="/log/assets/img/irontide-w4-steaming-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*Open water under steam. Canvas furled, funnel working, the spectral sea from last watch doing its job underneath.*

## Afternoon — the keel learns the depth

A ship that can be a shallow sloop or a deep galleon needs the sea to care about the difference, so hulls got a **draft** — 0.8 m for a sloop, 3.6 m for a galleon — and the seabed under the keel is sampled every frame. A shallow-draft sloop slips into a reef a galleon grounds in. In a metre and a half above the draft, forward thrust bleeds off; at the draft you're aground with a firm grind of deceleration. Reverse is never limited, so you can always back out.

![A sloop lying offshore of a forested island, a wide pale-turquoise shelf running along the whole coast under a lighthouse](/log/assets/img/irontide-w4-shallows.jpg)
*The pale band is the shelf. A sloop crosses most of it; a galleon would stop at the outer edge and have to find another way in.*

That's the version that works. Getting there took four goes, and the failure modes are a nice tour of what "the seabed" even means in a procedurally generated world:

- **Take one** sampled depth at the ship's *centre*, so steaming at a vertical cliff slowed you gently to a halt with your bow six metres inside the rock.
- **Take two** probed the bow and added a contour collision — remove the into-the-shallows component of any step, using the depth gradient as the outward seabed normal — so the hull stops at the contour and still slides *along* a cliff face.
- **Take three** keyed on the wrong depth field. The smooth shore field is deliberately blurred by about nine metres so the foam and colour bands look good, which smears a sharp cliff's land contour inland — measured at thirty-five metres off, which the player experiences as "steam right inside the cliff, stop half way".
- **Take four** fused both fields and takes the shallower of the two: the blurred field for the smooth shelf drag, the raw voxel heightfield — which *is* the mesh you can see — for where the land actually starts.

Then one more pass for the two things that must never happen: the ship could back its stern onto a beach and get stuck (grounding only ever probed the bow, and only handled forward motion), and a leviathan could crawl up into a dune. Now the probe follows the *leading edge in the direction of travel*, and there's a depenetration step that walks a hull toward deeper water every frame it's over sub-draft ground — so you can never stay aground, from anywhere on land.

## The middle of the watch — the codebase files bugs on itself

Somewhere in the middle of all this I pointed the agents at the entire repository and asked what was wrong with it.

They filed **211 verified findings**, issues #892 through #1110, across the game and the editor. Not lint. Things like: the cannonball hit test swaps the length and beam axes, so every ship's hitbox is rotated ninety degrees relative to the hull you can see. Same-frame multi-ball kills pay the sink reward once per ball. The boarding RNG returns a half-width range, so the jitter band is half what it's documented to be. The dev console opens on backquote even while you're typing a captain's name into a text field. A shipped build would have had *no gameplay VFX at all*, because the effects root was baked to a developer's absolute path with no fallback.

Then the fixes started landing in TDD batches — twelve crash and correctness fixes, seven correctness fixes, four perf and cleanup — and the day's commit count peaked at 142.

The companion piece to that sweep is the document I keep re-reading, a survey of what a fully AI-driven development loop for this project would actually need. Its executive summary is the most useful sentence anyone has written about this project:

> The bottleneck is not agent capability and not control surfaces — it is that "looks right" is not a checkable artifact, and nothing runs automatically.

It then lists what's missing with unpleasant precision. **Any CI at all** — the clippy gate and the test suite are rituals someone remembers to perform, and there is zero shader validation anywhere, so a syntax error in a shader ships silently and surfaces as a magenta screen on a real GPU. **A closed visual loop** — screenshots are captured in three different hosts and asserted nowhere; the UI baseline-diff harness exists in full and has never had any baselines created; the art reference folder is inert files no script reads. And **evidence-carrying autonomy** — the agents can do the work but can't prove it: no standard evidence bundle on a pull request, no perf regression gate, no frame-deterministic capture.

That last one is subtler than it sounds and it's the load-bearing gap. Every 3D screenshot this project takes is wall-clock phase-noisy — the ocean is always mid-wave — so naive pixel comparison against a reference can never work. Until there's a "pause, step exactly N frames, capture" mode, there is no such thing as the same frame twice, and everything visual stays human-eyeball-only.

The dossier is also refreshingly rude about what *not* to build: don't use a vision model as a pass/fail gate (the best score about 51% on game-QA benchmarks — triage aid, never oracle); don't use a software rasteriser as the shader-correctness gate, because it will never reproduce the driver bugs that actually bite us; don't run zero-threshold pixel diffs against a live ocean; and don't let an aesthetic-scoring model near art direction, because they're all biased toward generic photorealism and actively hostile to intentional stylisation.

## Evening — the sea gets a voice

The other big system of the watch exists because of a constraint I set at the very beginning: **you are the ship**. No walking around, no port interiors, no crew you can see. Which is atmospheric right up until you notice that nobody in this world ever says anything to you.

So: a radio. Channels, a message log, cooldowns, relay range. Market headlines and rumours arrive while you're at sea. Contract offers arrive too, and you can accept them *without docking*, which is a real quality-of-life win in a game where the point is to be on the water. Pirates hail you before the guns come out, with comply, flee or fight. Each faction has a voice — the Admiralty formal, the merchant League mercantile, the Free Ports rough — and there's a small quality-based story engine underneath choosing what's worth saying based on what's true about you right now. A Telegraphist crew role extends your effective range, and **storms degrade the signal**, which ties the radio to the weather and to the crew in one stroke.

<video src="/log/assets/vid/irontide-w4-storm.mp4" poster="/log/assets/img/irontide-w4-storm-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*Heavy weather. Beautiful, and now also the thing that cuts you off — storm severity folds directly into radio range, so the worse it gets, the less the world can tell you.*

Alongside it, crew experience: a shared pool you earn from contracts, combat, discovery and storm travel, spent on whichever officer you choose, capped by your own captain level. I picked the shared-pool model deliberately over per-officer XP, for one reason — **a lost officer should be a gold sink, not a re-grind**. You can hire a replacement and spend the pool back into them. You never lose an evening to a dead man.

The first playtest report on the two systems is the kind of thing I started this whole workflow to get:

> The radio delivers on its promise — a bodiless world gains a voice. Hearing *"Admiralty Signal Station: your conduct is noted with approval…"* or a contract offer arrive while sailing makes the sea feel inhabited.

## Night — three playtests, and the fourth thing

That first report also filed three findings, and the most interesting one is a balance bug that nobody would have found by reading the code. Discovery awards a flat 50 experience for charting a new port. The world is infinite and procedural. Therefore sailing is an *unlimited* experience stream — roughly two charts to level two, eight to level three, a hundred and sixty-two to level ten — and a player can out-level the entire economy just by exploring, skipping contracts and combat entirely. It got a diminishing-returns curve.

Round two was a different shape: a live session plus an adversarial exploit hunt over the two new systems' code. Twenty-one raw findings, eighteen confirmed, twelve distinct after deduplication. Muting the hails channel *broke the hail system entirely*, because the detector latched its state even when the muted message was filtered out, blocking every hail for an hour and a half of game time. Saving mid-hail and loading produced a zombie prompt where comply, flee and fight were all silent no-ops. And combat kill experience was flat, undecayed and ungated against threat, against about four respawning passive merchants — a risk-free farm, and the only experience source in the game with no anti-farm guard.

Those twelve got fixed. And then round three, which is the part I want to keep:

> The round-3 thesis: *each fix wave can introduce new bugs.* This sweep targeted the code the round-2 fixes touched, to catch regressions the fixes themselves shipped. It did: **four of the round-2 fixes carried or introduced a fresh defect.**

Sixty-one agents, eighteen raw findings, twelve confirmed by two-out-of-three adversarial refutation, nine distinct after deduplication. Two of them are exquisite. The new tribute rule was supposed to stop a captain dodging a pirate's demand with a thin hold — and it counted the ship's *coal* as cargo, so a broke captain with a starting bunker of four coal paid nothing at all, the exact opposite of the comment sitting directly above it. And the new "don't award kill XP for non-hostiles" gate read the target's reputation standing *after* applying the kill's own reputation penalty, so sinking a neutral patrol dropped it below the hostile threshold and then paid out for a hostile kill. Both fixes were semantically inverted. As the report puts it, that's exactly the class of bug a playtest reads as "this doesn't do what the changelog says."

The finding that stopped me, though, was the last one, and it isn't a regression at all — it's the thing three rounds of testing a *different* system finally tripped over:

> **First-session cargo trap.** The starter Sloop has `cargo_cap=6` but spawns with `STARTING_COAL=4` → only **2 free holds**, yet every generated contract needs **3–6** units. A new captain literally cannot carry the first contract offered.

Every single new player's first act in this game was impossible. It had been impossible for weeks. It survived a full economy pass, an agent playing the trade loop end to end, and two prior playtests — because everyone who tested it, human and agent alike, was testing something *else*, from a save with a hold and a hull and money. The fix is one number: the sloop's hold goes from six to eight.

All nine round-three findings were filed, fixed, merged and re-validated on a rebuilt binary in the same session.

The last commit of the watch is, appropriately, about being told things: a full overhaul of the toast system. Messages wrap instead of truncating, hovering holds the whole stack open while you read, a thin bar shows you how long you've got, every toast now also lands in the captain's log, ambient chatter drips out at one per ten seconds while a kill or a hail bypasses the queue entirely, and you can pin one so it never expires. Also — and this is the detail that tells you a real person used it — the close button was a seven-pixel target, which is unhittable. It's twenty-two pixels now.

## What the watch taught

The three headline bugs of this watch are the same bug wearing different clothes. The wake canyon: a truncation that had always been there, made visible by an unrelated change. The cargo trap: a starting configuration that had always been broken, hidden by everyone testing from a later state. The inverted tribute gate: a fix that shipped doing precisely the opposite of its own comment. None of these are hard problems. All of them are *invisible* problems, and the entire discipline of this project is turning invisible into checkable.

Which is why the sweep and the dossier matter more to me than the shipyard does. The agents are extremely good at anything with an assert attached — 211 findings and a 142-commit day says so. They are exactly as good as my instrumentation at everything else. "Looks right is not a checkable artifact" is the sentence I'd put over the door.

And round three is the honest counterweight to my own enthusiasm. A fix wave is not free. Adversarially re-sweeping the code your own fixes just touched found four fresh defects in twelve fixes — a third of them. Any story about AI development that doesn't have that number in it is selling something.

## The numbers

| Metric | Value |
|---|---|
| Fictional hours | 24 |
| Commits | 480 |
| Busiest burst | 142 commits |
| Rust code | ~236,000 → ~271,000 lines across 52 crates |
| WGSL shader code | 80 → 98 files (~24,600 lines) |
| Issue tracker | #782 → #1571 |
| Bugs the codebase filed against itself | 211, in one sweep |
| Playtests of the same two systems | 3 — the last a 61-agent re-sweep of its own fixes |
| Fixes that carried a fresh defect | 4 of 12 |
| Attempts to make shallow water clear | 4 (3 cosmetic, 1 structural) |
| Pull requests to heal one wake | 7 |
| Tests green at watch end | 748 |

## Where this lands

The water works now, at every scale I can test: clear and green over sand, deep and mean in a storm, and it closes behind you instead of remembering where you've been. The ship is a thing you buy, fit out and outgrow, and it stops when the sea gets too shallow for its keel. The world can talk to you. And the codebase has, for the first time, been made to look at itself.

What's still a painting is the sky. There's weather in the game, but it's a state on a dial, not a place — the clouds don't build, the storm doesn't come from *somewhere*, and lightning is a light on a timer rather than a thing that hits. If the sea is eighty percent of the screen, the sky is the other twenty, and right now it's the part doing the least work.

**Next: I go after the sky — a storm you can watch coming over the horizon, clouds with insides, lightning that picks a target, and fog banks that hide an island until you're in them.**
