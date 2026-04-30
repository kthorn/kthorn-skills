---
name: pi-refine
description: Use when iteratively refining a design doc, plan, or specification through repeated pi reviews until quality converges
---

# Pi Refine

Iteratively refine a document through repeated `reviewer` subagent reviews until it converges on quality.

**Core principle:** Review → filter → fix → re-review → repeat until clean.

## Which Reviewer to Use

| Document type                                         | Agent           | Why                                                                                                                                      |
| ----------------------------------------------------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Implementation plans, design docs, architecture specs | `plan-reviewer` | Cross-references every claim against the actual codebase — checks file existence, function signatures, architecture alignment, data flow |
| Prose documents, process docs, general specs          | `reviewer`      | General document review without codebase dependency                                                                                      |

## Model Roster

Pi-refine cycles through a roster of reviewer models so each iteration gets a fresh perspective. Different models catch different issues — one may spot architectural gaps another overlooks, while another may catch logic errors the first missed.

**Default roster** (used unless overridden):

| Order | Model ID                      | Strengths                                                                   |
| ----- | ----------------------------- | --------------------------------------------------------------------------- |
| 1     | `opencode-go/deepseek-v4-pro` | Broad codebase reasoning, catches missing edge cases and architectural gaps |
| 2     | `opencode-go/qwen3.6-plus`    | Strong at logic errors, contradictions, and ordering problems               |
| 3     | `opencode-go/kimi-k2.6`       | Detail-oriented, catches API/interface mismatches and dependency gaps       |

On each iteration, the skill picks the next model in the roster: iteration 1 uses #1, iteration 2 uses #2, etc. When the roster is exhausted, it wraps back to the start.

**Overriding the roster** — To use different models, set a `piRefine.modelRoster` array in `.pi/settings.json`:

```json
{
  "piRefine": {
    "modelRoster": [
      "opencode-go/deepseek-v4-pro",
      "opencode-go/qwen3.6-plus",
      "anthropic/claude-sonnet-4-6"
    ]
  }
}
```

If no roster is configured, the default above is used. 2-4 models is recommended; more than 4 usually brings diminishing returns.

## When to Use

- When you want a design doc or plan polished through iterative external review
- After drafting a doc and before implementing it
- When a doc needs thorough vetting but you want the process automated

## Invocation

The user may say things like "refine this doc with pi", "iterate on this plan", etc.

## The Iteration Loop

For each iteration (max 2× the roster size; 6 with the default 3-model roster):

### Step 1: Dispatch Reviewer Subagent

Send the document to the reviewer agent with fresh context and capture output. Each iteration uses a different model from the roster, cycling through for diverse perspectives.

Read the model roster from `.pi/settings.json` if available, otherwise use the default:

```typescript
const modelRoster = settings.piRefine?.modelRoster || [
  "opencode-go/deepseek-v4-pro",
  "opencode-go/qwen3.6-plus",
  "opencode-go/kimi-k2.6",
];
const model = modelRoster[iteration % modelRoster.length];
```

**For implementation plans / design docs (use `plan-reviewer`):**

```typescript
subagent({
  agent: "plan-reviewer",
  model: model,
  task: `Review this implementation plan against the actual codebase.

Cross-reference every file, module, function, API, and config reference in the plan
against the codebase. Verify claims by inspecting actual code.

Check:
1. File/module references — do they exist? Are they the right places?
2. Architecture alignment — does the plan follow existing patterns?
3. API/interface compatibility — do function signatures, class constructors match?
4. Dependency gaps — missing imports, unavailable services, wrong config keys?
5. Data flow consistency — does the plan's data pipeline match actual schemas?
6. Feasibility — any hard blockers?
7. Missing edge cases — what does existing error handling reveal?
8. Test coverage gaps — would this break existing tests?`,
  reads: [filePath],
  output: `/tmp/pi-refine-iter-${iteration}.md`,
});
```

**For general documents (use `reviewer`):**

```typescript
subagent({
  agent: "reviewer",
  model: model,
  task: `Below is the full text of a document to review. Review ONLY this text.

