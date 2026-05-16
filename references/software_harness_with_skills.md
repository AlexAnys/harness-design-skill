# Software Harness with External Skill Packs

> For software projects where mattpocock/skills (methodology) and/or gstack (runtime infrastructure) are installed. This reference shows how to wire them into the three harness roles **without bloating Coordinator context** or duplicating Claude Code native capabilities.

## The two-layer mental model

```
┌─────────────────────────────────────────────────────────────────┐
│  Methodology layer — how the agent thinks                       │
│  mattpocock/skills · pure prompts · zero infra dependency       │
│  /tdd /diagnose /grill-with-docs /zoom-out /to-prd /to-issues   │
│  /improve-codebase-architecture /prototype /triage /handoff     │
├─────────────────────────────────────────────────────────────────┤
│  Runtime layer — what the agent can DO                          │
│  gstack (pruned) · unique tech only                             │
│  /browse /qa /qa-only /canary /benchmark /scrape /design-*      │
│  /cso /pair-agent /open-gstack-browser /setup-browser-cookies   │
├─────────────────────────────────────────────────────────────────┤
│  Claude Code native — already provided, do not re-install       │
│  Read / Write / Edit / Bash / Grep / Glob / Agent / TeamCreate  │
│  SendMessage / Hooks / Plan mode / /compact / WebFetch          │
├─────────────────────────────────────────────────────────────────┤
│  Harness layer (this skill) — role separation + blackboard      │
│  Coordinator / Builder / QA + .harness/* + lessons + hooks      │
└─────────────────────────────────────────────────────────────────┘
```

**Critical principle**: most prompt-template skills (`/office-hours`, `/autoplan`, `/plan-*-review`, `/investigate`, `/careful`, `/freeze`, `/ship`, `/codex`, `/learn`, `/context-save`, etc.) are **replaceable** by Claude Code native + a 50-line `.harness/` file or a few Bash lines. Keep only the skills with **unique technology** (browser daemon, Pretext layout, structured prompts you genuinely cannot reproduce by hand).

The pruning rationale + evidence: `evidence/2026-05-15_mattpocock_vs_gstack.md`.

---

## Recommended pruned install

### Keep from gstack (~16 skills) — these have non-replicable tech

| Skill | Why keep |
|---|---|
| `/browse` `/scrape` `/skillify` | persistent Chromium daemon, ~100ms latency, anti-bot stealth, cookie import |
| `/qa` `/qa-only` | structured browser-testing flow on top of `/browse`, daemon-fast |
| `/canary` `/benchmark` | post-deploy monitoring via daemon, Core Web Vitals |
| `/cso` | OWASP+STRIDE audit with 17 false-positive exclusions, 8/10 confidence gate, finding verification |
| `/design-shotgun` `/design-html` `/design-review` `/design-consultation` | Pretext computed layout, multi-variant generation board, taste learning |
| `/connect-chrome` `/open-gstack-browser` `/setup-browser-cookies` `/pair-agent` | browse adjuncts: real-Chrome bridging, cookie auth, multi-agent share |

### Remove from gstack (~29 skills) — Claude Code native or mattpocock covers them

| Removed | Replacement |
|---|---|
| `/office-hours` `/autoplan` `/plan-*-review` | mattpocock `/grill-with-docs` (engineering domain) + Coordinator judgment |
| `/investigate` | mattpocock `/diagnose` (significantly higher quality methodology) |
| `/careful` `/freeze` `/guard` `/unfreeze` | Claude Code PreToolUse hooks (see `references/enforcement.md`) |
| `/learn` `/sync-gbrain` `/setup-gbrain` | `.harness/lessons.md` (see `references/lessons_pattern.md`) + native `~/.claude/CLAUDE.md` |
| `/context-save` `/context-restore` | Claude Code native `/compact` + `.harness/HANDOFF.md` |
| `/ship` `/land-and-deploy` `/setup-deploy` `/landing-report` | Bash + `gh pr create` / `gh pr merge` |
| `/codex` | Bash + `codex exec --full-auto` |
| `/document-release` `/retro` | pure prompts — write what you need ad-hoc |
| `/health` `/benchmark-models` `/gstack-upgrade` | niche, can be Bash one-liners when needed |
| `/devex-review` `/plan-devex-review` `/plan-tune` `/make-pdf` | rarely-used prompts; reach for them only if needed |
| `/review` (gstack) | mattpocock `/review` (in-progress) or just Bash + `git diff` |

