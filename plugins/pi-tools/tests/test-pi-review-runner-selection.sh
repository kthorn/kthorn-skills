#!/usr/bin/env bash
# Guards pi-review's runner facts and cross-source model-roster consistency.
#
# pi-review previously told the reader that `reviewer` "has access to `bash` ...
# so it can run `git diff` itself" and "can Edit code directly when appropriate".
# Neither is true: reviewer's tools are read, grep, find, ls, contact_supervisor.
# Following that guidance produced a thirty-minute review that timed out with no
# verdict, because the agent could not run git and read whole files instead.
#
# pi-refine separately advertised `opencode-go/grok-4.5`, which is not in the
# model registry (only grok-4.6), while settings.json and AGENTS.md both said
# grok-4.6 -- so its own roster could not dispatch.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
skill="$repo_root/plugins/pi-tools/skills/pi-review/SKILL.md"
refine_skill="$repo_root/plugins/pi-tools/skills/pi-refine/SKILL.md"

[ -f "$skill" ]
grep -Fq 'name: pi-review' "$skill"

for required in \
  'openai-codex/gpt-5.6-terra' \
  'contact_supervisor' \
  'cannot run commands and it cannot edit code' \
  'plan-reviewer' \
  'reads' \
  'PASEO_AGENT_ID' \
  'PASEO_AGENT_CWD' \
  'Reuse or create a workspace by path, never `--cwd`' \
  '`paseo wait` returns on transient idle' \
  'status" != idle' \
  'PASEO_REVIEW_PAUSED' \
  "grep -Ec '^RESULT: (clean|findings)\$'" \
  'timeoutMs' \
  '30 minutes' \
  'subagent-artifacts' \
  'message.content[*].thinking'; do
  grep -Fq -- "$required" "$skill" || {
    printf 'pi-review is missing required text: %s\n' "$required" >&2
    exit 1
  }
done

# The false capability claims must not come back.
for forbidden in \
  'has access to `bash`' \
  'Edit code directly when appropriate' \
  'openai-codex/gpt-5.5'; do
  if grep -Fq -- "$forbidden" "$skill"; then
    printf 'pi-review still claims: %s\n' "$forbidden" >&2
    exit 1
  fi
done

# Cross-source roster consistency: every grok model named in the guidance must
# match the live roster and the master guidance. Each source is optional so the
# test still runs on a machine without them, but any source that exists must agree.
settings="${PI_SETTINGS_FILE:-$HOME/.pi/agent/settings.json}"
agents_md="${PI_AGENTS_MD:-$HOME/.pi/agent/AGENTS.md}"

expected_grok="$(grep -oE 'opencode-go/grok-[0-9]+\.[0-9]+' "$settings" 2>/dev/null | sort -u | head -1 || true)"

if [ -n "$expected_grok" ]; then
  for other in "$refine_skill" "$agents_md"; do
    [ -f "$other" ] || continue
    found="$(grep -oE 'opencode-go/grok-[0-9]+\.[0-9]+' "$other" | sort -u | tr '\n' ' ')"
    for model in $found; do
      if [ "$model" != "$expected_grok" ]; then
        printf 'roster drift: %s names %s but settings.json says %s\n' \
          "$(basename "$other")" "$model" "$expected_grok" >&2
        exit 1
      fi
    done
  done

  # The advertised model must exist in the registry, when one is reachable.
  if command -v paseo >/dev/null 2>&1; then
    if ! paseo provider models pi 2>/dev/null | grep -Fq -- "$expected_grok"; then
      printf 'roster drift: %s is not in the Pi model registry\n' "$expected_grok" >&2
      exit 1
    fi
  fi
fi

printf 'pi-review runner facts ok; grok roster = %s\n' "${expected_grok:-unchecked}"
