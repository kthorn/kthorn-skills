---
name: auditing-redundancy
description: Use when an operator requests a repository-wide or scoped audit for duplicated or reimplemented functionality, drifting copies of one concept, or dead and unused code, with findings filed as issues or small PRs.
---

# Auditing redundancy

Find duplicated implementations and dead code across a repository, then file one issue per
independently reviewable repair. Open a PR only when the repair is unambiguous (see Filing). For a
read-only review of a given diff or files, use `reviewing-complexity` instead; this skill is the
repository sweep that ends in filed work.

Optional input: a scope (paths, packages, or lenses) and `drafts-only`, which returns issue drafts
without writing to the tracker. Default scope is the repository's production code. Tests and scripts
count as consumers, not audit targets, unless the scope names them.

You are the sole writer. Workers are read-only and return candidates; only you file issues, open
PRs, or comment.

## Repository profile

Before generating candidates, look for a repository profile at `docs/redundancy-audit.md`, or at the
path the repository's agent instructions (`AGENTS.md`, `CLAUDE.md`) name. A profile can supply the
default scope, canonical-owner modules, dynamic-registration mechanisms, intent records, labels,
delivery rules, extra lenses, calibration examples, and costs from earlier runs. Follow it where it
is more specific than this skill. Without one, infer owners and intent records from the repository,
and ask the operator for labels and delivery rules before filing anything.

## Representation

**Duplication is one policy enforced at several sites.** A policy is a rule about bytes, identity,
bounds, error classification, security, lifecycle, or presentation: "canonical JSON sorts keys and
rejects NaN", "an object-store read is bounded and pinned to the observed version", "this exception
means retry". The unit of finding is the policy and its canonical owner, not a clone pair. Textual
similarity is neither necessary nor sufficient: the costly copies usually share no tokens (a
`json.dumps(sort_keys=True)` beside an incremental encoder), while look-alike boilerplate may be
deliberate layering. Search for what code *does*, then compare how.

**Dead code is a definition whose effect no production path consumes.** References overstate
liveness: tests, registries, `__all__` lists, schemas, settings models, re-exports, and its own
module keep dead code referenced. Reference-based tools (vulture, ts-prune, knip) are a first pass
only; the dead code agents leave behind is usually still referenced.

**Drift is the priority signal.** When copies disagree, at least one is probably wrong, and any
consolidation forces a behavior decision. A drifted copy is a latent bug report; an identical copy
is cleanup.

## Candidate generation

Run every generator over the scope. They are complementary; each misses what another finds.

1. **Policy-first sweep (highest yield).** For each concern family in
   [lenses.md](references/lenses.md), enumerate *every* site implementing it by searching for the
   underlying primitives: raw library calls, literal patterns, exception and error-code names,
   header and field names. Do not search only for the canonical helper's name; bypasses never
   mention it.
2. **Chokepoint bypass.** Inventory the canonical owners: shared or common packages, per-package
   core modules, spec-declared chokepoints, and generated contracts (API clients, schema types). For
   each, find code doing the same job without calling it. List every bypass site; one example is
   not a finding.
3. **Structural clones.** Cheap and low-recall; use for candidates only. Examples: `jscpd` over the
   source globs with tests excluded (it skips gitignored paths, so point it at a symlink when the
   checkout lives under an ignored directory), identifier-normalized AST hashes, same-name symbols
   across modules, and sync/async twin modules.
4. **Consumer reachability (dead code).** Build a production reference graph with tests excluded.
   Classify each symbol: unreferenced, test-only, self-only, registry/re-export-only. Then apply the
   semantic dead-code lenses, which the graph cannot see: written-never-read fields and settings,
   transforms whose input domain is empty, superseded paths kept beside their replacements, dead
   parameters, and orphans of recent removals (`git log --diff-filter=D`).
5. **Self-description.** Comments and docstrings saying "keep in sync with", "mirrors", "copied
   from", or "same as" mark known duplicates. Docs, decision records, or docstrings that cite
   missing symbols or claim a caller that no longer calls mark a dead neighbor.

Run the cheap generators (clone detection, a tests-excluded reference scan) once yourself and hand
their output to every worker.

## Coverage

Partition the work as a lens × package matrix and keep a coverage ledger: cell, worker, status,
generators run. Split large packages by subpackage. Assign each lens to exactly one cell; a worker
that notices another cell's concern lists it under "leads" without verifying it. Give each worker
one bounded cell, the relevant lenses, and the return contract below.

Dispatch each batch in parallel and blocking, so that results return to you before you continue
(for example, several agent calls in one message with background execution off). Launch no more
cells than you will wait for, and do not hand back while workers run. Workers start no workers or
background processes of their own. A cell that did not return is uncovered: rerun it or report it.
A quiet cell is evidence only if its search could have found a known instance; calibrate on the
profile's examples, a closed duplication or cleanup issue, or a removal in git history.

