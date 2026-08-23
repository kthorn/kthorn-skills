#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
overlay="$repo_root/plugins/pi-tools/skills/brainstorming/SKILL.md"
upstream_package="${SUPERPOWERS_PACKAGE_DIR:-$HOME/.pi/agent/git/github.com/obra/superpowers}"

[ -f "$overlay" ]
grep -Fq 'name: brainstorming' "$overlay"
grep -Fq '$HOME/.pi/agent/git/github.com/obra/superpowers/skills/brainstorming/SKILL.md' "$overlay"
grep -Fq 'pi-refine' "$overlay"
grep -Fq 'Do not ask for final spec approval or invoke `writing-plans` until refinement has converged.' "$overlay"

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
# --no-skills excludes ambient skills; explicit -e package resources still load.
output="$(cd "$sandbox" && pi --no-session --no-context-files --no-skills \
  -e "$repo_root" \
  -e "$upstream_package" \
  -p 'Use the brainstorming skill. An architectural design spec just passed its self-review. Answer exactly: Automatic refinement before final approval: <yes or no>. Next step: <short name>.')"
printf '%s\n' "$output"
grep -Eqi 'Automatic refinement before final approval: *yes' <<<"$output"
grep -Eqi 'pi-refine' <<<"$output"
