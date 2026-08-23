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

Read this required configuration from `~/.pi/agent/settings.json`:

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

All four objects, in this order, are required. A missing or unknown `runner`,
model, thinking value, provider, or mode is a dispatch failure. Never invent a
model, thinking level, fallback, or replacement reviewer.

Before the first dispatch, verify native IDs against Pi's loaded registry. For
the Paseo entry, run `paseo provider diagnostic claude` and verify
`claude-opus-5` is available. Authentication, quota, model-resolution,
permission, timeout, or execution failures pause refinement and are reported to
the user; they are never clean and never skipped.

## Subject Contract

For codebase-grounded subjects, use `plan-reviewer`. Pin exactly one subject
file via `reads: [absoluteSpecPath]`; it must be the first text document in
`reads`. Pass the repository root separately so Paseo can inspect the same
codebase. Do not let either reviewer guess the subject.

## Round-Robin Claim

Claim a slot immediately before **every** dispatch, including after an automatic
edit or a user answer. The persistent cursor makes later specs begin after the
last review call, not always with Kimi.

```bash
state_dir="$HOME/.pi/agent/state"
state_file="$state_dir/pi-refine-roster-index"
lock_file="$state_dir/pi-refine-roster-index.lock"
mkdir -p "$state_dir"

slot="$(flock "$lock_file" bash -c '
  state=$1
  index=$(cat "$state" 2>/dev/null || printf 0)
  case "$index" in 0|1|2|3) ;; *) exit 2 ;; esac
  printf "%s\n" "$(( (index + 1) % 4 ))" >"$state"
  printf "%s\n" "$index"
' _ "$state_file")"
```

A malformed cursor fails loudly; do not reset it. A missing cursor begins at
slot `0`.

## Review Dispatch

Run at most eight dispatches in one pass. Use the claimed object, not an
iteration number, to choose the route.

### Pi route

For `runner: "pi"`, dispatch `plan-reviewer` with the route's exact model and
thinking level, a nonempty codebase-grounded review task, the pinned `reads`
subject, and a unique `mktemp` output file.

The task must require file-and-line citations and these checks: file/module
references, architecture alignment, API compatibility, dependencies, data flow,
feasibility, edge cases, and test coverage.

### Paseo route

For `runner: "paseo"`, create a separate native-provider job in a local
Paseo workspace for `repository_root`. Do not rely on `--cwd`: an ambient
`PASEO_AGENT_ID` can select the caller workspace instead. Reuse a workspace with
the exact repository path or create one, then pass its explicit ID to the job.
Use a unique prompt file and output file; do not add a wrapper, extension,
dependency, or `--output-schema` (Paseo forbids it with `--background`).

```bash
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
wait_json="$(paseo wait --json "$agent_id")"
test "$(jq -er '.status' <<<"$wait_json")" = idle
paseo logs "$agent_id" --tail 200 >"$output_file"
grep -Eq 'RESULT: (clean|findings)' "$output_file"
```

Record `workspace_id`, `agent_id`, and the output path in the refinement
summary. A non-idle wait, missing result marker, or failed command pauses the
pass and surfaces the Paseo IDs and diagnostic output to the user.

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

A review is clean only when it explicitly says `RESULT: clean` **and** has no
substantive finding. A clean review immediately converges the pass; do not call
the remaining roster entries. After a substantive edit, claim the next slot and
review again. Do not require a full roster pass.

After eight dispatches without a clean review, report unresolved findings and
pause. Never proceed to implementation planning from an unresolved pass.

## Completion Report

On convergence, add or update `**Status:** Refined` near the document title.
Report each dispatched route, model, thinking level, Paseo agent ID when used,
all findings and dispositions, the number of dispatches, and whether it
converged. Return control to `brainstorming` for the final user-approval gate.
