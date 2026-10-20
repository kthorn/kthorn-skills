# Auditing correctness: templates

Replace `<…>` with the campaign's values. Keep each template's output format exactly as given:
the orchestrator merges these outputs mechanically.

## Audit lane

```text
You are a read-only auditor for lane <LANE> (<AREA>) of <SUBSYSTEM>, ahead of <RELEASE EVENT>.
Work only by reading files under <WORKTREE>. Do not edit, create, run tests, or use git write
commands.

Scope: <files/modules>
Focus: <the lane's risks; for protocol lanes, say whether each multi-step protocol's correctness
depends on interleavings, crashes or retries across more than one actor>

Read first: <owning specs>, <decision records>, <formal-model README if any>.

Do:
1. Inventory every actor and write path in scope: what it writes (tables, objects, in-memory
   state), under which lock, lease or transaction, and what happens on crash, retry and
   cancellation. Cite file:line.
2. For every stated invariant touching the scope, find its current oracle: search the tests for
   ones that exercise it and record node ids, or "none". List the invariants the code relies on
   that no spec states.
3. For each suspected defect, search the decision records and completed design docs. If a decision
   makes the behaviour intentional, record it as "by design (<file>: <heading>)" instead.
4. Emit candidates where a regression test, property test or model would add information: the
   oracle is missing or weak, or you suspect a defect.

Output exactly two sections:

## Inventory
| Actor | Code | Writes | Under | Crash/retry/cancel behaviour |

## Candidates
### <LANE>-<n>: <short title>
- invariant: "<exact spec text>" | unstated: <one sentence> | by design: <citation>
- actors/write paths: <list>
- current oracle: <node ids> | none
- suspected failure: <operation sequence -> wrong observable state> | none suspected; coverage gap only
- consequence/likelihood/gap: <H|M|L>/<H|M|L>/<H|M|L>
- tool fit: regression | hypothesis | tlc | lean — <reason>
- cost: S | M | L
- evidence: <file:line, ...>

Rate consequence H when the failure loses or duplicates money or receipts, resurrects deleted
content, exposes another owner's data, or corrupts migrated history. Rate likelihood by whether
ordinary traffic (retries, cancellation, concurrency, restarts) reaches the path. Rate gap H when
the oracle is "none". Prefer fewer, sharper candidates.
```

## Audit index

One file on the discovery branch, with these sections in order:

1. **Ranking rule.** Score = consequence × likelihood × gap; give the tie-break.
2. **Actor and write-path inventory**, merged from the lanes.
3. **Ranked candidates.** Columns: rank, id, title, C/L/G, score, tool fit, cost, and your own check
   ("code-confirmed: …" or "oracle claim checked").
4. **Model candidates**, as proposed at the gate. For each: actors, properties, bounds and bridge
   test.
5. **Gate decisions:** the approved lanes, deferrals, and any security handling the operator agreed.
6. **Findings.** Columns: id, candidate, title, class, release-blocking, security-sensitive, repro
   path, disposition.
7. **Closing summary**, written at the end.

## Lane brief

```text
Lane <slug>: <candidates>. Worktree <path> on branch <discovery>-<slug>.
Contract: <the stated or decided invariants, quoted>.
Real code under test: <entry points; only infrastructure beyond the real interface may be faked>.
Reference model / oracle: <independent expression of intended behaviour; no production helpers>.
Coverage labels (each must be reached): <label: the interaction it proves happened>.
Mutations to plant: <NN-name: the realistic defect, and which label/oracle must catch it>.
Deliverables:
- the machine and/or regressions;
- mutation patches;
- strict-xfail reproductions for confirmed findings;
- NOTES.md with finding blocks, refutations and harness artifacts.
Stop when: <stopping rule>. Do not fix production code.
```

## Fix brief

```text
Fix <finding ids> (<issue>) on branch <name> from <base>, in worktree <path>.
Decided contract: <operator decision verbatim, with its date and where it is recorded>.
Defect: <trigger -> observed -> expected>, reproduced by <discovery repro path>.
Do:
1. Commit a failing regression in <owning test module>. It must not import the discovery suite.
2. Commit the smallest complete fix at the owning chokepoint. Reuse the canonical helpers: <list>.
3. Update <spec/decision record> where the invariant is durable.
Do not: <out-of-scope areas; no flag; no unrelated cleanup>.
Report: commits, before/after failure counts for the new tests, and suite totals.
No push, no PR. Leave the worktree clean.
```

For a later round, send only the review findings you accepted, each with the reason and the
expected behaviour, plus anything the operator decided since.

## Closing summary

1. **Candidates and findings per lane:** triaged, confirmed, and refuted or narrowed.
2. **Findings by the tool that surfaced them:** audit then regression; property machine or fault
   injection; model; proof.
3. **Mutation results per lane and model**, and any coverage-gate tuning.
4. **Models:** kept (with the property and the bridge test), exploratory, and not built (with the
   reason).
5. **Fix phase:** the defects that review or CI caught in the fixes themselves, and tooling lessons.
6. **Release-blocking findings** with their final status.
7. **Remaining blind spots** for the release to check.
