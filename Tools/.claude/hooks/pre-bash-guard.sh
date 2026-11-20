#!/usr/bin/env bash

readonly LOG="$HOME/.claude/guard.log"
readonly LOG_MAX_BYTES=1048576

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

block() { decide deny "Blocked: $1"; }
confirm() { decide ask "$1"; }

# Flags are checked outside quoted strings so commit messages can't trigger them
bare=$(printf '%s' "$cmd" | tr '\n' ' ' | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

matches() { printf '%s' "$bare" | grep -qE -- "$1"; }

log_destructive() {
  printf '%s' "$bare" | grep -qE '\brm -rf\b|git reset --hard|git clean -[a-z]*f|git push.*--force|DROP (TABLE|DATABASE)|TRUNCATE' || return 0

  if [[ -f "$LOG" ]] && (( $(stat -c %s "$LOG") > LOG_MAX_BYTES )); then
    tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi
  printf '[%s] %s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$PWD" "$cmd" >> "$LOG"
}

# Read() deny rules don't cover Bash, so secret paths are checked here.
# Quoted text is kept on purpose (`cat ".env"`); git commands are skipped so messages can mention them.
touches_secrets() {
  matches '^\s*git\b' && return 1

  local refs
  refs=$(printf '%s' "$cmd" | grep -oE '(^|[^A-Za-z0-9_.-])\.env(\.[A-Za-z0-9_-]+)?\b' \
    | grep -vE '\.env\.(example|sample|template|dist)$')
  [[ -n "$refs" ]] && return 0

  printf '%s' "$cmd" | grep -qE '\.(ssh|aws|gnupg)(/|\s|$|["'\''])|\.credentials\.json|\.pem\b|\bid_(rsa|ed25519|ecdsa)\b'
}

log_destructive

if matches '\bgit\b.*\bpush\b' && matches '(--force|\s-f)\b' && matches '\b(main|master)\b'; then
  block "force push to main/master"
fi

# `-n` means --no-verify only for commit; for push it is --dry-run
if { matches '\bgit\b.*\b(commit|push|merge|rebase)\b' && matches '--no-verify'; } \
  || matches '\bgit\b.*\bcommit\b[^;&|]*\s-[a-zA-Z]*n[a-zA-Z]*\b'; then
  block "--no-verify is not allowed; fix the hook failure instead"
fi

if matches '\brm\s+-[a-zA-Z]*r[a-zA-Z]*f?[a-zA-Z]*\s+(/|~|\$HOME)/?(\s|$)'; then
  block "recursive rm on / or home directory"
fi

if touches_secrets; then
  confirm "Command references secrets (.env, SSH/AWS/GPG keys or credentials)"
fi

exit 0
