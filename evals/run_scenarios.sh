#!/usr/bin/env bash
# Runner for evals/evals.json scenario_evals — MANUAL and TOKEN-COSTING.
# Each case spawns a real `claude -p` generation into a fresh sandbox; never run this
# from CI or run-evals.sh.
#
# Grading is UNCALIBRATED (the X3 lesson): a FAIL is signal; a PASS is weak evidence
# until a human reads the generated scaffold and transcript. Null floor: before
# generation, every deterministic check is run in the still-EMPTY sandbox — a check
# that already passes there cannot distinguish "scaffolded correctly" from "did
# nothing" and is marked non-discriminative (negative). A case whose checks all pass
# but with zero positive checks reads UNKNOWN, not PASS. Cases built entirely from
# absence checks (SE-006/007) can therefore never read PASS here — by design.
# SE-005's fixture is described in its prompt but not materialized by this runner;
# treat its verdict accordingly.
#
# Usage: bash evals/run_scenarios.sh [-k SE-002] [-m haiku]
# Artifacts: evals/runs/<UTC-stamp>/<case-id>/ (scaffold copy, transcript, result.json).
# Exit: non-zero if any case FAILs. UNKNOWN does not fail the run — it means "can't tell".
set -u
cd "$(dirname "$0")/.." || exit 1

command -v python3 >/dev/null || { echo "run_scenarios: python3 required" >&2; exit 1; }
command -v claude  >/dev/null || { echo "run_scenarios: claude CLI required" >&2; exit 1; }

ONLY="" MODEL=""
while getopts "k:m:" opt; do
  case $opt in
    k) ONLY=$OPTARG ;;
    m) MODEL=$OPTARG ;;
    *) echo "usage: bash evals/run_scenarios.sh [-k SE-00N] [-m model]" >&2; exit 1 ;;
  esac
done

RUN_DIR="evals/runs/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$RUN_DIR"

ONLY="$ONLY" MODEL="$MODEL" RUN_DIR="$RUN_DIR" REPO="$(pwd)" python3 - <<'EOF'
import json, os, shutil, subprocess, sys, tempfile

repo, run_dir = os.environ['REPO'], os.environ['RUN_DIR']
only, model = os.environ['ONLY'], os.environ['MODEL']

cases = json.load(open('evals/evals.json'))['scenario_evals']['cases']
cases = [c for c in cases if not only or c['id'] == only]
if not cases:
    print('run_scenarios: no case matched %r' % only, file=sys.stderr); sys.exit(1)

def run_check(check, cwd):
    return subprocess.run(['bash', '-c', check], cwd=cwd, capture_output=True).returncode == 0

sysprompt = ('You have the harness-design skill. Its SKILL.md is at %s/SKILL.md '
             '(references/ alongside). Apply it and scaffold your answer into the '
             'current directory as real files. This is a non-interactive run: do not '
             'ask clarifying questions — make reasonable assumptions and write the '
             'files now. If the skill routes to "no scaffold", write nothing and say why.' % repo)

any_fail = False
rows = []
for c in cases:
    sandbox = tempfile.mkdtemp(prefix='se-sandbox-')
    # Null floor: a check that passes on the empty sandbox is non-discriminative.
    polarity = ['negative' if run_check(chk, sandbox) else 'positive'
                for chk in c['deterministic_checks']]

    cmd = ['claude', '-p', c['prompt'], '--append-system-prompt', sysprompt,
           '--allowedTools', 'Write,Edit,Bash', '--permission-mode', 'acceptEdits']
    if model:
        cmd += ['--model', model]
    gen_error = ''
    try:
        gen = subprocess.run(cmd, cwd=sandbox, capture_output=True, text=True, timeout=900)
        gen_out, gen_err, gen_rc = gen.stdout, gen.stderr, gen.returncode
    except subprocess.TimeoutExpired as e:
        gen_out, gen_err, gen_rc = (e.stdout or ''), (e.stderr or ''), -1
        gen_error = 'generation timed out (900s)'

    results = [{'check': chk, 'polarity': pol, 'pass': run_check(chk, sandbox)}
               for chk, pol in zip(c['deterministic_checks'], polarity)]
    n_pos = sum(1 for r in results if r['polarity'] == 'positive')
    if gen_error or any(not r['pass'] for r in results):
        verdict = 'FAIL'
    elif n_pos == 0:
        verdict = 'UNKNOWN'
    else:
        verdict = 'PASS'
    if verdict == 'FAIL':
        any_fail = True

    case_dir = os.path.join(run_dir, c['id'])
    os.makedirs(case_dir, exist_ok=True)
    shutil.copytree(sandbox, os.path.join(case_dir, 'scaffold'), symlinks=True, dirs_exist_ok=True)
    open(os.path.join(case_dir, 'generation.stdout.txt'), 'w').write(gen_out)
    open(os.path.join(case_dir, 'generation.stderr.txt'), 'w').write(gen_err)
    json.dump({'id': c['id'], 'verdict': verdict, 'model': model or '(default)',
               'generation_exit': gen_rc, 'generation_error': gen_error,
               'positive_checks': n_pos, 'checks': results, 'expected': c['expected']},
              open(os.path.join(case_dir, 'result.json'), 'w'), indent=2)
    shutil.rmtree(sandbox, ignore_errors=True)
    rows.append((c['id'], verdict, n_pos, results, gen_error))

print('\n%-8s %-8s %s' % ('case', 'verdict', 'checks (pass/fail, polarity)'))
for cid, verdict, n_pos, results, gen_error in rows:
    print('%-8s %-8s positive=%d/%d%s' % (cid, verdict, n_pos, len(results),
          ('  [' + gen_error + ']') if gen_error else ''))
    for r in results:
        print('    [%s][%s] %s' % ('pass' if r['pass'] else 'FAIL', r['polarity'], r['check']))
print('\nartifacts: %s' % run_dir)
sys.exit(1 if any_fail else 0)
EOF
