# Reference: Structure Routing (worked examples)

> **Read this as worked examples, not a template.** SKILL.md Step 1 carries the decision itself (prequalifier + three questions + one-line routing). This file is the expanded version: per-structure cases, a prequalifier case, hybrids, and calibration recipes. Every number below is **an example from a specific project, not a quota** — recalibrate per project.

---

## The three questions, expanded

1. **Oracle** — a qualifying oracle is a signal the agents can see but that does not share the generator's blind spots: tests, compiler, exit codes, objective metric commands, reproduction scripts, fixture diffs, screenshot comparison. Verification strength ordering: deterministic checks > visual checks > LLM judge. If an oracle can close the loop, never spend an LLM judge on it.
2. **Blast radius** — low/reversible: sandboxed, git-revertible, rerunnable, no production side effects. High/irreversible: production data, real deploys, money, anything you can't roll back. High radius means a closed oracle is *not* enough on its own — add an independent verification context and a human checkpoint.
3. **Splittability** — many low-coupling sub-tasks (batch fixes, migrations, multi-source collection) vs. one coupled body (most feature work; highly entangled systems where parallel workers would all hit the same wall).

## Routing cases

**Case 0 — prequalifier rejection.** "Help me decide our product strategy for next quarter." No machine- or consistently human-checkable success signal exists; any scaffold would orchestrate opinions. Correct output: no harness — stay in a human-led conversation, and revisit only if a checkable sub-goal emerges (e.g. "draft three options and score them against these five written criteria" — now a fan-out + judge is conceivable).

**Case 1 — solo + check.** "Make this data pipeline 2× faster without breaking `make test`." Oracle closed (timing command + test suite), reversible (git), single body. Structure: one agent looping *act → run check → read exit code → keep or roll back* on a `LOG.md` ledger. **The check command is the evaluator — adding a QA agent here is wasted context.** Minimal files: `GOAL.md` (end state + metric command + budget/stop line), `check.sh`, `LOG.md`, lean `CLAUDE.md`.

**Case 2 — pipeline.** "Migrate 300 test files off deprecated assertions." Oracle closed (suite must stay green), reversible, splittable into ordered stages (inventory → transform → verify → commit per file). Stage gates are commands; a stage enters the next only when its check passes. Fan-out within a stage is fine (headless per-file runs returning OK/FAIL). Minimal files: `PIPELINE.md` (stages + entry/exit checks + rollback), per-stage `check.sh`, a manifest, `SUMMARY.md`.

**Case 3 — triangle.** "Build the billing settings page" (subjective acceptance: layout, copy, UX) or anything touching production money paths (high radius even with tests). Planner writes spec + observable acceptance criteria; Builder implements from the spec; QA is a fresh context that runs the product against the criteria. Even inside a triangle, **every objectively checkable criterion still goes to `tests/` or a command — the QA agent only judges what can't be written as a dead rule.**

**Case 4 — fan-out + judge.** "Evaluate 40 prompt variants" / multi-source research synthesis. Subjective quality, many independent units, low radius. N workers write findings to disk (light references back, not full text); an independent judge grades against a rubric the human defined. Generation ⊥ evaluation, in the wide form: N generators instead of one Builder. Minimal files: `SCOPE.md` (rubric + unit list + spot-check rate), `run.sh` (spawns workers), `findings/` (one file per worker); role files in `.claude/agents/`: coordinator (the resident session — see SKILL.md Step 4 gate wiring) and judge; workers are sacrificial, no role files.

**Hybrids.** A triangle whose build stage fans out across independent modules; a pipeline whose final stage is a triangle for the one subjective deliverable. Route each *stage* by its own signal — structures compose; the questions don't change.

## Calibration recipes (worked numbers — examples, not quotas)

- **Human spot-check anchor (pipeline / fan-out):** wholly automated verdicts drift; keep a light human anchor. One batch-fix project spot-checked ~5–10% of outputs; pick a rate that keeps the anchor honest for yours.
- **Adversarial verification (fan-out claims):** one research setup sent each falsifiable claim to 3 independent verifiers prompted to REFUTE, treated ≥2 refute votes as rejection and a 2–1 split as downgraded confidence. The pattern (independent adversarial votes, refute-biased default) is the point — the counts are not.
- **Few-shot judge calibration:** anchored examples with known verdicts covering clear-fail / marginal / clear-pass (finsim used 3–5). Validate the validator: read a sample of judge transcripts before trusting any automated grade.
- **High-radius overlay:** on any structure, high blast radius adds — sandbox/worktree base, human sync on core-logic changes, and a user-feedback channel. Oracles never cover 100%; the human anchor can be light but not absent.
