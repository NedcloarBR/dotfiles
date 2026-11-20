#!/usr/bin/env bash

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$file" ] || [ ! -f "$file" ] && exit 0

ext="${file##*.}"

# Unfixable diagnostics go back to Claude so it can fix them in the same turn
report() {
  jq -n --arg c "$1 reported issues in $file:"$'\n'"$2" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}'
  exit 0
}

find_biome() {
  local dir
  dir=$(cd "$(dirname "$file")" && pwd)
  while [ "$dir" != "/" ]; do
    [ -x "$dir/node_modules/.bin/biome" ] && echo "$dir/node_modules/.bin/biome" && return
    dir=$(dirname "$dir")
  done
  command -v biome
}

case "$ext" in
  js|jsx|mjs|cjs|ts|tsx|mts|cts|json|jsonc|css|graphql)
    biome=$(find_biome) || exit 0
    out=$("$biome" check --write --no-errors-on-unmatched --colors=off --max-diagnostics=20 "$file" 2>&1) || report "Biome" "$out"
    ;;
  py)
    command -v ruff  &>/dev/null && ruff format -q "$file" 2>/dev/null && exit 0
    command -v black &>/dev/null && black -q "$file" 2>/dev/null
    ;;
  go)
    command -v gofmt &>/dev/null && gofmt -w "$file" 2>/dev/null
    ;;
  rs)
    command -v rustfmt &>/dev/null && rustfmt "$file" 2>/dev/null
    ;;
  php)
    dir=$(dirname "$file")
    if [ -f "$dir/vendor/bin/pint" ]; then
      "$dir/vendor/bin/pint" "$file" 2>/dev/null
    elif [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/vendor/bin/pint" ]; then
      "$(git rev-parse --show-toplevel)/vendor/bin/pint" "$file" 2>/dev/null
    else
      command -v pint &>/dev/null && pint "$file" 2>/dev/null
    fi
    ;;
esac

exit 0
