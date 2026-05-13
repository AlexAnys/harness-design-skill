# finsim audit — six-week harness usage review

**Date**: 2026-04-29  
**Project**: finsim (灵析) — Next.js 15 + Prisma + Tailwind financial-education platform  
**Phase / scope**: Apr 22 → Apr 28, ~70 commits across 65 PR units, 22 commits in a single 3.4-day session (cf6f8b55)

## What was observed

Hard numbers from `.harness/progress.tsv` and 3 JSONL transcripts (cf6f8b55 + 38a259b7 + 4050b83f):

| Metric | Value |
|---|---|
| Distinct units | 65 |
| Units passing on r1 | 62 (95%) |
| Units triggering r2 due to QA-found bug | 2 (3%) |
| Units triggering r2 due to scope expansion | 3 |
| r3+ rounds | 1 |
| Coordinator Edit/Write to app code (Phase 8 + PR-NAME-1) | 13 |
| Coordinator Edit/Write to app code (PR-AUTH-1) | 0 |
| Build/QA reports produced | 112 |
| TodoWrite invocations across 3 sessions | 0 |
| Mode A (one-shot Agent) commits per transcript line | 1 per 45 |
| Mode B (TeamCreate + SendMessage) commits per transcript line | 1 per 411 |
| Stop hook fires per session | cf6f8b55: 21 / 38a259b7: 14 / 4050b83f: 25 |
| Real user input ratio (text vs tool_result) | Phase 8: 6–8% / PR-AUTH-1: 25% |

Notable failures:

- **PR-CALENDAR-1 r1 FAIL**: Prisma `include` missed `semesterStartDate`. CLAUDE.md explicitly warned about this exact pattern in "Prisma Gotchas" — the warning was static and not triggered into action.
- **PR-AUTH-1 stageC r1 FAIL**: `<Image style={{height:"auto"}}>` inline style overrode CSS `.lx-brand-logo { height: 56px }`. Caught only because QA agent ran `getComputedStyle` in a real browser. A diff-only review would not have caught this.
- **Codex first invocation (PR-SIM-4)**: `--full-auto` flag missing meant sandbox defaulted to read-only. Silent failure — agent "completed" without producing edits. Required a retry with explicit flag.

## What worked

1. **`.harness/spec.md` as the contract** — every unit had a written plan before code touched. Scope drift across 65 units was minimal.
2. **`.harness/progress.tsv` as the truth log** — 65 single-row entries made the audit trivially possible. Without it, this finding wouldn't exist.
3. **QA agent + browser verification (gstack `/qa-only`)** — caught the PR-AUTH-1 stageC inline-style bug that no other layer would have. Provided computed-style measurements as evidence.
4. **Build/QA report files** — 112 high-density markdown files. Real evidence, real screenshots, real test counts. The audit trail's primary asset.
5. **Coordinator-as-default-agent (`settings.json`)** — opening Claude Code in finsim lands on coordinator. Discipline became infrastructure.
6. **SessionStart banner hook** — PR-AUTH-1 session (4050b83f) opened, user said "开始 B" and work continued without re-explaining context. Real ROI on context survival.

## What didn't earn its keep

1. **"Coordinator does NOT write application code" as moral rule**: violated 13 times. All 13 violations produced zero observable failures (PR-NAME-1 PASSed, lint-fix PASSed, fix-defensive PASSed). The rule's stated rationale (self-persuasion bias) doesn't match the actual failure surface. *Implication*: reframe as context-economy concern.
2. **2/2 consecutive-PASS dynamic exit**: real fire rate ~3% (only 2 cases where r1 FAIL → r2 PASS was caused by real bugs). The other 95% of units exit on r1 PASS, making 2/2 unreachable per-unit. The rule is vestigial.
3. **`test.md` acceptance file**: finsim never wrote one. Nothing failed. Aspirational scaffolding.
4. **15-item instantiation checklist**: was never used as a checklist; coordinator made implicit judgment calls. Decomposes naturally to ~5 essential items.
5. **Long anti-pattern enumeration in skill**: more cognitive load than value. Real anti-patterns deserve dated evidence entries, not bullet lists.
6. **"tools:" field as enforcement**: in current Claude Code, this field is advisory — coordinator had `tools: Agent, TeamCreate, ...` (no Edit) and used Edit 13 times. The field documents intent; it doesn't enforce.

## What was missing

1. **Rolling lessons capture**. PR-CALENDAR-1 hit a gotcha CLAUDE.md had warned about, because the warning was static and there was no mechanism to bring it forward when a related diff appeared. New gotchas (like the inline-style override) had nowhere to land except informally in HANDOFF.md. *Implication*: add `lessons.md` + a PostToolUse hook to require entries on r2+ PASS.
2. **Context economy as an explicit principle**. The skill said "Coordinator doesn't write code" without giving the underlying *why*. With the why ("Coordinator's context must stay lean across long sessions, this is sharding not purity"), the rule becomes self-explanatory and admits sensible exceptions. *Implication*: new reference `context_economy.md`.
3. **Stop hook diff-guard**. ~30–50% of Stop hook invocations (especially in team-mode sessions with SendMessage rounds) fire on turns with empty `git diff`. Each invocation is a 120-second agent call. *Implication*: prepend a command-type hook that exits 0 when no diff.
4. **Codex command template**. The first Codex invocation failed silently due to default-sandbox-read-only. No template in `codex-tasks/` showed the right command line. *Implication*: provide a prefilled command-line template.
5. **HANDOFF.md size discipline**. By end of week 6, HANDOFF.md was 11 KB with 3 concurrent project-phase sections. SessionStart injects all of it. Without rolling archive, this grows unbounded. *Implication*: cap + auto-archive at size threshold.

## Implications for SKILL.md / references

Specific changes shipped in v0.1.0:

- **SKILL.md**: compressed to ~120 lines (was ~700). New "Context Economy as hidden fourth principle" section. Anti-patterns reduced to 4 observed cases, each linking to this evidence. Dynamic exit simplified.
- **`references/context_economy.md`**: new. Explains why role separation is context sharding, with practical rules (coordinator's 3-file-Read threshold, when Edit is OK vs not).
- **`references/lessons_pattern.md`**: new. `lessons.md` format + three-state maintenance + promotion path.
- **`references/enforcement.md`**: rewritten. Three catastrophic-only hooks (PostToolUse lesson-write, Stop diff-guard, PreToolUse warn-not-block). "What we explicitly do NOT enforce" section.
- **`references/upgrade_playbook.md`**: new. Non-invasive upgrade procedure for existing harnesses (the finsim case).
- **CHANGELOG.md**: v0.1.0 entry.

## Open questions

1. **Is context drift via compaction actually causing decision degradation in finsim, or is it a theoretical concern?** Hard to measure without a controlled comparison. Worth watching for "we changed direction without realizing we'd lost the original rationale" moments.
2. **Should Mode A (one-shot Agent, no QA) be discouraged entirely, or kept as a valid mode for non-runtime changes?** Mode A produced 22 commits with zero observed misses in finsim Phase 8. But the work was mostly text/data changes, not visual/runtime. Need more diverse evidence.
3. **Codex CLI as a third execution channel**: 1 success after 1 failure. Sample size too small to recommend a decision tree. Watch over more uses.
4. **Whether to formalize "what changes need a QA-agent run" vs "Stop hook suffices"** — currently coordinator judgment. May need a checklist if mistakes start appearing.
