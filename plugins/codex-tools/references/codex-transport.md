# Codex transport

Use an installed, authenticated Codex CLI. Honor configured defaults; do not hardcode model identities or override them unless the operator explicitly requests it. Check `codex exec --help` for the installed version.

Inside a governed delegation workflow, use its approved Codex-capable runner. Direct CLI invocation is for an operator-selected CLI workflow, not a fallback after native runner failure. A delegated child does not gain authority to start another reviewer.

For direct CLI review, first execute `mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX"` and retain its returned path. Write `prompt.txt` inside that directory using the file tool: identify the exact subject/version, review questions, repository access mode, evidence requirement, and read-only boundary. Do not put credentials or customer data into prompts.

In the invocation shell, set `run_dir` to that already-created absolute path and `repo` to the approved repository/context directory. Shell variables from a previous tool call may not persist. Do not create a second directory after writing the prompt.

```sh
codex exec --sandbox read-only --cd "$repo" \
  --output-last-message "$run_dir/review.txt" - \
  < "$run_dir/prompt.txt" > "$run_dir/stdout.txt" 2> "$run_dir/stderr.txt"
```

Check exit status before interpreting results. Nonzero exit, absent/empty final output, or a reported execution blocker is a failed/incomplete review. Preserve relevant error evidence; do not treat an old artifact as the new result or silently change runner, sandbox, or execution mode.

`codex exec` writes its final response to stdout; `--output-last-message` also saves it to a file. Read the actual saved response and relevant stderr. Use the same unique directory with distinct outputs for later authorized rounds; never use fixed `/tmp` paths or document basenames as a concurrency identifier.

Keep useful private evidence only as authorized; remove temporary artifacts when no longer needed. Do not upload raw prompts/reviews automatically. Refinement edits belong to the approved writer, not this read-only CLI review.
