#!/usr/bin/env bash
#
# SessionStart: injects the project's handoff so a fresh or compacted session resumes the task.
# On plain startup, handoffs older than MAX_AGE_DAYS are ignored as stale.

readonly MAX_AGE_DAYS=3

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
source=$(printf '%s' "$input" | jq -r '.source // "startup"' 2>/dev/null)

file=$(bash "$(dirname "${BASH_SOURCE[0]}")/handoff-path.sh" "${cwd:-$PWD}")
[[ -f "$file" ]] || exit 0

if [[ "$source" == "startup" ]]; then
  age_days=$(( ($(date +%s) - $(stat -c %Y "$file")) / 86400 ))
  (( age_days > MAX_AGE_DAYS )) && exit 0
fi

jq -n --arg c "Handoff from a previous session ($file). Resume from it; run /handoff done when the task is finished."$'\n\n'"$(cat "$file")" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
