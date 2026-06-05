# gstack retirement + ecosystem deep-research audit

**Date**: 2026-06-05
**Project**: skill ecosystem (user environment) + a 39-agent deep-research run over finsim_Mini and session archives
**Phase / scope**: gstack decision chain 2026-05-08 → 2026-06-05; research run 2026-06-04 (12 evidence agents, 124 findings, 12 proposals → 6 survived dual-lens adversarial verification)

## What was observed

### gstack decision chain (now closed)

- **2026-05-08 skills checkup**: 56 skills ≈ 6,069 description tokens always-resident; ~45/56 never invoked; duplicate descriptions (`browse` ≈ `gstack` near-verbatim, `connect-chrome` = `open-gstack-browser` bit-for-bit); 3.0–3.3× over the 1% skill-listing budget. Decision at the time: defer dedup, raise `skillListingBudgetFraction` to 4%.
- **2026-05-10**: full uninstall offered as an option; user declined ("升级，不需要精简").
- **2026-05-15/16 (v0.2)**: two-layer model; prune 45→16 keeping unique tech (browse daemon, /cso, design pipeline).
- **2026-06-05**: **user retired gstack entirely** ("我自己本身已经把 gstack 卸载了"). Reasons consistent with the 05-08 findings: low skill quality (duplicated / boilerplate descriptions) and visible context cost. Note: at the time of writing `~/.claude/skills/gstack/` was still physically present on the MBP — the retirement is confirmed as a decision; physical cleanup pending per machine.

### Deep-research run (2026-06-04; full report archived at `~/Downloads/harness-design-v03-deep-research-2026-06-04.json`)

- **finsim_Mini "seven-piece" infra** (6 commits `5165d52`→`f52fafb`, 2026-05-21: archive/ + prune.sh, lessons.md, STYLE.md, lesson-warn hook, SessionStart trim, COMMIT_TEMPLATE): frozen since landing — zero commits after 05-21, prune.sh never ran, archive empty, all 6 Verify metrics at baseline with zero observations (~2-week window, due ~06-18). **Never pushed to origin** — collaborating agents (e.g. Codex) cannot see it.
- **harness-design barely exists as an *invoked* skill.** Across recent sessions it was loaded-then-exited once and never Skill-invoked; it actually lives in three forms: (a) research asset / GitHub repo, (b) the two-layer mental model embedded in the user's CLAUDE.md, (c) phase structure hand-written into ultrawork Workflow scripts.
- **ultrawork session 2026-06-02** (Workflow × 26): Generate⊥Evaluate collapsed repeatedly — builders mock-tested their own work and never ran a real browser (anti-pattern 3 recurring in workflow-driven work). The first batch also failed wholesale with `subagent completed without calling StructuredOutput`.
- **Citation fabrication as a failure mode**: 5/12 research proposals were killed partly for referencing a non-existent `references/workflow_layer.md` and out-of-range line numbers in the source article. Proposal-stage agents hallucinate references; dual-lens adversarial verification caught it.
- **Documentation drift in this repo** (all line-verified): SKILL.md banner said "(v0.1)" while CHANGELOG was at 0.2.0; `/investigate` (removed in v0.2) still recommended in agent_definitions.md; the old "two consecutive rounds" exit rule survived in software_harness.md and knowledge_harness.md against SKILL.md's r1-PASS rule; hardcoded model versions ("Opus 4.6", "Opus 3.5"); README layout missing two files; stale "NEW" tags.

## What worked

- **Dual-lens adversarial verification** (evidence lens: is the citation real / over-extrapolated? doctrine lens: does it violate the subtractive culture / context economy?) killed plausible-but-unevidenced proposals, including the entire workflow-integration line. The subtractive culture held under pressure.
- **The evidence-first discipline made the audit possible**: progress.tsv / lessons / report trails were the primary data.

## What didn't earn its keep

- **The runtime layer (gstack) as a default recommendation.** The decision chain closed against it.
- **Version-pinned wording in living docs** (banner versions, model numbers) — drifts silently. Version facts belong in CHANGELOG only.

## What was missing

- **An empirical path for the dynamic-workflow integration question**: zero in-harness workflow runs with verifiable transcripts exist. Until one does, workflow integration stays a hypothesis — deferred, not rejected.
- **A replacement answer for daemon-based browser QA** after gstack retirement. The QA-runs-the-product doctrine is tool-agnostic and unchanged; the concrete default reverts to Playwright MCP. Open whether that suffices for authenticated multi-step flows.

## Implications for SKILL.md / references

Shipped as v0.2.1 (see CHANGELOG):

- SKILL.md: version-agnostic banner; routing-table label marks gstack runtime retired.
- software_harness_with_skills.md: status banner — runtime-layer sections become a historical record; methodology layer (mattpocock) remains current.
- agent_definitions.md / software_harness.md: gstack QA recommendations demoted to historical notes; Playwright MCP restored as the default; exit-rule wording aligned to r1-PASS; model versions de-pinned.
- knowledge_harness.md: dynamic exit aligned to the simplified rule.
- README.md: layout completed; stale NEW tags removed.

## Open questions

1. **Browser QA after gstack**: is Playwright MCP enough for authenticated multi-step flows, or does the daemon gap need filling? Decide when the next web project's QA hits real friction.
2. **Workflow integration**: deferred until one real in-harness workflow run produces a verifiable transcript — then write its evidence entry and revisit the five killed proposals.
3. **finsim seven-piece**: Verify metrics due ~2026-06-18, but the infra is unpushed and unexercised. Decide whether to push it or fold the patterns back into this skill as an optional tier tagged "runtime-unverified".
4. **"完全弃用" memory vs local artifacts**: the user's recollection of an earlier full-abandonment conclusion has no trace on this machine (possibly a mac mini session). The 2026-06-05 decision makes it moot.
