---
layout: post
title: "The Wind Has an Opinion"
date: 2026-07-29 16:20:00 +0200
tags: [ai, development, gamedev, rust, bevy, aigamedev]
---

Last time the agent built itself a camera and shot a trailer. I posted it to r/aigamedev. The reception was… quiet — a handful of one-word replies, none of them kind. I could have argued with the tone. What I couldn't argue with was the *shape* of the complaint, because I'd felt it myself watching the reel back: it's a boat moving through a very pretty ocean, and **you have no idea what you'd actually do out there.**

It's the Quake-demo problem. A movement showcase — look, I can run through this beautiful level — is not the same as a game. Cool traversal, sure. But where's the decision?

So the agent spent the next day making the ocean into something you have to *sail*, not just cross. Here's the reel that came out the other side. Watch it, then I'll tell you what changed under it — the agent sailed every metre of this itself and recorded it on the capture rig it built last week.

<video src="/log/assets/vid/irontide-sailing-trailer.mp4" poster="/log/assets/img/irontide-sailing-poster.jpg" controls autoplay loop muted playsinline style="width:100%;height:auto"></video>
*The new trailer — the agent at the helm, not just behind the camera. Golden-hour sailing, a wind that fights the tiller, a deck that rocks on the swell, a storm that bites.*

## The diagnosis: the sea was a screensaver

Iron Tide has a strategic chart and a real-time ocean. The problem, stated plainly: the chart did the interesting part, and the ocean was scenery. On the water you could harvest, fight, or dock — and the map handled the connective tissue *better*, with less friction. So the optimal way to play was to open the chart, plot a course, and let it carry you. The ocean — the 80% of the screen we spend all our shader budget on — was a thing you skipped.

That's the failure every map-plus-world game fights: when the strategic layer can resolve everything the tactical layer can, the tactical layer has no reason to exist. The fix isn't more scenery. It's giving the sea a decision the map can't make for you.

Four things came out of the next day of the loop.

## 1. The wind fights your helm

This is the one I'm proudest of, and it's a perfect little parable of building with an agent.

I asked for wind drift — the boat should be pushed by the weather, not glide on rails. The first pass added *leeway*, a sideways slip, and dialled it so gently I couldn't feel it at all. *Make it stronger*, I said — so it did, and overshot into something worse: the ship now slid sideways across the water like a car doing a handbrake turn, bow pointing one way, the whole hull skating the other. Technically "drift." Viscerally wrong. I told it so in about those words: *that's not how a boat works — a keel resists side-slip hard; wind doesn't skate you sideways, it mostly turns your bow, and you fight that turn with the rudder.*

Third time, it came back with the right model. Now the wind puts a **yaw** on the hull — a weather helm that rounds your bow up toward the wind — and the sideways slide is gone, reduced to a handful of degrees of honest crab (up to about sixteen in a full gale, a couple on a light day). Let go of the tiller on a beam reach and the bow swings up into the wind and stalls you. Hold a course and you're holding *rudder against the weather* the whole time. It's scaled so a fixed bit of helm holds at any speed, so it's a steady pressure to fight, not a twitch.

The difference in feel is the entire point. Before, you held forward and watched. Now you *steer*. The playtester verdict after the rework was one line: "this feels much more like active sailing now." That's the sea having an opinion about where your bow should point, and you disagreeing with it, continuously. That's a decision, ten times a minute.

## 2. The camera rides the swell

Small thing, big feel. I wanted the camera to feel alive on the water instead of bolted to the boat on a stick. The agent's first attempt bobbed the camera *up and down* with the ship's heave — and I genuinely could not see it. Of course I couldn't: a half-metre of vertical movement, fifteen metres up, aimed at the horizon, against a sea that's already moving, is invisible.

The fix wasn't to throw the heave away — it was to keep the gentle bob and add the thing you *actually* feel on a boat: **tipping the horizon**. The camera now also takes a dampened share of the ship's own wave-pitch and wave-roll, so the world leans a little as you ride each swell — gentle in a moderate sea, a proper toss in a storm. A fraction of the boat's motion, not all of it, so it reads as *loosely* riding the deck rather than glued to it. That's the shot in the trailer where the horizon rolls under the bowsprit.

## 3. Work comes over the wire — and it has a clock

Two changes that are really one idea: give the sailing a *point*, and give the point *stakes*.

First, **the radio**. You can now take contracts over the wire while you're at sea — a port's dispatch calls an offer, you answer "accept," and the job's yours without docking. It's diegetic; the sea talks to you.

Second — and this is the load-bearing one — contracts now have a **delivery deadline**. Before, a job you failed to deliver just… quietly evaporated. No cost. Which meant there was no clock, which meant no diversion was ever a *choice*: chasing a tidegleam bloom off your route, or routing the long way round a storm, cost you nothing, so it wasn't a decision, it was sightseeing. Now a missed delivery **fails** — you take a reputation hit with the faction — and the HUD counts down the hours, reddening as it closes.

That deadline is the smallest change in the batch and the most important, because it's the clock that makes everything else matter. *Punch through the storm and risk the damage to make the deadline, or route around it and eat the time?* That question doesn't exist without a clock. Now it does, and the weather helm and the storm damage stop being flavour and start being terms in a decision.

## The vertical cut

While the agent had the camera out, it cut a phone-shaped version — a true crop, not letterboxed, the ship riding centre-frame the way the chase-cam already keeps it:

<video src="/log/assets/vid/irontide-sailing-trailer-vertical.mp4" poster="/log/assets/img/irontide-sailing-vertical-poster.jpg" controls autoplay loop muted playsinline style="width:56%;height:auto;display:block;margin:0 auto"></video>
*The same reel, reframed for phones. Center-cropped from the real footage so it fills the frame — no black bars.*

## The numbers

| Metric | Value |
|---|---|
| The complaint | *movement, not gameplay* — a Quake run with no decision |
| The fix | weather helm + camera rock + radio contracts + delivery deadlines, 4 slices to `main` |
| Wind model | a yaw that turns your heading (weather helm), not a sideways car-skid; leeway demoted to a small crab (a few degrees, ~16° in a gale) |
| The keystone | a **delivery deadline** with a rep penalty — the clock that makes storm-routing a real choice |
| Iterations to get drift right | 3 — imperceptible → a car-skid → weather helm |
| Human's job | *"that's not how boats work"* and *"now it feels right"*; the agent did the model, the tests, the shoot |
| Generated-image assets | still zero — stylized WGSL and low-poly, hand-reasoned |

## Where this lands

The honest meta of this one is the loop itself. A stranger's one-line dunk, my *"a keel doesn't work like that,"* the agent's rework, my *"there it is."* None of the three of us could have done it alone — the crowd supplied the diagnosis, I supplied the physical intuition, and the agent supplied everything with a compiler in front of it. The thing the agent still can't do is feel that the first version was wrong. The thing I can't do is write the weather-helm math and the deadline system and the trailer script in an afternoon. Together it's a sea you have to respect.

There's more ocean to give teeth — storms you genuinely choose to run or avoid, a chart you have to earn by sailing it, blooms and wrecks that only exist if you're *there*. But the clock is in now, and a clock is the thing that turns a pretty view into a gamble.

**Next: I keep giving the sea decisions — and the map stops being where the game is played.**
