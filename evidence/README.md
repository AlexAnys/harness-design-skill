# Evidence

This directory holds dated findings from real projects that have used (or audited) the harness-design skill. Every meaningful change to SKILL.md or references should cite at least one evidence entry.

## Why this exists

The skill is meant to evolve based on observation, not aspiration. Anti-patterns and best practices are easy to invent; only ones that show up in real projects earn space in SKILL.md.

## Format

One file per finding: `evidence/{YYYY-MM-DD}_{project-or-topic}.md`. Examples:

- `2026-04-29_finsim_audit.md` — what an existing finsim harness looked like in practice
- `2026-05-08_deep_research_integration.md` — synthesis with external best-practice research
- `2026-07-12_project-X_postmortem.md` — hypothetical future entry

### Template

```markdown
# {Project / Topic} — {short headline}

**Date**: YYYY-MM-DD  
**Project**: name (or N/A if external research)  
**Phase / scope**: e.g. "after 6 weeks of use, 70+ commits"

## What was observed

Concrete data: commit counts, hook fire rates, failure modes, time-to-detect, etc. Numbers preferred. Tools-of-the-trade examples preferred. Avoid theorizing.

## What worked

The mechanisms whose value is now empirically established.

## What didn't earn its keep

The mechanisms that produced no observable value. List them — they're candidates for removal from the skill.

## What was missing

Failure modes the skill didn't anticipate, or guidance that didn't exist when needed.

## Implications for SKILL.md / references

Concrete proposals: which file to update, which section, what to add/remove. Link to a CHANGELOG entry if the change has shipped.

## Open questions

Things this evidence doesn't settle.
```

## How to use this when iterating

When a project completes (or hits a meaningful milestone):

1. **Write the evidence entry** while the project is fresh. Specifics matter — vague observations don't drive good updates.
2. **Open a PR** to this repo with the evidence entry alone (no SKILL.md changes yet).
3. **In a follow-up PR**, propose the SKILL.md / references changes motivated by the evidence. Link the evidence file in the PR description.
4. **Update CHANGELOG.md** to record the change and cite the evidence.

This two-PR pattern keeps "what happened" and "what we should change" distinct. The evidence stands on its own — even if the proposed change isn't accepted, the finding is preserved.

## Anti-patterns to avoid when writing evidence

- **Trade-off acceptances** — those belong in the project's own HANDOFF.md, not here. Evidence is what we learned, not what we tolerated.
- **General opinions about agents** — only what was observed in *this* project.
- **Skill-internal navel-gazing** — evidence is about projects that used the skill, not about the skill itself.
- **Single-occurrence reactions** — wait for a pattern (or explicitly flag "single occurrence, watch for repeats").
