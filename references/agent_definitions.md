# Reference: Agent Definitions (worked examples)

> **Read this as an example, not a template.** The YAML shapes below are the conventional form, but tool allocation, MCP choice, and permission mode all vary by project.

---

## Where agent definitions live

Project-scoped agents: `.claude/agents/{role}.md` — one file per agent.
User-scoped agents (available across projects): `~/.claude/agents/{role}.md`.

Each file is a markdown document with YAML frontmatter, followed by the agent's instruction body.

---

## Frontmatter fields

```yaml
---
name: planner                     # short identifier, used in @mentions
description: One sentence — when to delegate to this agent
tools: Read, Write, Glob, Grep    # minimum necessary
model: opus[1m]                   # 1M context for harness work
permissionMode: acceptEdits       # NOT bypassPermissions
mcpServers:                       # optional
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
---
```

**Why `model: opus[1m]`**: harness agents need to hold the plan, prior reports, and domain knowledge in one context window. Opus 4.6 with 1M context holds whole repositories. Shorter contexts force chunking that the harness principles explicitly argue against.

**Why `acceptEdits` and not `bypassPermissions`**: `bypassPermissions` silently ignores the `tools` allow-list. If you write `tools: Read, Write` and set `bypassPermissions`, the agent will happily run `Bash` and nothing stops it. Use `acceptEdits` so the scope is actually enforced.

---

## Tool allocation — the "minimum necessary" principle

Each role answers a different question. The tools it gets should match that question, and nothing more.

**Planner** (answers "what needs to be built"):
```yaml
tools: Read, Write, Glob, Grep, WebSearch
```
The planner thinks and writes. It reads code for context, searches the web for domain knowledge, and writes plans. It does not execute code. Giving it `Bash` is tempting but usually results in a planner that starts implementing things it should be delegating.

**Builder / Executor** (answers "how to implement"):
```yaml
tools: Read, Write, Edit, Bash, Glob, Grep
```
The full toolkit. Builder reads code, writes code, runs tests, commits. This is the one role that legitimately needs everything.

**QA / Verifier** (answers "does it work"):
```yaml
tools: Read, Write, Bash, Glob, Grep
mcpServers:
  - playwright: { type: stdio, command: npx, args: ["-y", "@playwright/mcp@latest"] }
```
QA reads the plan and the code, actually runs things (Bash, Playwright), and writes reports. Critically, QA should *not* have `Edit` — a verifier that can edit the code it's verifying will silently "fix" problems instead of reporting them. Make QA write its findings; make Builder read them and act.

For web projects with gstack installed, the QA agent should invoke `/qa-only` for browser-based verification instead of configuring Playwright MCP separately. gstack's browse daemon provides persistent Chromium with sub-100ms latency, cookie import for authenticated testing, and screenshot capture — all report-only, matching QA's "no Edit" constraint. The Builder can use `/qa` (with auto-fix) for self-testing during development, and `/investigate` for structured debugging.

**Coordinator** (answers "who should do this next"):
```yaml
tools: Agent, TeamCreate, SendMessage, Read, Write, Glob, Grep, Bash
```
Coordinator uses the `Agent` tool (one-shot delegation) or `TeamCreate` + `SendMessage` (persistent team mode) to dispatch named agents, reads the current state of the blackboard, and writes the initial plan (or delegates that too).

> **Note on Coordinator not writing application code**: this is a context-economy rule, not a moral one. See `references/context_economy.md` — Coordinator's context must stay lean for long-horizon decisions; sacrificial Builder/QA contexts absorb the expensive work. Occasional small Edits to `.md` / `.harness/` files are fine; multi-file Reads of source code mean "delegate."

---

## The instruction body

After the frontmatter, the body is the agent's standing instructions. What goes there:

1. **Role in one paragraph** — what this agent is responsible for, and what it is *not* responsible for.
2. **Blackboard contract** — which files it reads, which files it writes, in which format.
3. **Domain knowledge** — the project-specific patterns, constraints, and failure modes extracted from the domain research step. *This is where most of the value lives.* A generic planner is a bad planner; a planner that knows "this project doesn't use decorators" and "API responses are always envelope-wrapped" is a good planner.
4. **Handoff rules** — when to escalate, when to step back, when to re-engage.

Example coordinator body (trimmed):

```markdown
You are the coordinator for this project. On startup, read `.claude/agents/` to know
which agents exist, and read `.harness/` to know current progress.

Your job:
1. Align user intent — if unclear, ask before proceeding.
2. Plan — write a plan to `.harness/spec.md` (or delegate to @planner if one exists).
3. Delegate execution to named agents — you do NOT write application code.
4. Step back during agent-to-agent collaboration — agents talk through `.harness/` files.
5. Re-engage on repeated failures, requirement gaps, or task completion.

Risk-ceremony rule: classify the risk of each change in one sentence, pick an
appropriate ceremony level. A typo needs no plan; a schema migration needs one.
Let judgment scale ceremony — don't follow a line-count rule.
```

The body should *not* repeat the SKILL.md meta-principles. It should apply them, not restate them.

---

## Dedicated planner vs. coordinator-plans

Whether to have a separate `@planner` agent is a per-project judgment call:

- **Coordinator plans** (default) — simpler, no handoff, fewer moving parts.
- **Dedicated planner** — when planning requires deep architectural analysis that would overwhelm the coordinator, or when the plan needs a different voice than the coordinator's user-facing one.

Prefer coordinator-plans until you observe specific planning failures that warrant the extra agent.

---

## How agents are invoked

```bash
# Inside a coordinator session, delegate via @mention:
@planner write a harness spec for the dashboard module
@builder implement Phase 2 per .harness/spec.md
@qa test the dashboard against .harness/reports/build_dashboard_r1.md

# Start a standalone session as a specific agent:
claude --agent planner
claude --agent builder

# Natural language also works (coordinator routes):
"Add a dark-mode toggle to the settings page"
```

The coordinator delegates to *named* agents. It does not spawn anonymous ones. Named agents are the unit of accountability — each one has a file, a role, a history of reports.
