---
name: pi-refine
description: Use when iteratively refining a design doc, plan, or specification through repeated codebase-grounded reviews until it converges
---

# Pi Refine

Review → triage → fix → re-review until a review is clean.

`brainstorming` invokes this automatically for completed design specs after its
self-review. Manual use remains available for any document. Automatic
implementation-plan review is intentionally out of scope.

## Required Review Roster

For a codebase-grounded design spec, read this required configuration from `~/.pi/agent/settings.json`:

```json
{
  "piRefine": {
    "modelRoster": [
      { "runner": "pi", "model": "opencode-go/kimi-k3", "thinking": "max" },
      { "runner": "pi", "model": "opencode-go/qwen3.8-max", "thinking": "max" },
      { "runner": "pi", "model": "opencode-go/grok-4.5", "thinking": "high" },
      {
        "runner": "paseo",
        "provider": "claude",
        "model": "claude-opus-5",
        "thinking": "high",
        "mode": "plan"
      }
    ]
  }
}
```

All four objects, in this order, are required for a codebase-grounded design
spec. A missing or unknown `runner`, model, thinking value, provider, or mode
is a dispatch failure. Never invent a model, thinking level, fallback, or
replacement reviewer.

Before a codebase-grounded design-spec dispatch, verify native IDs against Pi's
loaded registry. For the Paseo entry, run `paseo provider diagnostic claude`,
then `paseo provider models claude --thinking`; require a `claude-opus-5` row that lists `high`. Authentication, quota, model-resolution, permission,
timeout, or execution failures pause refinement and are reported to the user;
they are never clean and never skipped.

## Subject Contract

For a codebase-grounded design spec, use `plan-reviewer`. Pin exactly one
subject file via `reads: [absoluteSpecPath]`; it must be the first text document
in `reads`. Pass the repository root separately so Paseo can inspect the same
codebase. Do not let either reviewer guess the subject.

## General Documents

For a general document, use `reviewer` with the pinned document and a text-only
review task. For a general document, do not run native-model or Paseo preflight.
Do not use `plan-reviewer`, claim a design-spec roster slot, or inspect a repository. Do not start a Paseo job for this path. This remains a manual pi-refine capability; no automatic caller dispatches it.

## Round-Robin Claim

For a codebase-grounded design spec, claim a slot immediately before **every**
dispatch, including after an automatic edit or a user answer. The persistent
cursor makes later specs begin after the last review call, not always with Kimi.

```bash
state_dir="$HOME/.pi/agent/state"
state_file="$state_dir/pi-refine-roster-index"
lock_file="$state_dir/pi-refine-roster-index.lock"
if ! mkdir -p "$state_dir"; then
  printf 'PI_REFINE_ROSTER_PAUSED cannot-create-state-dir=%s\n' "$state_dir" >&2
  exit 1
fi

if ! slot="$(flock "$lock_file" bash -c '
  set -euo pipefail
  state=$1
  if [ -e "$state" ] || [ -L "$state" ]; then
    if [ -L "$state" ] || ! [ -f "$state" ]; then
      printf "invalid-cursor=%s\n" "$state" >&2
      exit 1
    fi
    index=$(cat "$state")
  else
    index=0
  fi
  case "$index" in 0|1|2|3) ;; *) printf "invalid-cursor-value=%s\n" "$index" >&2; exit 1 ;; esac
  printf "%s\n" "$(( (index + 1) % 4 ))" >"$state"
  printf "%s\n" "$index"
' _ "$state_file")"; then
  printf 'PI_REFINE_ROSTER_PAUSED cursor=%s\n' "$state_file" >&2
  exit 1
fi

```

A missing cursor begins at slot `0`. An unreadable, non-regular, malformed, or
unwritable cursor fails loudly; never reset it.

## Review Dispatch

For a codebase-grounded design spec, run at most eight dispatches in one pass.
Use the claimed object, not an iteration number, to choose the route. A manual
general-document review uses `reviewer` directly and never enters this route.

### Pi route

For `runner: "pi"`, dispatch the packaged `plan-reviewer` with a nonempty
codebase-grounded review task, the pinned `reads` subject, and a unique
`mktemp` output file. Pass the route's model and thinking together as a
thinking-suffixed model string; for example:

```javascript
subagent({
  agent: "plan-reviewer",
  model: "${route_model}:${route_thinking}",
  reads: [absolute_spec_path],
  task: review_task,
  output: review_output
})
```

