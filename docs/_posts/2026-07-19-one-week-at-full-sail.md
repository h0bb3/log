---
layout: post
title: "One Week at Full Sail"
date: 2026-07-19
tags: [ai, development, gamedev, rust, bevy]
---

Last Monday I started building a game. Tonight, Sunday, there is a steampunk nautical trading RPG on my disk — an infinite procedural ocean, a dynamic economy, three factions, real-time broadside combat, boarding actions, and a crew that deserts if you quietly go bankrupt. Roughly 630 commits in seven days.

I did not write most of those commits. Claude Code did. My job was closer to... admiralty. This is the log of that week: what the agents did, what worked shockingly well, and where the whole thing ran aground.

Back in January I wrote about [Ralph Wiggum loops](/log/ai/development/automation/2026/01/24/ralph-wiggum-loops.html) — autonomous coding agents churning through issue backlogs — and their [downsides](/log/ai/development/automation/2026/01/25/ralph-wiggum-loops-downsides.html), chief of which was *coherence*: you can close 71 issues and still end up with a game-shaped pile of features, because no agent ever asks "does this feel right?" Iron Tide was, among other things, my attempt to answer that post.

## The game

**Iron Tide.** You are the ship — no walking around, no port interiors. A steampunk brigantine with cloth sails and a coal-fired boiler, on an infinite procedural ocean. Ports sit under lighthouses; prices follow supply and demand; contracts pay gold and reputation; the Admiralty, the Merchant League and the Free Ports Alliance all keep score of what you've done. Combat is broadside cannons with zone damage — hull, sails, crew — and below 40% hull, boarding. Defeat is a story beat, not a game over.

Spiritual ancestors: Elite Dangerous, Wind Waker, Pirates of the Caribbean, Dwarf Fortress. Stack: Rust, Bevy 0.18, WGSL shaders.

The plan existed before the first line of code: a GDD, an implementation plan, and a `CLAUDE.md` — exactly the planning-first lesson from the Ralph posts. The implementation plan defines a series of *throwaway prototypes*, each answering exactly ONE design question, grouped by dependency: rendering foundations, then navigation feel, then core systems, then integration. No building on top of prototype code. Answer the question, learn, rewrite fresh.

## Monday — the blank page, and the best decision of the week

![The first ocean shader and the first procedural island, side by side](/log/assets/img/irontide-day1-pair.jpg)
*Monday, hour one: the first ocean (still flat-shaded) and the first island, beach ring proudly terraced. It gets better.*

The first two prototypes landed twenty minutes apart: P1, a Gerstner-wave ocean shader, and P2, procedural island generation. Classic day one.

The most important thing built on Monday, though, was P0: **the agent loop**. Before building more game, I had Claude bake an HTTP server into every prototype binary: `GET /screenshot`, `GET /state`, `POST /action`, `POST /shutdown`. That's the whole trick. An agent that can *see* what it built and *drive* what it built doesn't need me for every iteration.

The master prompt that then drove the prototypes reads like a shift order:

> Autonomously improve all existing Iron Tide prototypes to passing quality. Run up to 4 prototypes in parallel. Do not ask for permission between iterations. Do not stop until every prototype passes or is blocked.

With rules like "Fix one issue per iteration per prototype", "If same fix fails 3 times — document blocker, move to next", and my favourite, the one that carries the whole methodology:

> Always read screenshots as images — never guess.

It ran four game windows at once, screenshotted them over HTTP, read the screenshots, fixed shaders, rebuilt, restarted, repeated. The three-layer kill script (API → PID → `fuser`) exists because early agents kept orphaning processes — the "sawing off the branch you're sitting on" class of bug from the Ralph posts, alive and well.

By evening the ship prototype was generating modular vessels with cloth-simulated sails, and the physics fight had begun: the ship sat *on* the water like a bath toy instead of *in* it. Twelve straight commits of buoyancy, inertia damping and wave averaging later — and then the discovery that the Gerstner waves had been **inverted the whole time**. Sharp troughs instead of sharp crests. An agent had been dutifully polishing an upside-down ocean for hours. A screenshot finally caught it.

