# Enforcement

> Read this as worked examples, not a template. Adapt the specifics to the project's actual rules. The hooks here are calibrated against finsim-audit findings: **only enforce what causes catastrophic information loss; everything else is a warning**.

---

## Layers

```
Layer 0 : CLAUDE.md rules                (soft — guides; can be ignored under pressure)
Layer 1 : Structural default agent       (baseline — coordinator loads automatically)
Layer 2 : Stop hook QA gate              (baseline — independent verifier on every response)
Layer 3 : Catastrophic-only Hooks        (3 hooks; see below)
Layer 4 : Tool scopes in agent files     (documentation; current Claude Code does not strictly enforce)
```

**L0–L2 are baseline for triangle / fan-out structures.** For solo+check and pipeline structures — oracle-closed, low blast radius — L2 is a check command (e.g. a Stop hook running `bash check.sh`), not an agent-type QA gate: the oracle is already deterministic. L3 adds three specific hooks that target unrecoverable failure modes. L4 is documentation of intent — useful for human readers, but real enforcement happens at L3.

A SessionStart banner hook is a nice-to-have for at-a-glance visibility but is not baseline.

---

## Layer 1 — Default agent

```json
{
  "agent": "coordinator"
}
```

Opening Claude Code in the project lands on the coordinator. The user can't forget to use the harness because there's nothing else to use. (Triangle / fan-out structures; a solo+check project needs no default agent.)

---

## Layer 2 — Stop hook QA gate (with diff-guard prefix)

Fires after every Claude response. In triangle / fan-out structures it must be **agent-type** (not command-only) so it can reason about "does this match the plan?" not just "does this parse?" In solo+check / pipeline structures the gate is the check command itself — no agent invocation needed.

The diff-guard prefix skips the expensive agent invocation when `git diff` is empty (SendMessage rounds, file-reading turns, etc.). The finsim audit measured this saves ~30–50% of Stop hook invocations on team-mode sessions.

```json
{
  "agent": "coordinator",
  "hooks": {
    "Stop": [{
      "hooks": [
        {
          "type": "command",
          "command": "git -C \"$CLAUDE_PROJECT_DIR\" diff --quiet HEAD && exit 0 || exit 1"
        },
        {
          "type": "agent",
          "prompt": "You are an independent QA gate. Check git diff for uncommitted changes. Verify: (1) no obvious bugs or broken imports, (2) if data-layer files changed, confirm migrations + client regen + dev-server restart were done, (3) if service interfaces changed, check all callers were updated, (4) UI text matches project locale conventions, (5) thin layers (route handlers, controllers) have no business logic, (6) changes match the plan in .harness/spec.md if it exists, (7) if UI/routing/CSS changed, flag that qa agent should run browser verification. Respond {\"ok\": true} or {\"ok\": false, \"reason\": \"specifics\"}. $ARGUMENTS",
          "timeout": 120
        }
      ]
    }]
  }
}
```

Customize the QA prompt: inject the domain-specific failure modes from your project's `lessons.md` and `qa.md` calibration.

---

## Layer 3 — Three catastrophic-only hooks

These three hooks target failure modes that cause **unrecoverable** information loss or judgment drift. Everything else is left to coordinator judgment.

### Hook A — PostToolUse on commit: require lessons.md entry for r2+ PASS

**What it prevents**: same gotcha biting twice because no one wrote down the first occurrence. This is the highest-ROI hook from the finsim audit (PR-CALENDAR-1 hit a CLAUDE.md-warned gotcha because the warning was static and untriggered).

```json
{
  "PostToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "echo \"$CLAUDE_TOOL_INPUT\" | grep -q 'git commit' || exit 0; tail -5 \"$CLAUDE_PROJECT_DIR/.harness/progress.tsv\" 2>/dev/null | grep -E \"$(printf '\\tr[23]\\t[^\\t]*\\tPASS(\\t|$)')\" >/dev/null || exit 0; TODAY=$(date -u +%Y-%m-%d); grep -q \"$TODAY\" \"$CLAUDE_PROJECT_DIR/.harness/lessons.md\" 2>/dev/null && exit 0; echo '⚠ r2+ PASS detected but no lessons.md entry dated today. Append a lesson (symptom/root cause/detection/prevention/commit) before next unit.' >&2; exit 2"
    }]
  }]
}
```

This is the **only hook that actively blocks** (exit 2). Everything else warns.

**Hook engineering rule** (applies to every hook here and every hook you generate): non-trivial hook logic lives in a script file (`.claude/hooks/*.sh`) registered by a one-line JSON entry — and **every hook ships with a minimal trigger self-test**: feed one line that must match and one that must not, assert the exit codes, *before* the hook is trusted to gate anything. A hook that has never fired in a test is scaffolding theater.

