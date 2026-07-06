# Changelog

All notable changes to this skill. Updates are evidence-based — each entry cites the project/audit/research that motivated the change.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [0.3.1] — 2026-07-06

- **Hook B contract test** (`evals/hook_b_contract.sh`, self-lint SL-1c; 13 → 14 assertions): the shipped `coordinator-edit-warn.sh` is now extracted from `enforcement.md` and exercised via the real stdin-JSON contract — warns the coordinator on app-code edits, passes Builder-identity / exempt paths / 5-second-retry stamp / fail-open. Closes the "Hook B is validated by hand, not by an eval" open question in `evidence/2026-07-02_v03_pr_adversarial_review.md`.
- **Scenario-runner plumbing wired** (`evals/run_scenarios.sh`): manual and token-costing, never run by CI or `run-evals.sh`; each case generates into a fresh sandbox and is graded **null-floor first** — a deterministic check that already passes in an empty directory counts as non-discriminative, so an all-green run indistinguishable from an empty directory reads UNKNOWN, not PASS. Grading is uncalibrated (the X3 lesson: FAIL is signal, PASS is weak evidence until a human reads the transcripts); calibration, dual-arm baselines, and blind A/B stay deferred.

## [0.3.0] — 2026-06

Oracle-first decision layer + correctness fixes + machine-checkable self-lint. Motivated by the 2026-06 orchestration-upgrade research (`evidence/2026-06-17_orchestration_upgrade.md`: R1–R4 audits + X3 blind A/B, n=1 direction-only); every change below is backed by a machine-verified fact or multi-source evidence. Eval delta: evals.json self-lint 0 → 13 executable assertions, all green at release (see the review-pass note below — the initial rewrite shipped 11, hardened to 13 pre-merge).

### Fixed (P0 correctness)

- **Hook A dead regex** (`references/enforcement.md`): the example PostToolUse regex `\tr[23]\tPASS` could never match this skill's own canonical `progress.tsv` column order (`round | scores | status` — a column apart), and its JSON double-escaping fed grep a literal backslash. Replaced with the column-pinned, POSIX-portable form `grep -E "$(printf '\tr[23]\t[^\t]*\tPASS(\t|$)')"` — verified to match a canonical r2 PASS row and reject r1 rows and FAIL rows containing "PASS" as a substring. The skill's only blocking hook now actually fires.
- **Stale exit rule in `operations_harness.md`** ("two clean rounds = done / three repetitions = escalate") — a v0.1-retired rule that contradicted the canonical rule; v0.2.1's alignment sweep had missed it.

### Added

- **SKILL.md Step 1 — Choose the structure**: prequalifier (no checkable signal → no framework) + three questions (oracle? blast radius? splittability?) + four-structure routing (solo+check / pipeline / triangle / fan-out) + a "too small to harness" exit. The triangle is one structure, not the default. Frontmatter description rewritten to match; eval/experiment trigger words added.
- **`references/structure_routing.md`** — expanded routing cases and calibration recipes; all numbers explicitly marked "examples, not quotas".
- **Hook engineering rule** in `references/enforcement.md`: hooks live in script files for anything non-trivial, and **every hook ships with a minimal trigger self-test** (one line that must match, one that must not, assert exit codes).
- **evals.json rewritten** from a two-versions-stale shell into 11 executable self-lint assertions (hook-must-fire incl. negative/adversarial controls, no-living-gstack-refs by tombstone-marker allowlist, exit-rule-single-source, no-phantom-pointers, decision-layer-present, enforcement-conditional) + a 7-case scenario pool with deterministic post-generation checks (generation runner deliberately not wired — deferred). The old eval#1 expectation that hardcoded worktree parallelism (contradicting our own 2026-05-08 evidence stance) is gone; splittability is now judged, not prescribed.
- **`evals/run-evals.sh`** — runner for the self-lint assertions above (JSON-validate + execute, exit 0 = all green). This is *not* the deferred scaffold-generation runner; that one is still deliberately unwired.

### Changed

