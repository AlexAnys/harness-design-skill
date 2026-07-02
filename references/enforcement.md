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

Opening Claude Code in the project lands on the coordinator. The user can't forget to use the harness because there's nothing else to use. (Triangle / fan-out structures; solo+check and pipeline projects need no default agent.)

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

Per the hook-engineering rule below, the logic lives in a script; `settings.json` only registers it:

```json
{
  "PostToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/lessons-gate.sh\""
    }]
  }]
}
```

Claude Code delivers the tool payload to a hook as **JSON on stdin** — there is no `$CLAUDE_TOOL_INPUT` environment variable (an earlier version of this example read one, so the hook never fired in a real session even though its regex was correct in isolation). The script reads stdin, pulls the command, and gates on it:

```bash
# .claude/hooks/lessons-gate.sh — after an r2+ PASS, block git commit until that day's lesson is written
IN=$(cat)
printf '%s' "$IN" | jq -r '.tool_input.command // ""' | grep -q 'git commit' || exit 0
PAT="$(printf '\tr([2-9]|[1-9][0-9]+)\t[^\t]*\tPASS(\t|$)')"
TSV="$CLAUDE_PROJECT_DIR/.harness/progress.tsv"
LESSONS="$CLAUDE_PROJECT_DIR/.harness/lessons.md"
for d in $(tail -5 "$TSV" 2>/dev/null | grep -E "$PAT" | cut -c1-10 | sort -u); do
  grep -q "$d" "$LESSONS" 2>/dev/null && continue
  echo "⚠ r2+ PASS on $d has no lessons.md entry dated $d. Append a lesson (symptom/root cause/detection/prevention/commit) before committing." >&2
  exit 2
done
exit 0
```

Two design points the earlier one-liner got wrong: it gates on **each matching row's own date**, not "today" (a PASS whose lesson was written the day it happened must not block an unrelated commit the next morning), and the pattern covers `r2` **and any later round** (`r4 PASS` after alternating failures still earns a lesson). It is pinned to the `progress.tsv` column order defined in `software_harness.md` (`timestamp | unit | round | scores | status | …`).

This is the **only hook that actively blocks** (exit 2). Everything else warns.

**Hook engineering rule** (applies to every hook here and every hook you generate): non-trivial hook logic lives in a script file (`.claude/hooks/*.sh`) registered by a one-line JSON entry — and **every hook ships with a minimal trigger self-test** that feeds the real contract (a stdin JSON payload, not just a regex line) and **asserts the exit codes**, *before* the hook is trusted to gate anything. A hook that has never fired in a test is scaffolding theater. The self-test must exit non-zero when the hook is dead, so a CI step or a `&& trust` gate can rely on it — echoing `$?` for a human to eyeball is not an assertion:

```bash
# .claude/hooks/test-lessons-gate.sh — assert Hook A's exit codes before trusting it; any failure exits non-zero
GATE="$(dirname "$0")/lessons-gate.sh"
export CLAUDE_PROJECT_DIR="$(mktemp -d)"
mkdir -p "$CLAUDE_PROJECT_DIR/.harness"
printf '2026-06-06T00:00:00Z\tauth\tr2\t9/10\tPASS\t0.41\tfix login\tabc1234\n' > "$CLAUDE_PROJECT_DIR/.harness/progress.tsv"
: > "$CLAUDE_PROJECT_DIR/.harness/lessons.md"
rc() { printf '%s' "$1" | bash "$GATE"; echo $?; }
# must BLOCK (exit 2) — git commit after an r2 PASS with no lesson dated that day:
[ "$(rc '{"tool_input":{"command":"git commit -m x"}}')" = 2 ] || { echo 'FAIL: r2 PASS with no dated lesson did not block — Hook A is dead' >&2; exit 1; }
# must PASS (exit 0) — a non-commit command:
[ "$(rc '{"tool_input":{"command":"ls"}}')" = 0 ] || { echo 'FAIL: non-commit command was blocked' >&2; exit 1; }
# must PASS (exit 0) — the day's lesson now exists:
echo '## L-001 · 2026-06-06 · fix' >> "$CLAUDE_PROJECT_DIR/.harness/lessons.md"
[ "$(rc '{"tool_input":{"command":"git commit -m x"}}')" = 0 ] || { echo 'FAIL: blocked even though a same-day lesson exists' >&2; exit 1; }
echo 'hook A self-test: PASS'
```

### Hook B — PreToolUse on Edit/Write: warn coordinator before app-code edits

**What it prevents**: silent context bloat from Coordinator drifting into Builder's role. Per `references/context_economy.md`, occasional Coordinator self-edits are fine; persistent ones erode long-horizon judgment via compaction risk.

This is **warn-don't-block** — re-running the same tool call within 5 seconds proceeds. The point is to make context cost visible, not to forbid the action.

Registered globally, script-first like Hook A; the acting agent's identity also arrives on stdin as `.agent_type` (there is no `$CLAUDE_AGENT_NAME` variable, and the session-level `CLAUDE_CODE_AGENT` would misfire — a Builder sub-agent's edits would still read as "coordinator"; a sub-agent's own type takes precedence on stdin):

```json
{
  "PreToolUse": [{
    "matcher": "Edit|Write",
    "hooks": [{
      "type": "command",
      "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/coordinator-edit-warn.sh\""
    }]
  }]
}
```

```bash
# .claude/hooks/coordinator-edit-warn.sh — warn when the coordinator (not a Builder) edits app code
IN=$(cat)
[ "$(printf '%s' "$IN" | jq -r '.agent_type // ""')" = coordinator ] || exit 0
FILE=$(printf '%s' "$IN" | jq -r '.tool_input.file_path // ""')
echo "$FILE" | grep -qE '\.harness/|\.md$|settings\.json$' && exit 0
STAMP=/tmp/coord-edit-ack-$(printf '%s' "$FILE" | shasum | cut -c1-12)
test -f "$STAMP" && test $(($(date +%s) - $(stat -f %m "$STAMP" 2>/dev/null || echo 0))) -lt 5 && { rm -f "$STAMP"; exit 0; }
touch "$STAMP"
echo "⚠ coordinator about to edit application code ($FILE). This adds ~2-5KB to your context. If trivial, retry within 5s to proceed. If non-trivial, spawn a Builder." >&2
exit 2
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
