---
layout: post
title: "Ralph Wiggum Loops"
date: 2026-01-24
categories: ai development automation
---

# Ralph Wiggum Loops

*"Me fail English? That's unpossible!"* - Ralph Wiggum

I've been experimenting with autonomous AI coding loops using Claude Code. The name comes from the Simpsons character - these loops just keep going, happily working away, occasionally saying something unexpected. After a 9-hour run with 3 concurrent agents producing 71 completed issues, I figured it was worth documenting.

## The Setup

The basic idea is simple: wrap Claude Code in a bash loop that restarts after each task. Instead of relying on Claude's internal looping (which tends to crash with weird bash errors after a few hours), you make each cycle self-contained.

```bash
#!/bin/bash
REPO="/path/to/your/repo"
cd "$REPO" || exit 1

while true; do
  echo "[$(date)] Starting Ralph cycle..."
  claude --dangerously-skip-permissions --print "$(cat RALPH.md)"
  echo "[$(date)] Cycle complete (exit code: $?)"
  sleep 5
done
```

That's it. Claude reads its instructions from `RALPH.md`, does one complete unit of work, exits, and the loop restarts fresh. No resource leaks, no stuck shells, no accumulated context window cruft.

## The Critical Part: Planning First (With Claude)

Here's what most people get wrong: they jump straight into the loop without a proper plan.

**Don't do this.**

But here's the thing - you don't have to do the planning alone. Use Claude Code interactively to build your specs. The key is getting Claude to ask *you* questions.

Start a session and say something like:

> "I want to build a cyberpunk roguelike RPG. Interview me about the design. Ask detailed questions about mechanics, systems, and player experience. Don't assume anything - make me articulate my vision."

Then let Claude grill you. It'll ask about:
- Core gameplay loops
- Progression systems
- How different mechanics interact
- Edge cases you hadn't considered
- Technical constraints

This interview process is gold. Claude asks questions you wouldn't think to answer in a solo braindump. After an hour of back-and-forth, you'll have surfaced assumptions and decisions that would have bitten you later.

Once you've answered enough questions, have Claude synthesize everything into a proper design document. Review it, iterate, and keep going until it's comprehensive enough that a developer (human or AI) could build from it without asking clarifying questions.

**The planning artifacts you need:**

1. **A comprehensive design document** - Every feature, every API endpoint, every data model specced out. My Game Design Document runs 50+ pages. The agents reference it constantly.

2. **Clear architectural patterns** - Document your coding conventions, file structure, testing patterns. Put this in a `CLAUDE.md` at the repo root. When agents need to make decisions, they follow established patterns instead of inventing new ones.

3. **Well-defined issues** - Vague issues produce vague results. Each issue should have clear acceptance criteria. "Add user authentication" is bad. "Add JWT-based authentication with refresh tokens using the existing middleware pattern" is better.

4. **Labeling system** - Priority labels (P0/P1/P2), status labels (`in-development`), and optionally area labels (backend/frontend). This prevents agents from stepping on each other.

The upfront planning investment pays off massively. With good specs, agents produce consistent, mergeable code. Without them, you get a mess of conflicting approaches that need constant human intervention.

## Bootstrap: Let Agents Create Issues

Here's a trick that keeps the backlog healthy: create meta-issues that instruct agents to create more issues.

For example, create an issue like:

> **Title:** Architectural review of frontend state management
>
> **Description:** Review the current frontend architecture against the GDD Phase 2 requirements. Identify gaps, inconsistencies, and missing features. Create well-specified P1/P2 issues for each finding. Close this issue when the review is complete.

The agent will:
1. Read your design docs
2. Audit the current codebase
3. Create 5-10 detailed, actionable issues
4. Close the meta-issue

One of my agents did exactly this during the run - picked up a "frontend overhaul audit" issue and created 6 new issues covering missing API integrations, state management improvements, and a critical bug it discovered. Those issues then got picked up by subsequent cycles.

You can also use this for:
- **Code quality sweeps** - "Review all TODO comments in the codebase and create issues for each"
- **Test coverage gaps** - "Identify untested code paths and create issues for missing tests"
- **Documentation** - "Audit public APIs and create issues for undocumented endpoints"
- **Dependency updates** - "Check for outdated dependencies and create upgrade issues"

This makes the system somewhat self-sustaining. Agents don't just burn through your backlog - they actively grow it with well-specified work they discovered themselves.

## The RALPH.md File

The instruction file is where the magic happens. Mine evolved through trial and error into something like this:

```markdown
# Ralph Wiggum Development Loop

You are an autonomous developer. One issue per cycle, then exit.

## Shell Hygiene (CRITICAL)
- Always start commands from main repo root
- Before any git worktree operations: `cd /path/to/repo && pwd`
- NEVER run `git worktree remove` while inside the worktree
- If commands fail weirdly, immediately `cd /path/to/repo`

## Workflow
1. Setup - pull latest main
2. Pick highest priority issue WITHOUT `in-development` label
3. Mark it `in-development`
4. Create worktree and branch
5. TDD - write failing test, make it pass
6. Create PR
7. Merge (handle conflicts by bailing)
8. Cleanup worktree (FROM OUTSIDE THE WORKTREE)
9. Deploy and verify
10. Exit with /exit

## Merge Conflict Recovery
If merge fails:
1. Remove `in-development` label
2. Close PR
3. Delete branch
4. Clean up worktree
5. Exit - next cycle retries with fresh main
```

The shell hygiene section exists because Claude kept deleting the worktree directory while its shell was still cd'd into it. Classic "sawing off the branch you're sitting on" problem. The explicit instructions to navigate out before cleanup eliminated ~90% of the crashes.

## Running Multiple Agents

Three concurrent agents on the same repo works surprisingly well:

| Metric | Result |
|--------|--------|
| Issues completed | 71 |
| Runtime | ~9 hours |
| Merge conflicts | 25 (~26%) |
| Successful conflict recovery | 100% |
| Claude crashes | 2 |
| Shell stuck | 3 |

The `in-development` label is crucial. Without it, agents would constantly race on the same issues. With it, each agent picks different work and conflicts only happen when two agents touch the same file.

Conflicts aren't failures - they're expected. The "bail and retry" approach handles them cleanly. The agent abandons its work, removes the label, and the issue goes back in the queue. Next cycle picks it up with fresh main and usually succeeds.

## What Goes Wrong

**Claude Code crashes** - Usually `Error: No messages returned`. The bash loop handles this automatically - just restarts and continues.

**Shell gets stuck** - Happens when the working directory gets deleted. The agents now detect this and exit gracefully.

**No issues available** - When all issues are `in-development`, the agent just exits. Add a sleep to prevent rapid cycling:

```bash
if ! gh issue list --label ready --json number -q '.[0]' | grep -q .; then
  echo "No issues, sleeping 5m..."
  sleep 300
  continue
fi
```

**Duplicate work** - Occasionally two agents discover the same bug and both create issues/fixes. The agents handle this gracefully - one merges, the other notices and closes its duplicate.

## Results

Running overnight, three agents went from version 0.100.3 to 0.137.2 - that's 37 minor versions, each representing a completed feature or fix:

- Combat buff system
- Character stress mechanics
- Territory wars
- NPC dialogue overhaul
- Terminal commands (heat, map, contacts, safehouse, etc.)
- Bug fixes discovered along the way
- Documentation improvements

The agents also created new issues when they found TODOs in the codebase or discovered bugs during implementation. The backlog grew even as they worked through it.

## The Workflow Summary

1. **Plan with Claude** - Have it interview you. Answer questions until your vision is fully articulated. Let it synthesize into design docs.

2. **Bootstrap issues** - Create meta-issues for architectural reviews, audits, and planning tasks. Let agents generate the detailed work items.

3. **Run the loops** - Start your agents with good RALPH.md instructions. Monitor initially, then let them run.

4. **Iterate on specs** - When agents produce unexpected results, it's usually a spec problem. Refine your docs and try again.

## Is This the Future?

For certain types of work, absolutely. Well-specified features with clear patterns and good test coverage are perfect candidates. The agents follow TDD, write tests, and deploy verified code faster than I could manually.

For exploratory work, architectural decisions, or anything requiring judgment calls? That's where the collaborative planning phase comes in. You still need human judgment to decide *what* to build - but Claude can help you think it through more rigorously than you would alone.

The key insight: **the quality of autonomous agent output is directly proportional to the quality of your planning documents**. Garbage specs in, garbage code out. Crystal clear specs in, surprisingly good code out.

And you don't have to write those specs alone. Use Claude to interview you, challenge your assumptions, and synthesize your answers into something comprehensive. Then let the agents execute.

## Try It Yourself

1. Start a Claude session and have it interview you about your project
2. Iterate until you have thorough design docs and a `CLAUDE.md`
3. Set up your repo with clear patterns and labels
4. Create a few bootstrap issues for architectural review
5. Write your `RALPH.md` with explicit shell hygiene rules
6. Start with one agent, watch the logs
7. Scale up once you trust the process

The agents aren't magic - they're persistent, tireless, and surprisingly good at following instructions. Give them good instructions and they'll surprise you.

*Now if you'll excuse me, I have 71 new features to review...*
