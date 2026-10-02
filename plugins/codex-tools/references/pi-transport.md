# Pi transport

Use the installed pi-subagents tools and configured roles. First inspect `subagent` with `action: "list", capabilities: true`; external runners must report available. Inspect current tool help/schema when unsure. A role name alone does not prove shell access, repository visibility, or read-only execution.

Select the configured reviewer suited to the named risk. Omit model overrides unless the operator explicitly requests one. Give the reviewer the pinned absolute subject/version, relevant repository context, approved scope, evidence questions, read-only boundary, and stop conditions. Do not assume support for a `reads` dispatch field, mandatory `plan-reviewer`, model rotation state, or a separate Paseo runner.

A typical single-review request uses supported fields:

```json
{
  "agent": "reviewer",
  "task": "Review the exact subject and revision identified in this brief. Read-only: report repository-backed findings and blockers; do not edit, delegate, or publish.",
  "cwd": "/absolute/session-owned/worktree",
  "context": "fresh",
  "async": true,
  "output": "/absolute/private/review-output.md"
}
```

Replace the brief and paths with the actual target and durable private output. Capability checks and this example do not themselves authorize delegation. Keep the session-owned worktree; isolate any separately authorized concurrent writer.

For an authorized multi-step/parallel delegated workflow, use one top-level asynchronous workflow and launch children inside it, following the installed orchestration guide. Do not turn ordinary children into orchestrators or give them parent publication authority.

Continue independent work or return control after launch. Native completion wakes the parent; do not poll/sleep or use `bg_wait` merely to await that notification. Consume the actual result at the dependency barrier. A launch notification is not a completed review.

Runner/tooling failure blocks that lane. Report the exact failure, run/status, cwd/branch, and any partial diff; do not silently switch to shell/foreground CLI or weaken the tool contract. When a resumed reviewer is needed, use supported continuation rather than creating a replacement roster.
