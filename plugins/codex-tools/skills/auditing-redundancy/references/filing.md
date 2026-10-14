# Issue bodies

Write for an implementer who has not seen the audit. Every location is `path:symbol`, with line
numbers only as hints.

## Duplication

```markdown
## Finding
<The policy in one sentence, and the fact that N sites implement it independently.>

## Exact locations
- `path:symbol`: <how this copy implements the policy; its callers>
- ...

## Canonical owner
<Existing implementation to extend, or the lowest common component for a new one, and why.>

## Behavioral differences / risk
<Difference table across sites. For each difference: intentional (cite), drift (which side is
correct), or environment-imposed. Persisted or wire outputs that consolidation could change.>

## Smallest consolidation
<Primitive signature, migration order, and what stays caller-specific.>

## Acceptance criteria
- One implementation owns the policy; the listed copies are removed.
- Parity test over representative inputs covers every migrated caller; intended behavior changes
  are listed explicitly.
- <Recurrence guard, if proposed.>
```

## Dead code

```markdown
## Finding
<What is dead and what it was for.>

## Exact locations
- `path:symbol` (unreferenced | test-only | registry-only | written-never-read | ...)

## Evidence of deadness
<Searches run, dynamic consumers checked, and the live path that superseded it, if any.>

## Removal scope
<Symbols, tests that only exercise them, docs that describe them, and anything that becomes dead
in turn. Persisted or wire data affected.>

## Acceptance criteria
- Listed symbols and their test-only tests are removed; the live path's tests still cover the
  behavior.
```
