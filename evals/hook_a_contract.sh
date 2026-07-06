#!/usr/bin/env bash
# Extracts Hook A's gate + self-test from references/enforcement.md and runs them against
# fixtures using the REAL hook contract (tool input arrives as JSON on stdin). Fails loudly
# if the shipped hook drifts from firing correctly — the physical-not-copy guard for SL-1:
# a hand-copied regex in evals.json cannot catch enforcement.md rot (the phantom-env-var
# and dead-column-order bugs both shipped green under literal-string assertions).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ENFORCEMENT_SRC:-$ROOT/references/enforcement.md}"
command -v jq >/dev/null || { echo "hook_a_contract: jq required to exercise the hook" >&2; exit 1; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

extract_block() { # $1 = ERE matching the block's first content line
  awk -v pat="$1" '
    /^```bash/ { inblock=1; first=1; buf=""; keep=0; next }
    inblock && /^```/ { if (keep) { printf "%s", buf; exit } inblock=0; next }
    inblock { if (first) { if ($0 ~ pat) keep=1; first=0 } buf = buf $0 "\n" }
  ' "$SRC"
}
extract_block '^# \.claude/hooks/lessons-gate\.sh'      > "$WORK/lessons-gate.sh"
extract_block '^# \.claude/hooks/test-lessons-gate\.sh' > "$WORK/test-lessons-gate.sh"
[ -s "$WORK/lessons-gate.sh" ]      || { echo "hook_a_contract: could not extract lessons-gate.sh from enforcement.md" >&2; exit 1; }
[ -s "$WORK/test-lessons-gate.sh" ] || { echo "hook_a_contract: could not extract test-lessons-gate.sh from enforcement.md" >&2; exit 1; }

# 1. The shipped self-test must pass against the shipped gate (block / non-commit / same-day-lesson).
bash "$WORK/test-lessons-gate.sh" >/dev/null 2>&1 || { echo "hook_a_contract: shipped self-test FAILED against shipped gate" >&2; exit 1; }

# 2. Extra edge cases the self-test doesn't cover, run directly against the extracted gate.
export CLAUDE_PROJECT_DIR="$WORK/proj"; mkdir -p "$CLAUDE_PROJECT_DIR/.harness"
rc() { printf '%s' "$1" | bash "$WORK/lessons-gate.sh" 2>/dev/null; echo $?; }
fail() { echo "hook_a_contract: $1" >&2; exit 1; }

: > "$CLAUDE_PROJECT_DIR/.harness/lessons.md"
printf '2026-06-06T00:00:00Z\tauth\tr2\t9/10\tPASS\t0.41\tfix\tabc1234\n' > "$CLAUDE_PROJECT_DIR/.harness/progress.tsv"
[ "$(rc '')" = 0 ] || fail "empty stdin did not fail open"
[ "$(rc 'not json')" = 0 ] || fail "garbage stdin did not fail open"

printf '2026-06-06T00:00:00Z\tauth\tr1\t9/10\tPASS\t0.41\tok\tabc1234\n' > "$CLAUDE_PROJECT_DIR/.harness/progress.tsv"
[ "$(rc '{"tool_input":{"command":"git commit -m x"}}')" = 0 ] || fail "r1-only PASS wrongly blocked (regex over-fires)"

printf '2026-06-06T00:00:00Z\tauth\tr2\t3/10\tFAIL\t0.42\tretry PASSword fix\tabc1234\n' > "$CLAUDE_PROJECT_DIR/.harness/progress.tsv"
[ "$(rc '{"tool_input":{"command":"git commit -m x"}}')" = 0 ] || fail "FAIL row with 'PASSword' in description wrongly blocked"

echo "hook_a_contract: PASS"
