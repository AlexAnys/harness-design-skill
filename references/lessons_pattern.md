# Lessons Pattern — Rolling Knowledge Capture

> Why this exists: static "Calibration" sections in QA prompts don't evolve. The same gotcha bites again because no one wrote down "this happened, here's how to detect it." Calibration is the crystallized layer; `lessons.md` is the flowing pool.

This pattern is borrowed from a well-known practice in production engineering teams (post-mortem culture, the PROGRESS.md convention popularized by some Claude Code power users). Its absence was the single biggest preventable cost surfaced by the finsim audit.

## File: `.harness/lessons.md`

Append-only. One entry per lesson. Format:

```markdown
## L-{NNN} · {YYYY-MM-DD} · {one-line title}

- **Symptom**: what was observed (concrete, not abstract — error message, broken behavior, wrong number)
- **Root cause**: the actual mechanism, traced (not the symptom restated)
- **Detection**: how QA could have caught it (the new check — a command, a step, a script)
- **Prevention**: where this check goes — `qa.md`? `builder.md`? `CLAUDE.md` "Gotchas"?
- **Commit**: <short-sha> (the fix that proved the lesson)
- **Status**: `active` | `superseded-by-L-XXX` | `deprecated`
```

### Why every field matters

- **Symptom** must be concrete enough that a future Builder/QA can search for it by error message or behavior. Abstract symptoms ("things were slow") don't pay rent.
- **Root cause** must be the mechanism, not the symptom. "include was missing" not "the page broke."
- **Detection** is the new check that would have caught this earlier. This is the operational value of the lesson.
- **Prevention** routes the check to the right agent role.
- **Commit** lets you read the actual diff and verify the lesson matches reality.
- **Status** enables maintenance (below).

## When to append — the only enforced rule

PostToolUse hook on `git commit`: if the most recent row in `progress.tsv` is `r2|r3 PASS`, **require a new lessons.md entry dated today** before the next commit is allowed (or warn loudly, depending on enforcement appetite — see `references/enforcement.md`).

Rationale: a Failure that took two rounds to resolve is, by definition, a lesson. Letting it pass without capture is the failure mode this whole mechanism exists to prevent.

## Three-state maintenance

- `active` — the lesson still applies; QA should still check.
- `superseded-by-L-XXX` — replaced by a more general or correct lesson. Keep for history; readers can follow the chain.
- `deprecated` — the underlying code segment was rewritten or the architecture changed; the lesson no longer applies. Keep for history (often instructive to see why something used to matter).

**Never delete a lesson.** The audit trail is the value. Update its status.

## Promotion path — lessons → static rules

When a single lesson keeps recurring across different units — it has shown generality, not coincidence — promote it (finsim's heuristic was 3 triggers; an example, not a quota):

1. Copy its essence into `CLAUDE.md` "Gotchas" or `qa.md` "Calibration" section as a permanent check.
2. Mark the original lesson `superseded-by-static-rule` and link the static rule.
3. The static layer grows slowly; the rolling layer absorbs new findings.

This keeps the QA agent prompt from bloating (prompt is finite context) while still letting the project accumulate operational knowledge.

## What NOT to record as a lesson

- Style preferences without a failure attached ("we should prefer X over Y") — those belong in CLAUDE.md or a style guide.
- Generic best practices — those belong in CLAUDE.md.
- Trade-offs that were accepted (not failures) — those belong in HANDOFF.md or a decisions log.
- Things that "could happen" — only record what did happen.

## Seed entries — the finsim audit's actual omissions

If your project has had failures that weren't captured, seed `lessons.md` with them retroactively. From the finsim audit:

```markdown
## L-001 · 2026-04-22 · schedule.service include missing semesterStartDate
- Symptom: "本周" tab empty; tsc passes; 41 tests pass; runtime renders blank
- Root cause: `prisma.schedule.findMany` include omitted `semesterStartDate`; CLAUDE.md "Prisma Gotchas" had warned about this exact pattern but the warning was static and not enforced
- Detection: QA must do a real browser load (Playwright MCP); the browser console should show no "cannot read property of undefined"
- Prevention: qa.md calibration list (promotion candidate after one more occurrence)
- Commit: <pr-calendar-1-r2>
- Status: superseded-by-static-rule (CLAUDE.md "Prisma Gotchas" — 已多次导致 500 错误)

## L-002 · 2026-04-28 · inline style auto/auto overrides CSS height
- Symptom: lockup PNG renders at natural 256×85 when CSS .lx-brand-logo specified 56px / 36px
- Root cause: next/image warning fix added `style={{height: "auto", width: "auto"}}`; inline style has higher specificity than class CSS
- Detection: getComputedStyle(el).height vs CSS-expected value; must check on real browser, not just diff review
- Prevention: qa.md add to checklist for any PR that adds inline style on an element with class-controlled dimensions
- Commit: 2a6abc7 (PR-AUTH-1 stageC r2 fix)
- Status: active
```

## Where lessons.md sits in the agent flow

- **Coordinator** reads the recent tail when planning to surface relevant prior failures before writing the spec.
- **Builder** reads it for the unit being implemented (grep by file path, by error pattern) to avoid known traps.
- **QA** reads it as part of the verification checklist — "have any active lessons been re-triggered by this change?"
- The PostToolUse hook ensures the file actually gets written; the agents ensure it gets read.

The file stays small and high-density. It is the cheapest possible mechanism for "don't make the same mistake twice."
