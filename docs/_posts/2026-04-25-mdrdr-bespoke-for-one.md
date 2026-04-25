---
layout: post
title:  "An Audience of One"
description: "A markdown reader, built almost entirely by an AI, for reading what the AI writes."
author: "h0bb3"
comments_id: 22
tags: "programming rust ai-development bespoke markdown claude tooling"
---

# An Audience of One: How AI Made Bespoke Software Free

*Or: I needed a markdown reader, so I asked Claude to write one. I barely typed.*

## The setup

I don't write markdown. Claude does.

I read it. Plans, design docs, code reviews, research summaries, refactoring proposals, post-mortems, agent traces, "here's what I just did" notes — these days the markdown in my filesystem is overwhelmingly produced by AI agents working on my behalf. My role in that pipeline is *reader*, not *author*. I poke. I redirect. I read the output. The output is markdown.

So when I needed a better way to consume that firehose, the answer wasn't a markdown editor. It was a markdown **reader**. An optimised consumption surface. Something that boots in 200 ms, follows file changes the moment an agent rewrites them, renders mermaid because agents love diagrams, renders LaTeX because agents love equations, has a sidebar tree because agents generate *whole directories* of documents, and has Ctrl+P fuzzy search because I lose those documents in those directories.

There are zero tools that fit this shape. Every markdown app I tried was an editor with a preview pane bolted on, written for the imagined user who actually types markdown by hand. That user is increasingly not the typical user.

