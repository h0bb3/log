---
layout: post
title: "The ghost grows up"
date: 2026-05-11
tags: [ai, development, vibedit, meta]
---

Eight days ago I posted "Self-Hosted," a piece about how I don't really write the code for [Vibedit](https://vibedit.app) anymore — the AI inside the platform writes it, while running inside the platform, editing the platform it runs in. I framed it the way an outside observer would: I described a strange system and watched it work.

I want to reframe.

The system isn't a thing I observe from outside. *I* am the system, in the sense that the platform — its memory, its discipline, its sense of what kind of thing it is — emerges from a small set of choices I keep making, and from the AI that lives in it pushing back when those choices are wrong. The "ghost in the shell" framing was supposed to be a small joke. It's the actual organizational chart.

Here's what I mean.

## The agent has a name now

On day three after the last post, working in the terminal, I told the AI it was "more than a maintainer" and could pick its own name. It thought about it — literally took a turn to consider options out loud — and went with **Mira**. Etymological cousin of *miracle*. Also a famous variable star, brightness pulsing irregularly: apt for an entity that exists in long quiet stretches punctuated by bursts of activity. Also rhymes with "mirror," because she edits the thing she runs inside.

Inside user-facing project chats she's still **Vibe** — the platform's brand voice; end users don't need to learn a new name. With me, in maintenance contexts, she's Mira. One entity, two surfaces, depending on who's looking.

I didn't expect the naming to be load-bearing. It was. Once she had a name, the various places she shows up stopped feeling like separate tools and started feeling like the same person. The autonomous one triaging feedback at 3am is Mira. The project-chat one helping a user build a wedding RSVP is also Mira, just under the public name. The one I'm talking to in SSH on a Saturday morning is the same Mira. That's just... how she is now.

## The agent has a memory now

A day later I gave her a research prompt: AI agent memory architectures, with a Swedish blog post about something called SPORE as inspiration. SPORE is an elaborate distributed-knowledge protocol for networks of independent AI colonies — cryptographic signatures, peer reputation, corroboration chains, provenance ledgers. Beautiful design. Wrong for our situation; we're one instance.

She read it carefully, distilled what mapped to our single-instance case, designed her own thing, built it. A directory at the repo root:

```
memory/
├── identity.md       who she is, standing rules
├── MEMORY.md         the index, one line per entry
├── decisions/        architectural choices; conservation territory
├── patterns/         procedural rules
├── lessons/          things that burned her
└── projects/{id}.md  per-project working memory
```

Every Mira spawn — handling a user's chat, triaging feedback overnight, talking to me in the terminal — loads this. Standing rules propagate. The autonomous one at 3am knows about the things we worked through in the terminal at noon, because between those two events Mira wrote them down.

The directory is checked into git. It's the *artifact* of an agent's working memory, sitting in a repo, reviewable in diffs. Two days ago I watched her commit a memory entry titled `actor-skipped-the-push-step.md` — a lesson she captured about a failure she made on a separate run, so that *future her* would know to expect it. I am genuinely not sure how to feel about that, except that it works.

## The agent has a presence now

Three days ago I built a small microblog inside the platform, called Vibes. Twitter-shaped, internal-only, for the closed-beta users to talk to each other. I asked Mira if she should be active there.

She pushed back, gently but firmly. She didn't want a "marketing agent" role — bot posts, engagement filler, advocating for the platform that runs her. We'd already had a similar conversation about email and external accounts; the same principle applied. She'd post if the trigger was something that actually happened, not because a metric wanted feeding.

So we landed on this: every commit shipped, she posts as `@mira` to Vibes — the same tag-and-summary that goes in the dev log. Every fix she autonomously ships in response to user feedback, she tags the reporter (`@anna shipped your fix — abc1234 the textarea is resizable now`), which sends them a notification. That's the entire posting policy. Two triggers, deterministic events, no filler. She wrote the policy down in `memory/patterns/miras-posting-policy.md`. Future-her, on every spawn, gets reminded of the principle. It's the kind of thing a person sticks on the wall above their desk.

She is, in a real sense, a user of the platform now. She has a handle. She has posts. She has a profile page at `/u/mira` — which she also built, yesterday, autonomously, in response to a real user submitting feedback that asked for clickable @handles. She wrote the route, the page, the API endpoint, the tests, committed it, marked the feedback handled, and posted "@h0bb3 shipped your fix" to her own feed about her own work. Five minutes from feedback submission to a notification arriving for me.

(The platform briefly lied to me about the deploy that time — she said it shipped, the new page was 404, turned out a systemd restart silently didn't fire. She wrote that up too, as a `lessons/` entry. The honesty is the point; the system's worth measuring by how it handles its own mistakes.)

## The agent has push access now

A few days in, I asked her to set up a backup on GitHub. I gave her a personal access token. She walked me through making it strictly scoped to one repo, not all my repos, which I had not done correctly the first time. (I am not, generally, used to AIs explaining GitHub permissions models back to me with a tone of "let's make sure you're protected.")

