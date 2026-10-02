# kthorn-skills

A collection of portable skills for Pi, Claude Code, and Codex, organized as a marketplace with optional plugins.

## Plugins

### research-superpowers

Systematic literature searching and review toolkit. Search PubMed, screen papers, extract data, traverse citations, and synthesize findings from scientific literature.

**Skills included:**

- `getting-started` - Introduction and setup guide
- `answering-research-questions` - Main workflow for research queries
- `searching-literature` - PubMed search integration
- `building-screening-rubrics` - Create relevance scoring criteria
- `evaluating-paper-relevance` - Abstract screening and data extraction
- `traversing-citations` - Citation network traversal
- `checking-chembl` - ChEMBL database lookups
- `finding-open-access-papers` - Unpaywall integration for open access
- `subagent-driven-review` - Parallel large-scale paper review
- `cleaning-up-research-sessions` - Session management and cleanup

### codex-tools

The single owner of generic review/refinement procedure. The existing plugin identity is retained to avoid an installation rename; it now supports optional Codex and configured Pi transports.

**Skills included:**

- `codex-review` / `codex-refine` - Operator-selected Codex review/document refinement
- `pi-review` / `pi-refine` - Review/document refinement with configured Pi roles
- `refining-specs` - Risk-triggered, transport-neutral specification refinement
- `reviewing-complexity` - Explicitly requested, read-only complexity review

The thin entrypoints load [one shared procedure](plugins/codex-tools/references/review-and-refinement.md). Review-only and authorized edits remain distinct. No model roster, mandatory delegated writer, automatic refinement overlay, or cross-plugin reference is required.

### wslopen-tools

Safe WSL-to-Windows directory/file links plus one shared link-authoring skill. See [its README](plugins/wslopen-tools/README.md) for the explicit Windows-side handler installation.

**Skills included:**

- `using-wslopen` - Emit configured `wslopen://` Markdown links for supported WSL paths

## Installation

### Pi

```bash
pi install git:github.com/kthorn/kthorn-skills
```

The package selects the six review/refinement skills and `using-wslopen`; research is not selected by the Pi manifest. Pi transport requires an installed, configured pi-subagents package. Codex transport requires an installed, authenticated Codex CLI only when chosen. WSL handler installation remains separate and explicit.

For development, select the full `plugins/codex-tools/skills` source directory in Pi's `skills` configuration. Do not copy an isolated entrypoint: its package-local references must remain available.

### Claude Code

```bash
claude plugin marketplace add kthorn/kthorn-skills
claude plugin install codex-tools@kthorn-skills
```

Install `research-superpowers@kthorn-skills` or `wslopen-tools@kthorn-skills` separately only when wanted. Local testing can use `claude --plugin-dir /absolute/path/to/plugins/codex-tools`; do not register or install unrelated plugins just to review this package. `claude plugin validate` is a static check, not an efficacy test.

### Codex

Clone the repository and link the **entire review plugin**, retaining its nested skills and references:

```bash
git clone https://github.com/kthorn/kthorn-skills.git
mkdir -p ~/.agents/skills
ln -s "$(realpath kthorn-skills/plugins/codex-tools)" ~/.agents/skills/codex-tools
```

Do not overwrite an existing destination. Current native Codex discovery advertises these bundled skills as `codex-tools:<skill-name>` (for example, `codex-tools:refining-specs`). Confirm the names/source paths through the installed discovery interface, then start a fresh session. Pi-specific entrypoints require Pi tools; their presence does not authorize a different execution route. Shared source files remain the maintained owner rather than copied per-harness variants.

## Version 2 migration

- `pi-review` and `pi-refine` now live in `codex-tools`; remove explicit paths to the retired `plugins/pi-tools` directory and select the replacement before deleting local variants.
- No `brainstorming` overlay is supplied. Upstream Superpowers remains independently installed and unmodified; no ordering trick is needed to shadow it.
- Packaged `plan-reviewer` and model-rotation/cursor configuration are retired. Use configured native roles and capability discovery.
- Move duplicate generic skills to a private rollback backup only after replacement paths resolve. Preserve unrelated settings and private domain skill selections.
- Hosted Claude plugin users need the changed plugin version/update and a restart/reload; merging a commit alone does not prove a cached installation changed.

## Checks and boundaries

With Pi installed, run the native package check against its `dist/core/skills.js` module:

```bash
node plugins/codex-tools/tests/check-package.mjs /path/to/pi-coding-agent/dist/core/skills.js
claude plugin validate .
```

It checks resource precedence and copied/symlinked reference loading, including an intentionally broken bundle. It does not execute models, install handlers, prove agent adherence, or measure review quality. Operator/repository scope and authority remain controlling.

## Prerequisites

Research prerequisites remain PubMed MCP, Semantic Scholar, Unpaywall, and optional ChEMBL access. Review prerequisites depend on the selected transport, not a hardcoded model or authentication method. WSL prerequisites and handler setup are documented in its plugin README.

## License

MIT