So [mdrdr](https://github.com/h0bb3/mdrdr) exists. ~9,651 lines of Rust. Four direct dependencies. Forty-nine commits across one long weekend. The interesting part of this post isn't *what* it does — the README covers that — but *how it got built*. Because the building is the actual story.

## The interaction log

I want to be precise about how much I typed, because the headline of this post is "AI made bespoke software free" and I'd like that to mean something concrete.

Roughly the entire human side of building mdrdr was:

- **One initial prompt** describing what I wanted. A markdown reader. Live reload. LaTeX. Mermaid. File tree. Dark mode. Headless screenshot. Tiny dep tree.
- **One `CLAUDE.md`** I sketched out in five minutes — the four-crate rule, the architecture diagram, "things that look tempting but will hurt." Maybe 80 lines of text.
- **Drag-and-drop screenshots** when something looked wrong. *"This label bleeds past the edge."* *"The arrow is overlapping the box."* *"This is too small."* Often without any words at all — just a PNG.
- **Three-word redirections.** *"What's next?"* *"Looks good."* *"Push and release."* *"Per block it is."* *"Lets go for diagonal."*
- **One single-paragraph product idea** for a novel mermaid layout I'd been wanting for years. I sketched it on paper and photographed it with my phone.

That's it. I never opened a Rust file. I never typed `cargo build`. I never wrote a commit message, picked a release branch strategy, or chose how to structure the HTTP API. I read the diffs Claude posted, looked at the screenshots, said "yes" or "fix this" and let it go.

Claude built the parser, the layout engine, the renderer, the HTTP server, the file watcher, the clipboard bridge, the math typesetter, the mermaid layout (twice, after I rejected the first version), the context menu system, the fuzzy file finder, the per-block layout overrides, the CI pipeline, the GitHub release workflow, and the README. It debugged its own bugs by running the headless renderer and reading the PNGs back. It set up the macOS universal binary build with `lipo`. It wrote the desktop entry registration commands for Linux. It wrote the Gatekeeper workaround for macOS. It pushed the commits. It tagged the release.

I am described in the commit log as "h0bb3" but I would not survive a deposition on most of those commits.

## The architecture (which I also did not design)

Here's the part that's actually about *AI-first* development as a methodology, not just as a marketing phrase.

Halfway through the first day, Claude proposed the architecture as a single pure function:

```
render(source, viewport, scroll, theme, fonts, ...) -> Framebuffer
```

It does not touch the window. It does not touch the network. It does not touch the filesystem. Given a markdown string and configuration, it returns pixels.

Three different shells call into it: the headless `mdrdr render foo.md --out preview.png` command, the live `mdrdr` window via `winit`+`softbuffer`, and the HTTP API at `/screenshot`. All three produce identical output for the same input.

Why? Because Claude needed to see what Claude was building.

The iteration cycle that ran for two days, almost without my involvement, looks like this:

1. Claude edits a layout file.
2. Claude runs `cargo build --release`.
3. Claude runs `mdrdr render /tmp/test.md --out /tmp/check.png`.
4. Claude reads `check.png` (Claude is multimodal; PNGs are first-class input to it).
5. If the result looks wrong, Claude edits and goes back to step 2. If the result looks right, Claude moves on to the next task.

I am not in this loop. I am occasionally consulted at the end, when Claude wants to confirm a design choice or has finished a milestone and is wondering what to do next. The screenshot loop is autonomous. The whole point of the pure render function is that it makes the loop autonomous.

This is what I think most people miss when they say "AI writes code." The interesting part isn't the writing. The writing is fine. The writing has been fine for a year. The interesting part is **building systems whose verification is mechanical**, so the AI can iterate without a meat-relay (me) between the keyboard and the screen. Mdrdr's pure render function, headless mode, and HTTP control plane exist for one reason: so that *Claude can be its own QA*. The architectural shape of the project was chosen by the AI to make the AI faster.

If your AI agent has to ask you "did the layout work?" every single iteration, your throughput collapses to your typing speed plus your attention span. If the agent can render the layout, look at it, and decide for itself, your throughput collapses to the agent's wall-clock cost. Those are very different speeds.

The deepest takeaway from building mdrdr: **most software needs to be re-architected for the new bottleneck**. That bottleneck is no longer "writing the code." It's "feeding the AI fast feedback so it stays unblocked." Pure functions, deterministic outputs, headless modes, machine-readable state, structured logs, screenshot endpoints. Those are the new productivity multipliers. The IDE is irrelevant. The agent just needs a way to *see*.

## The four-crate rule

The one rule I really did insist on is in `CLAUDE.md`:

> **Everything above the primitive layer is written by us.** The primitive layer is exactly four crates and no more.

`winit` for window events, `softbuffer` for pixels, `fontdue` for glyph rasters, `image` for PNG/JPEG. Everything else — markdown parsing, GFM tables, LaTeX math, mermaid layout, the HTTP server, JSON emission, URL decoding, fuzzy search, the file watcher — is hand-written. By Claude. Out of nothing.

This is a pointless rule, in the conventional sense. *Don't reinvent the wheel* is good advice. For humans.

For AI, it inverts. The cost of a hand-rolled CLI flag parser, when an AI is rolling it, is twenty lines and ten seconds. The cost of pulling in `clap` is paid forever — by binary size, by compile time, by transitive surface area, by "what does that derive macro do" debugging headaches that *I* end up reading. A human reaches for `clap` because typing `clap::Parser` saves an hour of their life. The AI doesn't have an hour of life, marginally. So the trade flips.

The four-crate rule isn't asceticism. It's economics. The new ratio: code is cheap, complexity is expensive. So minimise complexity, even if it costs more code.

Result: a 9.4 MB statically-linked binary, ~9,650 lines of Rust, dependency tree small enough to fit on a slide. Built in a weekend.

## The bespoke part

About a day and a half in, the basics worked, and I started asking for the silly little things that no general-audience tool would ever ship.

I have a particular way I like to think about service architectures. When I'm sketching *X talks to Y, which calls Z, which talks back to X* — chains and cycles — I draw it as a matrix. Each node sits on the diagonal. Forward calls run through the upper-right triangle. Return paths and back-edges live in the lower-left. The cycles untangle visually in a way they don't with mermaid's standard top-down or left-right flowcharts.

I sketched it. Claude added a new layout direction. `flowchart DG`. Right-click any mermaid block, pick **Layout ▸ Diagonal**, the diagram re-renders into the matrix view. Live, in the same viewer.

There is no other tool on Earth that ships this layout. The audience for it is exactly one person — me. There is no Issue #237 with seven thumbs-ups asking for it. I'd been wishing for it for years and never had a way to get it short of writing the entire mermaid renderer myself. Now Claude has written the entire mermaid renderer, and adding a layout direction is a 200-line problem, not a 10,000-line one.

This is what I mean by "bespoke for free." The economics of software historically *required* generality. You needed a million users to fund the team that built the tool, and a million users have a million opinions, so every feature got smoothed into a compromise. Software was a vending machine: pick the prepared option closest to what you wanted, live with the gap.

When the marginal cost of a feature collapses to "an evening with an AI agent," you stop picking from the menu. You order off-menu. Every feature is *exactly the one you wanted*, because the cost of "exactly" and the cost of "approximately" are now the same number.

## Honest costs

I'm not going to pretend this is free in every sense.

**Code quality varies.** `window.rs` is 2,910 lines. Some parts are cleaner than I'd write; some show seams from long sessions where Claude lost context partway through and the resulting style is a little quilted. There are 17 compile warnings I haven't asked it to fix. Dead code from a refactor that didn't fully complete. A method nobody calls. In a code review at work I'd leave polite-but-firm comments about all of it. Here I shrug, because cleanup is also cheap — I'll ask for it tomorrow.

**Review is partial.** I cannot read every line of every PR-sized diff with the same care I'd apply to a colleague's code. The diffs are too big and there are too many. I read the architecturally interesting parts, glance at the rest, and rely on the screenshot loop. *This is uncomfortable.* It is also the only way to get throughput. The mitigation is architectural: the dangerous parts (the render core, the parser, the HTTP API) are small and well-fenced. If something goes wrong, the blast radius is bounded.

**Maintenance is theoretical.** If I come back to this in six months I won't remember much of the code. Neither will Claude — its memory of this session is gone the moment the chat closes. The `CLAUDE.md` and the inline comments are the institutional memory. If I keep them honest, re-onboarding is a paragraph plus an architecture diagram. If I don't, future-Claude and I are both confused.

**Bus factor: 1.** Nobody else can pick this up easily, because nobody else has my context and nobody else has my AI's context. The repo is on GitHub, builds cleanly, README is maintained. But "fork and contribute" is much closer to "rewrite from scratch with the same goals" than the open-source norm. That's the bespoke trade — not a bug, the whole point.

## What this means

We're roughly two years into a transition where most of the economics of software has changed and most of the software hasn't caught up.

- **Internal tools** fall first. Every team has a Slack channel full of *"wouldn't it be nice if our admin panel did X."* Most of those got triaged and ignored. Now they get built. Quietly. By one person, in an evening.
- **Personal tools** are next. I now own a markdown reader, a todo workflow, and a dotfile manager that fit my brain exactly. I expect everyone reading this will have several such tools by 2027.
- **Bespoke replacements for SaaS** are starting. The CRMs, the Notions, the project trackers — anything whose moat is "it exists and would be expensive to rebuild" is in trouble. The moat is evaporating fast.
- **General-audience consumer software** is fine for now. Polish, marketing, content libraries, distribution muscle still cost real money. But the functional core is becoming a smaller share of why people pay.

The risk people raise is *"the world fills up with personalised one-offs that nobody else can use."* That's correct, and I think it's largely fine. Most of life is bespoke. My kitchen knife is sharpened the way I sharpen knives. My desk setup is mine. My git aliases would baffle a stranger. The reason software was uniformly generic was that production economics demanded it; we mistook the constraint for a virtue. It wasn't.

## So. About this markdown reader.

It does what I want. The mermaid Diagonal layout is genuinely nice. Live reload is fast. Ctrl+P fuzzy search opens in 8 ms. Right-click → Copy table as CSV worked the first time, because Claude wrote tests I didn't ask for. The HTTP screenshot endpoint means I can drop `mdrdr` into AI-driven UI test loops for *other* projects. The whole binary is under 10 MB. It boots in under 200 ms.

It will probably never have another user. That's fine. It has the user it was built for: a guy who reads more markdown than he writes, because his AI writes more markdown than he does.

If you want one too, the source is at [github.com/h0bb3/mdrdr](https://github.com/h0bb3/mdrdr) and the release binaries (Linux, macOS universal, Windows) are on the releases page. Or — and this is the actual takeaway — go and ask your AI to build *yours*. Whatever the *yours* is. The audience-of-one tool you've been wishing for. The thing that's almost-right but never-quite. The feature you've been filing into the void.

The vending machine isn't the whole shop anymore. Order off-menu.

---

**Tally:**

- 9,651 lines of Rust
- 4 direct crate dependencies
- 49 commits in one weekend
- Human typing: ~200 lines of natural-language prose, a `CLAUDE.md`, and a paper sketch of the Diagonal layout
- Human authorship of `.rs` files: zero lines
- 1 entirely new mermaid layout option that exists nowhere else
- Cost: a Claude subscription and some electricity

**Lesson learned:** *"Don't reinvent the wheel"* optimised for human time. The new constraint is complexity, not code volume. Reinvent away — and architect your project so the AI can verify itself.
