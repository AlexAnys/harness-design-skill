# Workflow-tool orchestration in production sessions — first transcript evidence for the shelved integration line

**Date**: 2026-07-06
**Project**: three real sessions using Claude Code's Workflow tool as the orchestration layer (this repo's pre-merge review; a multi-source investment deep-research run; an external PR audit), 2026-06-24 → 2026-07-06
**Phase / scope**: the 2026-06-04 verdict shelved all workflow-integration proposals for this skill as "zero empirical evidence" and set a re-open condition: a transcript of a real workflow run. This entry records the first such transcripts and their failure modes. It does not propose integration.

## What was observed

Three production runs with full journals on disk:

1. **Pre-merge adversarial review of this repo's v0.3 PR** (2026-07-02, journal: session `8dacb777` → `wf_381e47d2-8a0`): 31 agents, 1.82M subagent tokens, 488 tool calls, ~23 min wall clock. Structure: 5 review dimensions fanned out, every candidate finding handed to an independent skeptic that had to reproduce it before it counted. Yield: 26 findings → 25 confirmed, **1 killed by its skeptic** (a plausible-sounding "missing re-entry pointer" claim that turned out to already match the eval's expected behavior line-for-line). A context-recovery run in the same session (`wf_6dfa2a53-cfb`, 8 readers, 626K tokens) reconstructed three weeks of scattered session history in ~8 min.
2. **Investment deep-research run** (2026-07-02, session `2419110a`): 107 agents, 5.13M subagent tokens. The search/fetch/verify stages completed; the **synthesize step and 5 follow-up agents all died on a session usage limit**. The workflow had no checkpoint resume path the operator used; it degraded to returning 19 unmerged verified claims, and the human-facing report had to be assembled manually days later.
3. **External PR audit** (2026-06-24, session `b3eb2eab`): 5-dimension review + per-claim adversarial voting, 32 findings, 31 confirmed / 1 refuted — same shape as run 1, independently converging on the finder/skeptic split. In an adjacent 2026-06-16 run, a workflow killed mid-flight by a session limit **resumed 18.5 h later with 7 completed agents replayed from cache** — resume works when invoked.

Recurring failure modes across runs: subagents finishing without calling their structured-output tool (18 in one 2026-06-05 run, killed after nudges); server-side rate limits silently killing verification voters mid-fanout; `Write` reporting success while nothing landed on disk (caught only by a `ls`/`cat` oracle days later).

## What worked

- **Finder ⊥ skeptic at the workflow level**: forcing every finding through an independent refuter context is Generate ⊥ Evaluate applied to review work, and it demonstrably filtered false positives (1/26 and 1/32 killed in the two review runs) while the confirmations came back with reproduction commands attached.
- **Structured-output schemas as the inter-agent contract**: readers returned bounded JSON instead of prose dumps; the orchestrating context stayed small — same context-economy motive as the blackboard, achieved without files.
- **Cache-based resume** after a multi-hour interruption (when actually invoked).

## What didn't earn its keep

Nothing removable from the skill — the skill currently says nothing about workflows, which is the point of this entry.

## What was missing

- **No checkpoint discipline for the operator**: run 2 lost its synthesis to a usage limit even though resume machinery existed — the harness layer (not the tool) lacked a "resume before regenerate" rule.
- **No disk oracle on agent self-reports**: the false-success `Write` and the no-structured-output deaths are the same class this skill already documents for agents ("a green oracle can hide a dead hook"); workflow runs need the same treatment, e.g. verifying journal/artifact existence before trusting a run's summary.

## Implications for SKILL.md / references

None shipped. The 2026-06-04 re-open condition is now **partially met**: these are real transcripts, but none ran *inside a scaffolded project harness* (coordinator agent invoking Workflow as its fan-out layer) — they ran in ad-hoc sessions. The integration line stays deferred until an in-project run exists. When one does, the candidate shape suggested by this evidence is narrow: workflows as the *ephemeral fan-out + verify* layer inside a structure the decision layer already chose, not a fifth topology.

## Open questions

- Does a workflow journal (`journal.jsonl`) satisfy "execute on documents", or does fan-out work still need blackboard files a human can diff?
- Is the finder/skeptic split worth its ~2× token cost outside review-shaped tasks?
- Single-occurrence watch: cache-resume has one success and one non-use; needs a deliberate kill-and-resume trial before it earns a recommendation.