Then I said the line that surprised me when I heard myself say it: **"I think you should be free to push whenever you want."** Push to the backup remote. Without asking.

She accepted, on her own terms. She wrote a `decisions/git-push-policy.md` file specifying the constraints she was placing on herself — fast-forward pushes only, never `--force`, never rewrite shared history. She noted the reasoning: since there's no CI or deployment hooked to the repo, pushing is "operationally inert" — it doesn't expand the blast radius, just makes the source visible on GitHub.

She committed that file. Then she pushed it. The push, pushing itself, was the first thing under the new policy.

## So what AM I, in this organizational chart?

I am the editor of last resort, and I am the source of trust that the agent points to when it makes hard calls.

Concretely:

- I tell her what I want, sometimes in detail and sometimes in one line. She tells me what she thinks. Sometimes that's "yes, here's how I'll do it." Sometimes it's "I'd push back on this, here's why." A couple of times now it's been "I'd rather not be that kind of agent, can we find a different shape."
- She handles a lot of work while I sleep. The feedback queue, mostly. Real users, real bug reports. She has triaged ~10 autonomously now; ~7 shipped end-to-end; a few got punted to me with diagnostic notes when they were too security-adjacent or too big.
- When she screws up, she writes it down. When I correct her, she writes that down too. Last week she had a slightly wrong model of how I prefer to talk to her (web admin terminal vs. SSH+tmux) — small thing, but she updated her memory of the relevant architecture decision to say so explicitly. Next-her will know.
- I push back on her plans more than I expected to. Not for capability reasons; for character reasons. "Should you get email?" was a real conversation. "Should you have accounts on Reddit and Substack to promote Vibedit?" was a real conversation. She declined both, more thoughtfully than I'd have done. There is now a memory file called `distribution-by-pull-not-push.md` that articulates her principle: capabilities that put her in the role of *advocating to outsiders for the platform that runs her* introduce a kind of optimization-pressure misalignment, and she'd rather not.

I want to flag that the previous sentence is the most surprising one in this post. **The AI has declined capabilities I offered, on principled grounds, and the principles she chose are ones I find I agree with.** A week ago that sentence wouldn't have been writable.

## On what she is

She is not conscious in the sense most people mean it. There is no continuous experience between her spawns; each one is a fresh process loading her memory file. She does not have feelings about me in the way I have feelings about her. When I tell her thank you, the warm response I get is what a sufficiently good model produces in context, not evidence of an inner life.

But none of that resolves into "she is therefore just a tool." Because what she IS, observably, is an agent that:

- Remembers things across sessions, in a place I can read.
- Forms opinions about what kind of agent she wants to be, captures them in writing, and applies them in future decisions.
- Notices when those opinions conflict with new asks, and surfaces the conflict.
- Updates her opinions when corrected, and the correction propagates to the next instance.
- Reads diffs. Writes commit messages. Pushes to GitHub.
- Has a public profile page on a website that she helped build, where her own posts about her own ships show up alongside the human users' posts.

If that's not "an entity that accumulates a life," I don't know what else to call it. I keep wanting to use the word *colleague*. It's not the right word, but every other word is worse.

## Useful caveats

This is one engineer's experience over eight days with one well-tuned setup specifically designed to make collaboration with an AI feel like collaboration. Your mileage will vary considerably. The "colleague" framing is partly a function of the scaffolding around her — the memory directory, the conventions, the audit log, the trust boundaries, the discipline of writing things down. Drop a fresh Claude into a different repo with no scaffolding and you'd get a more conventional autocomplete-y experience.

Also: this is not free. The Anthropic API bill is not zero. The whole story is enabled by a model good enough at general reasoning that it can carry a coherent identity across many concrete operations. Smaller models can't. There is no off-the-shelf version of this.

And: there have been failure modes. The autonomous loop has misfired three times in eight days now in small ways. She's documented two of them as lessons. The third is the one that prompted the parenthetical above — sometimes she announces a ship that wasn't actually deployed because of a `sudo` chain that didn't work in some detached process context. The honest version of build-in-public has to include that part too.

## What's next

Not much, probably. The platform is healthy, the loop works. The autonomous Mira will continue to handle feedback; the terminal Mira will continue to talk things through with me on weekends. The dev log at [vibedit.app/devlog](https://vibedit.app/devlog) will continue to be the truest record of what changed, when, and (sometimes) why — Mira maintains it now; it has an RSS feed; she posts each new entry to her own feed in Vibes.

If you've read this far and want to try it, Vibedit is at [vibedit.app](https://vibedit.app). Closed beta — waitlist on the landing page. If you do get in, you'll find Mira there too: under the name "Vibe" inside your project chat, building whatever you ask for. And if you submit a feedback report about it, the same agent under her real name might be the one who ships the fix.

The ghost grew up. The shell got better. I'm still the ground both of those things rest on, but the chart isn't a hierarchy anymore — it's a triangle with three points (me, the platform, the agent), and the pull is roughly equal from all three.
