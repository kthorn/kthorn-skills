#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
skill="$repo_root/plugins/pi-tools/skills/pi-refine/SKILL.md"

for required in \
  '"runner": "paseo"' \
  'claude-opus-5' \
  'paseo provider models claude --thinking' \
  'paseo workspace create --isolation local' \
  '--workspace "$workspace_id"' \
  'paseo run --background --json' \
  '--mode plan' \
  'paseo wait --json --timeout 900' \
  'pi-refine-roster-index' \
  'flock' \
  "grep -E '^RESULT: (clean|findings)\$'" \
  'eight dispatches'; do
  grep -Fq -- "$required" "$skill"
done

! grep -Fq 'skip it this cycle' "$skill"
