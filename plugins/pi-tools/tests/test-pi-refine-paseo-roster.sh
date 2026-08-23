#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
skill="$repo_root/plugins/pi-tools/skills/pi-refine/SKILL.md"

for required in \
  '"runner": "paseo"' \
  'paseo provider models claude --thinking' \
  'require a `claude-opus-5` row that' \
  'lists `high`' \
  'paseo workspace create --isolation local' \
  '--workspace "$workspace_id"' \
  'paseo run --background --json' \
  '--mode plan' \
  'paseo wait --json --timeout 900' \
  'if [ "$status" != idle ]; then' \
  'PASEO_REVIEW_PAUSED' \
  'pi-refine-roster-index' \
  'flock' \
  'Start with exactly one line: RESULT: clean or RESULT: findings.' \
  "grep -E '^RESULT: (clean|findings)\$'" \
  'eight dispatches'; do
  grep -Fq -- "$required" "$skill"
done

log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT
printf 'Start with exactly one line: RESULT: clean or RESULT: findings.\n' >"$log_file"
! grep -Eq '^RESULT: (clean|findings)$' "$log_file"
printf 'RESULT: findings\n' >>"$log_file"
result="$(grep -E '^RESULT: (clean|findings)$' "$log_file" | tail -n1)"
test "$result" = 'RESULT: findings'

pause_line="$(grep -n -F 'if [ "$status" != idle ]; then' "$skill" | head -n1 | cut -d: -f1)"
logs_line="$(grep -n -F 'paseo logs "$agent_id"' "$skill" | head -n1 | cut -d: -f1)"
test "$pause_line" -lt "$logs_line"
non_idle_block="$(sed -n "${pause_line},$((logs_line - 1))p" "$skill")"
grep -Fq 'PASEO_REVIEW_PAUSED agent=%s workspace=%s status=%s' <<<"$non_idle_block"
grep -Fq 'exit 1' <<<"$non_idle_block"

! grep -Fq 'skip it this cycle' "$skill"
