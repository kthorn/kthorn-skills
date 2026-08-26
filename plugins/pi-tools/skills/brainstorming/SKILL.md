---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Overlay

Read and follow the installed upstream Superpowers brainstorming skill completely:
`$HOME/.pi/agent/git/github.com/obra/superpowers/skills/brainstorming/SKILL.md`.

This overlay changes only the upstream **Architectural** path after its Spec
Self-Review. Do not change its Spike or Bounded paths.

## Automatic Spec Refinement

After the upstream spec self-review, invoke `pi-refine` on the exact
just-written design spec and wait for convergence. If it needs a preference,
architecture, scope, or security decision—or reaches its eight-dispatch cap—
present that issue to the user, apply the answer, and resume the same
refinement pass.

Do not ask for final spec approval or invoke `writing-plans` until refinement has converged.
This workflow does not automatically review implementation plans. If refinement
changes the spec, commit the refined spec before the upstream User Review Gate.

If the upstream skill is unavailable, stop and report that prerequisite rather
than replacing it with a partial local copy.
