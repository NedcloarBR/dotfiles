#!/usr/bin/env bash
#
# Prints the handoff file path for a directory (default: $PWD).
# Handoffs live in ~/.claude/handoffs, never inside the repo, so they can't be committed.

dir="${1:-$PWD}"
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")
slug=$(printf '%s' "${root#"$HOME"/}" | tr '/' '-' | tr -c 'A-Za-z0-9._-' '-')

echo "$HOME/.claude/handoffs/$slug.md"
