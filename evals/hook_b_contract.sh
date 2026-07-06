#!/usr/bin/env bash
# Extracts Hook B (coordinator-edit-warn.sh) from references/enforcement.md and runs it
# against fixtures using the REAL hook contract (payload arrives as JSON on stdin; the
# acting agent's identity is stdin .agent_type). Same physical-not-copy guard as
# hook_a_contract.sh: a prose description of the hook cannot certify that the shipped
# script fires — only executing it can.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ENFORCEMENT_SRC:-$ROOT/references/enforcement.md}"
command -v jq >/dev/null || { echo "hook_b_contract: jq required to exercise the hook" >&2; exit 1; }
WORK="$(mktemp -d)"

extract_block() { # $1 = ERE matching the block's first content line
  awk -v pat="$1" '
    /^```bash/ { inblock=1; first=1; buf=""; keep=0; next }
    inblock && /^```/ { if (keep) { printf "%s", buf; exit } inblock=0; next }
    inblock { if (first) { if ($0 ~ pat) keep=1; first=0 } buf = buf $0 "\n" }
  ' "$SRC"
}
extract_block '^# \.claude/hooks/coordinator-edit-warn\.sh' > "$WORK/coordinator-edit-warn.sh"
[ -s "$WORK/coordinator-edit-warn.sh" ] || { echo "hook_b_contract: could not extract coordinator-edit-warn.sh from enforcement.md" >&2; rm -rf "$WORK"; exit 1; }

# The hook stamps /tmp/coord-edit-ack-<hash-of-file_path>; unique paths per run keep
# parallel/repeated runs from consuming each other's stamps, and the trap removes ours.
APP="src/app-hookb-$$-$(date +%s).ts"
STAMP="/tmp/coord-edit-ack-$(printf '%s' "$APP" | shasum | cut -c1-12)"
trap 'rm -f "$STAMP"; rm -rf "$WORK"' EXIT

rc() { printf '%s' "$1" | bash "$WORK/coordinator-edit-warn.sh" 2>"$WORK/stderr"; echo $?; }
fail() { echo "hook_b_contract: $1" >&2; exit 1; }

# must WARN (exit 2, names the Builder alternative) — coordinator editing app code:
[ "$(rc '{"agent_type":"coordinator","tool_input":{"file_path":"'"$APP"'"}}')" = 2 ] \
  || fail "coordinator app-code edit did not warn — Hook B is dead"
grep -q Builder "$WORK/stderr" || fail "warn message does not mention spawning a Builder"

# must PASS (exit 0) — retry of the same edit within 5s consumes the stamp:
[ "$(rc '{"agent_type":"coordinator","tool_input":{"file_path":"'"$APP"'"}}')" = 0 ] \
  || fail "retry within 5s was blocked — ack stamp not honored"
[ ! -f "$STAMP" ] || fail "ack stamp not consumed by the retry"

# must PASS (exit 0) — a Builder editing the same app code (the misfire the env-var version had):
[ "$(rc '{"agent_type":"builder","tool_input":{"file_path":"src/other-'$$'.ts"}}')" = 0 ] \
  || fail "builder edit was warned — identity check over-fires"

# must PASS (exit 0) — coordinator editing exempt paths (blackboard, docs, settings):
[ "$(rc '{"agent_type":"coordinator","tool_input":{"file_path":".harness/progress.tsv"}}')" = 0 ] \
  || fail ".harness/ edit was warned"
[ "$(rc '{"agent_type":"coordinator","tool_input":{"file_path":"notes-'$$'.md"}}')" = 0 ] \
  || fail ".md edit was warned"
[ "$(rc '{"agent_type":"coordinator","tool_input":{"file_path":".claude/settings.json"}}')" = 0 ] \
  || fail "settings.json edit was warned"

# must PASS (exit 0) — fail-open on empty or malformed stdin:
[ "$(rc '')" = 0 ] || fail "empty stdin did not fail open"
[ "$(rc 'not json')" = 0 ] || fail "garbage stdin did not fail open"

echo "hook_b_contract: PASS"