![Turntable of the ship builder's brigantine with cloth-simulated sails](/log/assets/img/irontide-shipbuilder.gif)
*The ship builder at the end of Monday: cloth sails re-inflating in gusting wind. Race presets reshape the same hull — the Dwarf variant is squat, wide, and entirely convinced of itself.*

![Timelapse of the day/night cycle over the ocean](/log/assets/img/irontide-daynight.gif)
*A full day/night cycle from the sky prototype: dawn, noon, golden hour, stars, repeat.*

## Tuesday — making water feel like water

Sailing day. Wind system, heavy ship physics — inertia, slow turning, wind heel. The ship leans when you run a beam reach and comes about like it weighs 200 tonnes, because its time constants are tuned for exactly that.

Two bugs from today illustrate the texture of agent-driven graphics work:

- The ocean **treadmill**: the wave pattern scrolled under the moving ship like a conveyor belt — the fragment shader wasn't compensating for the ship-anchored mesh. Trivial to see, easy to fix, *once a human notices it in motion*. Static screenshots never caught it; I did, watching the window. Frame-sequence validation scripts went on the tooling list that minute.
- The hull **winding order** saga: parametric hull generation produced inside-out meshes twice. The final fix is immortalized in a commit message: `[a,b,c,b,d,c] produces correct outward-facing CCW`. Agents are genuinely good at this once they can see the result; until then they will happily argue the mesh is fine.

![The ship heeling through a turn with spray bursting off the bow](/log/assets/img/irontide-sailing-spray.jpg)
*The ship-ocean marriage: an interaction atlas follows the hull and writes wake, foam and spray into the ocean shader.*

By midnight the wake was trailing properly. The tuning commit notes: "remove the motorboat spray — this is a sailing ship, not a speedboat."

## Wednesday — the agents start playing the game

This is where Iron Tide stopped being a rendering project.

The economy, faction and combat prototypes are text-and-numbers system sims — and instead of unit-testing them, I had Claude *play* them, in character, and write reports. Captain Wadler opened the economy run with "Fog on the water, fog on the ledger," turned 600 gold into 7,666 in nine in-game days of famine arbitrage, and learned the market's central lesson first-hand: "the bigger I dump, the less I get." The factions run ended with a line I'd frame: "The flag on your mast is made of paper, and all three harbor offices are keeping copies." And when the Admiralty patrol finally caught him running arms, the combat report shrugged: "I know the math. I fight anyway." He lost. The game handed him a skiff and 100 gold instead of a game-over screen — "The system didn't punish the choice with a game-over — it punished it with a skiff."

These reports are design validation you cannot get from asserts. Each prototype had one question; each report answers it with evidence and a story.

Then the vertical slice: same ocean, same ship, same economy, one binary — followed by a 44-commit marathon adding the nav chart, fog-of-war, port trading UI, coal fuel, faction flags, and combat. An enemy ship, zone damage, HP bars.

![Sailing toward a discovered island with the full captain's HUD](/log/assets/img/irontide-p12-sailing.jpg)
*The vertical slice becomes a game: wind, sail efficiency, hull/crew/sails, coal — and somewhere to go.*

The HP bars took **five commits**. Flicker, back-side darkening, z-fighting, billboarding. Then the enemy AI got Approach/Broadside/Retreat states and promptly demonstrated a bug where its broadside arc pointed astern — `ship_right` was rotated 90°, so the enemy politely fired away from you. Coordinate conventions were the single most reliable way to lose an agent-hour this week; there is now a rule that every `atan2` call site documents its convention.

Boarding closed the day: below 40% hull a blue ring appears, crews clash, and surrender branches by faction — the Admiralty arrests you, pirates ransom you, merchants let you limp off. A twenty-minute session now reliably produces a story worth retelling. That was the design question. Answer: yes.

![A crippled pirate with a nearly empty hull bar and the blue boardable ring](/log/assets/img/irontide-p12-combat.jpg)
*Battle stations: hull bar nearly empty, blue ring up — boardable.*

## Thursday — Captain Vesper is becalmed

The crew layer went in — hiring hall, wages, fatigue, morale — and with it the best artifacts of the week. I asked Claude to play long sessions in character and keep captain's logs. It invented **Captain Vesper**, hired three sailors, and set out. Then the wind died, six hundred metres from harbour:

> The Crustailsa lighthouse is a thin vertical mark in the haze, six hundred metres to the northwest. I can *see* it. Every sailor on the watch can see it. And the wind has gone entirely. ... Six hundred metres is about half a mile. In a dead calm, with no coal, it might as well be the other side of the world.
>
> I gave the order to rest the crew. If we weren't moving, I'd rather their morale not break. Aldric organised a singing watch on the forecastle. Petra cleaned the cannons, though we hadn't fired a shot.

Vesper drifted within sight of port for fifteen in-game days, and graded the experience honestly: "They were boring in the way real sailing is probably boring. That's either a feature or a design problem. I suspect it's a design problem."

A second captain, **Marren Ashfell**, went bankrupt instead. Wages ticked out silently every day until the ledger hit zero, two sailors deserted without so much as a log banner, and a third died to a pirate broadside. "The game is telling me the story of my own negligence," Ashfell wrote of forty identical wage lines in the journal. "It's the most boring and most damning piece of prose I've ever written by accident." His verdict on the wage math — 600 starting gold at 15 a day is 40 days of runway — "that's not a trap, that's a guaranteed bankruptcy if your first run doesn't hit."

![Crew roster panel with one sailor struck through as DEAD](/log/assets/img/irontide-crew-roster.png)
*A roster after a rough fight. One line struck through. (Yes, there's a sailor named Vesper — the name generator has favourites.)*

Those two logs produced a fix list no test suite would ever generate: an anchor for fast stops, crew that jury-rig sails at sea, a wind forecast, wages slashed, desertion toasts, a zero-crew rescue path, and — after captain number three, **Ossian Redmarr**, the designated economist, hammered the medicine trade — symmetric demand impact to kill the last repeatable exploit.

This is the answer to January's coherence problem, or the best one I've found: **make the agent play the product and narrate the experience.** "Do the tests pass?" never finds becalmed-at-600-metres. A captain's log does.

## Friday — the real game, in one day

Prototype phase over. In the morning the reusable parts — economy, crew, combat core, weather, ocean, world — were extracted into library crates. Then `iron_tide/`, the actual game crate, was bootstrapped from zero: seventy-plus commits in a day. Ocean, skydome, chunked infinite world, ports, markets, NPC ships with dispositions, cannonballs, reputation, captain's log panel, day/night cycle. Each commit is one system, ported from the best prototype answer, onto a clean architecture.

![The first iron_tide build: a blocky island with a lighthouse](/log/assets/img/irontide-v0-lighthouse.jpg)
*iron_tide v0, hours old: the islands are lumpy, the lighthouse placement is optimistic, and it is unmistakably the real game.*

![The v0 ship steaming toward a lighthouse island into the sunset](/log/assets/img/irontide-v0-steaming.gif)
*First voyage in the real game: steaming to port as the day/night cycle slides into sunset.*

This only worked because every prototype had already answered its question. The agents weren't designing; they were *assembling known-good answers*. The one thing that fought back hard was — of course — the ocean shader, which arrived with mysterious dark blobs that turned out to be the ocean shadowing itself. The fix commit: "disable self-shadow sampling — source of the dark blobs."

I also scoped the GDD down to an honest Early Access cut — one race, three factions — and parked the six-race grand vision as a post-launch reference. Boring decision, big velocity win: the agents stopped scaffolding for hypothetical elves.

A drop-down dev console with an HTTP mirror went in too, so agents can run `teleport`, `spawn_test_target` or `repair_all` mid-session. Tooling for the player-agent, again.

## Saturday — islands worth sailing to

The biggest commit day of the week (81), almost all of it in three parallel "labs" — sandbox crates where an agent iterates on one hard visual problem with parameter sliders and a reseed button, then ports only the winner into the game:

- **Island lab:** a staged generator — coastline planform, then relief, then droplet-simulated hydraulic erosion with cliff naturalisation. The first version's erosion didn't visibly erode anything; the fix commit is titled "hydraulic erosion that actually erodes."
- **UI lab:** the parchment theme. Brass filigree corners, wax faction seals, a procedural icon pipeline. The game's start menu and nav chart got skinned the same day.
- **Voxel lab:** true 3D islands — density fields meshed with surface nets, so overhangs, sea arches and caverns are possible. Stratified sedimentary rock in the shader, wet-sand sheen at the waterline.

![An eroded island with palm forests seen from the ship](/log/assets/img/irontide-altv2-island.jpg)
*Out of the island lab and into the game: erosion-carved cliffs, a sea cave, palms on the headland.*

![The parchment-themed start menu](/log/assets/img/irontide-start-menu.jpg)
*The UI lab's parchment theme on the start menu, dev overlay and all.*

![Orbit around a voxel island with stratified rock](/log/assets/img/irontide-voxel-orbit.gif)
*The voxel lab's party trick: a full orbit around a density-field island — strata, undercut cliffs, sea arches.*

![Inside a sea cavern looking out through the arch](/log/assets/img/irontide-sea-cave.jpg)
*Standing inside a carved sea cavern, looking out. Heightmaps can't do this; density fields can.*

Palms and rocks went into the game proper the same day — palm-anchored beach clusters, wind-sway shader, distance culling.

The struggle story of the day: a "rock fleck" artifact speckling the voxel undergrowth. The agent spent a long stretch tuning *data* — density fields, material assignment, smoothing passes — before a splat-weight visualization proved the flecks came from a leftover kill-grass branch in the *shader*. Lesson relearned: when a visual is wrong, first prove which stage is lying. The debug view that settles it is worth ten speculative fixes.

## Sunday — play, file, fix, repeat

Final day, and the loop closed all the way. The playtest agent played the real game through its HTTP API — no cheats, hours at a stretch, on a deliberately ancient spare box (a 12-year-old i5 with integrated graphics) that doubles as the frame-budget canary — and wrote up every session in first person. Each report ends with numbered issues. Fix agents work the batch; the next playthrough verifies.

![Storm seas off an island with two lighthouses, HUD showing wind 1.00](/log/assets/img/irontide-storm-lighthouses.jpg)
*The playtest agent beating into a full storm off Sheidbaesleim. Wind 1.00, dock gate 361 metres away — this is where the overshoots happen.*

Eight sessions ran today. A sampler of what they surfaced:

- **The ghost ship.** Crew hit zero mid-session and the game just... kept going. "I had become a ghost ship anchored at a port that didn't recognise my deed."
- **The overshoot.** "My polling interval was wide enough that we passed Sheidbaesleim at full steam and kept going." By the time the agent noticed, the ship was twenty kilometres east, the coal bunker empty, and twelve crew had died quietly to pirates it cruised past. This bought us a proper auto-dock pilot and a pinned navigation target.
- **The reticle problem.** Nine aimed shots at moving pirates: zero hits. "An agent without a reticle is throwing rocks." After an intercept solver went in, the same test hit 42%. Combat went from unwinnable to merely hard, and the fix helps human players just as much.
- **The self-defeating contract.** The agent accepted a coal delivery, switched to steam, and arrived with an empty hold — the boiler had burned the cargo en route, because bunker and hold were the same pool. Filed, with a proposed bunker/cargo split, in the same report.
- **The feral auto-pilot.** Given an unloadable target, the fallback held heading and crawled forward — into unexplored ocean, discovering four brand-new ports. "Actually entertaining, but not the documented behaviour."

A code audit ran between sessions and was unsparing: `main.rs` had hit 9,624 lines, one action-handler match was 520 lines long, and we'd bumped into Bevy's 16-system-param ceiling twice — "the canary for 'this function is doing too much.'" The refactor batch landed the same afternoon, five modules extracted, each as its own reviewed branch.

By the last run of the evening the tracker stood at issue #52, almost all of them filed by the agents themselves, most already closed. And the final session was the payoff: a clean four-port trade circuit, five contracts delivered, zero deaths, +4,219 gold. The report calls it "the closest the agent-driven game has come to 'actually playable' — a clean, profitable trader's loop that runs on a single command per port."

![The parchment port screen with market prices and a delivery contract](/log/assets/img/irontide-port-parchment.jpg)
*Docked at Boultheixoux on the last run: live market, a Merchant League contract, and the Cast off button that ends the week.*

Graphics got Sunday polish too: shore foam driven by a per-island distance field, and real screen-space refraction so shallow water reads as *shallow*, not merely transparent.

![Docked beneath a lighthouse at dusk with transparent shallow water](/log/assets/img/irontide-dusk-lighthouse.jpg)
*Dusk under the harbour light — the new water transparency showing the shelf falling away beneath the hull.*

![The ship passing beneath a harbour lighthouse, shore foam on the headland](/log/assets/img/irontide-hero-lighthouse.jpg)
*Sunday evening. Shore foam on the headland, palms on the cliff, a Merchant League light overhead.*

![Eight seconds underway: animated ocean, stern wake, shallow refraction](/log/assets/img/irontide-sailing-final.gif)
*Where the week ends: underway at 8 knots past the western shore.*

## What worked

1. **Build the feedback loop before the game.** P0 — screenshot/state/action endpoints in every binary — was the highest-leverage work of the week. Every later system was cheaper because agents could see and drive what they built. If AI can't verify its own output, you don't have automation, you have delegation with extra steps.
2. **One question per prototype, then throw it away.** Agents are spectacular at "rewrite fresh using lessons learned" and mediocre at "carefully evolve this tangle."
3. **Agents as playtesters, in character.** Captain's logs and playthrough reports found balance problems, exploits, and *feel* problems no test would express. Vesper's becalming and Ashfell's bankruptcy did more for the design than any dashboard. This is the coherence mechanism January was missing.
4. **The play → report → file → fix → replay loop.** January's loop closed issues. This one closes issues *and generates the next batch from lived experience with the product.*
5. **Labs.** Give an agent a sandbox crate with sliders and a reseed button, let it iterate at high frequency, port only the winner.

## What fought back

1. **Anything the screenshot can't see.** Motion bugs (the ocean treadmill), input bugs (invisible egui regions silently eating clicks — twice), state behind the render. Each needed either a human glance or new tooling — frame sequences, UI-event probes — before agents could self-serve.
2. **Coordinate conventions.** Heading vs. rotation vs. mesh-forward vs. `atan2` argument order. Days of agent time in aggregate. Document the convention at every call site; agents actually read those.
3. **Confidently wrong visuals.** The inverted Gerstner waves are the emblem: locally plausible, globally upside down, polished indefinitely unless something forces ground truth. Screenshots into the loop early, always.
4. **Shader-vs-data misattribution.** The rock-fleck hunt. When a visual artifact appears, agents default to tuning the layer they touched last. Build the visualization that isolates the stage *first*.
5. **Process hygiene.** Orphaned windows, port collisions, a worktree deleted from inside itself. Same lesson as January: explicit shell discipline in the prompt, kill scripts, and never trusting "it probably shut down."

## The numbers

| Metric | Value |
|---|---|
| Calendar days | 7 |
| Commits | ~630 |
| Peak day | 81 commits |
| Rust code | ~164,000 lines across 46 crates |
| WGSL shader code | ~21,700 lines in 72 files |
| Prototype & lab crates | 34 |
| AI playthrough sessions | 8 full + 4 captain's logs |
| Issue tracker by Sunday night | #52 |
| Best AI trade run | +4,219 gold, zero deaths |
| Hit rate before/after the reticle fix | 0% → 42% |
| Times the ocean was upside down | 1 (that I know of) |

## Where this lands

The honest caveat from January still applies: throughput is not quality, and a week of agent velocity buys you a *foundation*, not a finished game. There are placeholder meshes, balance numbers only Vesper has ever stress-tested, and an art direction maybe 40% of the way to the WoW-steampunk target in my head.

But the coherence problem has a real answer now. The thing keeping this codebase honest isn't the test suite — it's that every day, something with no hands and infinite patience sails the actual ocean, trades in the actual ports, goes bankrupt on the actual wage math, gets becalmed six hundred metres from the actual lighthouse, and writes down how it felt.

![Sailing into the sunset toward a distant island](/log/assets/img/irontide-sunset-underway.jpg)
*Day 3, 17:38, 588 gold. Underway.*

Sail, trade, fight, choose, survive. The loop works. Next week: making it beautiful.
