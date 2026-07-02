# Orchestration-upgrade research — dead hook, decision layer, and two oracle blind spots

**Date**: 2026-06-17
**Project**: harness-design skill audit + X1–X4 experiments (finsim PR-17 replay; finsim infra docs A/B; cross-domain scaffold blind review; eval-set mining) — 2026-06 orchestration research
**Phase / scope**: 157 retrospective cards + 4 experiments + R1–R4 independent audits + 25 user adjudications (J1–J25) + 3-worker implementation with independent zero-context diff review

> Scope note (README anti-pattern 3): observations below come from projects that exercised the skill — scaffolds it generated for three real briefs (X3), the finsim harness it scaffolded (X1/X2, P3-04), and this repo's own executable assets run against fixtures — not from introspection.

## What was observed

**Experiments (all n=1, direction-only; no statistical significance claimed):**

- **X1 — four orchestration modes, same task** (finsim PR-17 bug replay, 11 held-out acceptance tests as oracle): all four cells 11/11 — ceiling effect, primary instrument non-discriminative. Secondary signals: cost 1 call (solo goal-loop) vs 6 (triangle+QA gate); the independent QA gate was the only cell that caught a real hidden flaky-test race AND the only one ruling "underspecified, not a defect" instead of inventing copy; a builder writing 60 extra self-probes surfaced no new defect ("more self-written tests" ≠ "independent role").
- **X2 — finsim infra docs A/B** (6 probe scenarios, ground-truth checklist judge): slim set lost zero rules, zero hallucinated tools; incumbent set polluted 5 answer sheets with retired-tool prescriptions (/qa-only, $B persistent Chromium, /cso, /investigate — actively prescribed). Bytes dropped only 4.2% — the disease is stale prescriptions, not length.
- **X3 — blind A/B: skill v0.2.1 vs oracle-first decision-tree variant** (3 project briefs, 3 blind judges + deterministic machine checks): the incumbent forced a resident P-B-QA triangle + blocking hooks onto a single-person eval-matrix project (38 vs 23 files; ceremony 2 vs 5). On the soft control the variant regressed 2 points: its self-proclaimed highest-value blocking hook regex `\tr[23]\tPASS` never matches its own progress.tsv column order (scores sits between round and status) — a dead hook, machine-verified. Verdict: **absorb oracle-first as a decision layer; keep the incumbent's engineering discipline** (hooks as scripts, few-shot calibration prefill, no duplicate acceptance registration, code-level hard gates). Complementary layers, not a replacement.
- **X4 + soft-oracle pilot**: 88.5% (139/157) of real retrospective tasks reproducible as evals; rubric+gold soft oracles are a reliable pass/fail gate but a weak ranking instrument (ceiling effect).

**Audits (R1–R4, line-number-verified against 2b44bb7):**

- **R1 (maintenance):** event-triggered maintenance + quarterly sweep; retirement review needs baseline A/B ("with skill vs bare model"); official authoring guidance — assume the model is smart, match freedom to fragility, no time-sensitive content in living docs.
- **R2a/R2b (full-repo audit):** F1 — this repo's own Hook A regex was dead (same column-order bug as X3's variant, ugrep + BSD grep double-confirmed; JSON double-escaping additionally fed grep a literal backslash); F2 — enforcement.md still actively recommended retired gstack safety skills; dynamic-exit existed in 5 places (3 living restatements + 2 legitimate records); software_harness_with_skills.md retention rate 40–45%.
- **R3 (proposal re-review):** confirmed absorb-not-replace; added the "too small to harness" exit.
- **R4 (control vs context):** numeric quotas in prompt files are control, not context — demote to principles + acceptance lines, keep worked numbers as examples. Anchor case **P3-04**: after finsim's QA prompt was rewritten from a fixed template to a project-risk checklist judged PASS/FAIL/UNKNOWN, QA immediately caught a real LAN exposure the template had missed.

**Adjudication:** 25 items (J1–J25) individually ruled by the user in UPGRADE-PLAN-FINAL.md; 8 explicit fix classes entered IMPL-SPEC; X3 protection list (few-shot prefill, no duplicate registration, code-level hard gates) held as red lines.

**Two self-report failures during implementation (each caught only by independent machine verification):**

