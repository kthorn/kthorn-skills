# Invoking a reviewer

Use an available, authorized Paseo or host agent mechanism. Instructions to run Claude or Codex are also valid when that route is authorized. Discover capabilities through the current host; do not assume a particular tool schema, role name, runner, or shell interface.

Select a configured route that satisfies the [shared family rule](review-and-refinement.md#reviewer-family). Establish the actual selected model family from trustworthy session/configuration information or operator confirmation; an executable or role name alone is not proof. Preserve configured defaults rather than inventing model identities or changing configuration. If the required family or usable route cannot be established, stop and ask for help.

Honor the host's permissions, sandbox, delegation, workspace ownership, and continuation contracts. A failed governed route is a blocker, not permission to switch silently to CLI or weaken the contract. If the host cannot provide the required read-only review boundary, ask for help.

Provide a concise brief containing:

- The requesting working agent's family and required opposite reviewer family.
- The exact subject/version: document paths, or repository/base/head and intended diff.
- The session-owned workspace, relevant context, questions, and evidence expectations.
- A read-only assignment, scope limits, and stop conditions. A delegated reviewer cannot edit, publish, expand scope, or launch another reviewer.

Consume the actual completed result through the host's supported mechanism. A launch acknowledgement is not a review. Execution failure, unresolved blockers, or missing/stale output means incomplete; report the failure and ask for help rather than substituting same-family review. Keep useful private evidence only as authorized; do not automatically upload raw prompts or reviews.