### Install mattpocock fully

```bash
git clone https://github.com/mattpocock/skills.git ~/Projects/mattpocock-skills
bash ~/Projects/mattpocock-skills/scripts/link-skills.sh
```

This adds 24 skills as symlinks into `~/.claude/skills/`. The script skips `deprecated/`. Skill name collisions (`tdd`, `to-prd`, etc.) resolve to mattpocock because its top-level symlink wins over gstack's subdirectory entries.

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

Coordinator does **NOT** invoke runtime-layer skills directly — those are Builder/QA's job. Coordinator stays in methodology + planning + delegation.

### Builder (sacrificial context, gets work done)

| Trigger | Skill to invoke |
|---|---|
| New feature / new code | mattpocock `/tdd` — red→green→refactor, vertical slicing |
| Bug or perf regression | mattpocock `/diagnose` — feedback-loop-first, 6-phase discipline |
| Confused about a module | mattpocock `/zoom-out` — explain in context of the whole system |
| Want to try a design before committing | mattpocock `/prototype` — throwaway prototype, terminal or UI variant |
| UI to build from a mockup | gstack `/design-html` |
| Need to explore UI options first | gstack `/design-shotgun` |
| Quarterly cleanup pass | mattpocock `/improve-codebase-architecture` |

Builder owns the inner loop. Use `/tdd` / `/diagnose` as the **default** for non-trivial work — they enforce vertical slicing and feedback loops that drive quality.

### QA (sacrificial context, independent verification)

| Trigger | Skill to invoke |
|---|---|
| UI / routing / CSS change | gstack `/qa-only` — real browser, daemon-fast, report-only |
| Auth / permission / payment change | gstack `/cso` — OWASP+STRIDE audit, High/Critical = FAIL |
| Visual polish PR | gstack `/design-review` — designer's eye, AI slop detection |
| Perf-sensitive PR | gstack `/benchmark` — Core Web Vitals before/after |
| Post-deploy health | gstack `/canary` |

QA **never edits source code**. If `/cso` or `/qa-only` finds issues, QA writes them to `qa_*.md` and SendMessage's Builder.

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

## When to skip the runtime layer

The runtime layer (gstack-kept) is valuable for **web-app / UI / browser-flow** projects. Skip it for:

- **Native desktop apps** — no browser, no `/qa-only`, no `/canary`
- **CLI tools / SDKs / libraries** — methodology layer is enough
- **Backend-only services** with no UI — `/cso` for security still applies; rest of runtime layer doesn't
- **Knowledge / research projects** — neither layer applies; lean on Coordinator/Builder/QA + blackboard alone

Trying to force the runtime layer onto a non-web project just creates ceremony. The methodology layer (mattpocock) is universally useful.

---

## Anti-patterns observed

1. **Coordinator runs `/office-hours` in main context** — the 6 forcing-question interview accumulates in Coordinator's window. Prefer mattpocock `/grill-with-docs` (more terse + ADR-driven) or a fresh sub-session.
2. **Installing all of gstack "just in case"** — drags in ~60 skills, most of which duplicate Claude Code native. Audit and prune (see "Recommended pruned install" above).
3. **Treating gstack's `/learn` and our `lessons.md` as the same** — `/learn` is freeform memory; `lessons.md` is structured failure capture. Use one, not both (we recommend `lessons.md`).
4. **Using `/investigate` when `/diagnose` is installed** — finsim audit comparison showed mattpocock `/diagnose` significantly higher quality methodology (10 explicit feedback-loop construction strategies, perf vs logic branch separation, regression-test seam discipline). Default to `/diagnose`.

---

## Quick reference card

| I'm about to ... | I should run ... |
|---|---|
| Spec a new feature | `/grill-with-docs` then write `spec.md` |
| Write the code | `/tdd` |
| Debug a hard bug | `/diagnose` |
| Get a wide view of unfamiliar code | `/zoom-out` |
| Convert this discussion into a PRD | `/to-prd` |
| Break the PRD into issues | `/to-issues` |
| Test a UI change in a real browser | `/qa-only` |
| Audit an auth-related change | `/cso` |
| Explore UI options before committing | `/design-shotgun` |
| Turn approved mockup into HTML | `/design-html` |
| Quarterly architecture cleanup | `/improve-codebase-architecture` |
| Ship the PR | Bash + `gh pr create` (no skill needed) |
| Save session state | `/compact` + update `HANDOFF.md` |
