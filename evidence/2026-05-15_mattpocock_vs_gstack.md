# mattpocock/skills vs gstack — head-to-head + harness fit

**Date**: 2026-05-15  
**Project**: N/A (external research synthesis)  
**Phase / scope**: Full install of both skill packs, side-by-side quality read, e2e demo of mattpocock `/tdd` in a TypeScript+vitest sandbox.

## What was observed

### Install footprints

| | mattpocock/skills | gstack |
|---|---|---|
| Skills shipped | 28 (engineering 10 / productivity 4 / misc 4 / personal 2 / in-progress 4 / deprecated 4) | 60+ slash commands + 8 power tools + binaries |
| Avg SKILL.md size | 60–120 lines | varies; many have 50-line frontmatter with `hooks`, `gbrain.context_queries`, preamble bash |
| External dependencies | none (pure markdown) | bun, playwright/chromium, optional gbrain (PGLite or Supabase) |
| CLAUDE.md size | 14 lines | 471 lines |
| Repo lifecycle metadata | `deprecated/`, `in-progress/`, ADRs governing skill design itself | quarterly releases (v0.19 in 60 days), telemetry, eureka logs |

### Quality density (sampled SKILL.md)

- mattpocock `/diagnose` (117 lines): 6 phases, **10 explicit feedback-loop construction strategies in priority order**, perf-vs-logic branch separation, explicit tagged-debug-log discipline (`[DEBUG-a4f2]`), Phase 5 "correct-seam" test discipline, Phase 6 hand-off to architecture cleanup.
- gstack `/investigate` (50-line frontmatter alone, then 4-phase prose): "Iron Law: no fixes without root cause"; preamble bash that calls `gstack-update-check`, registers session, queries `~/.gstack/projects/{repo_slug}/learnings.jsonl`; PreToolUse hooks linking to `/freeze`. Methodology body shorter and less specific than mattpocock's.
- mattpocock `/tdd` (109 lines): explicitly warns against horizontal slicing with ASCII diagram, tracer-bullet metaphor, "never refactor while RED" rule, per-cycle 5-line checklist.
- mattpocock `/grill-with-docs` (88 lines): CONTEXT.md glossary discipline + ADR three-condition gating + 4 conversation tactics + lazy file creation.

### e2e: `/tdd` in `/tmp/skills-eval-20260516/tdd-demo/`

Sandbox: TypeScript + vitest 4.1.6, target = `chunk<T>(arr: T[], size: number): T[][]`.

| Cycle | Test added | Impl change | Result | Skill value point |
|---|---|---|---|---|
| 1 (tracer bullet) | `chunk([1,2,3,4], 2)` | slice loop | ✅ 132ms | "minimum code" rule prevented preemptive validation |
| 2 (remainder) | `chunk([1,2,3,4,5], 2)` → `[[1,2],[3,4],[5]]` | none (passed) | ✅ | exposed cycle-1 over-impl by 1 line (small) |
| 3 (error path) | `chunk([], 0)` expects throw | added `if (!Number.isInteger(size) \|\| size <= 0) throw` | First hung at 5s timeout; after fix ✅ 111ms 3/3 | **real bug caught**: size=0 produced infinite loop (`i += 0`) |

Final artifact: 10-line `chunk.ts` + 22-line `chunk.test.ts`. Total time < 2 minutes / 4 tool calls.

### Native-vs-skill audit (which gstack skills survive when Claude Code's native tools are factored in)

| gstack skill | Claude Code already provides? | Verdict |
|---|---|---|
| `/browse` `/scrape` `/qa` `/qa-only` `/canary` `/benchmark` | Has `mcp__Claude_in_Chrome__*` + `mcp__Claude_Preview__*` but slower (200-500ms vs 100ms daemon) and lack structured QA flow | KEEP (unique daemon speed + flows) |
| `/cso` | No — well-tuned OWASP+STRIDE prompt with 17 false-positive exclusions + 8/10 confidence gate is genuinely rare | KEEP |
| `/design-shotgun` `/design-html` `/design-review` `/design-consultation` | No — Pretext computed layout + multi-variant generation are non-trivial | KEEP |
| `/connect-chrome` `/open-gstack-browser` `/setup-browser-cookies` `/pair-agent` `/skillify` | No — browser daemon adjuncts | KEEP |
| `/office-hours` `/autoplan` `/plan-*-review` `/devex-review` `/plan-tune` | Pure prompts; mattpocock `/grill-with-docs` covers methodology better | REMOVE |
| `/investigate` | Pure prompt; mattpocock `/diagnose` is significantly higher quality | REMOVE |
| `/careful` `/freeze` `/guard` `/unfreeze` | Claude Code PreToolUse hooks natively | REMOVE |
| `/learn` `/sync-gbrain` `/setup-gbrain` | Claude Code native memory + `~/.claude/CLAUDE.md` + our `.harness/lessons.md` | REMOVE |
| `/context-save` `/context-restore` | Claude Code native `/compact` + `.harness/HANDOFF.md` | REMOVE |
| `/ship` `/land-and-deploy` `/setup-deploy` `/landing-report` | Bash + `gh pr create` / `gh pr merge` | REMOVE |
| `/codex` | Bash + `codex exec --full-auto` | REMOVE |
| `/document-release` `/retro` `/health` `/benchmark-models` `/make-pdf` `/gstack-upgrade` `/review` | Pure prompts / Bash wrappers / niche | REMOVE |