The suffix is mandatory for every native route, including
`opencode-go/grok-4.5:high`; do not rely on the agent definition's default
thinking level. Treat a missing or different reported model/thinking level as a
dispatch failure. The task must require file-and-line citations and these
checks: file/module references, architecture alignment, API compatibility,
dependencies, data flow, feasibility, edge cases, and test coverage.

### Paseo route

For `runner: "paseo"`, create a separate native-provider job in a local
Paseo workspace for `repository_root`. Do not rely on `--cwd`: an ambient
`PASEO_AGENT_ID` can select the caller workspace instead. Reuse a workspace with
the exact repository path or create one, then pass its explicit ID to the job.
Use a unique prompt file and output file; do not add a wrapper, extension,
dependency, or `--output-schema` (Paseo forbids it with `--background`).

```bash
set -euo pipefail

prompt_file="$(mktemp)"
output_file="$(mktemp)"
trap 'rm -f "$prompt_file"' EXIT

cat >"$prompt_file" <<EOF
Review only the design spec at: $absolute_spec_path
Inspect the repository at: $repository_root
Do not edit any file. Cross-reference the spec against the codebase and cite paths and lines.
Start with exactly one line: RESULT: clean or RESULT: findings.
Then use the plan-reviewer headings: Critical, Important, Minor, Codebase Context, Verified.
EOF

workspace_id="$(paseo workspace ls --json | jq -r --arg cwd "$repository_root" \
  'first(.[] | select(.cwd == $cwd) | .workspaceId) // empty')"
if [ -z "$workspace_id" ]; then
  workspace_id="$(paseo workspace create --isolation local --path "$repository_root" \
    --title 'Pi spec review' --json | jq -er '.workspaceId')"
fi

run_json="$(paseo run --background --json \
  --workspace "$workspace_id" --provider claude --model claude-opus-5 \
  --thinking high --mode plan "$(<"$prompt_file")")"
agent_id="$(jq -er '.agentId' <<<"$run_json")"
wait_json="$(paseo wait --json --timeout 900 "$agent_id")"
status="$(jq -er '.status' <<<"$wait_json")"
if [ "$status" != idle ]; then
  printf 'PASEO_REVIEW_PAUSED agent=%s workspace=%s status=%s\n' \
    "$agent_id" "$workspace_id" "$status" >&2
  exit 1
fi
paseo logs "$agent_id" --tail 200 >"$output_file"
marker_count="$(grep -Ec '^RESULT: (clean|findings)$' "$output_file" || true)"
if [ "$marker_count" -ne 1 ]; then
  printf 'PASEO_REVIEW_PAUSED agent=%s workspace=%s invalid-result-marker-count=%s\n' \
    "$agent_id" "$workspace_id" "$marker_count" >&2
  exit 1
fi
result="$(grep -E '^RESULT: (clean|findings)$' "$output_file")"
```

The 900-second wait bound turns a hung job into a timeout pause rather than an
indefinite block. Record `workspace_id`, `agent_id`, and the output path in the
refinement summary. A non-idle wait, missing result marker, or failed command
pauses the pass and surfaces the Paseo IDs and diagnostic output to the user.

## Triage and Convergence

Classify every finding:

- **Fix:** clear, substantive factual gap, incompatibility, logic error, or
  security/privacy/authorization issue. Apply the smallest targeted document
  edit.
- **Ask the user:** architecture, scope, security trade-off, or preference that
  lacks an objectively correct choice. Pause, ask one concrete question, apply
  the answer, then continue the same pass.
- **Ignore:** hallucination, duplicate already fixed issue, formatting nit,
  bikeshed, or unjustified scale-only/over-engineered suggestion.

A Paseo review is clean only when it has exactly one `RESULT: clean` marker **and** has no substantive finding. A missing, duplicated, or conflicting marker pauses the pass. A Pi or manual-general-document review is clean when its output has no substantive finding. Treat Critical and Important findings as substantive; Minor-only output is clean.

A clean codebase-grounded design-spec review immediately converges the pass; do
not call the remaining roster entries. After a substantive design-spec edit,
claim the next slot and review again. Do not require a full roster pass.

For a manual general document, use the same triage rules and re-dispatch
`reviewer` after a substantive edit; no Paseo or design-spec roster applies.

After eight design-spec dispatches without a clean review, report unresolved
findings and pause. Never proceed to implementation planning from an unresolved
pass.

## Completion Report

On convergence, add or update `**Status:** Refined` near the document title.
Report each dispatched route, model, thinking level, Paseo agent ID when used,
all findings and dispositions, the number of dispatches, and whether it
converged. Return a codebase-grounded design-spec review to `brainstorming` for the final user-approval gate; return a manual general-document review to its caller.
