# v0.3 PR adversarial review — a green oracle hiding a still-dead hook

**Date**: 2026-07-02
**Project**: harness-design skill (this repo), PR for v0.3.0 (`v0.3-explicit-fixes` @ e39d983)
**Phase / scope**: pre-merge review of the v0.3 diff (15 files) — 5 review dimensions run in parallel, each confirmed finding independently reproduced by a separate skeptic context; 31 agents total

## What was observed

The review split into five dimensions — hook regex, hook self-test, executable-evals adversarial, docs consistency, methodology fidelity — and every candidate finding was handed to an independent skeptic that had to reproduce it against the real repo (or a scratchpad copy) before it counted. **25 findings confirmed, 1 refuted.** The refuted one (a "prequalifier rejection has no re-entry pointer" claim) was killed because the SE-006 expected behavior already matched SKILL.md:45 line-for-line — a nice-to-have, not a defect.

The load-bearing findings, all machine-reproduced:

- **Blocker — Hook A still dead in a real session** (`references/enforcement.md`). v0.3's headline fix corrected the regex's column order, but the hook's first clause read `$CLAUDE_TOOL_INPUT`, which **Claude Code does not set** — tool input arrives as JSON on stdin. Confirmed end-to-end with `claude -p` (Claude Code 2.1.198): the hook env carried `CLAUDE_PROJECT_DIR` but no `CLAUDE_TOOL_INPUT`; `strings` on the binary found 0 occurrences. So the "only blocking hook now fires" claim was true in an isolated regex self-test and false in a session — the dead point had simply moved from the regex to the input path. Hook B shared the bug (`$CLAUDE_AGENT_NAME`, also phantom; identity is on stdin as `.agent_type`).
- **The self-test that should have caught it was theater.** enforcement.md had just shipped a rule — *every hook ships with a trigger self-test that asserts exit codes* — and the very next example only `echo`ed `$?` instead of asserting it, so it stayed exit 0 under a dead regex. A CI step or `&& trust` gate reading that exit code got a false green.
- **The evals tested copies, not the physical asset.** SL-1b/c/d exercised a regex re-typed inside evals.json; SL-1a pinned only a substring. Injecting a broken regex into the real enforcement.md left all 11 assertions green. Same decoupling for the decision layer: emptying `structure_routing.md` to 0 bytes, or deleting the whole four-structure routing table, stayed 11/11 green — v0.3's headline deliverable had zero content assertions.
- **The retirement guard could be whitewashed.** SL-2's tombstone allowlist keyed on the bare word `evidence`, a high-frequency legit word here; any live retired-tool instruction that mentioned "evidence" in the same line was waved through. And the verb list (`gstack|/qa-only|/cso`) missed `$B` and eight other retired verbs — one live instance (`software_harness_with_skills.md:27` enumerating 10 gstack verbs + recommending "browser daemon / Pretext") sat in exactly that blind spot while the suite showed green.

## What worked

- **Independent per-finding reproduction.** Every confirmed finding came with a re-runnable script; the one refuted finding was refuted the same way. Self-report was never trusted — the same discipline the skill preaches.
- **Running assets against fixtures beat reading them.** The phantom env var, the copy-not-physical drift, and the SL-2 whitewash were all found by executing, not reviewing prose.

## What didn't earn its keep

- **`echo $?` as a self-test.** Printing an exit code for a human to eyeball is not an assertion; under a dead hook it is indistinguishable from success.
- **Literal-string assertions as drift guards.** A pinned substring or a re-typed regex copy cannot detect that the shipped asset changed. Only extracting and *executing* the shipped hook catches it.

## What was missing

- **A behavioral eval for the hook.** Nothing fed the actual hook a stdin JSON payload and checked the exit code — so both the phantom-env-var death and any future regex drift were invisible to the "executable evals".
- **Content assertions for the decision layer.** The four-structure routing table and `structure_routing.md` had presence-of-file checks but no presence-of-content checks.
- **Any automatic trigger.** No CI workflow, no git hook — the regression suite ran only when someone remembered to.

## Implications for SKILL.md / references

Fixed in this review pass (CHANGELOG [0.3.0] → "Review pass (2026-07-02)"):

- **Hooks A and B rewritten as stdin-reading scripts** (`.claude/hooks/*.sh`), following the repo's own hook-engineering rule; Hook A gates on each PASS row's own date (fixing a cross-day false positive) and covers `r2`-and-later rounds; Hook B gates on stdin `.agent_type` (not the session-level `CLAUDE_CODE_AGENT`, which would misfire on a Builder sub-agent).
- **Self-test rewritten to assert the real contract** — constructs stdin JSON, asserts exit codes, exits non-zero when the hook is dead.
- **SL-1 now extracts and executes the physical hook** (`evals/hook_a_contract.sh`) against a fixture matrix (block / non-commit / same-day-lesson / fail-open / r1-no-overfire / adversarial PASS-substring) — a re-introduced phantom var or dead regex turns it red. SL-1a pins the full regex, not a substring.
- **SL-2 marker tightened** to path-form `evidence/` and the verb list generalized to the retired class (incl. `$B`); `software_harness_with_skills.md:27` rewritten tool-agnostically with tombstone markers.
- **SL-3b/SL-3c** added (canonical exit-rule single-source: body-present + verbatim-copy canary); **SL-9a/SL-9b** added (decision-layer content in SKILL.md + `structure_routing.md` non-empty with its four case names); **SL-4** widened to the whole prompt layer with a hyphen/digit/upper-tolerant charset.
- **`.github/workflows/evals.yml`** runs the suite on push/PR — the guard now has a trigger.
- Assorted doc-consistency fixes (dangling anchors, a distorted external pointer, a drifted paraphrase of the canonical exit rule, stale line-count anchor).

## Open questions

- ~~The self-test / contract test cannot yet observe Hook B behaviorally (warn-only, lower stakes) — it is validated by hand, not by an eval.~~ *Resolved in 0.3.1: `evals/hook_b_contract.sh` (self-lint SL-1c) exercises the shipped Hook B end-to-end.*
- SL-2's verb list is still an enumeration; a genuinely new retired verb outside the list stays invisible until re-audit. The tombstone-marker approach has a residual narrow channel (a live line that cites an `evidence/` path can still be waved through) — accepted for a lint.
- The scenario evals (SE-001..007) still assert nothing without a generation runner, which stays deliberately deferred. *Update 0.3.1: a manual, uncalibrated runner is wired (`evals/run_scenarios.sh`, null-floor gated); grading calibration and dual-arm baselines remain open.*
