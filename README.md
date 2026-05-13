# harness-design-skill

A Claude Code meta-skill for designing and setting up multi-agent harnesses.

> **What this is**: a *skill*, not a *harness kit*. This produces the scaffolding (agents, blackboard, hooks) you put in a project; the project then uses that scaffolding to do its real work. Distinct from [claude-harness-blueprint](https://github.com/AlexAnys/claude-harness-blueprint) and [claude-harness-kit](https://github.com/AlexAnys/claude-harness-kit), which are pre-baked harness templates / product collections.

## The three principles

1. **Plan ⊥ Execute** — the agent that converts intent into a plan is a different context from the agent that executes the plan.
2. **Execute on documents** — every executor reads from a markdown blackboard and writes a markdown report.
3. **Generate ⊥ Evaluate** — the agent that produces work cannot be the agent that judges it.

## The hidden fourth — Context Economy

Role separation is a **context-sharding strategy**, not a discipline issue. The Coordinator must stay lean across the project's lifetime; Builders and Evaluators are sacrificial contexts that fill up and die at task end. The blackboard is how state survives.

This reframe (added in v0.1) explains when separation can be relaxed and when it must hold. See `references/context_economy.md`.

## Install

```bash
# Clone to your Claude Code user skills directory
cd ~/.claude/skills
git clone https://github.com/AlexAnys/harness-design-skill.git harness-design

# Verify
ls ~/.claude/skills/harness-design/SKILL.md
```

Claude Code auto-loads skills from `~/.claude/skills/`. The skill triggers when you ask about multi-agent harnesses, planner/builder/qa setups, agent teams, etc.

## Layout

```
harness-design-skill/
├── SKILL.md                 ← entry point (slim, ~120 lines, progressive disclosure)
├── references/              ← worked examples, loaded on demand
│   ├── software_harness.md
│   ├── knowledge_harness.md
│   ├── operations_harness.md
│   ├── agent_definitions.md
│   ├── enforcement.md       ← hooks, settings.json, catastrophic-only enforcement
│   ├── context_economy.md   ← NEW — why role separation is context sharding
│   ├── lessons_pattern.md   ← NEW — rolling failure capture (PROGRESS.md style)
│   └── upgrade_playbook.md  ← NEW — for existing harnesses
├── evidence/                ← dated findings from real projects
│   ├── README.md
│   ├── 2026-04-29_finsim_audit.md
│   └── 2026-05-08_deep_research_integration.md
├── evals/                   ← test harness for the skill itself
└── CHANGELOG.md
```

## How to update this skill (evidence-based iteration)

The skill is designed to evolve as evidence from real projects arrives. After each project ships:

1. **Write an evidence entry**: `evidence/{YYYY-MM-DD}_{project}.md`. Use the template in `evidence/README.md`. Capture what worked, what didn't, what should be added/removed/updated.
2. **Open a PR** to this repo. Describe the proposed SKILL.md / references changes; link to the evidence entry as motivation.
3. **Promote stable findings** into SKILL.md or references. Demote outdated guidance to historical notes; never delete (keep the trail).
4. **Update CHANGELOG.md** with the change and which evidence drove it.

This pattern keeps the skill grounded in observed reality rather than aspirational principles.

## Provenance

Built on principles from:

- Anthropic's [harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- The 2026-spring coding-agent best-practice convergence (OpenAI / Anthropic / GitHub official sources + Martin Fowler harness engineering writeups)
- The finsim project audit (Apr 2026) — what the original meta-skill got right and where it bloated

See `evidence/` for the integration notes.

## License

MIT. See `LICENSE`.
