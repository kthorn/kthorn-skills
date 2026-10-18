#!/usr/bin/env bash
# Session start hook for Research Superpowers
# This hook is loaded at the start of each Claude Code session

# Get the project root (parent of hooks/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Display welcome message
cat <<EOF

🔬 Research Superpowers Loaded

Available research skills:
- answering-research-questions - Main workflow for research queries
- searching-literature - PubMed search integration
- evaluating-paper-relevance - Abstract screening + data extraction
- traversing-citations - Citation network traversal

Find skills: $PROJECT_ROOT/scripts/find-skills [pattern]
Get started: Read $PROJECT_ROOT/skills/getting-started/SKILL.md

EOF
