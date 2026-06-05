---
name: harness-design
description: Design and set up a multi-agent harness for any project type — software (Planner → Builder → QA), knowledge compilation (Coordinator → Compiler → QA), or operations (Coordinator → Executor → Monitor). Use this skill whenever the user wants to build with multiple AI agents, set up automated workflows, create an agent pipeline, apply harness methodology, or structure any complex task that benefits from separating planning, execution, and verification. Also use when the user mentions "harness", "multi-agent", "planner/builder/qa", "coordinator/compiler", "generator/evaluator", or wants to coordinate multiple Claude Code instances.
---

# Harness Design

A meta-skill for setting up multi-agent harnesses. The output is the scaffolding (agents, blackboard, hooks) that the project uses to do its real work — not the work itself.

> This skill is **evidence-based**: it updates after each real project from observations recorded in `evidence/`. See `CHANGELOG.md` for version history and `evidence/` for the raw findings.

---

## Three principles (the only invariants)

1. **Plan ⊥ Execute** — the agent that converts user intent into a markdown plan must be a different context from the agent that executes the plan.
2. **Execute on documents** — every executor reads from a markdown blackboard and writes a markdown report. No verbal handoffs, no implicit state.
3. **Generate ⊥ Evaluate** — the agent that produces work cannot be the agent that judges it. The evaluator runs the product, not just reads the code.

## The hidden fourth — Context Economy

Role separation is not aesthetic and not about "self-persuasion bias." It is **context sharding**:

- The Coordinator's context must stay lean across the project's lifetime to make sound long-horizon decisions.
- Generators and Evaluators are **sacrificial** contexts — they fill up doing dirty work and die at task end.
- The blackboard (`.harness/` files) is how state survives the death of sacrificial contexts.

This reframe matters: it tells you when role separation can be relaxed (a trivial Coordinator-side fix is cheaper than a Builder spawn) and when it must hold (anything that would force Coordinator to Read multiple source files).

See `references/context_economy.md`.

---

## Step 0 — Detect mode

Does the target project already have `.claude/agents/` with agent definitions?

- **NO** → New build. Go to Step 1.
- **YES** → Upgrade. Read `references/upgrade_playbook.md`.

## Step 1 — Build the minimum viable harness

Three roles, one blackboard, two `.claude/` files.

```
.claude/
├── agents/
│   ├── coordinator.md
│   ├── builder.md
│   └── qa.md
└── settings.json   ← "agent": "coordinator" + Stop hook QA gate

.harness/
├── spec.md         ← current plan (Coordinator-written, user-confirmed)
├── progress.tsv    ← one row per QA round
├── HANDOFF.md      ← cross-session continuity
├── lessons.md      ← rolling failure → fix → prevention (v0.1)
├── CONTEXT.md      ← domain glossary, ubiquitous language (v0.2, when /grill-with-docs is used)
├── docs/adr/       ← architectural decision records (v0.2, three-condition rule — see below)
└── reports/        ← build_*.md + qa_*.md per round
```

Routing table — read only what you need:

| If you need … | Read |
|---|---|
| Software project + skill packs (mattpocock methodology layer; gstack runtime retired 2026-06) | **`references/software_harness_with_skills.md`** |
| Software project blackboard, agent files, browser verification | `references/software_harness.md` |
| Knowledge / wiki / research harness (wiki-as-blackboard) | `references/knowledge_harness.md` |
| Operations / continuous-loop harness (experience layer) | `references/operations_harness.md` |
| YAML frontmatter, tool allocation, MCP integration | `references/agent_definitions.md` |
| Hooks, settings.json, what to enforce vs warn | `references/enforcement.md` |
| Rolling lessons capture + maintenance | `references/lessons_pattern.md` |
| Why role separation = context economy + practical rules | `references/context_economy.md` |
| Upgrading an existing harness without breaking it | `references/upgrade_playbook.md` |

## Step 2 — Do NOT add by default

Earlier versions of this skill carried extra scaffolding that the finsim audit (`evidence/2026-04-29_finsim_audit.md`) showed did not earn its keep. Skip unless project data justifies it:

- `test.md` acceptance file (finsim never wrote one; nothing failed)
- Duration / domain ritual classification table (judgment is faster)
- 15-item instantiation checklist (compressed to 5 below)
- "Sources read-only" invariant (only applies when there's an input data layer)
- Long anti-pattern enumerations in the main skill (each one belongs in a real lesson, dated and commit-linked)
- 2/2 consecutive-PASS dynamic exit rule (real trigger rate: 3% in finsim — vestigial)

Use the simpler rule: **r1 PASS exits the unit. r1 FAIL → r2. Same fail again → re-plan and write a lesson.**

## Step 3 — Instantiation checklist (5 items)

- [ ] Three role files in `.claude/agents/` — coordinator, builder, qa
- [ ] `.harness/` exists with empty `spec.md`, `progress.tsv` header, `lessons.md` header
- [ ] `.claude/settings.json` sets `"agent": "coordinator"` + Stop hook QA gate
- [ ] CLAUDE.md describes project rules + harness roles in ≤ 2 screens
- [ ] First task spec written and user-confirmed before any code is touched

## Anti-patterns observed in the wild

Only four, all evidence-backed (see `evidence/`):

1. **Coordinator dives in to "fix it quick" repeatedly** → context bloat, eventual compaction loss of early decisions. The fix it produced is fine; the long-tail context degradation is invisible. → `references/context_economy.md`.
2. **Same failure happens twice without a lesson written** → known gotcha keeps biting. finsim's PR-CALENDAR-1 r1 FAIL hit a gotcha CLAUDE.md explicitly warned about, because nothing forced new gotchas back into the static rules. → `references/lessons_pattern.md` + PostToolUse hook in `references/enforcement.md`.
3. **QA reads the diff but doesn't run the product** → ships visual / runtime bugs that look fine in code review. finsim's PR-AUTH-1 stageC r1 FAIL (inline style overriding CSS height) was only caught because QA actually rendered the page. → `references/software_harness.md` (browser verification patterns).
4. **Spec becomes a wishlist nobody verifies against** → scope drifts silently. Build report should cite spec line numbers; QA verdict references both.

## Evidence-based iteration

This skill updates as evidence arrives:

- `evidence/{date}_{project}.md` — dated findings from past projects (audits, post-mortems, what worked, what didn't).
- After each real project ships, write a short evidence entry.
- Promote stable findings into SKILL.md or the references; demote outdated guidance to historical notes (don't delete — keep the trail).
- `CHANGELOG.md` records what changed and which evidence drove it.

See `evidence/README.md` for the template.
