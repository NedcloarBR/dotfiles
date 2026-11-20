#!/usr/bin/env bash
#
# Links this directory's Claude Code config into ~/.claude.
# Run as your user (no sudo) from a persistent clone of the dotfiles repo:
#   bash Tools/.claude/install.sh
#
# Existing files are moved to ~/.claude/backups/dotfiles-<timestamp>/.
# ~/.claude/machine.md is created from machine.example.md if missing and never overwritten.
# rtk (https://github.com/rtk-ai/rtk) is installed to ~/.local/bin if missing; skip with --no-rtk.

set -euo pipefail

readonly SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEST="$HOME/.claude"
readonly BACKUP="$DEST/backups/dotfiles-$(date +%Y%m%d-%H%M%S)"

readonly RTK_INSTALLER="https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh"

readonly LINKS=(
  "CLAUDE.md"
  "settings.json"
  "statusline-command.sh"
  "hooks"
)

# Linked one by one: ~/.claude/skills also holds skills synced from claude.ai
readonly SKILLS_DIR="skills"

# Replaced by skills/commit; a leftover command would shadow nothing but confuse /help
readonly LEGACY=(
  "commands/commit.md"
)

link() {
  local name="$1" src="$SRC/$1" dest="$DEST/$1"

  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$src" ]]; then
    echo "ok       $name"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$BACKUP/$(dirname "$name")"
    mv "$dest" "$BACKUP/$name"
    echo "backup   $name -> $BACKUP/$name"
  fi

  ln -s "$src" "$dest"
  echo "linked   $name"
}

install_rtk() {
  if command -v rtk >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/rtk" ]]; then
    echo "ok       rtk"
    return
  fi

  local tmp
  tmp=$(mktemp -d)
  # Official installer: verifies the release SHA-256 before extracting
  curl -fsSL "$RTK_INSTALLER" -o "$tmp/install.sh"
  sh "$tmp/install.sh"
  rm -rf "$tmp"

  "$HOME/.local/bin/rtk" gain >/dev/null 2>&1 \
    || echo "warning: installed rtk doesn't answer 'rtk gain'; wrong package?" >&2
  echo "installed rtk"
}

retire() {
  local name="$1" dest="$DEST/$1"
  [[ -e "$dest" || -L "$dest" ]] || return 0

  mkdir -p "$BACKUP/$(dirname "$name")"
  mv "$dest" "$BACKUP/$name"
  echo "retired  $name -> $BACKUP/$name"
}

main() {
  if [[ $EUID -eq 0 ]]; then
    echo "Run as your user, not root" >&2
    exit 1
  fi

  command -v jq >/dev/null 2>&1 || echo "warning: jq not found; hooks depend on it" >&2

  mkdir -p "$DEST" "$DEST/handoffs"
  chmod +x "$SRC"/hooks/*.sh "$SRC/statusline-command.sh"
  rm -f "$DEST"/*:Zone.Identifier

  for name in "${LINKS[@]}"; do
    link "$name"
  done

  mkdir -p "$DEST/$SKILLS_DIR"
  for skill in "$SRC/$SKILLS_DIR"/*/; do
    link "$SKILLS_DIR/$(basename "$skill")"
  done

  for name in "${LEGACY[@]}"; do
    retire "$name"
  done

  if [[ "${1:-}" != "--no-rtk" ]]; then
    install_rtk
  fi

  if [[ ! -e "$DEST/machine.md" ]]; then
    cp "$SRC/machine.example.md" "$DEST/machine.md"
    echo "created  machine.md (edit it: keep only this machine's profile)"
  else
    echo "kept     machine.md"
  fi
}

main "$@"