Pruned install: **45 gstack entries → 16** (kept ones above). Net effect: less ambient noise in the skill list, fewer collisions with mattpocock's same-named skills, faster routing.

## What worked

1. **mattpocock's methodology density is real and measurable.** /diagnose's Phase 1 alone — "Build a feedback loop" with 10 concrete strategies in priority order — is more useful than entire 4-phase gstack /investigate.
2. **Naming collisions resolved cleanly during install.** mattpocock's top-level symlinks won over gstack's subdirectory entries for `tdd`, `to-prd`, `triage`, `handoff`, `caveman`, `improve-codebase-architecture`, `grill-me`, `setup-pre-commit`. Both packs coexist for skills with distinct names.
3. **e2e demo proved /tdd's rules pay rent.** The size=0 infinite-loop bug was caught precisely because /tdd's vertical-slicing discipline forced "one behavior per test." A spec-style write-all-tests-upfront approach would have likely tested only the common cases.
4. **Two-layer model survives stress-testing.** Methodology (mattpocock) and runtime (pruned gstack) cleanly serve different harness roles: Coordinator/Builder consume methodology, QA consumes runtime. They don't compete for the same slot.

## What didn't earn its keep

1. **Most of gstack's prompt-template skills.** `/office-hours`, `/plan-*-review`, `/autoplan`, `/devex-review`, etc. are valuable prompts but provide no unique technology — they're replaceable by mattpocock equivalents (often higher quality) or by Claude Code native + ad-hoc Coordinator judgment.
2. **gstack's safety skills duplicate Claude Code hooks.** `/careful`, `/freeze`, `/guard`, `/unfreeze` are PreToolUse-hook wrappers. Claude Code already exposes this primitive.
3. **gstack's memory layer.** `/learn`, `/sync-gbrain`, `/setup-gbrain` add another memory system on top of Claude Code's native memory + our project-level `.harness/lessons.md`. Three layers is one too many.
4. **gstack's preamble bash + gbrain queries** in every skill invocation. They pull cross-project state into Coordinator's context — directly antithetical to context economy. mattpocock's pure-prompt skills have zero such overhead.

## What was missing (gaps surfaced)

1. **`/grill-with-docs` outputs (CONTEXT.md + docs/adr/) weren't part of our blackboard.** Adding them in v0.2 — Coordinator/Builder/QA can now reference project-specific glossary and architectural decisions, complementing `lessons.md` (failure record) and `HANDOFF.md` (session continuity).
2. **mattpocock's `/tdd` lacks "what if test passes without code change" guidance.** Our e2e cycle 2 hit this: the remainder test passed without impl change, meaning cycle 1 was 1 line over-implemented. A small skill-improvement opportunity to feed back to the mattpocock repo as a PR.
3. **Neither pack provides explicit hand-off-to-Coordinator escalation paths.** mattpocock's skills assume single-agent flow; gstack's assume sprint pipeline. Our harness imposes the hand-off via SendMessage between roles, which neither pack documents.

## Implications for SKILL.md / references

Specific changes shipped in v0.2.0:

- **`references/software_harness_with_skills.md`** (new) — two-layer model, per-role skill mapping, pruned install procedure, blackboard layout with CONTEXT.md + docs/adr/.
- **SKILL.md routing table** updated — promotes the new reference as the recommended starting point for software projects with external skill packs.
- **Blackboard layout** in SKILL.md gains `CONTEXT.md` and `docs/adr/`, marked as v0.2 (created lazily by `/grill-with-docs`, not pre-baked).
- **CHANGELOG.md** v0.2.0 entry with this rationale.

## Open questions

1. **Should mattpocock's CONTEXT.md format be formally specified in our `references/lessons_pattern.md`?** Currently mattpocock's `CONTEXT-FORMAT.md` lives in their /grill-with-docs/ skill folder. Vendoring vs referencing is a maintenance trade-off.
2. **mattpocock's `/handoff` and our `.harness/HANDOFF.md` overlap.** Currently both exist; ours is project-scoped, theirs is session-scoped. Worth observing real usage to decide if one supersedes the other.
3. **Could mattpocock's three-state lesson maintenance (active/superseded/deprecated) be applied to ADRs?** ADRs traditionally use status fields (proposed/accepted/superseded/deprecated). Mostly an alignment question — might not need new doc.
4. **For finsim specifically — is now the time to convert `/investigate` references in qa.md to `/diagnose`?** Risk: builder/qa agents need re-validation. Reward: better methodology. Probably worth a finsim T2 follow-up task.
