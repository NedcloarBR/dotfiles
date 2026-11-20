#!/usr/bin/env bash
#
# Usage: bash Tools/.claude/tests/pre-bash-guard.test.sh

set -uo pipefail

GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/pre-bash-guard.sh"
readonly GUARD
HOME="$(mktemp -d)"
export HOME
mkdir -p "$HOME/.claude"

failures=0

decision() {
  local out
  out=$(jq -n --arg c "$1" '{tool_input: {command: $c}}' | bash "$GUARD")
  printf '%s' "${out:-{\}}" | jq -r '.hookSpecificOutput.permissionDecision // "none"'
}

expect() {
  local want="$1" cmd="$2" got
  got=$(decision "$cmd")
  if [[ "$got" == "$want" ]]; then
    printf 'ok    %-5s %s\n' "$want" "$cmd"
  else
    printf 'FAIL  want=%s got=%s  %s\n' "$want" "$got" "$cmd"
    failures=$((failures + 1))
  fi
}

expect deny 'git push --force origin main'
expect deny 'git push -f origin master'
expect deny 'git commit --no-verify -m "x"'
expect deny 'git commit -nm "x"'
expect deny 'rm -rf ~'
expect deny 'rm -rf /'
expect ask  'cat .env'
expect ask  'cat ".env.local"'
expect ask  'grep -r TOKEN apps/api/.env.production'
expect ask  'ls ~/.ssh'
expect ask  'cat ~/.aws/credentials'

expect none 'git push --force origin feature/x'
expect none 'git push -n origin main'
expect none 'git commit -m "fix: never use --no-verify on main"'
expect none 'git commit -m "chore: load .env in dev"'
expect none 'cat .env.example'
expect none 'rm -rf ./dist'
expect none 'ls -la'

rm -rf "$HOME"
if (( failures > 0 )); then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