Identify:
1. Gaps, missing steps, or incorrect assumptions
2. Logic errors, contradictions, or ordering problems
3. Security, privacy, or authorization concerns
4. Unclear or ambiguous sections

Reference section/task/step numbers from the document. Organize by severity: critical, important, minor.`,
  reads: [filePath],
  output: `/tmp/pi-refine-iter-${iteration}.md`,
});
```

Then read `/tmp/pi-refine-iter-${iteration}.md`. Record which model produced this review for the summary report.

### Step 2: Triage Findings

Categorize each finding into one of:

**Fix** — Implement the change:

- Genuine gaps, missing steps, or incorrect information
- Logic errors, contradictions, or broken ordering
- **Security concerns**: authentication, authorization, input validation, injection risks, secret handling
- **Privacy concerns**: data exposure, logging PII, missing access controls, data retention issues
- **Authorization concerns**: missing permission checks, privilege escalation paths, role boundary violations
- Unclear sections that would confuse readers

**Ignore** — Skip silently (do not ask the user):

- **Hallucinations**: References to files, APIs, libraries, or features that don't exist in the project. **Note:** `plan-reviewer` findings are codebase-verified by construction — if it cites a specific file and line number, the reference is real. Still filter out claims that misidentify the purpose of a file or misrepresent what code does.
- **Trivial nits**: Formatting preferences, naming bikeshedding, stylistic opinions
- **Scale-only concerns**: Rate limiting, sharding, horizontal scaling, load balancing, caching layers, distributed locking, high-availability patterns — anything only relevant at multi-user/SaaS scale. This is an internal product with a handful of users.
- **Over-engineering**: Suggestions to add abstraction layers, plugin architectures, feature flags, or other complexity not justified by the current user base
- **Redundant with prior iterations**: Issues already addressed in a previous iteration that the reviewer is re-raising

**Ask the user** — When a finding is borderline:

- It might be valid but you're not sure if it applies to this project
- It's a design tradeoff where user preference matters
- It suggests a significant architectural change that may or may not be wanted
- Security/privacy concern that seems theoretical rather than practical for an internal tool

Use `AskUserQuestion` for borderline items. Present the finding and your assessment, and let the user decide fix or ignore.

### Step 3: Implement Fixes

Apply all "Fix" changes to the document using Edit/Write tools. Make targeted, minimal edits — don't rewrite sections that aren't flagged.

### Step 4: Check Convergence

Converge when there are no more important findings to address. Reviewers will always find _something_ to say — the question is whether those findings matter for implementation. Exit the loop if **any** of these hold:

1. **No fixes applied this iteration** — all findings were ignored or trivial.
2. **All findings are unsubstantial** — every finding this iteration falls into:
   - Wording, phrasing, or semantic tweaks ("consider rephrasing X as Y")
   - Bikeshedding (naming preferences, formatting opinions, style nits)
   - Clarifications that wouldn't change what a reader builds
   - Language polish, tone adjustments, or "would be nice" documentation additions

   If there's even one substantive finding mixed in with the noise (a real gap, logic error, missing step, security/privacy/auth concern), the iteration is not converged — fix the substance and keep going. A mix of substance and unsubstantial is not convergence.

   **Acid test:** "Would a reader acting on the current spec build the wrong thing, or just write prose a reviewer might phrase differently?" If every finding falls in the latter bucket, converge. If you're genuinely unsure whether a finding matters, err on the side of fixing it or asking the user — don't dismiss it to force convergence.

3. **Diminishing returns** — findings are minor variations on themes already addressed (same class of nit, different phrasing), even if technically new. Reviewers rephrasing the same concern in different words is not new substance. But if a finding is genuinely new even if small (e.g., a missing edge case no prior reviewer caught), it counts as substance.

4. **Full roster pass with no new substance** — every model in the roster has reviewed the current version of the document and none produced a substantive new finding (implementation gap, logic error, missing step, security/privacy/auth concern). Language-only findings from a model seeing the doc for the first time don't prevent convergence under this rule, but any substantive finding from any model resets the clock.