Hook A's pattern is pinned to the `progress.tsv` column order defined in `software_harness.md` (`timestamp | unit | round | scores | status | …`). If the column order changes, the regex and this self-test change together:

```bash
# must match (exit 0) — canonical r2 PASS row:
printf '2026-06-06T00:00:00Z\tauth\tr2\t9/10\tPASS\t0.41\tfix login\tabc1234\n' \
  | grep -qE "$(printf '\tr[23]\t[^\t]*\tPASS(\t|$)')"; echo "match: exit=$? (want 0)"
# must NOT match (exit 1) — r1 PASS row:
printf '2026-06-06T00:00:00Z\tauth\tr1\t9/10\tPASS\t0.41\tok\tabc1234\n' \
  | grep -qE "$(printf '\tr[23]\t[^\t]*\tPASS(\t|$)')"; echo "no-match: exit=$? (want 1)"
```

### Hook B — PreToolUse on Edit/Write: warn coordinator before app-code edits

**What it prevents**: silent context bloat from Coordinator drifting into Builder's role. Per `references/context_economy.md`, occasional Coordinator self-edits are fine; persistent ones erode long-horizon judgment via compaction risk.

This is **warn-don't-block** — re-running the same tool call within 5 seconds proceeds. The point is to make context cost visible, not to forbid the action.

```json
{
  "PreToolUse": [{
    "matcher": "Edit|Write",
    "hooks": [{
      "type": "command",
      "command": "test \"$CLAUDE_AGENT_NAME\" != coordinator && exit 0; FILE=$(echo \"$CLAUDE_TOOL_INPUT\" | jq -r '.file_path // \"\"'); echo \"$FILE\" | grep -qE '\\.harness/|\\.md$|settings\\.json$' && exit 0; STAMP_FILE=/tmp/coord-edit-ack-$(echo -n \"$FILE\" | shasum | cut -c1-12); test -f \"$STAMP_FILE\" && test $(($(date +%s) - $(stat -f %m \"$STAMP_FILE\" 2>/dev/null || echo 0))) -lt 5 && { rm -f \"$STAMP_FILE\"; exit 0; }; touch \"$STAMP_FILE\"; echo \"⚠ coordinator about to edit application code ($FILE). This adds ~2-5KB to your context. If trivial, retry within 5s to proceed. If non-trivial, spawn a Builder.\" >&2; exit 2"
    }]
  }]
}
```

### Hook C — Stop hook diff-guard (already shown in Layer 2 above)

**What it prevents**: 120-second QA agent invocations on turns where nothing changed. Pure cost optimization, no behavior change. Already part of the Layer 2 example.

---

## What we explicitly do NOT enforce

These were considered and rejected, per the finsim audit:

| Considered | Why rejected |
|---|---|
| Block Coordinator Edit on app code | Breaks legitimate unblock scenarios (lint fix, 2-line follow-up); warn (Hook B) covers it |
| Force TeamCreate (Mode B) on visual PRs | Should be coordinator judgment based on the change type; over-enforcement creates ceremony |
| Require 2 consecutive PASSes per unit | Real trigger rate 3% in finsim — vestigial |
| Cap session length | Human-imposed boundaries fragment flow; rely on natural commit cadence |
| Block QA agent's Edit tool capability | `tools:` field doesn't strictly enforce in current Claude Code; document in agent_definitions.md instead |

---

## Layer 0 — CLAUDE.md orient every agent

CLAUDE.md is read by every Claude Code session. It should contain:

1. **What the project is** in one paragraph.
2. **Harness roles and communication paths** — one small diagram/table.
3. **Reference code locations** — where to look for established patterns.
4. **Architecture constraints** — things the project has committed to.
5. **How progress is measured** — the frontier metric and where it lives.
6. **Development conventions** — naming, formatting, test layout.
7. **Pointer to `lessons.md`** — so agents know to consult it.

Agent-specific instructions do *not* belong here — they go in `.claude/agents/{role}.md`. Keep CLAUDE.md short; if it's longer than two screens, something belongs in a reference file instead.

---

## Layer 4 — Tool scopes (documentation, not strict enforcement)

Each agent's `tools:` field documents intent. In current Claude Code, this field is advisory — it does not hard-block tools not listed. So use it for clarity (readers know what the role should do) but rely on Layer 3 hooks for actual enforcement of the few catastrophic cases.

For destructive-command protection at this layer, use PreToolUse command hooks — block `git push --force`, `git reset --hard`, `rm -rf` and similar before they execute (same mechanism as Hook B; a per-project allowlist hook is a few lines of shell).
