# Software Harness with External Skill Packs

> For software projects using the mattpocock methodology skills. This reference shows how to wire them into the three harness roles **without bloating Coordinator context** or duplicating Claude Code native capabilities.

> **Status 2026-06-05 — gstack retired** (quality + context-cost grounds; see `evidence/2026-06-05_gstack_retirement.md`). Only the methodology layer (mattpocock) remains current. Browser QA = Playwright MCP (`references/agent_definitions.md`); the historical two-layer keep/remove analysis lives in the evidence file, not here.

## The layered mental model

```
┌─────────────────────────────────────────────────────────────────┐
│  Methodology layer — how the agent thinks                       │
│  mattpocock/skills · pure prompts · zero infra dependency       │
│  /tdd /diagnose /grill-with-docs /zoom-out /to-prd /to-issues   │
│  /improve-codebase-architecture /prototype /triage /handoff     │
├─────────────────────────────────────────────────────────────────┤
│  Claude Code native — already provided, do not re-install       │
│  Read / Write / Edit / Bash / Grep / Glob / Agent / TeamCreate  │
│  SendMessage / Hooks / Plan mode / /compact / WebFetch          │
├─────────────────────────────────────────────────────────────────┤
│  Harness layer (this skill) — role separation + blackboard      │
│  Coordinator / Builder / QA + .harness/* + lessons + hooks      │
└─────────────────────────────────────────────────────────────────┘
```

Runtime tooling (browser daemons, design pipelines) is introduced per-need — check Claude Code native first. That check is what retired gstack; see `evidence/2026-05-15_mattpocock_vs_gstack.md`.

**Critical principle**: most prompt-template skills (`/office-hours`, `/autoplan`, `/plan-*-review`, `/investigate`, `/careful`, `/freeze`, `/ship`, `/codex`, `/learn`, `/context-save`, etc.) are **replaceable** by Claude Code native + a 50-line `.harness/` file or a few Bash lines. Keep only the skills with **unique technology** (browser daemon, Pretext layout, structured prompts you genuinely cannot reproduce by hand).

The pruning rationale + evidence: `evidence/2026-05-15_mattpocock_vs_gstack.md`.

---

## Methodology install (mattpocock)

```bash
git clone https://github.com/mattpocock/skills.git ~/Projects/mattpocock-skills
bash ~/Projects/mattpocock-skills/scripts/link-skills.sh
```

This adds 24 skills as symlinks into `~/.claude/skills/`. The script skips `deprecated/`.

Where retired runtime skills had unique value, the current equivalents are: session save/restore → native `/compact` + `.harness/HANDOFF.md`; destructive-command guards → PreToolUse hooks (`references/enforcement.md`); freeform memory capture → `.harness/lessons.md`; shipping → Bash + `gh pr create` / `gh pr merge`. The full historical keep/remove analysis: `evidence/2026-05-15_mattpocock_vs_gstack.md`.

---

## Mapping skills to harness roles

### Coordinator (lean context, long-horizon decisions)

| Trigger | Skill to invoke |
|---|---|
| New project / new direction | mattpocock `/grill-with-docs` — challenges plan against existing domain model, writes CONTEXT.md / ADRs inline |
| Convert this conversation to a PRD | mattpocock `/to-prd` |
| Break plan into independent issues | mattpocock `/to-issues` |
| Need second opinion on architecture | Bash + `codex exec --full-auto`, capture output, decide |
| Session getting long, save state | Claude Code native `/compact` + update `.harness/HANDOFF.md` |
| Long-session token costs spiking | mattpocock `/caveman` — ultra-compressed communication mode |

Coordinator stays in methodology + planning + delegation — execution-flavored skills run in Builder/QA contexts, not here.

### Builder (sacrificial context, gets work done)

| Trigger | Skill to invoke |
|---|---|
| New feature / new code | mattpocock `/tdd` — red→green→refactor, vertical slicing |
| Bug or perf regression | mattpocock `/diagnose` — feedback-loop-first, 6-phase discipline |
| Confused about a module | mattpocock `/zoom-out` — explain in context of the whole system |
| Want to try a design before committing | mattpocock `/prototype` — throwaway prototype, terminal or UI variant |
| Quarterly cleanup pass | mattpocock `/improve-codebase-architecture` |

