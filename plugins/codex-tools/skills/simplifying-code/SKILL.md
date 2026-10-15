---
name: simplifying-code
description: Use when the operator requests behavior-preserving code cleanup with edits, including an explicit pre-PR simplification pass.
---

# Simplifying Code

Review the requested changes for reuse, clarity, and unnecessary work, then apply justified improvements while preserving required behavior.

This is a **review-and-fix** task. The cleanup request authorizes behavior-preserving edits within its scope—not unrelated refactoring, new functionality, commits, or opening a PR.

## Establish the scope

Use the requested PR diff, base revision, or named files. Otherwise, identify the current task's changes, including relevant uncommitted work. If the target is unclear, ask rather than guessing from recently modified files.

Read enough surrounding code and affected consumers to understand the behavior. Preserve unrelated user work.

## Review and fix

Load the shared [code/test-quality criteria](../../references/code-quality.md). Look for existing helpers or standard-library/platform equivalents, redundant state or repeated work, and indirection that no longer serves a useful purpose.

For each candidate:
- Establish what is unnecessary and what behavior must remain.
- Check relevant semantics and edge cases before substituting an implementation.
- Apply the smallest supported improvement.
- Skip unsupported or merely stylistic suggestions; do not invent changes to justify the pass.

Preserve validation, recovery, accessibility, operator controls, compatibility, and meaningful boundaries. Fewer lines alone do not establish an improvement.

If a finding requires a product decision, migration, interface change, or consequential redesign, report it instead of silently including it in cleanup. Continue with independent, safe improvements.

Leave disputed behavior and its test expectations unchanged pending the operator's decision. Removing a prototype-only guard still chooses behavior; neither its origin nor deleting its test makes that change behavior-preserving.

## Verify and finish

Follow the repository's established verification requirements for the affected behavior. Repair problems introduced by cleanup and report unresolved failures; do not weaken tests to obtain a green result.

Summarize what changed, what was checked, and any deferred decisions. An already-simple result is a successful pass.

Finish the cleanup before handing control back to the normal PR workflow. Do not launch a fixed reviewer panel or automatically repeat passes until something changes.
