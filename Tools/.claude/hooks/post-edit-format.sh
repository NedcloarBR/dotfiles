#!/usr/bin/env bash

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$file" ] || [ ! -f "$file" ] && exit 0

ext="${file##*.}"

case "$ext" in
  js|jsx|ts|tsx|json|css|graphql)
    command -v biome &>/dev/null && biome format --write "$file" 2>/dev/null
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