**Multi-model convergence rule:** With a cycling roster, each new model will find _something_ on its first pass — that's expected and normal. Track which models have reviewed the current doc state; reset the "seen" set whenever substantive fixes are applied. After the full roster has seen the current version: if the remaining findings across all models are exclusively bikeshedding, semantics, or polish, converge. If any model found something substantive, fix it and give the roster another pass — different models catch different things, and the next model in the cycle may find additional substance the current one missed.

When converging under #2, #3, or #4, you may still apply one or two high-value findings before exiting (e.g., removing a leaked identifier, noting a version requirement) — the criterion is about _stopping the loop_, not _rejecting every remaining suggestion_. But don't apply the whole set of clarifications; that's the trap this rule exists to break.

Otherwise, increment iteration counter and go back to Step 1.

### Step 5: Update Plan Status

If the document has a YAML-style header or metadata section, add or update a `Status: Refined` line in it. If the document has no clear header/metadata area, add a status line near the top of the document after the title:

```
**Status:** Refined
```

### Step 6: Report Summary

After the loop ends (converged or hit iteration cap), report a comprehensive summary to the user covering everything that was found and what was done about it:

```
## Refinement Summary

**Iterations:** N
**Converged:** yes/no

### All Findings and Actions

For each iteration, list every finding with its disposition:

**Iteration 1 (model: <model name>):**
- [FIXED] <finding description> → <what was changed>
- [FIXED] <finding description> → <what was changed>
- [IGNORED: hallucination] <finding description>
- [IGNORED: scale-only] <finding description>
- [ASKED USER → fixed/ignored] <finding description> → <outcome>

**Iteration 2 (model: <model name>):**
- [FIXED] <finding description> → <what was changed>
- [IGNORED: nit] <finding description>
...

### Summary of Changes Made
- Bullet list of all substantive changes across all iterations

### Ignored (noise):
- [brief list of ignored items grouped by category with counts]

### Remaining (if hit cap):
- [any unresolved items from the final review]
```

## Important Notes

- Use a distinct output file per iteration (`/tmp/pi-refine-iter-1.md`, `-iter-2.md`, etc.) so you can reference earlier reviews.
- If the reviewer raises the same issue across iterations after you've already fixed it, it may be hallucinating the problem. Ignore on the second occurrence.
- **`plan-reviewer` output is codebase-grounded.** When it cites a specific file and line, that reference was verified against actual code. Give plan-reviewer findings higher weight than generic reviewer findings — treat them as close to ground truth rather than speculative suggestions.
- If `plan-reviewer` doesn't exist in the project (e.g., working on a different codebase), create it first: write a `.pi/agents/plan-reviewer.md` file following the template at [the plan-reviewer agent definition].
- **Convergence posture: filter noise, fix substance.** Reviewers will always find _something_ to say — that's what they're designed to do. Your job is to distinguish between findings that would cause someone to build the wrong thing and findings that are just a reviewer being thorough. Converge when no important findings remain — not because you're tired of iterating. The acid test for every finding: "Would someone following this spec build the wrong thing?" If no, it's noise; if yes or you're unsure, fix it.
- The iteration cap (2× roster size) is a safety net. Most docs should converge in 2-4 iterations even with model cycling. If the full roster has seen the current version and is producing only language polish, converge immediately — do not wait for the cap.
- **Model cycling purpose:** Each model brings different blind spots. DeepSeek V4 Pro excels at broad architecture reasoning; Qwen3.6 Plus catches logic and ordering issues; Kimi K2.6 spots API/interface mismatches. Cycling through them catches more issues than re-running the same model. But once all models have seen your doc and found nothing substantive, you're done — additional cycles are waste.
- If a model in the roster is unavailable (rate-limited, down), skip it this cycle and try it on the next wrap-around rather than blocking.
- This skill is for document refinement. For one-off code or document review, use `pi-review` directly.
- **Security/privacy/auth findings are always worth fixing** — even for internal tools, these protect against insider threats and accidental data exposure.
- **Scalability/SaaS patterns are noise** — don't add complexity for hypothetical growth. Internal tools with a handful of users don't need production-grade infrastructure patterns.
