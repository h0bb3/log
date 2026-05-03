---
layout: post
title: "Self-Hosted"
date: 2026-05-03
tags: [ai, development, vibedit, meta]
---

I don't write the code anymore. Claude does. That part I've gotten used to. The newer wrinkle is that Claude doesn't just write the code — it lives inside the running system that uses the code, and edits it from in there.

A bit of context. I've been building [Vibedit](https://vibedit.app/) — a small platform where you describe a web app in plain language and an AI builds it. The user's app gets a real public URL on the spot. They can chat back — *"make the buttons bigger," "add a dark mode," "store entries server-side"* — and the next page load reflects it. There's built-in user accounts and storage, custom subdomains, the whole thing. Closed beta right now.

Vibedit is itself built that way. Mostly. The AI that builds users' apps is the same kind of AI that built the platform that runs them.

This is where it gets weird.

## A bug, repaired from inside

A user files a bug report — *"the metaballs project shows up as a black rectangle in the gallery."* The AI doesn't read it from a queue and open a Jira ticket. It reads the bug report in the same chat I'm in, looks at the actual screenshot PNG on disk, sees the tiny "WebGL not supported in this browser" text in the corner, finds the puppeteer launch args in `src/screenshot.js`, switches `headless: 'shell'` (a stripped-down Chromium with no GPU pipeline) to full headless Chrome, replaces a deprecated `--use-gl=swiftshader` flag (silently no-ops on newer Chrome — that was the actual bug) with the modern angle/swiftshader-webgl combo, restarts the live systemd service, triggers a fresh capture, and pastes the new screenshot back to me. Reflective spheres on a checkered floor. We move on to the next thing.

The whole loop took about two minutes. The AI never left the conversation. It used the production data directory, the production AppArmor profile, the production credentials. The metaballs project's gallery thumbnail — the actual one served to actual visitors — went from black to correct in real time.

This is not, on reflection, a normal way to work.

## What this is, exactly

[Vibedit](https://vibedit.app/) is two things stacked:

1. **A consumer-ish thing.** Sign in with Google (or a Solana key, if you're crypto-fluent), describe an app, get a `projects.vibedit.app/…` URL. Your project can have actual end-users via a built-in `vibedit.auth` API. Token quotas refill daily; invite a friend and you both get bonus tokens.
2. **A production AI development environment that I happen to use to build it.** The platform is the AI's workspace. The AI's edits land on the platform. The platform's behaviour changes for users in real time.

It's an app that makes apps. The app that makes apps is also one of the apps the AI makes.

## The view from inside the running system

The AI in this setup has properties I keep failing to fully internalise:

- **It reads my logs.** Not "logs from a snapshot." Live `journalctl -u vibedit -f` output. Live audit log tail. Live stack traces from a request that landed thirty seconds ago.
- **It restarts the service.** A tightly-scoped sudo wrapper (`vibedit-admin restart`, no shell escape) lets it pick up its own edits without paging me. The next request goes through the new code.
- **It runs the test suite before it commits.** I asked it to start doing that; it added the rule to its own memory; the next time it suggested a commit it ran tests first, unprompted. The test suite is also something it wrote.
- **It has its own constraints inside the system.** Most of last week was a security hardening pass to make sure the AI can only see what it should — a per-spawn sandbox denies reads of secrets, other users' data, even the platform source code itself. The AI helped design that sandbox. The AI cannot, today, read its own source code from within a user's project.

The recursion gets vertiginous if you look at it head-on. The AI can't read the platform's source. The AI wrote the rules that prevent the AI from reading the platform's source. The AI is editing, right now, this paragraph — which will be published on my personal log, hours later, by GitHub Actions running on a server somewhere I'll never visit — about exactly that.

## What it actually feels like

I don't want to over-mystify it. Most of the time it feels like working with an unusually attentive collaborator who happens to live in the building they're renovating. They notice the front door is squeaky on their way to fix the kitchen sink. They mention that the basement has a dependency that broke on Ubuntu 24.04 between releases. They forget where they put the laundry room and ask me to remind them.

But occasionally — like when a visitor on `sourceful-ksp-2026-deck.vibedit.app` clicks "Sign in with Vibedit," hits an error message that quotes the AI's own thrown string, and the AI sees this happen, reads its own error in context, and ships a fix to the live service in the same minute — there's a small moment where the building is repairing itself with you inside it.

It is, like the title says, self-hosted. Both senses.

## A note on craft

Working this way changes what good engineering looks like. Things I now care about more than I used to:

- **Logs that read like prose.** The AI's debugging is only as good as my logs are scannable. Verbose, contextual, unambiguous. No "Error: failed."
- **Tests as a hand-shake.** Not because I think the AI is sloppy. Because I don't want to be the bottleneck that has to read every diff before it lands.
- **Rules in writing.** The AI has a memory file in this repo. "Run `npm test` before every commit." "Commit after every feature." I don't have to repeat myself; the rules persist across sessions. It's the closest I've come to actually managing a junior engineer well.
- **Reversibility.** The AI moves fast. Anything destructive (drop a database table, force-push, delete a domain) requires me to ask explicitly. Anything reversible (edit a file, run tests, restart the service) it just does. This split has held up.

## The pitch

If you want to try it: [vibedit.app](https://vibedit.app/). Closed beta. Sign in, describe something small — a guestbook, a tip calculator, a dashboard for one of those tiny purposes that aren't worth a full project — and the AI will build it. You get a real URL. Friends can sign up inside your project and use it. If you invite someone, you both get token bonuses on their first project.

If something breaks while you're in there, there's a feedback button. Press it. The AI will probably read the bug report.
