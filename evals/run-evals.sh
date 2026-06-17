#!/usr/bin/env bash
# Runner for evals/evals.json self_lint — repo-state assertions, executable today.
# scenario_evals are NOT run here: they require a scaffold-generation runner
# (marked requires_generation_run in evals.json; deliberately not wired in v0.3.0).
# Usage: bash evals/run-evals.sh   (from anywhere; assertions run at the repo root)
# Exit 0 = JSON valid and all self_lint assertions green.
set -u
cd "$(dirname "$0")/.." || exit 1

python3 -c "import json; json.load(open('evals/evals.json'))" || {
  echo "evals.json: invalid JSON" >&2
  exit 1
}

python3 - <<'EOF'
import json, subprocess, sys
items = json.load(open('evals/evals.json'))['self_lint']
fail = [i['id'] for i in items if subprocess.run(['bash', '-c', i['assert']]).returncode != 0]
if fail:
    print('FAIL:', fail)
    sys.exit(1)
print('self_lint ALL GREEN (%d)' % len(items))
EOF