Cost scales with scope. One package of about 80k lines took 9 cells and 9 verifiers, roughly
3.5M tokens. When the operator gives no scope, state the planned cell count before dispatching.

Worker return contract, per candidate: the policy (one sentence) or dead symbol; every site as
`path:symbol`; a difference table across sites; for dead code, consumer evidence (searches run and
dynamic paths checked); suspected intent; confidence.

## Verification

Before filing, confirm each candidate:

- **Read every site.** Tabulate differences: accepted inputs, limits, encoding, error mapping,
  logging, side effects. Classify each difference as intentional (cite where), accidental drift
  (say which side looks correct and why), or imposed by the environment.
- **Check intent.** Search the repository's decision records, specs, and completed plans for each
  site's symbol names, module paths, and the concept. Respect dependency and deployable boundaries:
  a package that cannot depend on the shared one may need its own copy. Drop deliberate duplication
  unless its recorded rationale no longer holds, and cite the record in the dropped list so the
  operator can revisit the decision. A recorded constraint on the *output* (frozen bytes, a wire
  format, a persisted identity) constrains the repair and its parity test; it does not justify the
  copies.
- **Exhaust dynamic consumers for dead code:** decorator and route registration, registries and
  string dispatch, `getattr`, package entry points, build files, CI, deploy, evals, operator
  scripts, templates, and frontend entry points. A field may be dead in code yet live in persisted
  data or wire payloads; that removal is a migration question.
- **Refute independently.** Send each surviving finding to a fresh read-only verifier with the
  claim and sites, tasked to refute it; one verifier may take a themed group of about five. Drop or
  downgrade what it refutes, and file the verifier's corrections, not the worker's wording. For
  security-class claims, the verifier also assesses who can reach the path and what leaks or
  breaks; workers routinely overstate severity. This is in-audit verification. When the operator
  requires independent review, follow the [shared procedure](../../references/review-and-refinement.md).

## Prioritization

Rank by consequence class first, then drift, then copy count; never by line count.

1. **Consequence class.** Security (redaction, sanitization, URL encoding, authorization),
   integrity and identity (hashes, canonical bytes, persisted IDs), resource bounds, cancellation
   and lifecycle, and error classification that changes control flow. Copies of a policy in these
   classes are filed even when they currently agree: agreement today is what makes the
   consolidation a safe, behavior-preserving PR, and the next edit to one copy is the drift.
2. **Drift** raises priority within a class. A drifted copy is a latent defect.
3. **Copy count** breaks ties. Repeated protocol or client boilerplate across three or more sites
   (session setup, result unpacking, error mapping) is an adapter finding, not noise.

Small pure helpers outside those classes, with no drift and two copies, fall below the filing bar;
list them as dropped. Rank dead code by how much it misleads (a dead path that holds the only copy
of a safety check, docs that describe it as live) and by the maintenance it attracts.

## Repair shape

- **Canonical owner:** extend an existing canonical implementation before creating one. Place a
  new one in the lowest component every consumer already depends on.
- **Mechanics vs. policy:** separate what every copy does identically (forwarding, lifecycle,
  encoding, error mapping) from what each caller decides. Shared mechanics with per-caller policy
  consolidate as one owner with explicit hooks or overrides; differing policy alone does not make
  the mechanics distinct. If the *mechanics* need more than one or two per-caller switches, they
  are different implementations: file the drift, not a merge.
- **Behavior:** name the callers whose behavior changes. Require a parity test over representative
  inputs, written against the existing copies before migration.
- **Recurrence guard:** where a raw call must happen only inside the owner, propose a lint
  restriction (for example, a banned-API rule) or a spec chokepoint entry.
- **Grouping:** one issue per independently reviewable PR. A new primitive with many consumer
  migrations gets an issue for the primitive and one per risky consumer migration; mechanical
  migrations can share an issue.

## Filing

Unless `drafts-only`:

- **Dedup** against open and closed issues. A closed not-planned issue is a decision; refile only
  with new evidence.
- **Body:** use [filing.md](references/filing.md). Use the profile's labels; mark issues that need a
  behavior choice as needing a decision.
- **Security:** report suspected security defects to the operator before filing, and keep them out
  of public trackers until the operator chooses a disclosure route.
- **PR lane:** only for repairs with no open decision: dead code with no production consumer after
  the dynamic-consumer check, or migration onto an existing canonical owner with identical behavior
  for all inputs. No persisted, wire, seam, or product change. Follow the repository's delivery
  rules and keep one concern per PR. When a PR changes an object's interface, search tests for
  stand-in doubles of it (namespace objects, fakes, monkeypatched callables); they fail outside a
  focused test run. Everything else is an issue.

## Completion

Report: the coverage ledger, filed issue URLs (or drafts), PRs, dropped candidates with reasons
(intentional, below the filing bar, refuted, duplicate of an existing issue), uncovered cells, and
spend. Defects found along the way that are not redundancy go in a separate incidental-findings
list for normal bug filing. Say `INCOMPLETE` unless every cell in scope was covered.
