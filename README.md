# kthorn-skills

A collection of Claude Code skills organized as a marketplace with multiple plugins.

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

## Installation

### From the marketplace (recommended)

```bash
claude mcp add-skill-marketplace https://github.com/kthorn/kthorn-skills
```

### Install individual plugins

```bash
# Research superpowers only
claude plugin add https://github.com/kthorn/kthorn-skills/plugins/research-superpowers

# Codex tools only
claude plugin add https://github.com/kthorn/kthorn-skills/plugins/codex-tools
```

### Manual installation

Clone the repo and add the plugin directories to your Claude Code configuration:

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

## License

MIT
