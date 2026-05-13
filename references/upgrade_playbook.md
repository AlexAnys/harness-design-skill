# Upgrade Playbook

> For existing harnesses. Don't rebuild — diff against current principles and apply only what earns its keep.

## When to read this

Step 0 detection found `.claude/agents/` already populated. The project has been running on an earlier version of these principles. Goal: **non-invasive upgrade with backward compatibility**, not a rewrite.

## Procedure

### 1. Read what's there

```
.claude/agents/*.md
.claude/settings.json
CLAUDE.md
.harness/                          (if present)
```

Note the agent count, current tool allocations, hook configuration, blackboard layout.

### 2. Classify by domain

Read CLAUDE.md to determine:
- **Software** project (web app, CLI, API, library)
- **Knowledge / research** (wiki, dataset compilation, doc generation)
- **Operations** (continuous-loop, ops automation)

Software projects benefit from gstack browser verification; knowledge/ops projects usually don't.

### 3. Run the four-question diff

For each existing agent file, ask:

| Question | If "no" | If "yes" |
|---|---|---|
| Does the role file fit one of the three principles (Plan / Execute / Evaluate)? | Flag as scaffolding-creep; recommend deprecation | Keep |
| Does the role have a clear handoff contract (which files it reads/writes)? | Add a "Blackboard contract" section | Keep |
| Does the role's `tools:` allocation match its function? | Update; note that current Claude Code is advisory on this field | Keep |
| Is the role's instruction body under ~150 lines? | Prune; move detail to references or `lessons.md` | Keep |

### 4. Check the blackboard

Required files:

- [ ] `.harness/spec.md` — current plan
- [ ] `.harness/progress.tsv` — one row per QA round, with header
- [ ] `.harness/HANDOFF.md` — cross-session note
- [ ] `.harness/reports/` — build / qa reports
- [ ] `.harness/lessons.md` — **NEW in v0.1**, often missing in existing harnesses

If `lessons.md` is missing, this is the highest-ROI addition. Seed it retroactively from any past r2+ PASS entries in `progress.tsv` (search for previous failures + commits, write at least 2–3 historical lessons).

### 5. Check settings.json

Required:

- [ ] `"agent": "coordinator"` as default
- [ ] Stop hook QA gate (agent-type, not command-only)
- [ ] **Diff-guard prefix** on the Stop hook — `git diff --quiet` short-circuit (NEW in v0.1; ~30-50% cost reduction)

Recommended (v0.1 additions):

- [ ] PostToolUse `git commit` hook → require `lessons.md` entry on r2+ PASS
- [ ] PreToolUse Edit/Write hook → warn Coordinator on app-code edits (warn-don't-block)

See `references/enforcement.md` for JSON.

### 6. Compare HANDOFF.md against the new context-economy framing

Old framings to look for in your existing HANDOFF.md / coordinator.md:

| Old framing (deprecate) | New framing (replace with) |
|---|---|
| "Coordinator does NOT write application code" (as moral rule) | "Coordinator's context budget is limited; trivial Edits OK, multi-file Reads → delegate" |
| "Coordinator violations 自检" section | Drop. Real cost is context drift, not rule violation. |
| "2 consecutive PASSes / 3 FAIL re-plan" | "r1 PASS exits / r1 FAIL → r2 / same fail → re-plan + write lesson" |
| Long anti-pattern enumeration | Move to `lessons.md` as dated, commit-linked entries |

### 7. Generate a diff report for the user

Present the proposed changes per file, with rationale. Wait for per-file approval. Apply only what's confirmed.

### 8. Backfill evidence

Add `evidence/{date}_{project}-upgrade.md` capturing:
- What was already in place that worked
- What was removed and why
- What was added and what evidence motivated it (link to the project's own audit if there was one)

This becomes input to future skill iterations.

## Common pitfalls during upgrade

1. **Replacing instead of refactoring** — the existing harness has months of project-specific tuning in role bodies. Preserve that; refactor structure only.
2. **Adding lessons.md without the PostToolUse hook** — the file stays empty; the mechanism dies. The hook is what makes it actually get written.
3. **Migrating coordinator language all at once** — change the framing slowly; let it stabilize over a few units before the next change.
4. **Treating reference files as canonical** — they're worked examples. If the project has a different but working pattern, the project wins.

## Validation after upgrade

Run one full unit (plan → build → QA) using the upgraded harness:

- Coordinator drafted spec without diving into source files? ✓
- Builder report cites spec lines? ✓
- QA ran the product, not just read the diff? ✓
- If r2 happened, `lessons.md` got appended? ✓
- Stop hook fired only when diff non-empty? ✓

If all five hold, the upgrade is stable. Otherwise, narrow down the failure and adjust one piece at a time.