Builder owns the inner loop. Use `/tdd` / `/diagnose` as the **default** for non-trivial work — they enforce vertical slicing and feedback loops that drive quality.

### QA (sacrificial context, independent verification)

Browser verification = **Playwright MCP, report-only**: QA loads the real page, exercises the flow, captures screenshots / console output as evidence. Security-sensitive changes (auth / permissions / payments) → native `/security-review` or a human pass. QA **never edits source code** — findings go to `qa_*.md`, then SendMessage to Builder.

---

## Blackboard updates for v0.2 (CONTEXT.md + ADRs from mattpocock)

mattpocock's `/grill-with-docs` writes two artifacts that complement our existing blackboard:

```
.harness/
├── spec.md          current plan (Coordinator)                       (v0.1)
├── progress.tsv     one row per QA round                             (v0.1)
├── HANDOFF.md       cross-session note                                (v0.1)
├── lessons.md       rolling failure → fix → prevention                (v0.1)
├── CONTEXT.md       domain glossary + ubiquitous language             (v0.2 NEW)
├── docs/adr/        architectural decision records                    (v0.2 NEW)
└── reports/         build_*.md + qa_*.md per round                   (v0.1)
```

**CONTEXT.md** is the project's glossary. mattpocock owns the format (terms, definitions, relationships, flagged ambiguities). Written lazily — first term to resolve triggers file creation. Devoid of implementation detail. The agent uses it to keep variable / function / file naming consistent and to spend fewer tokens explaining jargon.

**docs/adr/** holds architectural decision records. mattpocock's three-condition rule: create an ADR only when the decision is (1) hard to reverse, (2) surprising without context, AND (3) the result of a real trade-off. Most decisions fail at least one condition and stay out.

Both files are populated by `/grill-with-docs` inline as Coordinator's planning session reveals terms and decisions worth recording. They are NOT created by template — only when content exists.

### How CONTEXT.md interacts with lessons.md

| Purpose | Lives in |
|---|---|
| Domain language ("Issue tracker", "Triage role") | CONTEXT.md |
| Architectural decisions ("event-sourced orders", "postgres for write model") | docs/adr/ |
| Failure → fix → prevention ("Prisma include missed semesterStartDate") | lessons.md |
| Trade-offs accepted ("next/image warning — accepted") | HANDOFF.md |

These are non-overlapping. A new lesson never goes into CONTEXT.md; a domain term never goes into lessons.md. If you find yourself unsure which file something belongs in, it's probably not load-bearing enough for any of them.

---

## When browser verification applies

Real-browser QA (Playwright MCP) is for **web-app / UI / browser-flow** projects. Skip it for:

- **Native desktop apps** — no browser surface; QA runs the app directly
- **CLI tools / SDKs / libraries** — invoke and diff outputs; the methodology layer is enough
- **Backend-only services** — exercise the API; security review via native `/security-review` or human pass
- **Knowledge / research projects** — lean on roles + blackboard alone

Forcing browser tooling onto a non-web project just creates ceremony. The methodology layer (mattpocock) is universally useful.

---

## Anti-pattern observed

**Don't run long interview-style skills in the Coordinator's main context** — a multi-question forcing interview accumulates in the Coordinator's window (context economy). Run `/grill-with-docs` early while the window is fresh, or in a separate session. (Three earlier anti-patterns referenced retired gstack-era skills and were removed with the retirement.)

---

## Defaults in one breath

Builder: `/tdd` for new features, `/diagnose` for bugs — the default for non-trivial work. Coordinator: `/grill-with-docs` to grind the spec, `/to-prd` / `/to-issues` for handoff, native `/compact` + `HANDOFF.md` to save state. QA: Playwright MCP, report-only. Shipping: Bash + `gh pr create` — no skill needed. Trust skill descriptions for anything else; CC routes on them.