1. **Worker-B empty dispatch:** a parallel worker dispatched with empty file_ownership wrote none of the 10 references/ changes yet the batch was reported complete. Independent zero-context diff review scored 4/16 with both P0s unfixed; a revision pass landed 16/16.
2. **SL-2 assertion blind spot:** implementer self-reported "gstack living refs = 0, self-lint 11/11 green"; independent re-check found SL-2 grepped only the literal word `gstack`, so retired command verbs (/qa-only, $B, /cso) escaped — a living /qa-only reference survived in lessons_pattern.md while the oracle showed green. Same lesson class as the dead hook: **a green oracle with a coverage hole is worse than no oracle.**

**Verification triple (re-runnable at any continuation point):**

```bash
bash evals/run-evals.sh                    # expect: self_lint ALL GREEN, exit 0
grep -rniE 'gstack|/qa-only|/cso' SKILL.md references/ | grep -icvE 'retired|historical|evidence/'   # expect: prints 0 (the command's own exit code is 1 — that's fine)
printf '2026-06-06T00:00:00Z\tauth\tr2\t9/10\tPASS\t0.41\tfix login\tabc1234\n' | grep -qE "$(printf '\tr([2-9]|[1-9][0-9]+)\t[^\t]*\tPASS(\t|$)')"; echo $?   # expect: 0
```

## What worked

- Deterministic machine checks over prose review: the dead hook, the gstack pollution, and the SL-2 hole were all found by running assets against fixtures, never by reading.
- Independent verification contexts (X1's QA gate; the zero-context diff review; the second-model re-check) — each caught something the generator's self-report missed.
- Hooks extracted to scripts with self-tests (incumbent discipline) beat inline JSON regexes (the variant's dead hook).
- Blind judging with pre-declared deterministic dimensions kept the X3 verdict taste-resistant.

## What didn't earn its keep

- The example Hook A regex shipped since v0.1 — the skill's only blocking hook could never fire (no fixture had ever been fed to it).
- evals.json as a prose shell — zero executable assertions, two versions stale.
- Fixed numeric quotas in prompt files (3-reads, 3–5 few-shot, 5–10% spot-check as rules) — control dressed as context.
- The default-triangle assumption for single-person, oracle-closed projects (X3 eval brief: 38 files of ceremony).
- Literal-string oracles (`grep gstack`) as retirement guards — verbs outlive the brand name.

## What was missing

- A decision layer before scaffolding: nothing asked "can a command judge success? is failure reversible? does the work split?" before instantiating roles.
- A prequalifier refusing orchestration when no consistently checkable success signal exists.
- A hook trigger self-test rule (one must-match + one must-not-match line before trusting any hook).
- Executable self-lint for the skill repo itself.

## Implications for SKILL.md / references

Shipped as v0.3.0 (CHANGELOG [0.3.0], commit e39d983): Hook A column-pinned regex + hook self-test rule; SKILL.md Step 1 decision layer (Question 0 + three questions + four-structure routing; triangle = one of four, not the default); references/structure_routing.md (all numbers marked examples-not-quotas); dynamic-exit canonicalized to one source; gstack living refs zeroed under a tombstone-marker allowlist; enforcement conditional on topology; evals.json → executable self-lint assertions + 7-case scenario pool (generation runner deliberately unwired); QA calibration rewritten as intent + acceptance line + two field-tested counters (per-dimension hard thresholds no-averaging; risk checklist PASS/FAIL/UNKNOWN — P3-04's LAN-exposure catch is the field evidence behind counter (b)).

A pre-merge adversarial review of that PR (see `evidence/2026-07-02_v03_pr_adversarial_review.md`) later found the shipped Hook A still dead for a *different* reason (phantom `$CLAUDE_TOOL_INPUT`) and several eval blind spots — the same "green oracle, coverage hole" class this research first named.

## Open questions

- All deltas are n=1, direction-only; X3's soft-control regression (−2) may understate the dead hook's cost; the variant's weakness may be this-implementation, not method ceiling.
- Deferred, experiment-gated: eval/experiment harness templates, dual-arm baselines, blind A/B gate; QA-no-Edit tools-field sink (needs a live spawn test); Hook B scripting, Hook A trigger re-anchoring; knowledge narrowing / operations archival.
- SL-2's verb list covers only the verbs that already leaked (/qa-only, /cso); the retired-verb class is larger — generalize or re-audit periodically.
- Scenario evals SE-001..007 assert nothing until a generation runner exists.
