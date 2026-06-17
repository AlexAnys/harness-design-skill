# Context Economy

> The hidden fourth principle. Role separation is a context-sharding strategy, not an aesthetic.

## The core claim

The Coordinator must stay lean across the project's lifetime — it makes long-horizon decisions, holds intent, and talks to the user. Generators (Builders) and Evaluators (QA) are **sacrificial** contexts: they fill up doing dirty work and die at task end.

This reframes everything:

- "Coordinator does NOT write code" — not for role purity, but to protect its context budget for decisions across days/weeks.
- "Agent Teams, not subagents" — because team-mode agents run in isolated context slots, not parented inside the Coordinator's context.
- "Blackboard is markdown files" — because documents are how state survives the death of expensive contexts.

## What lives where

| Context | Lifetime | Should hold | Should NOT hold |
|---|---|---|---|
| Coordinator | days–weeks | intent, plans, decisions, summaries of agent results | full file Reads, multi-Edit cycles, debug traces |
| Builder (per task) | minutes–hours | full Reads, Edits, test runs, fix iterations | (will die anyway, fill freely) |
| QA (per task) | minutes | spec, build report, product observation, screenshots | (will die anyway) |

## Coordinator's context budget — practical rules

A useful rule of thumb derived from the finsim audit:

> **When the Coordinator needs multiple source-file Reads to answer an architecture question, it's drifting into the Builder's role — delegate.** (finsim's observed tipping point was around three Reads in a row; an observation, not a threshold.)

The Edit/Write count alone isn't the signal — the signal is total bytes pulled into Coordinator's window. Reading one file then making one small Edit may be cheaper than spawning a Builder. Reading five files to figure out an architecture question is when delegation becomes the cheap option.

## When Coordinator may directly Edit (judgment, not rule)

**Acceptable** (the finsim audit showed these caused no observable harm):
- `.harness/*` files (spec, progress, handoff, lessons)
- All `.md` files (CLAUDE.md, README, docs)
- Trivial config / lint fix that unblocks CI in seconds (single-line, no Read required)
- 2-line follow-up after a Codex/Builder run, where the change is mechanical

**Avoid** (or actively reconsider):
- Multiple application source files (.tsx, .ts in app/, lib/, components/, etc.)
- Schema files (.prisma, migrations)
- Anything that would require Reading > 1 file to understand

**Default heuristic**: if unsure, spawn a Builder. Whatever a spawn costs, it is far below the silent, cumulative cost of Coordinator context degradation — you only see that one when compaction truncates the wrong early decision.

## Why long sessions concentrate the risk

Compaction events truncate early context. Early context typically holds:
- The original user intent (often a sentence or two from days ago)
- Spec rationale (why this approach was chosen over the alternatives)
- Decisions and their explicit reasons

Losing those means downstream decisions stand on partial truth. **This is the worst failure mode** — not a bug in code, but a slow drift in judgment. You won't notice it happen; you'll notice the project ended up somewhere different than intended.

The finsim cf6f8b55 session ran 3.4 days continuously, 22 commits across two distinct PR phases. That's the kind of high-risk profile context-economy thinking is meant to guard.

## Practical rules

1. **One task = one Builder spawn**. Don't reuse a Builder across unrelated tasks — the context bleed defeats the sharding.
2. **SendMessage carries summaries, not full file contents**. Long quotes in SendMessage land in BOTH the sender's and receiver's context.
3. **Builder/QA report files (`.harness/reports/`) are how state survives** the sub-agent's death. Write them like you'd brief a stranger.
4. **Coordinator should compact deliberately at unit boundaries** — write HANDOFF, decline to re-Read large files unless re-planning.
5. **Sacrificial contexts should be filled freely** — don't optimize Builder's token use. Optimize Coordinator's.

## Why this matters more than "role purity"

The original framing of role separation (defend against self-persuasion bias, prevent silent fixes by Evaluators, etc.) is correct but secondary. The dominant risk in long-running projects is **Coordinator context drift via compaction**, and most "role violations" observed in the finsim audit produced no immediate bug — the cost was paid silently, later, in degraded judgment on subsequent decisions.

This is why enforcement should target the **catastrophic-information-loss** points (Evaluator silently fixing instead of reporting, lessons not being captured), not the **everyday context-hygiene** points (Coordinator occasionally Editing). The former is unrecoverable; the latter is a slow leak whose remedy is a warning and a habit.
