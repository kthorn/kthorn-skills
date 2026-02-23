---
name: codex-refine
description: Iteratively review and refine a design doc or plan using Codex reviews until no significant issues remain. Dispatches Codex, filters noise, implements fixes, and re-reviews in a loop (max 5 iterations).
---

# Codex Refine

Iteratively refine a document through repeated Codex reviews until it converges on quality.

**Core principle:** Review → filter → fix → re-review → repeat until clean.

## When to Use

- When you want a design doc or plan polished through iterative external review
- After drafting a doc and before implementing it
- When a doc needs thorough vetting but you want the process automated

## Invocation

```
/codex-refine <file-path>
```

Or the user may say things like "refine this doc", "iterate on this plan with codex", etc.

## The Iteration Loop

For each iteration (max 5):

### Step 1: Dispatch Codex Review

```bash
codex exec -s read-only -o /tmp/codex-refine-iter-N.txt \
  "Review the document at <file-path>. Identify:
1. Gaps, missing steps, or incorrect assumptions
2. Logic errors, contradictions, or ordering problems
3. Security or correctness concerns
4. Unclear or ambiguous sections
Be specific and actionable. Organize by severity: critical, important, minor."
```

If not inside a git repo, add `--skip-git-repo-check`.

Use Bash with timeout 120000ms+.

Then read `/tmp/codex-refine-iter-N.txt`.

### Step 2: Triage Findings

Categorize each finding into one of:

**Fix** — Implement the change:
- Genuine gaps, missing steps, or incorrect information
- Logic errors, contradictions, or broken ordering
- Security or correctness issues relevant at any scale
- Unclear sections that would confuse readers

**Ignore** — Skip silently (do not ask the user):
- **Hallucinations**: References to files, APIs, libraries, or features that don't exist in the project
- **Trivial nits**: Formatting preferences, naming bikeshedding, stylistic opinions
- **Scale-only concerns**: Rate limiting, sharding, horizontal scaling, load balancing, caching layers, distributed locking — anything only relevant at multi-user/production scale. This is a hobby project with a handful of users.
- **Redundant with prior iterations**: Issues already addressed in a previous iteration that Codex is re-raising

**Ask the user** — When a finding is borderline:
- It might be valid but you're not sure if it applies to this project
- It's a design tradeoff where user preference matters
- It suggests a significant architectural change that may or may not be wanted

Use `AskUserQuestion` for borderline items. Present the Codex finding and your assessment, and let the user decide fix or ignore.

### Step 3: Implement Fixes

Apply all "Fix" changes to the document using Edit/Write tools. Make targeted, minimal edits — don't rewrite sections that aren't flagged.

### Step 4: Check Convergence

If no fixes were applied in this iteration (all findings were ignored or trivial), the doc has converged. Exit the loop.

Otherwise, increment iteration counter and go back to Step 1.

### Step 5: Update Plan Status

If the document has a YAML-style header or metadata section, add or update a `Status: Refined` line in it. If the document has no clear header/metadata area, add a status line near the top of the document after the title:

```
**Status:** Refined
```

This marks the plan as having been through the refinement process.

### Step 6: Report Summary

After the loop ends (converged or hit 5-iteration cap), report to the user:

```
## Refinement Summary

**Iterations:** N
**Converged:** yes/no

### Changes by iteration:
- **Iteration 1:** [brief list of what was fixed]
- **Iteration 2:** [brief list of what was fixed]
...

### Ignored (noise):
- [brief list of ignored items and why, grouped by category]

### Remaining (if hit cap):
- [any unresolved items from the final review]
```

## Important Notes

- **Always use `-o <file>`** to capture Codex output — it produces no stdout by default.
- Use a distinct output file per iteration (`/tmp/codex-refine-iter-1.txt`, `-iter-2.txt`, etc.) so you can reference earlier reviews.
- If Codex raises the same issue across iterations after you've already fixed it, it may be hallucinating the problem. Ignore on the second occurrence.
- The 5-iteration cap is a safety net. Most docs should converge in 2-3 iterations.
- This skill is for document refinement. For code review, use `codex-review` directly.

## Example

```
User: /codex-refine docs/plans/auth-system.md

You: I'll iteratively refine docs/plans/auth-system.md using Codex reviews.

**Iteration 1:**
[Dispatch Codex review]
[Read findings: 3 critical, 2 important, 4 minor, 2 hallucinations]
[Fix 5 real issues, ignore 2 hallucinations and 2 nits, ask about 1 borderline item]
[Apply edits to the doc]

**Iteration 2:**
[Dispatch Codex review]
[Read findings: 1 important, 3 minor]
[Fix 1 real issue, ignore 3 nits]

**Iteration 3:**
[Dispatch Codex review]
[Read findings: 2 minor nits only]
[Nothing to fix — converged]

## Refinement Summary
**Iterations:** 3
**Converged:** yes
...
```
