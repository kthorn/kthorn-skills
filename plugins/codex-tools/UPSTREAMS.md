# Upstream sources and local choices

These are sources consulted for the owned guidance, not additional instructions to load. Local destinations retain their existing scope and authority boundaries. Superpowers remains the unchanged development-workflow owner; this bundle does not import another lifecycle.

The current reference and refinement text is locally worded guidance about selected techniques, not a copy of an upstream prompt or skill. Source licenses and credits are recorded below for future updates and textual reuse. The repository's MIT license does not replace any license or notice that applies to copied upstream material.

## Unslop Code

Source: [carver/unslop-code](https://github.com/carver/unslop-code/tree/e92762836e6509bbc2b2a1896455e8d6cac5e235), reviewed at `e92762836e6509bbc2b2a1896455e8d6cac5e235`.

Credit: Jason Carver, copyright 2026. Prose and skills are [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/); prompt paths also include MIT material credited to gabeorlanski, copyright 2025. See the source's [license map](https://github.com/carver/unslop-code/blob/e92762836e6509bbc2b2a1896455e8d6cac5e235/REUSE.toml) and [license texts](https://github.com/carver/unslop-code/tree/e92762836e6509bbc2b2a1896455e8d6cac5e235/LICENSES). The anti-slop checklist itself comes from Slop Code Bench, as recorded in the [chunk README](https://github.com/carver/unslop-code/blob/e92762836e6509bbc2b2a1896455e8d6cac5e235/configs/prompts/min13-chunks/README.md).

Prompt fragments below are under [configs/prompts/min13-chunks](https://github.com/carver/unslop-code/tree/e92762836e6509bbc2b2a1896455e8d6cac5e235/configs/prompts/min13-chunks) at that revision.

| Source passage | Local destination and selection | Deliberate departure |
| --- | --- | --- |
| `T-implement-anti-slop.txt` | [Code quality](references/code-quality.md): cohesion, control flow, types, defensive code, wrappers, names and documentation | Review questions rather than blanket bans; retain meaningful variables, boundaries, checks and recovery |
| `D-testing-tests-per-phrase.txt` | Code quality: trace requirements to observable assertions | No one-test-per-sentence rule, required quotation comments, or test quota |
| `F-testing-generator-floor.txt` | Code quality: smallest permitted inputs and meaningful boundaries | Respect the actual input domain; no required generator framework |
| `H-testing-quotable-errors.txt` | Code quality: justify expected rejection | Include safety requirements and confirmed intent; silence does not require either acceptance or rejection |
| `I-testing-phrase-interactions.txt` | Code quality: interactions and changed requirements | Surface consequential conflicts; neither new wording nor old tests automatically wins |
| `R-implement-never-narrow.txt` | Code quality: investigate failing generated examples | Check domain and oracle as well as implementation; narrowing an invalid-domain generator can be correct |
| [`.claude/skills/spec-ambiguity-review/SKILL.md`](https://github.com/carver/unslop-code/blob/e92762836e6509bbc2b2a1896455e8d6cac5e235/.claude/skills/spec-ambiguity-review/SKILL.md) | [Spec refinement](skills/refining-specs/SKILL.md): source wording, alternative outcomes, concrete evidence and minimal clarification | The human designer decides intent; no hidden-test-author guessing, numerical risk scores, fixed judge panels or benchmark reruns |

The combined prompt's environment setup, benchmark markers, never-ask rule, and test-only-stage limits are not imported. Superpowers' TDD and verification procedures are not duplicated.

## Ponytail

Source: [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail/tree/e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156), version `4.10.0`, reviewed at `e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156`. Inspected `skills/ponytail/SKILL.md`, `skills/ponytail-review/SKILL.md`, `skills/ponytail-audit/SKILL.md`, and Pi instruction injection.

Credit/license: copyright 2026 DietrichGebert, [MIT](https://github.com/DietrichGebert/ponytail/blob/e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156/LICENSE).

Reuse, standard-library/native alternatives, and justified deletion are already owned by [reviewing-complexity](skills/reviewing-complexity/SKILL.md); no second reuse ladder is added. The code-quality reference preserves meaningful wrappers and safety checks rather than optimizing line counts. Persistent persona, code-first output, reduced testing prescriptions, separate review/audit entrypoints, and savings scoreboards are not imported.

## Pi Simplify

Source: published `pi-mono-simplify@1.7.3`, specifically `index.ts`, `README.md`, and `LICENCE.md`. [Repository navigation](https://github.com/emanuelcasco/pi-mono-extensions/tree/main/extensions/simplify) is not a pin; the reviewed npm version identifies the source inspected.

Credit/license: copyright 2026 Emanuel Casco, MIT; retain the published `LICENCE.md` notice when reusing source text.

The reuse, quality, and efficiency review lists were inspected for overlap. Existing owned review/complexity guidance covers reuse; the supplementary code-quality reference covers selected maintainability concerns. The fixed three-agent workflow, automatic edits, and additional efficiency checklist are not imported. This record does not install or remove `/simplify`.

## Existing owned redundancy audit

The [auditing-redundancy](skills/auditing-redundancy/SKILL.md) skill and its lenses/filing references were inspected at owned repository commit `b69bf45372f65645a73076b6555d8872a51828cb`; this is an internal source, not a new external dependency. Its policy ownership, mechanics-versus-policy, drift/parity, and consumer/retirement ideas inform targeted questions in spec refinement. Its sweep, coverage ledger, workers, verification, filing, and PR workflow remain separate and unchanged.

## Updating these selections

Compare the relevant upstream files against the recorded revision/version. Adopt only changes that serve the owned scope, preserve intentional departures, and validate any changed guidance using the existing authoring and package checks. Update this record with the inspected revision and affected local destinations. Do not automatically overwrite local text or activate upstream packages.

When copying or adapting upstream text, preserve applicable attribution and license notices, link the source and license, and identify local modifications. Do not assume the license of source code also covers prose or prompts; use the source's file-level license information.
