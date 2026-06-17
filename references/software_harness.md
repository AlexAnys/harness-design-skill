# Reference: Software Harness (worked example)

> **Read this as an example, not a template.** The shapes below are what a typical software project harness looks like after applying the SKILL.md principles. Your project's actual harness should diverge wherever the observed single-agent failures differ.

---

## When this shape applies

You've run the single-agent baseline on a software task and observed some combination of:

- The agent self-approves work that has runtime bugs (UI broken but "looks fine" to code review)
- Scope creeps across the session — the agent fixes things that weren't asked for and misses things that were
- Context is lost across sessions; a new session re-derives decisions already made
- The agent produces code that matches a spec's literal text but misses its intent

If you see *one* of these, you need *one* component. Not the whole shape at once.

---

## Typical agent roles

Three roles, each answering a different question:

- **Planner** — "what needs to be built, and how will we know it's done?" Writes a plan with scope, acceptance criteria, and constraints. Does not specify which functions to write.
- **Builder** — "how do I implement this within the project's existing patterns?" Reads the plan, reads nearby code for conventions, produces changes, writes an honest build report that names what it did and what it deferred.
- **QA** — "does the product actually do what the plan said?" Reads the plan and the build report, then *uses the product* — runs the app, clicks through flows, inspects network calls, checks layouts with browser automation. Writes a report with per-dimension pass/fail, not a global "looks good."

The coordinator, if present, aligns intent with the user and hands the plan to the Builder. Once handoff happens, the coordinator steps back.

---

## Typical blackboard layout

```
.harness/
  spec.md                          ← plan ground-truth (who, what, done criteria)
  progress.tsv                     ← one row per verify round; enables "did this round beat the last?"
  HANDOFF.md                       ← session-continuation note (last-done, next-step, open decisions)
  contracts/
    {unit}.md                      ← acceptance alignment between Builder and QA, written before work starts
  reports/
    build_{unit}_r{N}.md           ← Builder's honest report for round N
    qa_{unit}_r{N}.md              ← QA's independent assessment for round N
    final.md                       ← integration-level assessment when all units done
```

The file names here are not magic. What matters:

- **`spec.md`** is the ground truth the Builder and QA both read.
- **`progress.tsv`** lets you answer "is the frontier advancing?" across rounds. Example columns:
  `timestamp | unit | round | scores | status | cost_usd | description | git_commit`
- **`HANDOFF.md`** is updated at the end of every session so the next session starts with full context from a short read.
- **`contracts/{unit}.md`** is only written when the unit is complex enough that "done" isn't obvious from `spec.md`. Most units don't need one — only when QA and Builder would otherwise disagree on acceptance.
- Reports live in a per-round structure so patterns are visible over time. Appending to a single file destroys that signal.

---

## Acceptance alignment (when, and what)

For a unit where "done" is obvious from the spec, skip this. For a unit where it isn't — especially new patterns, new integrations, or anything where Builder and QA could reasonably disagree — Builder writes a short proposed acceptance list, QA adds what's missing, both agree, and only then does Builder start coding. This catches disagreements before work rather than at the end.

This replaces the older "Sprint Contract" concept. The reframe is important: the point is **alignment on done**, not **chunking work into sprints**. The modern frontier model can work coherently through large units; splitting those into sprints is optimizing for a previous model generation's limits, not the current one's.

---

## Control loop for software

```
Plan → Build → Verify ─── PASS → git commit → next unit
                        └─ FAIL → same failure as last round?
                                    ├─ NO  → Builder fixes, re-verify
                                    └─ YES → spec / approach is wrong, re-plan
```

**Dynamic exit:** apply SKILL.md's canonical rule (r1 PASS exits the unit; same fail twice → re-plan + lesson). The loop diagram above already encodes the FAIL branch.

**Keep / discard:**
- PASS → `git commit` with a descriptive message. Frontier advances.
- FAIL, fixable → Builder patches, re-verify.
- FAIL, fundamentally broken → `git reset` to last good state, try a different approach, log the discard in progress.tsv so patterns emerge.

---

## QA calibration (essential)

An uncalibrated QA is systematically lenient — a known failure mode (evidence: see this repo's `evidence/` on judge self-preference residue and uncalibrated soft-scoring ceilings). Counter it with one of two field-tested approaches:

- **(a) Anchored few-shot examples** with known verdicts covering clear-fail / marginal / clear-pass — count set by project (finsim used 3–5) — plus per-dimension hard thresholds: break quality into named dimensions, each with an explicit pass bar. **Any dimension failing = overall FAIL. No averaging.**
- **(b) A project-risk checklist judged item-by-item PASS/FAIL/UNKNOWN** — list the risks that actually apply to *this* project and force an explicit verdict on each (this rewrite once caught a real LAN exposure that the template version missed — see `evidence/`).

Domain-specific failure modes from the domain research step go into whichever form you pick — "check that the popup correctly reloads after background-script restart" is the kind of specific thing generic QA misses. Positive framing ("finding an issue = doing your job well") is a technique some setups found useful, not a rule.

---

## QA must use the product, not read the code

For anything with a UI, this means browser automation (Playwright MCP is the usual choice). The QA agent actually loads the page, clicks the thing, inspects the result, captures a screenshot or console log. Code review misses CSS layout issues, race conditions, data-format mismatches, keyboard-navigation bugs, and any interaction that involves the browser's actual behavior.

For CLI tools and APIs, the analog is the same: actually invoke it, capture the output, diff against expectations. Don't grade from the source alone.

### Browser QA daemon (historical note)

v0.1–v0.2 recommended gstack's `/qa-only` persistent-Chromium daemon here (sub-100ms commands vs Playwright MCP cold starts; it caught finsim's PR-AUTH-1 inline-style bug via `getComputedStyle`). gstack was retired in June 2026 — see `evidence/2026-06-05_gstack_retirement.md`. The doctrine above is tool-agnostic and unchanged: QA uses the product through a real browser, report-only, no Edit. Playwright MCP is the current default; whether it suffices for authenticated multi-step flows is an open question tracked in the evidence file.

---

## Parallel units with worktrees

When multiple units are independent (e.g. six modules that don't import from each other), you can run Builders in parallel using git worktrees — one worktree per unit, each with its own branch. Each Builder produces its own build report, each gets QA'd independently, and passing units are merged back. This is a performance optimization, not a correctness requirement. Use it when you actually have independent units; forcing parallelism on entangled work creates merge hell.
