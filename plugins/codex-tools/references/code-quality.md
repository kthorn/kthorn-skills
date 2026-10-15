# Code and test quality

Review the requested change and enough surrounding code to understand its behavior. These are investigative questions, not mechanical rewrite rules or reasons to expand into a repository audit.

## Code clarity and responsibility

- **Cohesion:** do functions, classes, and modules group related behavior? Flag responsibilities that obscure each other—not arbitrary size thresholds.
- **Control flow:** does nesting, branching, or helper indirection make the behavior difficult to follow? Prefer a clearer flow without replacing straightforward branches with clever dispatch machinery.
- **Types:** do casts or suppressions hide an unresolved mismatch? Distinguish validated narrowing from treating unchecked input as trustworthy.
- **Defensive code:** what invariant, failure mode, or trust boundary justifies each guard or exception handler? Investigate redundant checks, swallowed failures, and misleading fallback values. Preserve necessary validation and recovery.
- **Wrappers and helpers:** do they name a meaningful operation, preserve a contract, or isolate a real boundary? Recommend removal only when their purpose is demonstrably unnecessary.
- **Names and documentation:** retain intermediate variables that explain meaning and comments that explain constraints, invariants, or non-obvious decisions. Flag misleading documentation and narration that merely repeats the code.

Shorter code is not automatically clearer or equivalent.

## Test fidelity to the contract

- **Requirement coverage:** connect distinct requirements and their interactions to observable assertions. Look for missing behavior—not a quota of tests or one test per sentence.
- **Input domain:** check the smallest permitted inputs and meaningful boundaries, including empty and single-element cases where allowed. Property generators should represent the intended domain rather than exclude inconvenient cases.
- **Expected rejection:** ground error expectations in the contract, applicable safety requirements, or confirmed designer intent. Neither silence in a spec nor an existing test settles an uncertain policy.
- **Failing examples:** determine whether the input is permitted, the expected result is justified, and the implementation meets that expectation. Narrow a generator only when evidence establishes that it exceeded the intended domain—not simply to make the suite pass.
- **Changed requirements:** reconcile new behavior with existing guarantees and interactions. Surface consequential conflicts rather than silently making either the old tests or the new wording authoritative.

## Recommendations

Use the existing review format. Explain the concrete consequence, behavior that must remain, and smallest meaningful validation. Separate supported defects from optional style preferences; no findings is valid.

Review does not authorize edits, dependency changes, or another review stage.

Source selection and local departures are recorded in [UPSTREAMS.md](../UPSTREAMS.md).
