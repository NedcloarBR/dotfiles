#!/usr/bin/env bash

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Block: force push to main/master
if echo "$cmd" | grep -qE 'git push' \
  && echo "$cmd" | grep -qE '(--force|-f)\b' \
  && echo "$cmd" | grep -qE '\b(main|master)\b'; then
  echo "Blocked: force push to main/master" >&2
  exit 2
fi

# Log destructive patterns
if echo "$cmd" | grep -qE '\brm -rf\b|git reset --hard|git clean -fd?|DROP TABLE|TRUNCATE'; then
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$cmd" >> ~/.claude/guard.log
fi

exit 0