- **Enforcement conditional on topology** (`references/enforcement.md`): "L0–L2 are baseline for *every* harness" → baseline for triangle/fan-out; for solo+check and pipeline the L2 gate is a check command, not an agent-type QA gate. Default-agent and agent-type-Stop-hook wording conditioned the same way.
- **Dynamic exit canonicalized**: SKILL.md's r1-PASS rule is the single source; `software_harness.md` / `knowledge_harness.md` / `operations_harness.md` now carry one-line pointers (the upgrade-playbook teaching table and the enforcement veto record are not duplicates and stay).
- **QA calibration rewritten as intent + acceptance line + two field-tested counters** (anchored few-shot with hard per-dimension thresholds — *any dimension failing = overall FAIL, no averaging* — or a project-risk checklist judged PASS/FAIL/UNKNOWN). Numeric quotas across the prompt layer demoted to worked-example status (3-reads, ~5-sec spawn, 5-10 entries, ~50 lines/quarter, ~150 lines, 2–3 lessons, ≥3 promotions) — deleted outright or kept inline as project-attributed observations in their home files; the calibration-recipe numbers (spot-check rate, verifier votes, few-shot counts) live on in `structure_routing.md` as examples.
- **gstack living references zeroed** (the v0.2.1 sweep had missed `enforcement.md` L4 and `upgrade_playbook.md` step 2): keep/remove tables, QA skill-mapping table, dead quick-reference rows and 3.5/4 anti-patterns removed from `software_harness_with_skills.md`; replaced with Playwright MCP / native-equivalent prose. Compliant tombstones (lines carrying retired/historical/evidence markers) are the allowlist and remain.
- `agent_definitions.md`: `opus[1m]` rationale compressed to one sentence + global-rule pointer; invocation how-to compressed to three lines (named-agents accountability sentence kept).

### Explicitly deferred (not in this release)

- QA-no-Edit tools-field sink + the advisory-vs-enforced contradiction (needs one live spawn test). Hook A trigger re-anchoring and exit-2 level review; Hook B scripting (user decision pending). `eval_harness.md` / `experiment_harness.md` templates, dual-arm baselines, blind A/B gate (experiment-gated). knowledge narrowing / operations archival. Upgrade-playbook decision-layer channel + "NEW in v0.1" pin removal. MAINTENANCE.md.

### Review pass (2026-07-02)

Pre-merge adversarial review (5 dimensions, 25 findings confirmed / 1 refuted — `evidence/2026-07-02_v03_pr_adversarial_review.md`) caught the shipped Hook A **still dead in a real session**: the regex was fixed, but the hook read a phantom `$CLAUDE_TOOL_INPUT` (tool input actually arrives as JSON on stdin), and its `echo $?` self-test could never fail. This pass, in the same release:

- **Correctness** — Hooks A and B rewritten as stdin-reading `.claude/hooks/*.sh` scripts per the repo's own hook-engineering rule; Hook A now gates on each PASS row's own date (fixes a cross-day false positive) and covers `r2`-and-later rounds; Hook B gates on stdin `.agent_type` (the session-level `CLAUDE_CODE_AGENT` would misfire on a Builder sub-agent). The self-test asserts exit codes and exits non-zero when the hook is dead.
- **Evals hardened, self-lint 11 → 13** — SL-1 moved from a hand-copied regex to a physical extract-and-execute hook contract (`evals/hook_a_contract.sh`); SL-2 whitewash closed (tombstone marker tightened to path-form `evidence/`, verb list generalized to the retired class incl. `$B`); decision-layer and exit-rule-single-source content assertions added (SL-9a/b, SL-3b/c); phantom-pointer check widened to the whole prompt layer (SL-4); `.github/workflows/evals.yml` gives the suite a trigger.
- **Docs** — dangling `see below` anchor, a distorted external-CLAUDE.md pointer, an `escalate`-vs-`re-plan` paraphrase drift, and a stale line-count anchor fixed; `software_harness_with_skills.md` retired-verb enumeration rewritten tool-agnostically. The motivating research was backfilled as `evidence/2026-06-17_orchestration_upgrade.md`.

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
