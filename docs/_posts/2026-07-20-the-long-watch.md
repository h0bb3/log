---
layout: post
title: "The Long Watch"
date: 2026-07-20
tags: [ai, development, gamedev, rust, bevy]
---

Last week ended on a promise. I signed off the log with *next week: making it beautiful*, and then spent the next twenty-four hours mostly not doing that. Beauty, it turns out, is the last thing you build. First you have to make the thing *legible* — to yourself, to the tools, and to the agents doing the work.

This is the log of that one long day. It has a refactor in it that took a seven-thousand-line file apart, an editor that finally earned a name, a harvest run that went about as well as harvest runs go, and — right at the end of the watch, in the dark — the sea learning its first genuinely pretty trick. If you missed the first post, the short version is: [Iron Tide](/log/2026/07/19/one-week-at-full-sail.html) is a steampunk nautical trading RPG built almost entirely by Claude Code agents, and I mostly play admiral.

![A starter sloop steaming across open water toward a lighthouse island](/log/assets/img/irontide-w2-sea.jpg)
*Where the week sits: a starter sloop steaming toward a lighthouse island on the open sea. The water is still last week's ocean — the same Gerstner swell — and everything today happens on top of it.*

## Morning — the monolith comes apart

The single biggest thing that happened today wasn't visible on screen at all.

`iron_tide/src/main.rs` had grown to **7,578 lines**. That's the smell the January posts warned about: an agent will happily keep bolting features onto one enormous file, because each individual change compiles and each individual change is locally sensible, and no one ever stops to ask whether the *shape* is still holding. It wasn't. We'd already hit Bevy's system-parameter ceiling once. The file was a liability.

So I pointed the agents at issue #75 and let them carve. Not a rewrite — an *extraction*, one module at a time, one reviewed pull request each:

> extract startup setup subsystem · extract camera + ship-transform sync · extract crew dynamics · extract cannons · extract HUD + menu + nav-panel egui systems · extract heightmap island mesh builders · extract custom materials · extract lighthouse subsystem · extract ship input + physics + battle stations · extract world runtime systems · extract dock state + econ port factory + NPC sync

Twenty-eight of those in a row, twenty PRs, and by the end `main.rs` was **3,190 lines** — less than half what it started. This is the kind of work agents are genuinely, almost eerily good at: "move this coherent thing into its own module and prove the game still builds." It's mechanical, it's verifiable, and it's exactly the work a human puts off for six months. The game stopped being a seven-thousand-line `main.rs` with some crates around it and became a *codebase*.

