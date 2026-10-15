---
name: refining-specs
description: Use when a spec has a concrete ambiguity, contradiction, missing success criterion, or consequential design risk, or the operator explicitly requests refinement.
---

# Refining Specs

Name the specific risk that could make a competent implementer build the wrong thing. An approved document or its filename alone is not a refinement trigger.

Mode: **review-only unless authorized to write this spec**. Discovering a risk does not authorize reopening an approved/declined document; report the risk and ask before editing when that edit is not already authorized.

Load the [shared procedure](../../references/review-and-refinement.md) and [invocation guide](../../references/invocation.md). Requested or required independent review follows the shared opposite-family rule; unknown/unavailable family or route means stop and ask for help. Inline evidence gathering remains valid, but cannot substitute for required independent review. Do not add a review merely because another runner exists.

## Refine with the human designer

A spec can be internally consistent and still describe the wrong outcome. Treat the human designer as the authority on intent; tests, existing code, and agreement among agents are evidence—not substitutes for that intent.

Use the established goals, constraints, and decisions. When understanding is missing or contradictory, summarize your interpretation so the designer can correct it.

## Pressure-test consequential decisions

For each material uncertainty:

1. **Ground it:** quote the requirement or identify the missing decision.
2. **Make it concrete:** give an input, user action, or failure scenario where plausible interpretations produce different outcomes.
3. **Explain the choice:** present the strongest alternatives, their practical trade-offs, and your recommendation.
4. **Ask the designer:** pose a focused question choosing between the consequential outcomes, with your recommendation separate from the question. Confirm the behavior itself—not merely parameters of a preferred option. Proposed wording remains provisional until that choice is confirmed.
5. **Capture the answer:** when authorized, make the smallest clarification in the existing spec and identify an acceptance example that distinguishes the chosen behavior.

For example: “The client retries after a timeout, but the first request succeeded. Should the retry return the original result, create another operation, or fail?”

Distinguish ambiguous wording from clearly specified but potentially unwanted behavior. Diagnose whether a mismatch belongs to the spec, implementation, test, or fixture before changing the requirement.

## Check ownership and retirement when relevant

If the design duplicates or replaces existing behavior, identify:
- the existing policy owner;
- shared mechanics versus intentional differences;
- behavior that must remain equivalent;
- superseded paths and any dynamic, external, persisted, or wire consumers.

These are targeted questions, not a repository-wide redundancy audit.

## Stop appropriately

Preserve settled decisions unless new evidence warrants reopening them. Resolve supported gaps within scope; stop when remaining feedback is optional polish. If a consequential decision remains unanswered, pause dependent work—not unrelated work that can safely continue.

Repeated substantive findings need evidence, not automatic dismissal. Delegated agents perform only their assigned step.
