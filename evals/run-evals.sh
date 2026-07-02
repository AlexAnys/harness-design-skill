#!/usr/bin/env bash
# Runner for evals/evals.json self_lint — repo-state assertions, executable today.
# scenario_evals are NOT run here: they require a scaffold-generation runner
# (marked requires_generation_run in evals.json; deliberately not wired in v0.3.0).
# Usage: bash evals/run-evals.sh   (from anywhere; assertions run at the repo root)
# Exit 0 = JSON valid and all self_lint assertions green.
set -u
cd "$(dirname "$0")/.." || exit 1

command -v python3 >/dev/null || { echo "run-evals: python3 required" >&2; exit 1; }

err=$(python3 -c "import json; json.load(open('evals/evals.json'))" 2>&1) || {
  echo "evals.json: invalid JSON — $(printf '%s' "$err" | tail -1)" >&2
  exit 1
}

python3 - <<'EOF'
import json, subprocess, sys
items = json.load(open('evals/evals.json'))['self_lint']
fail = [(i['id'], i.get('name', '')) for i in items
        if subprocess.run(['bash', '-c', i['assert']]).returncode != 0]
if fail:
    print('FAIL:', json.dumps([f[0] for f in fail]))
    for fid, name in fail:
        print('  %s  %s' % (fid, name), file=sys.stderr)
    sys.exit(1)
print('self_lint ALL GREEN (%d)' % len(items))
EOF