The refactor also flushed out a pile of duplication that had been quietly accumulating: the ocean's uniform binding got shared through a single `iron_tide_ocean` crate instead of being redefined in three places (#80), the game learned to consume IronForge's lighthouse preset instead of hard-coding one (#82), and a sprawl of near-identical API action handlers collapsed to one canonical dispatcher (#88). None of it is glamorous. All of it is the reason next week is possible.

## Midday — the workbench earns a name

If you're going to make something beautiful, you need somewhere to *look at* it that isn't the running game. A screenshot of a live session is a slow, noisy feedback loop — the clock's moving, the weather's random, the ship won't hold still. What you want is a bench: load one asset, freeze the light, spin it around, tweak, repeat.

That bench had been growing for a while as a throwaway prototype crate called `p03g_mesh_hull`, and today it graduated. The commit that renamed it is unusually reflective for a rename:

> The crate long outgrew "mesh hull" — it's now a multi-surface authoring editor: ship hulls, cannon rigs, lighthouses, VFX bindings and ocean preview, all in one dockable workspace. It has also graduated past throwaway-prototype status, so the `p03g_` prototype prefix is dropped for a branded name: **IronForge.**

The day around that rename reads like someone wrestling an editor into shape one gizmo at a time — a dedicated cannon viewport, camera-aware transform handles, render-layer isolation so the gizmos don't bleed into the scene, a startup panic squashed. My favourite artifact of the whole stretch is a commit that reverts another commit from twenty minutes earlier: an agent talking itself out of a bad idea in real time, in the git log, for the record. The important property of IronForge is that it renders with the game's *real* materials — so what you author on the bench is what the game actually shows. It becomes the workbench for every ship, cannon and light that follows.

## Afternoon — the harvest, and something under it

With the plumbing moving, I sent a captain out to actually play.

Iron Tide has a signature resource called **Tidegleam** — glowing crystal that grows in ribbons out in the deep ocean, far from any port, and you harvest it by parking over a bloom and running the manifold. It is deliberately the opposite of the tidy trade loop: no lighthouse, no dock, just you and a long way from help. The captain followed a harbour rumour to a bloom that had already expired, sailed days more finding nothing, finally dropped onto a fresh ribbon and filled the hold — and *then* two deep-ocean predators surfaced and opened up.

The log entry is a masterpiece of understatement:

> Net trip: +2268 g, 3 crew lost, ship totalled twice.

Profit and catastrophe in a single line. And when the same predators chased the ship eight kilometres home and kept firing *inside* the friendly harbour ring, the agent didn't file a vague bug — it wrote the design principle straight into its own patch:

> Predators are deep-ocean creatures, not stalkers.

This is still the thing I trust most about the whole method. "Do the tests pass" never tells you the monster's leash is too long. A captain's log does, and then it fixes it, and then it tells you *why* in one dry sentence.

## Dusk — the sea learns to smoke, and to rain

Here's where the watch finally turns toward the thing I'd promised.

The combat had become legible in *text* last week — you could read a fight in the numbers. But you still couldn't read it by *looking*. A battered ship looked exactly like a fresh one right up until it vanished. So the agents spent the back half of the day teaching the world to show its state, and every one of these commit messages is a small thesis about legibility:

**Damage smoke** —

> a battered ship still looked identical to a fresh one until it sank — you couldn't read the state of a fight at a glance. Add a classic naval cue: a thickening soot plume that any ship trails once its hull fails.

**Sink-foam** —

> a beaten ship slid under the water and vanished silently. Add a waterline churn that marks where a ship went down.

**Storm rain** —

> heavy weather read only as bigger swells and a sound, never a downpour. Add a world-space rain sheet that fades in with wind strength.

Plus a spark-and-soot burst at the real impact point of every cannon hit — a hit used to make a sound and nothing else — and a storm tint that finally pulls the sky and the sea toward the same bruised colour when the weather turns. None of these are hard graphics. All of them are the difference between a simulation you read off a HUD and a world you read by watching it.

![A sloop in a storm, sky and sea tinted bruised blue-grey, heavy chop](/log/assets/img/irontide-w2-storm.jpg)
*Heavy weather with a mood at last: the storm tint pulls the sky and the sea toward the same bruised blue and the swell stands up. The rain sheet is in there too — it just won't hold still for a screenshot.*

## Night — the sea that glows

And then, in the dark, the one unabashedly *beautiful* thing of the day.

Iron Tide has a rare weather state called a Phosphorescent night — the game's signature magical moment. The trouble, as the commit puts it, was that it barely showed:

> the open sea looked identical to any calm night — the only glow came from tidegleam bloom ribbons. Away from a bloom there was nothing telling you the sea was alive. Add a faint ambient mote field so the signature state reads as magical everywhere.

So now, on a phosphorescent night, the whole sea breathes a faint bioluminescent glow, crossfading in and out as you sail — not just around the harvestable ribbons but everywhere, the way a real bloom lights an entire bay. It is the first thing built this week that exists purely because it's lovely. After a day of module boundaries and soot plumes, watching the water light up under the ship was a good way to end the watch.

![A phosphorescent dusk: a silhouetted ship, a lighthouse island, and teal glow in the water](/log/assets/img/irontide-w2-phosphor.jpg)
*A phosphorescent dusk off an unnamed island — the sea catching the last light and breathing its own faint blue-green, brightest where a Tidegleam bloom drifts ahead of the bow. A lighthouse on the headland, a stranger's sail on the horizon.*

## The tools that watch the tools

One more thing happened today that belongs to nobody's highlight reel and matters more than most of the above: the agents built scaffolding to check their own work. An end-to-end agent smoke test, an autonomous-economy harness that plays a trade loop and asserts the ledger, an IronForge screenshot smoke, a negative-action API probe. `main` targets were put under strict `clippy`, and a drift of test warnings got swept. It's the least cinematic work in the log and it's the flywheel — every guard rail an agent builds today is speed the next agent gets for free tomorrow.

## What the watch taught

Mostly this: **day one of "make it beautiful" is making it legible.** Carve the monolith so the next change fits. Build the bench so you can see what you're changing. Teach the world to *show* its state before you worry about making that showing pretty. The most valuable hours today produced nothing you could screenshot, and the prettiest thing — a glowing sea — took a fraction of the effort the invisible refactor did.

And the method keeps earning its keep in the same two ways: agents are superb at bounded, verifiable work (extract this module; add this cue), and playing the game in character finds what asserts can't (a monster's leash, a harvest run that costs three crew). The honest wart of the day is in that same harvest report — the predators shipped overtuned, and the agent said so, in the same breath it shipped them.

## The numbers

| Metric | Value |
|---|---|
| Fictional hours | 24 |
| Commits | 414 |
| Busiest burst | 97 commits |
| Rust code | ~164,000 → ~214,000 lines across ~48 crates |
| `main.rs` | 7,578 → 3,190 lines |
| WGSL shader code | ~22,100 lines in 74 files |
| Issue tracker | #52 → #337 |
| Effects born today | damage smoke, sink-foam, storm rain, cannon spark, phosphorescent glow |
| Best/worst harvest run | +2,268 gold, 3 crew lost, ship totalled twice |

## Where this lands

The sea you're looking at in all of this is still, underneath, last week's ocean — the same honest Gerstner waves, doing their best. It smokes now, and rains, and glows in the dark, but the water itself hasn't changed since day one.

That's next. The next twenty-four hours are the ones where I stop decorating the ocean and rebuild it from the wave up. **Next: the sea gets deeper.**
