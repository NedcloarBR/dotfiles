#!/usr/bin/env bash
#
# Rewrites Bash commands to their `rtk` equivalent so Claude reads compressed output.
# No-op when rtk isn't installed, so the config stays portable across machines.
# rtk answers "allow", which would skip permission prompts and the `ask` rules;
# only the rewrite is kept so the normal permission flow judges the new command.

rtk=$(command -v rtk || echo "$HOME/.local/bin/rtk")
[[ -x "$rtk" ]] || exit 0

out=$("$rtk" hook claude 2>/dev/null) || exit 0
[[ -n "$out" ]] || exit 0

printf '%s' "$out" | jq -c '
  .hookSpecificOutput |= del(.permissionDecision, .permissionDecisionReason)
' 2>/dev/null
exit 0
