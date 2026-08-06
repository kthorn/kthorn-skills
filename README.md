# kthorn-skills

A collection of skills for [pi coding agent](https://github.com/mariozechner/pi-coding-agent) and Claude Code, organized as a marketplace with multiple plugins.

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

AI-powered code and document review tools using OpenAI Codex CLI.

**Skills included:**

- `codex-review` - Dispatch Codex CLI for independent review of plans, PRs, and code changes
- `codex-refine` - Iteratively refine documents through repeated Codex reviews until convergence

### pi-tools

AI-powered code and document review tools using pi-subagents.

**Skills included:**

- `pi-review` - One-off code/design review via the `reviewer` builtin subagent
- `pi-refine` - Iteratively refine documents through repeated `reviewer` subagent reviews until convergence

### wslopen-tools

Safe WSL-to-Windows directory/file links plus one shared link-authoring skill. See [its README](plugins/wslopen-tools/README.md) for the explicit Windows-side handler installation.

**Skills included:**

- `using-wslopen` - Emit configured `wslopen://` Markdown links for supported WSL paths

## Installation

### Pi skills

```bash
pi install git:github.com/kthorn/kthorn-skills
```

This installs `pi-review`, `pi-refine`, and `using-wslopen`. `pi-review` and `pi-refine` require [pi-subagents](https://github.com/mariozechner/pi-subagents); `using-wslopen` also needs the Windows handler described in its [plugin README](plugins/wslopen-tools/README.md).

### Claude Code marketplace (all plugins)

```bash
claude mcp add-skill-marketplace https://github.com/kthorn/kthorn-skills
```

### Install individual plugins (Claude Code)

```bash
# Research superpowers only
claude plugin add https://github.com/kthorn/kthorn-skills/plugins/research-superpowers

# Codex tools only
claude plugin add https://github.com/kthorn/kthorn-skills/plugins/codex-tools

# Wslopen tools only
claude plugin add https://github.com/kthorn/kthorn-skills/plugins/wslopen-tools
```

### Manual installation

Clone the repo and add the plugin directories to your configuration:

```bash
git clone https://github.com/kthorn/kthorn-skills.git
```

## Prerequisites

### Research Superpowers

- PubMed MCP server (for literature search)
- Semantic Scholar API (free, for citation traversal)
- Unpaywall API (free, for open access discovery)
- ChEMBL API (free, optional)

### Codex Tools

- [OpenAI Codex CLI](https://github.com/openai/codex) installed and configured
- OpenAI API key

### Pi Tools

- [pi-subagents](https://github.com/mariozechner/pi-subagents) installed and configured
- Compatible pi coding agent with subagent support

### Wslopen Tools

- Windows with WSL and an explicit configured `/home/<user>` root
- The per-user handler installed from [plugins/wslopen-tools](plugins/wslopen-tools/README.md)

## License

MIT
