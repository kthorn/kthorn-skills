---
name: auditing-correctness
description: Use when an operator asks for a correctness audit of a subsystem before it ships, is switched on or is migrated, using property-based tests and formal models (TLA+/TLC, Lean) only where they add value, with findings fixed as separate PRs.
---

# Auditing correctness

Find correctness defects in a bounded subsystem before release, prove each with a reproduction
against real code, and land each fix as an independent PR. Most defects are found by reading
code against stated and unstated invariants and then reproducing them. Property tests and models
earn their place where an independent oracle exists or where interleavings decide correctness.

You orchestrate and are the only writer to shared state: the audit index, the discovery branch,
issues and PRs. Auditors and reviewers are read-only. Implementers write only in their own
worktrees.

## Repository profile

Look for `docs/correctness-audit.md`, or the path the repository's agent instructions name. A
profile supplies harness locations, test environment setup, formal-model conventions, decision
records, executor and reviewer routing, delivery rules, and earlier campaigns to calibrate on.
Follow it where it is more specific. Without one, ask the operator where discovery artifacts and
decisions live before building anything.

## Phase 0: Audit before building

1. **Lanes.** Split the subsystem into three to five areas: write/commit protocol, derived state,
   import/migration, deletion/lifecycle, read side. Dispatch one read-only auditor per area,
   on the strongest model available, using the
   [audit lane template](references/templates.md#audit-lane). The candidates steer everything
   after this point. Cheaper implementers build lanes and fixes later.
2. **Candidates are per invariant, not per component.** Each candidate names one invariant,
   classified as **stated** (quote the spec), **unstated** (one sentence the code relies on), or
   **by design** (cite the decision record that makes the behaviour intentional). An unstated
   invariant is not a weaker candidate. In the reference campaign, 16 of 25 confirmed findings
   broke unstated invariants, and 15 of them needed an operator decision.
3. **Find the current oracle** for every candidate: the test node ids that exercise it, or `none`.
   Gap is what makes a candidate worth a lane.
4. **Verify and rank.** Read every cited mechanism yourself, then rank by consequence × likelihood
   × gap (H=3, M=2, L=1). Write the inventory and ranked candidates into the audit index
   ([format](references/templates.md#audit-index)).
5. **Choose the tool per candidate:**

   | Candidate shape | Tool |
   |---|---|
   | A mechanism visible in the code with a concrete trigger | deterministic regression test |
   | An independent reference exists (full recomputation, literal set, decimal arithmetic, fault-free run) | Hypothesis machine or fault-injecting property |
   | Correctness depends on interleavings, crashes or locks across several actors, or on liveness | TLC model with a bridge test to real code |
   | A subtle algebraic claim that a property test cannot settle | Lean, which is rare |

   Don't commit to models before the audit points at a protocol. Do run TLC on any multi-actor
   protocol the audit flags. In the reference campaign it found a startup-liveness failure that no
   read-only lane had seen.
6. **Gate.** Present the ranked table, the proposed lanes and tools, and every unstated invariant
   that needs a decision. Wait for the operator's approval before Phase 1.

## Phase 1: Discovery lanes

Each approved lane runs in its own worktree from a brief
([template](references/templates.md#lane-brief)) and merges into one **discovery branch**. That
branch is never merged to main. It holds harnesses, models, reproductions and notes, and its
correctness matters more than its polish. Conventions are in [harness.md](references/harness.md).

- **Coverage gate.** Each machine declares the interactions it must reach. A label with zero hits
  fails the run. Count a hit only after the interaction has happened, not when a rule is entered.
  Write the gate first and watch it fail on an empty machine.
- **Mutation check.** Plant realistic defects as patches. A mutant is caught only when a test
  fails; the coverage gate alone doesn't count. A survivor means you strengthen the oracle or
  generator, or record the property as vacuous for that mutant. For TLC, weaken one guard in a
  copy of the module and expect a counterexample. Require every mutant to be caught.
- **Triage every failure.** Find the first divergence and rule out oracle or adapter error, which
  is a harness artifact and not a finding. Then write a deterministic reproduction against real
  code. Record what the reproduction refutes or narrows: a claim that splits into three findings
  and one refutation is the normal outcome.
- **Strict xfail.** Each confirmed reproduction lands on the discovery branch as a strict xfail
  that cites the finding id. It turns into a pass when the fix merges, and you retire it then. When
  retiring, read why it now passes or fails. Harness drift can masquerade as a fix or a regression.
- **Stopping rule.** A lane stops after two deep runs with no new failures and every coverage label
  above zero, or once every candidate has a mutation-checked passing oracle or a recorded finding.

## Findings

Record each finding in the index with: id, candidate, title, class (stated, unstated, or by
design), release-blocking, security-sensitive, reproduction path, and disposition. Disposition is
one of `fixed (#PR)`, `issue #N`, `operator decision: …` or `ambiguous (kept as xfail)`.

- **Unstated:** propose a contract and a default fix, and get the operator's decision before
  briefing a fix. Record the decision in the repository's decision record, not only in the PR.
- **Security-sensitive:** tell the operator first. Keep reproductions and discovery artifacts
  private until the operator chooses a disclosure route.
- **Release-blocking:** say so at once; don't hold it for the final report.

## Phase 2: Fixes

One root-cause cluster per PR, from a fresh branch off main. The PR carries its own deterministic
regression in the owning test module, never an import from the discovery suite. Brief each fix
with the [fix brief template](references/templates.md#fix-brief).

Run this loop for each implementation round:

1. The implementer commits the failing regression first, then the fix.
2. **Red/green yourself.** Run the round's new tests at the previous round's commit (expect
   failure) and at the head (expect a pass), in a temporary worktree. Copy the test files in, so
   that files the branch adds don't break the check. Use a per-test timeout, because unfixed code
   can hang ([harness.md](references/harness.md#redgreen)).
3. **Review.** Use `reviewing-work` for an independent read-only review of the round. After a fix
   round, review only the delta. Give the reviewer the operator's decision and the brief, because
   briefs can be wrong too.
4. Repeat until the review is clean. Then merge main, rerun focused validation, and run the
   repository's pre-PR cleanup.

Expect the fix rounds to find defects of their own. In the reference campaign, review or CI
caught real defects in most fix PRs. These included:
- an implementer departing from its brief;
- the orchestrator's own brief encoding the wrong contract;
- a fix that conflicted with an existing owner-scoped oracle.

After each merge, merge main into the discovery branch, retire the matching xfails, and update
the index.

## Completion

Close only when every lane has stopped and every finding has a disposition. Write a closing summary
into the index using the [closing template](references/templates.md#closing-summary), and post it
on the release or cutover issue. It covers:
- candidates and findings per lane, and refutations;
- which tool surfaced each finding;
- mutation results;
- kept and exploratory models;
- the release-blocking list with status;
- blind spots the release must still check, such as live services, model bounds, and paths
  changed after a model was last checked.

Leave out the details of any security finding the operator has not cleared.

## Common mistakes

| Mistake | Instead |
|---|---|
| Rank components and pick a tool per component | Rank invariants. The tool follows the candidate's shape |
| Close a violation as "by design" because no spec states it | Classify it as unstated and ask the operator; cite a decision record only when one exists |
| Commit to TLA+ models in the plan | Model the protocols the audit flags, and bridge each model to real code |
| Promote the discovery suite to CI | Keep it on the discovery branch; each fix carries its own regression |
| Accept a partial mutation score | Every mutant is caught by a failing test, or the property is recorded as vacuous |
| Put read-only auditors on a cheap model | Use the strongest model for audit lanes and review; cheap models implement |
| Trust the implementer's "fails before, passes after" | Re-run red/green yourself at the previous commit |
| Review a fix once | Review every round, including after your own brief changes |
