# Changelog

All notable changes to this skill. Updates are evidence-based — each entry cites the project/audit/research that motivated the change.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [0.1.0] — 2026-05-13

Initial public release. Synthesizes the original Anthropic-derived meta-skill with two new lines of evidence:

### Added

- **`references/context_economy.md`** — explicit fourth principle. Role separation is context sharding, not role purity. *Motivated by*: finsim 3.4-day single session compaction risk observation. (`evidence/2026-04-29_finsim_audit.md`)
- **`references/lessons_pattern.md`** — rolling failure capture in `.harness/lessons.md` with active/superseded/deprecated state machine. *Motivated by*: finsim PR-CALENDAR-1 hit a CLAUDE.md-warned gotcha because the warning was static and untriggered.
- **`references/upgrade_playbook.md`** — non-invasive upgrade procedure for existing harnesses. *Motivated by*: this skill being used to upgrade finsim, not just greenfield projects.
- **`evidence/`** directory — dated findings from real projects, format defined in `evidence/README.md`.
- **PostToolUse hook on `git commit`** — require `lessons.md` entry on r2+ PASS. The only blocking hook in the skill. (`references/enforcement.md`)
- **Stop hook diff-guard prefix** — skips agent-type QA gate when `git diff` is empty. Cuts ~30–50% of Stop hook invocations on team-mode sessions. (`references/enforcement.md`)
- **PreToolUse warn (don't block) on Coordinator Edit/Write to app code** — surfaces context cost without forbidding legitimate quick fixes. (`references/enforcement.md`)

### Changed

- **SKILL.md compressed from ~700 lines to ~120 lines.** Applies skill-creator's progressive-disclosure principle (`< 500 lines ideal`). Detail moved to references; SKILL.md is now routing + invariants.
- **Three principles reframed** as "the only invariants". Context economy explicitly elevated as hidden fourth.
- **Dynamic exit rule simplified** from "2 consecutive PASS / 3 FAIL re-plan" to "r1 PASS exits / r1 FAIL → r2 / same fail → re-plan + write lesson." finsim data showed 3% real trigger rate on the old rule (vestigial).

### Removed (intentionally)

- **`test.md` acceptance file requirement** — finsim never wrote one and nothing failed. Aspirational scaffolding.
- **Duration/domain ritual classification table** — formal taxonomy not used in practice; judgment is faster.
- **15-item instantiation checklist** — compressed to 5 items in SKILL.md Step 3.
- **"Sources read-only" invariant from main SKILL.md** — only relevant when there's an input data layer; demoted to operations_harness.md.
- **6-item anti-pattern enumeration** — replaced with 4 observed-in-the-wild patterns, all linked to evidence files.

### Evidence-driven rationale

This v0.1 release is the first one explicitly grounded in real-project data. Every change above links to either:

- `evidence/2026-04-29_finsim_audit.md` — what the original meta-skill produced in a real software project, and where the bloat / drift was
- `evidence/2026-05-08_deep_research_integration.md` — how 2026-spring coding-agent best practices (OpenAI harness engineering, Anthropic agent teams, Martin Fowler harness writeups) converge with the finsim findings

Future releases will follow the same pattern: cite a dated evidence entry for every meaningful change.

## [pre-0.1] — Original Anthropic-derived skill

Prior to v0.1, this lived as a single-file skill at `~/.claude/skills/harness-design/SKILL.md`, derived from Anthropic's harness-design writeup. The original principles (three core roles, blackboard, dynamic exit, ceremony scales with risk) carry forward into v0.1 unchanged in intent; the v0.1 changes refine the framing and trim the scaffolding that real-project evidence showed didn't earn its keep.
