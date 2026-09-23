#!/usr/bin/env bash
# Guards pi-refine's roster and Paseo contract by asserting the skill's text and the
# behaviour of its extracted snippets. It deliberately does NOT import pi-subagents
# internals: discoverAgents/applyThinkingSuffix live at paths that move between
# releases (0.69.0 -> 0.70.1 moved both, and switched .ts sources for compiled .js),
# which broke this test twice for reasons unrelated to the skill it guards.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
skill="$repo_root/plugins/pi-tools/skills/pi-refine/SKILL.md"
agent="$repo_root/agents/plan-reviewer.md"

jq -e '."pi-subagents".agents == ["./agents"]' "$repo_root/package.json" >/dev/null
[ -f "$agent" ]
grep -Fq 'name: plan-reviewer' "$agent"
grep -Fq 'thinking: max' "$agent"

for required in \
  '"runner": "paseo"' \
  'For a general document, use `reviewer`' \
  'For a general document, do not run native-model or Paseo preflight.' \
  'Do not start a Paseo job for this path.' \
  'return a manual general-document review to its caller.' \
  'PASEO_AGENT_ID' \
  'PASEO_AGENT_CWD' \
  'Paseo slot is skipped outside Paseo' \
  'paseo provider models claude --thinking' \
  'require a `claude-opus-5` row that' \
  'lists `high`' \
  'paseo workspace create --isolation local' \
  '--workspace "$workspace_id"' \
  'model: "${route_model}:${route_thinking}"' \
  'paseo run --background --json' \
  '--mode plan' \
  'paseo wait --json --timeout 900' \
  'if [ "$status" != idle ]; then' \
  'PASEO_REVIEW_PAUSED' \
  'pi-refine-roster-index' \
  'flock' \
  'Start with exactly one line: RESULT: clean or RESULT: findings.' \
  "grep -E '^RESULT: (clean|findings)\$'" \
  'marker_count="$(grep -Ec' \
  'if [ "$marker_count" -ne 1 ]; then' \
  'A Paseo review is clean only when it has exactly one `RESULT: clean` marker' \
  'A Pi or manual-general-document review is clean when its output has no substantive finding.' \
  'eight dispatches'; do
  grep -Fq -- "$required" "$skill"
done

log_file="$(mktemp)"
cursor_snippet="$(mktemp)"
paseo_context_snippet="$(mktemp)"
cursor_home="$(mktemp -d)"
trap 'rm -f "$log_file" "$cursor_snippet" "$paseo_context_snippet"; rm -rf "$cursor_home"' EXIT
printf 'Start with exactly one line: RESULT: clean or RESULT: findings.\n' >"$log_file"
! grep -Eq '^RESULT: (clean|findings)$' "$log_file"
printf 'RESULT: findings\n' >>"$log_file"
marker_count="$(grep -Ec '^RESULT: (clean|findings)$' "$log_file" || true)"
test "$marker_count" = 1
result="$(grep -E '^RESULT: (clean|findings)$' "$log_file")"
test "$result" = 'RESULT: findings'
printf 'RESULT: clean\nRESULT: findings\n' >"$log_file"
marker_count="$(grep -Ec '^RESULT: (clean|findings)$' "$log_file" || true)"
test "$marker_count" = 2

awk '
  /^## Paseo Context Gate$/ { section = 1; next }
  section && /^```bash$/ { code = 1; next }
  code && /^```$/ { exit }
  code { print }
' "$skill" >"$paseo_context_snippet"
printf 'printf "%%s\\n" "$inside_paseo"\n' >>"$paseo_context_snippet"
test "$(env -u PASEO_AGENT_ID -u PASEO_AGENT_CWD bash "$paseo_context_snippet")" = false
test "$(PASEO_AGENT_ID=agent PASEO_AGENT_CWD=/repo bash "$paseo_context_snippet")" = true
test "$(PASEO_AGENT_ID=agent env -u PASEO_AGENT_CWD bash "$paseo_context_snippet")" = false
test "$(PASEO_AGENT_CWD=/repo env -u PASEO_AGENT_ID bash "$paseo_context_snippet")" = false

awk '
  /^## Round-Robin Claim$/ { section = 1; next }
  section && /^```bash$/ { code = 1; next }
  code && /^```$/ { exit }
  code { print }
' "$skill" >"$cursor_snippet"
printf 'printf "%%s\\n" "$slot"\n' >>"$cursor_snippet"
cursor_output="$(HOME="$cursor_home" bash "$cursor_snippet")"
test "$cursor_output" = 0
state_file="$cursor_home/.pi/agent/state/pi-refine-roster-index"
test "$(cat "$state_file")" = 1
printf '0\n' >"$state_file"
chmod 400 "$state_file"
if HOME="$cursor_home" bash "$cursor_snippet" >/dev/null 2>"$log_file"; then
  echo 'unwritable cursor state unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'PI_REFINE_ROSTER_PAUSED' "$log_file"
chmod 600 "$state_file"
rm "$state_file"
mkdir "$state_file"
if HOME="$cursor_home" bash "$cursor_snippet" >/dev/null 2>"$log_file"; then
  echo 'directory cursor state unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'PI_REFINE_ROSTER_PAUSED' "$log_file"
rmdir "$state_file"
target_cursor="$cursor_home/target-cursor"
printf '0\n' >"$target_cursor"
ln -s "$target_cursor" "$state_file"
if HOME="$cursor_home" bash "$cursor_snippet" >/dev/null 2>"$log_file"; then
  echo 'symlink cursor state unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'PI_REFINE_ROSTER_PAUSED' "$log_file"

pause_line="$(grep -n -F 'if [ "$status" != idle ]; then' "$skill" | head -n1 | cut -d: -f1)"
logs_line="$(grep -n -F 'paseo logs "$agent_id"' "$skill" | head -n1 | cut -d: -f1)"
test "$pause_line" -lt "$logs_line"
non_idle_block="$(sed -n "${pause_line},$((logs_line - 1))p" "$skill")"
grep -Fq 'PASEO_REVIEW_PAUSED agent=%s workspace=%s status=%s' <<<"$non_idle_block"
grep -Fq 'exit 1' <<<"$non_idle_block"

! grep -Fq 'skip it this cycle' "$skill"
