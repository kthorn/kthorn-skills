---
name: reviewing-complexity
description: Use when an operator explicitly requests an over-engineering review, justified code deletions, or a scoped complexity audit.
---

# Reviewing Complexity

Find justified cuts, not reasons to redesign. This is a read-only, deletion-focused
review, not a general correctness review or an automatic-fix workflow.

Load the [shared procedure](../../references/review-and-refinement.md) and
[invocation guide](../../references/invocation.md). Requested or required independent
review follows the shared opposite-family rule; unknown/unavailable family or route
means stop and ask for help. Inline auditing remains valid when independent review
is not required; do not add a review merely because a runner exists.

## Scope and evidence

Start with the requested diff or files. Audit a repository only when explicitly
requested; follow relevant callers and contracts far enough to assess each cut.

Look for unnecessary layers, unused options, duplicated helpers, and custom code
or dependencies covered by an existing helper, standard library, or native feature.
Compare actual semantics and edge cases before recommending a replacement.

Keep required behavior, safety checks, accessibility, operator controls, and
independently evolving contracts. One visible implementation alone does not make
a boundary unnecessary. Less code is not evidence of equivalence.

Report recommendations without editing files, installing/removing dependencies,
committing, or publishing. Implementation follows the normal approved workflow.

## Findings

List larger, well-supported cuts first. Each finding names:

- **Location and cut:** what to remove and its concrete replacement, if needed.
- **Evidence:** callers, contracts, or tests showing why the complexity is unnecessary.
- **Preservation and check:** behavior that must remain and the smallest meaningful validation.

Example: `export.py:5 — reuse csv_core.write_row; removes duplicate quoting logic;
preserves CSV escaping; check: CSV round-trip regression.`

Separate unproven candidates from recommendations and name the missing evidence.
If nothing is justified, say **No justified cuts found**. Do not invent findings,
line-count targets, scores, or unmeasured savings.
