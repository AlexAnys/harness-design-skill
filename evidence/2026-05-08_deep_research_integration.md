# Deep research integration — 2026 spring coding-agent best practices

**Date**: 2026-05-08  
**Project**: N/A (external research synthesis)  
**Phase / scope**: Deep-research report covering Mar 2026 → May 2026 industry consensus, integrated with finsim audit findings.

## What was observed

A deep-research pass over official sources (OpenAI / Anthropic / GitHub) plus high-signal engineering writeups (Martin Fowler, Thoughtworks, Simon Willison) plus secondary community signal (HN, Reddit). Window: 2026-03-01 to 2026-05-10.

Seven convergence points across the industry:

1. **Repo knowledge must be source-controlled, and instruction files must be short.** Long-form goes in `docs/`; `CLAUDE.md` / `AGENTS.md` are tables of contents.
2. **Plan before edit.** Multi-vendor consensus (Codex best practices, Claude common-workflows, GitHub MCP tutorial).
3. **Skills use progressive disclosure.** Metadata always loaded; SKILL.md on trigger; references/scripts on demand. (OpenAI Skills Catalog + skill-creator.)
4. **Determinism externalized to hooks/scripts/CI, not prompts.** Anthropic hooks docs, OpenAI skills blog, Continue Docs converge here.
5. **Execution isolated; harness in trusted host.** Trusted host holds secrets/policy/audit; sandbox/worktree gets scoped workspace.
6. **Parallelism via worktree/branch/subagent isolation, not shared chat.** Both vendors officially support this; community tools (HN/Reddit) almost all build on this.
7. **Layered governance > permission popups.** allowlists + scanning + auto-review + audit, not "ask the user one more time."

## Where this converges with finsim audit findings

Cross-checking the deep research against `evidence/2026-04-29_finsim_audit.md`:

| Industry consensus | finsim audit echo |
|---|---|
| Plan before edit | `.harness/spec.md` written before code (always done in finsim) |
| Determinism via hooks | finsim's Stop hook QA gate (baseline); finsim *missing* the lesson-write hook (now added) |
| Repo knowledge as source of truth | finsim's CLAUDE.md was the right shape (short, role table, rules) |
| Progressive disclosure | finsim's `.harness/` structure already does this — but the skill itself violated it (SKILL.md was 700 lines) |
| Context management proactive (compaction at boundaries) | Maps directly onto the new context_economy.md principle |
| Verifier uses product, not just diff | finsim's `/qa-only` browser pattern (kept and emphasized in v0.1) |
| Skill metadata-first routing | Validated finsim's existing `description` field shape |

## Where the research adds language finsim didn't have

1. **Three-layer taxonomy**: `tool` (atomic) / `skill` (workflow) / `harness` (control plane). Before this, finsim conflated "skill" and "harness role" — the new vocabulary disentangles them.
2. **Side-effect class**: `read | write | release | deploy` as a metadata field on each skill. Useful for routing and permission gating in larger fleets.
3. **Artifact contract**: every skill names what it produces (a PR draft? a build report? a test result?). Helps with chained workflows.
4. **Command thrashing as a metric**: track tool-call count per task; spikes indicate the model is lost. finsim never measured this; might be worth adding.
5. **Trusted host vs sandbox separation**: finsim runs coordinator and builder in the same shell; works for single-developer, would need rework for multi-tenant or shared-CI scenarios.

## What the research adds that finsim is NOT yet ready for

These are valid industry directions but premature for a single-project single-developer harness:

- **Worktree fleet for parallelism**: finsim runs serially in a single repo. Worktree adds complexity that pays off only when concurrent task pressure exists.
- **Cloud agent / branch-PR automation** (GitHub Copilot style): finsim doesn't have the deploy automation maturity yet (deploys are still manual + occasionally stuck).
- **Cross-skill artifact contracts**: only useful when ≥3 skills routinely chain. finsim uses one skill (harness-design) to set up; the rest are gstack utilities invoked manually.
- **Skill eval suites with regression detection**: meta-skill (harness-design) has a tiny `evals/` folder but nothing automated yet. Worth adding when changes become frequent.

## What we explicitly chose NOT to import

- **The DRR's seven-consensus list as bullet points in SKILL.md**. Violates progressive disclosure and the user's "elegant + minimal" principle. The relevant pieces are absorbed into individual references; the full research lives here in `evidence/`.
- **The DRR's four-layer eval taxonomy** (skill routing / workflow / repo-gate / business). Useful framing for fleet-scale operations; overkill for a single-skill repo. Note for future.
- **The DRR's complete failure-mode table** (8 modes). Three of them apply to finsim-scale projects; absorbed into the four observed-in-the-wild anti-patterns in SKILL.md.

## Implications for SKILL.md / references

Mostly **language and framing refinements**; the structural changes were already driven by the finsim audit. Specifically:

- SKILL.md adopts the three-layer vocabulary (tool / skill / harness) implicitly via the "do NOT add by default" section.
- `references/upgrade_playbook.md` borrows the DRR's "four-question diff" framing.
- README.md cites the 2026-spring convergence as provenance.
- `evidence/README.md` adopts the "two-PR pattern" (evidence first, change second) inspired by the DRR's evidence-driven posture.

## Open questions

1. **Worktree parallelism**: at what project scale does it pay off? finsim's 70 commits in 6 weeks didn't justify it. Worth revisiting if a project hits 10+ concurrent units.
2. **METR's finding** that ~50% of SWE-bench-passing PRs aren't actually merge-worthy: how to translate that "maintainer view" check into our QA layer? Currently QA verifies functional behavior, not "would a real maintainer accept this." Possibly a new role or a more specialized QA prompt.
3. **Trusted-host pattern**: when finsim eventually moves to CI-driven deploys, the coordinator's role shifts. Anticipate this before it becomes urgent.
