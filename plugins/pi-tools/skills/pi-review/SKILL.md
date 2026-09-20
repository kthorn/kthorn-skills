---
name: pi-review
description: Use when needing external code review of git changes or design document review before implementation, or when the user asks for a pi review
---

# Pi Review

Get an independent review of code changes or a design document.

## Choose a runner first

The review agents differ in whether they can run shell commands. That matters
more than model choice: a reviewer with no shell cannot run `git diff`, `rg`, or
`pytest`, so it has to read whole files. On a diff of any real size that is slow,
and it eventually fails having produced nothing.

| Subject                       | Agent             | Shell          | Default                        |
| ----------------------------- | ----------------- | -------------- | ------------------------------ |
| Design doc, plan, spec        | `plan-reviewer`   | yes (`bash`)   | `opencode-go/kimi-k3` @ `max`  |
| Bounded change, 1–2 files     | `reviewer`        | **no**         | `openai-codex/gpt-5.6-terra` @ `max` |
| Branch / whole-branch diff    | Paseo Pi agent    | yes            | your choice — see below        |

Verify these against the registry with
`subagent({ action: "list", capabilities: true })` rather than trusting this
table. Guidance drifts; the registry does not.

## `reviewer` has no shell, deliberately

`reviewer`'s tools are `read`, `grep`, `find`, `ls`, `contact_supervisor`. It
cannot run commands and it cannot edit code. That makes it safe to point at
anything, but it also means it cannot see a diff for itself. It works well when
you supply the change directly:

```typescript
subagent({
  agent: "reviewer",
  task: "Review this diff for correctness, regressions, and missing error handling:\n\n" + diffText,
  output: "review.md",
});
```

Do not ask it to "inspect git diff" or "review the branch" — it cannot, and it
will quietly spend its whole budget reading files instead of reviewing.

## `plan-reviewer` is the shell-capable reviewer

Tools `read`, `bash`, `grep`, `find`, `ls`. It reviews **one pinned subject**
passed via `reads`: the first `.md`, `.txt`, or `.markdown` entry is the only
subject, and any further entries are codebase context, not alternate subjects.
It cites findings against paths and line numbers.

```typescript
subagent({
  agent: "plan-reviewer",
  model: "opencode-go/kimi-k3:max", // the thinking suffix is mandatory
  reads: [absoluteSpecPath],
  task: reviewTask,
  output: reviewOutput,
});
```

The suffix is required on every native route: do not rely on the agent
definition's default thinking level, and treat a different reported
model/thinking as a dispatch failure.

Use `plan-reviewer` for design documents, plans, and any review that has to
cross-reference the codebase.

## Branch review: the Paseo route

For a whole-branch diff, spawn a Pi agent in Paseo instead of a subagent child.
It gets a real shell, a long runtime, and its own workspace — none of which a
child has by default, and all three of which a branch review needs.

**Context gate.** This route exists only inside Paseo. Check both variables:

```bash
inside_paseo=false
if [ -n "${PASEO_AGENT_ID:-}" ] && [ -n "${PASEO_AGENT_CWD:-}" ]; then
  inside_paseo=true
fi
```

`PASEO_AGENT_ID` alone is insufficient. Outside Paseo, use the `reviewer` route
with the diff supplied, or hand the review back to the user.

**Reuse or create a workspace by path, never `--cwd`.** An ambient
`PASEO_AGENT_ID` can otherwise select the caller's workspace:

```bash
workspace_id="$(paseo workspace ls --json | jq -r --arg cwd "$repo_root" \
  'first(.[] | select(.cwd == $cwd) | .workspaceId) // empty')"
if [ -z "$workspace_id" ]; then
  workspace_id="$(paseo workspace create --isolation local --path "$repo_root" \
    --title 'Pi branch review' --json | jq -er '.workspaceId')"
fi
```

**Verify the resolved model.** `paseo inspect` reports what actually ran, so a
silent fallback to another model is caught rather than mistaken for a clean
review:

```bash
run_json="$(paseo run --background --json --workspace "$workspace_id" \
  --provider pi --model "$model" --thinking "$thinking" "$(<"$prompt_file")")"
agent_id="$(jq -er '.agentId' <<<"$run_json")"
paseo inspect "$agent_id" --json | jq -e --arg m "$model" '.Model == $m'
```

**`paseo wait` returns on transient idle.** Never read that as completion, and
never read a partial log as a verdict. Fail closed:

```bash
status="$(paseo wait --json --timeout 900 "$agent_id" | jq -er '.status')"
if [ "$status" != idle ]; then
  printf 'PASEO_REVIEW_PAUSED agent=%s status=%s\n' "$agent_id" "$status" >&2
  exit 1
fi
```

**Require exactly one result marker,** because a long log can mention the marker
in prose while reporting on it:

```bash
paseo logs "$agent_id" --tail 400 >"$output_file"
marker_count="$(grep -Ec '^RESULT: (clean|findings)$' "$output_file" || true)"
if [ "$marker_count" -ne 1 ]; then
  printf 'PASEO_REVIEW_PAUSED agent=%s invalid-result-marker-count=%s\n' \
    "$agent_id" "$marker_count" >&2
  exit 1
fi
```

`pi-refine`'s **Paseo route** section carries the same recipe with its full
roster and cursor logic. Keep the two consistent when changing either.

## Briefing any reviewer

- **State read-only explicitly.** Paseo agents and `plan-reviewer` are
  write-capable. Say "do not edit, create, or revert any file; report only", then
  verify afterwards with `git status --short` and confirm the worktree is untouched.
- **Budget the scope.** A child's default `timeoutMs` is 30 minutes. A brief with
  ten scrutiny areas over a seventy-file diff will not finish; it will time out
  having produced nothing. Cap it at roughly three areas per dispatch, or pass an
  explicit `timeoutMs`.
- **Tell it to grep, not read.** "Use `git diff`/`rg` to locate things; do not
  read whole files to find something" measurably changes how the budget is spent.
- **Ask for severity and citations.** Critical / Important / Minor, each with
  `file:line` and the corrected form, and a plain statement when a claim could
  not be verified.
- **Say what is already known.** Name defects an earlier pass found and fixed, so
  the reviewer verifies those fixes instead of rediscovering them.

## If a review times out

A timed-out child is not worthless. Its transcript usually holds the analysis
even when no verdict was written to the output artifact:

```
~/.pi/agent/sessions/<project>/subagent-artifacts/<runId>_<agent>_transcript.jsonl
```

Parse records with `role == "assistant"` and read `message.content[*].thinking`.
A 30-minute timed-out review still surfaced a real defect that way. Harvest the
transcript before re-dispatching — and treat what you find as the reviewer's
lead to verify yourself, not as a delivered review.

## Output

Present findings grouped by severity, preserving the reviewer's citations. Do not
soften a finding the reviewer marked Critical or Important, and do not report a
paused or timed-out review as clean.

## Related Skills

- `pi-refine` — iterative review → fix → re-review of a design spec, including
  the required model roster and the Paseo slot.
