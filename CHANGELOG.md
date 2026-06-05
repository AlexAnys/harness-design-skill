# Changelog

All notable changes to this skill. Updates are evidence-based — each entry cites the project/audit/research that motivated the change.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [0.2.1] — 2026-06-05

Documentation hygiene + gstack runtime retirement. Motivated by `evidence/2026-06-05_gstack_retirement.md`: the user retired gstack entirely (closing the 05-08 → 05-10 → 05-15 → 06-05 decision chain), and a 39-agent deep-research audit of the skill + finsim_Mini found six instances of documentation drift, all line-verified before fixing.

### Changed

- **gstack runtime layer marked retired across living docs.** `software_harness_with_skills.md` gains a status banner (runtime-layer sections kept as historical record; methodology layer remains current). `agent_definitions.md` / `software_harness.md` browser-QA recommendations demoted to historical notes — Playwright MCP restored as the default. SKILL.md routing-table label updated. The QA-runs-the-product doctrine is unchanged (tool-agnostic).
- **Exit-rule wording aligned** to SKILL.md's simplified rule (r1 PASS exits) in `software_harness.md` and `knowledge_harness.md` — the old "two consecutive rounds" phrasing had survived v0.1's simplification in both worked examples.
- **Version pins removed from living docs**: SKILL.md banner no longer names a skill version; hardcoded model versions ("Opus 4.6", "Opus 3.5 vs 4.6") replaced with version-agnostic wording. Version facts live in CHANGELOG only.
- **`/investigate` residue cleaned** from `agent_definitions.md` (it was removed from recommendations in v0.2); `/diagnose` is the debugging default.
- **README layout block completed** (`software_harness_with_skills.md` + the two newer evidence files) and stale "NEW" tags dropped.

### Deferred (explicitly not in this release)

- **Dynamic-workflow integration** (five candidate proposals from the 2026-06-04 research): zero in-harness empirical runs exist; dual-lens adversarial verification killed the whole line pending one real run with a verifiable transcript. See the evidence file's Open questions.
- **finsim seven-piece patterns** (archive/prune/STYLE/COMMIT_TEMPLATE etc.): runtime-unverified (~2-week window, zero observations, unpushed). Revisit after Verify metrics are observable.

## [0.2.0] — 2026-05-16

Pruned skill ecosystem + integration with external skill packs. Motivated by the realization that Claude Code's native tools (Read/Write/Edit/Bash/Agent/Hooks/etc.) already provide most of what wraparound prompt-template skills offer — only **unique technology** (browser daemon, design pipelines, well-tuned audit prompts) and **methodology that Claude Code doesn't ship** (TDD discipline, diagnosis loop, ubiquitous-language grilling) earn shelf space.

### Added

- **`references/software_harness_with_skills.md`** — two-layer model (methodology = mattpocock, runtime = pruned gstack), per-role skill mapping (Coordinator/Builder/QA), pruned install procedure, blackboard updates (CONTEXT.md + docs/adr/). *Motivated by*: `evidence/2026-05-15_mattpocock_vs_gstack.md`.
- **`.harness/CONTEXT.md`** + **`.harness/docs/adr/`** to the blackboard layout. Owned by mattpocock `/grill-with-docs`. Created lazily — first term resolved → file appears. ADRs use three-condition rule (hard-to-reverse + surprising-without-context + real-trade-off).
- New entries documenting how mattpocock's CONTEXT.md / ADR pattern composes with our `lessons.md` (non-overlapping: glossary / decisions / failure-fixes / accepted-tradeoffs each have a home).

### Changed

- SKILL.md routing table promotes `software_harness_with_skills.md` as the recommended starting point for software projects with external skill packs.
- Coordinator default for new-project planning shifts from gstack `/office-hours` → mattpocock `/grill-with-docs` (writes CONTEXT.md inline; more terse; ADR three-condition rule prevents decision-doc bloat).
- Builder default debugging shifts from gstack `/investigate` → mattpocock `/diagnose` (significantly higher methodology density: 10 explicit feedback-loop construction strategies, perf vs logic branch separation, regression-test seam discipline).

### Removed (from the recommended install, not from this repo)

- 29 gstack skills replaceable by Claude Code native or mattpocock equivalents. See `references/software_harness_with_skills.md` "Remove from gstack" table for the full list. Notable removals: `/office-hours` `/autoplan` `/plan-*-review` `/investigate` `/careful` `/freeze` `/learn` `/ship` `/codex` `/context-save` etc.

### Kept

- 16 gstack skills with non-replicable tech: `/browse` daemon, `/qa` `/qa-only`, `/cso`, `/canary` `/benchmark`, `/design-shotgun` `/design-html` `/design-review` `/design-consultation`, `/scrape` `/skillify`, `/pair-agent`, browse adjuncts.

### Evidence-driven rationale

- `evidence/2026-05-15_mattpocock_vs_gstack.md` — head-to-head comparison of mattpocock and gstack across philosophy, skill quality, and harness fit. Includes an e2e test running mattpocock `/tdd` in a sandbox (`/tmp/skills-eval-20260516/tdd-demo/`) that surfaced a real `size=0` infinite-loop bug — concrete demonstration of TDD's vertical-slicing discipline catching what spec-writing would miss.

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
