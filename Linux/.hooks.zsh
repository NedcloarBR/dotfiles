autoload -U add-zsh-hook

load-nvmrc() {
  local node_version

  if [[ -f .nvmrc ]]; then
    node_version=$(<.nvmrc)
    if ! nvm use "$node_version" &>/dev/null; then
      echo "⚠️ Version $node_version not installed, using latest version."
      nvm use node > /dev/null
    fi
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc
