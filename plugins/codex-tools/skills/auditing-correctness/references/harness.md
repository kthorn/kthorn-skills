# Auditing correctness: harness conventions

These are examples in Python, using pytest and Hypothesis. Use the repository's equivalents
elsewhere. The repository profile gives the paths.

## Layout on the discovery branch

```text
<tests>/property_discovery/<campaign>/
  AUDIT.md              audit index
  README.md             how to run; lanes table (targets, oracles, coverage counts, mutations, status);
                        open strict xfails; blind spots
  env.sh                test environment variables; never sourced before dependency sync
  profiles.py           budget(examples, steps=…) scales by a deep profile
  coverage.py           hit(label), require(lane, *labels)
  conftest.py           fails the session when a required label has zero hits
  run_mutations.sh      applies each patch, runs the lane, reverts; a patch is caught only by a failing test
  <lane>/test_*_repro.py, test_*_machine.py, mutations/NN-*.patch, NOTES.md
<formal>/discovery/<Model>.tla, .cfg, <Model>.mutations.md     exploratory models
```

A model is kept, under the repository's formal-methods conventions, only when it found a defect
or guards a subtle invariant the code depends on. Exploratory models stay on the discovery branch.

## Budgets and coverage

- **Budget.** Keep a small default budget for routine runs, with a deep profile at about 10×
  examples and 2× steps for the stopping-rule runs. Disable shrinking for mutation runs.
- **Coverage counters.** Increment a label only once the targeted interaction has happened. Under
  a modest budget, a rare interaction may hit zero and flake the gate. Raise that machine's budget
  and record why. Don't drop the label.

## Mutation runner

```bash
set -uo pipefail
lane="$1"; survived=0
git diff --quiet -- <src> || { echo "src not clean"; exit 2; }
for p in "<lane-dir>/$lane"/mutations/*.patch; do
  git apply "$p" || exit 2
  out="$(NO_SHRINK=1 pytest -q -x --hypothesis-seed=0 "<lane-dir>/$lane" 2>&1)"
  git apply -R "$p" || exit 2
  grep -qE '[0-9]+ failed' <<<"$out" && echo "caught   $p" || { echo "SURVIVED $p"; survived=1; }
done
exit $survived
```

For TLC, copy the module, weaken one guard or remove one fence action, and record the expected
violation in `<Model>.mutations.md`. Then run TLC on the copy.

## Strict xfail

```python
@pytest.mark.xfail(strict=True, reason="F-<n>: <one line>")
def test_<invariant_in_words>(...):
    ...  # the deterministic reproduction against real code
```

Run new reproductions once with `--runxfail` and confirm each fails for the stated reason. When a
fix merges, remove the marker. If the test then fails, read why: the harness may have drifted
from production signatures.

## Red/green

Run this for every implementation round. `PREV` is the previous round's commit, or the PR base for
round one.

```bash
FW=<fix worktree>; PREV=<commit>; T=<scratch worktree path>
files=$(git -C "$FW" diff --name-only --diff-filter=AM "$PREV"..HEAD -- '<tests>/**/*.py')
tests=$(git -C "$FW" diff "$PREV"..HEAD -- '<tests>/**/*.py' \
  | sed -nE 's/^\+(async )?def (test_[a-z0-9_]+).*/\2/p' | sort -u | paste -sd' ')
git worktree add --detach "$T" "$PREV"
for f in $files; do mkdir -p "$T/$(dirname "$f")"; git -C "$FW" show "HEAD:$f" > "$T/$f"; done
# sync dependencies in $T, then run the same selection in both trees:
(cd "$T"  && pytest -q --timeout=120 $files -k "${tests// / or }")   # expect failures
(cd "$FW" && pytest -q --timeout=120 $files -k "${tests// / or }")   # expect passes
git worktree remove --force "$T"
```

Copying the test files into a scratch worktree is safe even when the branch adds source files,
which `git checkout <base> -- <files>` is not. The timeout matters because unfixed concurrency
code can block forever.
