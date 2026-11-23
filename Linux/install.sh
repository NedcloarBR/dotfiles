#!/bin/bash
#
# Linux Dotfiles Installation Script
# ===================================
# Interactive menu to install development tools and configurations
#
# Usage: sudo ./install.sh [--all | --only <steps>] [--yes]
#        ./install.sh --list | --help
#
# Navigation:
#   ↑/↓ or k/j  - Navigate options
#   SPACE       - Toggle selection
#   ENTER       - Confirm and run installations
#   Q           - Quit without running
#

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# CONSTANTS
# ==============================================================================

# Terminal Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Steps in execution order: key|function|needs requirements (req|-)|menu label
readonly STEPS=(
  "update|install_update|-|Update System - (Recommended)"
  "requirements|install_requirements|-|Install Requirements - (Essential)"
  "zsh|install_zsh|req|Install ZSH + Plugins & Theme as default Shell - (Recommended)"
  "docker|install_docker|req|Install Docker - (Optional)"
  "qemu|install_qemu|-|Install QEMU + Virtual Machine Manager - (Optional, Linux only)"
  "nvm|install_nvm|req|Install NVM (Node Version Manager) + Node LTS - (Optional)"
  "sdkman|install_sdkman|req|Install SDKMan! (Java Version Manager) - (Optional)"
  "rust|install_rust|req|Install Rust + Cargo Plugins - (Optional)"
  "uv|install_uv|req|Install uv (Python Version & Package Manager) - (Optional)"
  "gh|install_github_cli|req|Install GitHub CLI - (Optional)"
  "remove-snap|remove_snap|req|Remove Snap completely + block reinstall - (Optional, Linux only)"
  "flatpak|install_flatpak|-|Install Flatpak + Flathub & Software Center - (Optional, Linux only)"
  "dotfiles|install_dotfiles|req|Install ZSH Dotfiles from repository - (Optional)"
)

# Destructive steps are never selected by --all
readonly ALL_EXCLUDED=("remove-snap")

readonly DOTFILES=(
  ".zshrc"
  ".p10k.zsh"
  ".aliases.zsh"
  ".functions.zsh"
  ".hooks.zsh"
  ".plugins.zsh"
  ".programs.zsh"
)

readonly REPO_URL="https://github.com/NedcloarBR/dotfiles.git"
readonly FLATHUB_REPO="https://dl.flathub.org/repo/flathub.flatpakrepo"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd || true)
readonly SCRIPT_DIR

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
readonly TIMESTAMP
readonly LOG_FILE="/var/log/dotfiles-install-${TIMESTAMP}.log"

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================

ACTUAL_USER="${SUDO_USER:-$(id -un)}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

ASSUME_YES=false
is_selected=()
current=0

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Run a command as the actual user (not root)
run_as_user() {
  if [[ "$(id -un)" == "$ACTUAL_USER" ]]; then
    "$@"
  else
    sudo -u "$ACTUAL_USER" -H "$@"
  fi
}

# Download an installer before running it, so a failed download never runs a partial script
fetch_script() {
  curl -fsSL --proto '=https' --tlsv1.2 "$1"
}

# Run a remote installer as the actual user: run_remote_installer <url> <shell> [args...]
run_remote_installer() {
  local url="$1" shell="$2" script
  shift 2
  script=$(fetch_script "$url")
  run_as_user "$shell" -s -- "$@" <<<"$script"
}

# Detect if running inside WSL
is_wsl() {
  case "$(uname -r)" in
    *microsoft*) return 0 ;; # WSL 2
    *Microsoft*) return 0 ;; # WSL 1
    *) return 1 ;;
  esac
}

# Detect if the distro is Ubuntu (or an Ubuntu derivative)
is_ubuntu() {
  [[ -r /etc/os-release ]] || return 1
  local id id_like
  id=$(. /etc/os-release && echo "${ID:-}")
  id_like=$(. /etc/os-release && echo "${ID_LIKE:-}")
  [[ "$id" == "ubuntu" ]] || [[ "$id_like" == *ubuntu* ]]
}

# Detect installed desktop environment: gnome | kde | none
detect_desktop() {
  if dpkg -s gnome-shell &>/dev/null; then
    echo "gnome"
  elif dpkg -s plasma-desktop &>/dev/null || dpkg -s plasma-workspace &>/dev/null; then
    echo "kde"
  else
    echo "none"
  fi
}

# Ask a yes/no question, returns 0 for yes (always yes with --yes)
confirm() {
  local prompt="$1" choice
  if [[ "$ASSUME_YES" == true ]]; then
    log_info "$prompt [y/N]: y (--yes)"
    return 0
  fi
  while true; do
    read -r -n 1 -p "$prompt [y/N]: " choice
    echo ""
    case "$choice" in
      [Yy]) return 0 ;;
      [Nn] | "") return 1 ;;
      *) log_warning "Please enter 'y' or 'n'" ;;
    esac
  done
}

# Restore terminal to normal state
restore_terminal() {
  tput cnorm              # Show cursor
  stty sane               # Reset terminal
  read -r -t 0.1 -n 10000 _ 2>/dev/null || true  # Clear input buffer
}

# ==============================================================================
# STEP HELPERS
# ==============================================================================

step_field() {
  local index="$1" field="$2" key fn req label
  IFS='|' read -r key fn req label <<<"${STEPS[index]}"
  case "$field" in
    key) echo "$key" ;;
    fn) echo "$fn" ;;
    req) echo "$req" ;;
    label) echo "$label" ;;
  esac
}

step_index() {
  local i
  for i in "${!STEPS[@]}"; do
    [[ "$(step_field "$i" key)" == "$1" ]] && { echo "$i"; return 0; }
  done
  return 1
}

selected_count() {
  local i count=0
  for i in "${!STEPS[@]}"; do
    [[ "${is_selected[i]}" == true ]] && ((count++)) || true
  done
  echo "$count"
}

select_all() {
  local i key
  for i in "${!STEPS[@]}"; do
    key=$(step_field "$i" key)
    [[ " ${ALL_EXCLUDED[*]} " == *" $key "* ]] || is_selected[i]=true
  done
}

select_keys() {
  local keys key index
  IFS=',' read -ra keys <<<"$1"
  for key in "${keys[@]}"; do
    if ! index=$(step_index "$key"); then
      log_error "Unknown step: '$key' (see --list)"
      exit 1
    fi
    is_selected[index]=true
  done
}

# Selecting a step that needs 'requirements' selects it too
add_required_steps() {
  local i req_index
  req_index=$(step_index requirements)
  [[ "${is_selected[req_index]}" == true ]] && return
  for i in "${!STEPS[@]}"; do
    if [[ "${is_selected[i]}" == true && "$(step_field "$i" req)" == req ]]; then
      log_warning "Selected steps need 'requirements' - adding it"
      is_selected[req_index]=true
      return
    fi
  done
}

# ==============================================================================
# MENU FUNCTIONS
# ==============================================================================

draw_menu() {
  tput clear

  # Header
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║           Linux Dotfiles Installation Script                   ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}Use ↑/↓ to navigate, SPACE to select, ENTER to confirm, Q to quit${NC}"
  echo ""

  # Options
  local i prefix checkbox color label
  for i in "${!STEPS[@]}"; do
    prefix="   "
    checkbox="[ ]"
    color=""
    label=$(step_field "$i" label)

    if [[ $i -eq $current ]]; then
      prefix="->"
      color="${CYAN}"
    fi

    if [[ "${is_selected[i]}" == true ]]; then
      checkbox="[x]"
      color="${GREEN}"
    fi

    if [[ -n "$color" ]]; then
      echo -e "${color}${prefix} ${checkbox} ${label}${NC}"
    else
      echo "${prefix} ${checkbox} ${label}"
    fi
  done

  # Footer
  echo ""
  echo -e "${YELLOW}Selected: $(selected_count) option(s)${NC}"
}

toggle_selection() {
  if [[ "${is_selected[current]}" == true ]]; then
    is_selected[current]=false
  else
    is_selected[current]=true
  fi
}

navigate_up() {
  if [[ $current -gt 0 ]]; then
    ((current--)) || true
  fi
}

navigate_down() {
  if [[ $current -lt $((${#STEPS[@]} - 1)) ]]; then
    ((current++)) || true
  fi
}

handle_input() {
  local key k1 k2

  IFS= read -rsn1 key 2>/dev/null || true

  # Handle escape sequences (arrow keys)
  if [[ "$key" == $'\x1b' ]]; then
    read -rsn1 -t 0.1 k1 2>/dev/null || true
    read -rsn1 -t 0.1 k2 2>/dev/null || true
    key="${k1}${k2}"
  fi

  case "$key" in
    " ")        toggle_selection; return 0 ;;
    "")         return 1 ;;  # Enter - exit loop and run
    'q' | 'Q')  return 2 ;;  # Quit
    '[A' | 'k') navigate_up; return 0 ;;
    '[B' | 'j') navigate_down; return 0 ;;
  esac

  return 0
}

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

install_update() {
  log_info "Updating system packages..."
  apt-get update -y
  apt-get upgrade -y
  log_success "System was updated!"
}

install_requirements() {
  log_info "Installing requirements..."
  apt-get update -y
  apt-get install -y build-essential dkms gcc wget make zip unzip git curl ca-certificates
  log_success "Requirements were installed!"
}

clone_if_missing() {
  local url="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    log_info "$(basename "$dest") already installed - skipping"
    return 0
  fi
  run_as_user git clone --depth=1 --quiet "$url" "$dest"
}

install_zsh() {
  log_info "Installing ZSH and plugins..."
  apt-get install -y zsh

  chsh -s "$(command -v zsh)" "$ACTUAL_USER"

  if [[ -d "${ACTUAL_HOME}/.oh-my-zsh" ]]; then
    log_info "Oh My Zsh already installed - skipping"
  else
    run_remote_installer "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" sh --unattended
  fi

  local zsh_custom="${ACTUAL_HOME}/.oh-my-zsh/custom"
  local -A repos=(
    ["themes/powerlevel10k"]="https://github.com/romkatv/powerlevel10k.git"
    ["plugins/zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["plugins/zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["plugins/zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
  )

  local path pid failed=false
  local -A pids=()
  for path in "${!repos[@]}"; do
    clone_if_missing "${repos[$path]}" "$zsh_custom/$path" &
    pids[$path]=$!
  done

  for path in "${!pids[@]}"; do
    pid="${pids[$path]}"
    if ! wait "$pid"; then
      log_error "Failed to clone $path"
      failed=true
    fi
  done
  if [[ "$failed" == true ]]; then
    return 1
  fi

  log_success "ZSH + Plugins & Theme were installed!"
  log_info "Please restart your terminal or run 'zsh' to start using ZSH"
}

install_nvm() {
  log_info "Fetching latest NVM version..."

  local nvm_version
  nvm_version=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)

  if [[ -z "$nvm_version" ]]; then
    log_warning "Could not fetch latest version, using fallback v0.40.3"
    nvm_version="v0.40.3"
  fi

  log_info "Installing NVM ${nvm_version}..."
  run_remote_installer "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" bash

  log_info "Installing Node LTS..."
  # shellcheck disable=SC2016
  run_as_user bash -c 'export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm install --lts'

  log_success "NVM ${nvm_version} + Node LTS were installed!"
  log_info "Restart your terminal to start using node"
}

install_sdkman() {
  log_info "Installing SDKMan! (Java Version Manager) - Latest version..."
  run_remote_installer "https://get.sdkman.io?rcupdate=false" bash

  log_success "SDKMan! was installed!"
  log_info "Run 'source ~/.sdkman/bin/sdkman-init.sh' or restart terminal"
}

install_rust() {
  log_info "Installing Rust dependencies..."
  apt-get install -y libssl-dev pkg-config

  log_info "Installing Rust and Cargo (Latest stable)..."
  run_remote_installer "https://sh.rustup.rs" sh -y --default-toolchain stable

  log_info "Installing cargo-binstall..."
  run_remote_installer "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh" bash

  log_info "Installing Cargo plugins (prebuilt binaries)..."
  # shellcheck disable=SC2016
  run_as_user bash -c '. "$HOME/.cargo/env" && cargo binstall --no-confirm cargo-watch cargo-modules cargo-nextest cargo-make cargo-release cargo-edit cargo-audit cargo-tarpaulin'

  log_success "Rust + Cargo Plugins were installed!"
}

install_uv() {
  log_info "Installing uv (Latest version)..."
  run_remote_installer "https://astral.sh/uv/install.sh" sh --no-modify-path

  log_info "Installing latest Python via uv..."
  run_as_user "${ACTUAL_HOME}/.local/bin/uv" python install

  log_success "uv + Python were installed!"
  log_info "Make sure ~/.local/bin is in your PATH and restart terminal"
}

install_github_cli() {
  if command_exists gh; then
    log_warning "GitHub CLI is already installed"
    return
  fi

  log_info "Installing GitHub CLI (Latest version)..."

  # Add GitHub CLI repository
  install -d -m 0755 /usr/share/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list

  apt-get update -y
  apt-get install -y gh

  log_success "GitHub CLI was installed!"
  log_info "Run 'gh auth login' to authenticate with your GitHub account"
}

# Prints the directory holding the dotfiles: this script's folder, or a fresh clone
dotfiles_source() {
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/.zshrc" ]]; then
    log_info "Using dotfiles from local repository: $SCRIPT_DIR" >&2
    echo "$SCRIPT_DIR"
    return
  fi

  local tmp_dir
  tmp_dir=$(mktemp -d)
  chown "$ACTUAL_USER" "$tmp_dir"
  log_info "Cloning repository..." >&2
  run_as_user git clone --depth=1 --quiet "$REPO_URL" "$tmp_dir/repo"

  if [[ ! -d "$tmp_dir/repo/Linux" ]]; then
    log_error "Could not find Linux directory in repository" >&2
    rm -rf "$tmp_dir"
    return 1
  fi
  echo "$tmp_dir/repo/Linux"
}

install_dotfiles() {
  log_info "Installing ZSH dotfiles..."

  local source_dir
  source_dir=$(dotfiles_source)
  if [[ "$source_dir" != "$SCRIPT_DIR" ]]; then
    # shellcheck disable=SC2064
    trap "rm -rf '${source_dir%/repo/Linux}'" EXIT
  fi

  local dotfile src dest
  for dotfile in "${DOTFILES[@]}"; do
    src="$source_dir/$dotfile"
    dest="${ACTUAL_HOME}/$dotfile"

    if [[ ! -f "$src" ]]; then
      log_warning "$dotfile not found in repository"
      continue
    fi

    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
      log_info "$dotfile is up to date"
      continue
    fi

    if [[ -f "$dest" ]]; then
      log_warning "Backing up existing $dotfile to ${dotfile}.backup-${TIMESTAMP}"
      run_as_user mv "$dest" "${dest}.backup-${TIMESTAMP}"
    fi

    run_as_user cp "$src" "$dest"
    log_info "Installed $dotfile"
  done

  log_success "Dotfiles were installed!"
  log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
}

install_qemu() {
  if is_wsl; then
    log_warning "QEMU/KVM is not supported on WSL."
    log_info "Use Hyper-V or VirtualBox on Windows instead."
    return
  fi

  if command_exists virt-manager; then
    log_warning "Virtual Machine Manager is already installed"
    return
  fi

  log_info "Installing QEMU, KVM and Virtual Machine Manager..."

  apt-get install -y qemu-kvm qemu-system qemu-utils libvirt-daemon-system libvirt-clients bridge-utils
  apt-get install -y virt-manager virt-viewer
  apt-get install -y ovmf swtpm swtpm-tools

  usermod -aG libvirt "$ACTUAL_USER"
  usermod -aG kvm "$ACTUAL_USER"

  systemctl enable libvirtd
  systemctl start libvirtd

  virsh net-autostart default 2>/dev/null || true
  virsh net-start default 2>/dev/null || true

  log_success "QEMU + Virtual Machine Manager were installed!"
  log_info "Please log out and log back in for group changes to take effect"
  log_info "Launch 'virt-manager' to start creating VMs"
}

# ------------------------------------------------------------------------------
# Docker Installation
# ------------------------------------------------------------------------------

install_docker() {
  if command_exists docker; then
    log_warning "Docker is already installed"
    return
  fi

  if is_wsl; then
    prompt_docker_wsl
  else
    prompt_docker_type
  fi
}

prompt_docker_wsl() {
  echo ""
  log_warning "WSL DETECTED: We recommend using Docker Desktop for Windows."
  echo -e "${CYAN}Please get Docker Desktop from https://www.docker.com/products/docker-desktop/${NC}"
  echo ""

  if confirm "Continue with Linux Docker installation anyway?"; then
    install_docker_engine
  else
    log_info "Docker installation canceled"
  fi
}

prompt_docker_type() {
  if [[ "$ASSUME_YES" == true ]]; then
    log_info "Installing Docker Engine (default with --yes)"
    install_docker_engine
    return
  fi

  echo ""
  echo -e "${BOLD}${CYAN}Choose Docker installation type:${NC}"
  echo ""
  echo -e "  ${GREEN}1)${NC} Docker Engine (CLI only)"
  echo -e "     ${YELLOW}Lightweight, command-line interface${NC}"
  echo -e "     ${YELLOW}Best for: servers, headless systems, advanced users${NC}"
  echo ""
  echo -e "  ${GREEN}2)${NC} Docker Desktop (GUI)"
  echo -e "     ${YELLOW}Full GUI with Kubernetes, extensions${NC}"
  echo -e "     ${YELLOW}Best for: development workstations, visual management${NC}"
  echo ""
  echo -e "  ${RED}3)${NC} Cancel installation"
  echo ""

  local choice
  while true; do
    read -r -n 1 -p "Select option [1/2/3]: " choice
    echo ""
    case "$choice" in
      1) install_docker_engine; return ;;
      2) install_docker_desktop; return ;;
      3) log_info "Docker installation canceled"; return ;;
      *) log_warning "Please enter 1, 2, or 3" ;;
    esac
  done
}

install_docker_engine() {
  log_info "Installing Docker Engine..."

  local script
  script=$(fetch_script "https://get.docker.com")
  sh -s <<<"$script"

  groupadd docker 2>/dev/null || true
  usermod -aG docker "$ACTUAL_USER"

  if [[ -d "${ACTUAL_HOME}/.docker" ]]; then
    chown "$ACTUAL_USER":"$ACTUAL_USER" "${ACTUAL_HOME}/.docker" -R
    chmod g+rwx "${ACTUAL_HOME}/.docker" -R
  fi

  systemctl enable docker.service
  systemctl enable containerd.service

  log_success "Docker Engine was installed!"
  log_info "Please log out and log back in for group changes to take effect"
}

install_docker_desktop() {
  local arch
  arch=$(dpkg --print-architecture)

  if [[ "$arch" != "amd64" ]]; then
    log_error "Docker Desktop only supports amd64 architecture. Your architecture: $arch"
    log_info "Falling back to Docker Engine..."
    install_docker_engine
    return
  fi

  log_info "Preparing Docker Desktop installation..."
  apt-get install -y gnome-terminal 2>/dev/null || apt-get install -y xterm 2>/dev/null || true

  local tmp_dir
  tmp_dir=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" EXIT
  local deb_file="$tmp_dir/docker-desktop.deb"

  log_info "Downloading Docker Desktop (this may take a while)..."
  curl -fsSL "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb" -o "$deb_file"

  log_info "Installing Docker Desktop..."
  apt-get install -y "$deb_file"

  log_success "Docker Desktop was installed!"
  log_info "Launch Docker Desktop from your application menu"
  log_info "You may need to log out and log back in for changes to take effect"
}

# ------------------------------------------------------------------------------
# Snap Removal
# ------------------------------------------------------------------------------

remove_all_snaps() {
  command_exists snap || return 0

  log_info "Removing installed snap packages..."

  # Multiple passes: apps first, then bases/core they depend on
  local pass snaps snap_name
  for pass in 1 2 3; do
    mapfile -t snaps < <(snap list --all 2>/dev/null | awk 'NR>1 && $1 != "snapd" { print $1 }' | sort -u)
    [[ ${#snaps[@]} -eq 0 ]] && break

    for snap_name in "${snaps[@]}"; do
      log_info "Removing snap: ${snap_name} (pass ${pass})"
      snap remove --purge "$snap_name" &>/dev/null || true
    done
  done

  snap remove --purge snapd &>/dev/null || true
}

block_snapd_reinstall() {
  log_info "Blocking snapd from being reinstalled..."

  apt-mark hold snapd &>/dev/null || true

  cat > /etc/apt/preferences.d/nosnap.pref <<'EOF'
# Prevent snapd from being installed as a dependency
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

  log_success "snapd is now pinned with priority -10"
}

install_firefox_deb() {
  log_info "Adding Mozilla APT repository..."

  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/packages.mozilla.org.asc
  chmod go+r /etc/apt/keyrings/packages.mozilla.org.asc

  echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
    > /etc/apt/sources.list.d/mozilla.list

  # Ensure the Mozilla build wins over Ubuntu's snap transitional package
  cat > /etc/apt/preferences.d/mozilla.pref <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

  apt-get update -y
  apt-get install -y firefox

  log_success "Firefox (deb) was installed from the Mozilla repository!"
}

remove_snap() {
  if is_wsl; then
    log_warning "Snap is not supported on WSL - nothing to remove."
    return
  fi

  echo ""
  log_warning "This will PERMANENTLY remove snapd and ALL installed snap packages."
  log_warning "Snap application data under /var/snap and ~/snap will be deleted."

  if command_exists snap; then
    echo ""
    echo -e "${CYAN}Currently installed snaps:${NC}"
    snap list 2>/dev/null || log_info "(none)"
  else
    log_info "snapd is not installed - only the reinstall block will be applied."
  fi

  echo ""
  if ! confirm "Continue with complete Snap removal?"; then
    log_info "Snap removal canceled"
    return
  fi

  # Ubuntu ships Firefox/Thunderbird only as snaps
  local install_firefox=false
  if is_ubuntu && command_exists snap && snap list firefox &>/dev/null; then
    echo ""
    log_warning "Firefox on Ubuntu is a snap and will be removed."
    if confirm "Install Firefox as a native deb (Mozilla repository) afterwards?"; then
      install_firefox=true
    fi
  fi

  remove_all_snaps

  log_info "Stopping snapd services..."
  systemctl stop snapd.socket snapd.service snapd.seeded.service &>/dev/null || true
  systemctl disable snapd.socket snapd.service snapd.seeded.service &>/dev/null || true

  log_info "Unmounting leftover snap mounts..."
  local mount_point
  while read -r mount_point; do
    umount -l "$mount_point" &>/dev/null || true
  done < <(mount | awk '$3 ~ "^/snap" { print $3 }' | sort -r)

  log_info "Purging snapd package..."
  apt-get purge -y snapd &>/dev/null || true
  apt-get autoremove --purge -y &>/dev/null || true

  log_info "Removing leftover snap directories..."
  rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd /root/snap
  rm -rf "${ACTUAL_HOME}/snap"

  block_snapd_reinstall

  if [[ "$install_firefox" == true ]]; then
    install_firefox_deb
  fi

  log_success "Snap was completely removed!"
  log_info "To undo the block: sudo apt-mark unhold snapd && sudo rm /etc/apt/preferences.d/nosnap.pref"
}

# ------------------------------------------------------------------------------
# Flatpak Installation
# ------------------------------------------------------------------------------

install_flatpak_store() {
  local desktop
  desktop=$(detect_desktop)

  case "$desktop" in
    gnome)
      log_info "GNOME detected - installing GNOME Software with Flatpak support..."
      # On Ubuntu the App Center is a snap; the deb GNOME Software replaces it
      apt-get install -y gnome-software gnome-software-plugin-flatpak
      if is_ubuntu; then
        log_success "GNOME Software (Ubuntu store) now lists Flatpak applications!"
      fi
      ;;
    kde)
      log_info "KDE detected - installing Discover with Flatpak support..."
      apt-get install -y plasma-discover plasma-discover-backend-flatpak
      log_success "Discover now lists Flatpak applications!"
      ;;
    *)
      log_warning "No supported desktop environment detected - skipping store integration"
      log_info "Flatpak apps can still be installed with 'flatpak install <app>'"
      ;;
  esac
}

install_flatpak() {
  if is_wsl; then
    log_warning "WSL DETECTED: Flatpak GUI apps require a working WSLg setup."
    if ! confirm "Continue with Flatpak installation anyway?"; then
      log_info "Flatpak installation canceled"
      return
    fi
  fi

  log_info "Installing Flatpak..."
  apt-get install -y flatpak

  log_info "Adding Flathub remote (system-wide)..."
  flatpak remote-add --if-not-exists flathub "$FLATHUB_REPO"

  log_info "Adding Flathub remote (user)..."
  run_as_user flatpak remote-add --user --if-not-exists flathub "$FLATHUB_REPO" || true

  if ! is_wsl; then
    install_flatpak_store
  fi

  log_success "Flatpak was installed!"
  log_info "Log out and log back in so Flatpak apps appear in your application menu"
  log_info "Usage: flatpak install flathub <app-id>"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

print_summary() {
  local -n ok_steps="$1" failed_steps="$2"
  local step

  echo ""
  echo -e "${BOLD}${CYAN}Summary${NC}"
  for step in "${ok_steps[@]}"; do
    echo -e "  ${GREEN}✔${NC} $step"
  done
  for step in "${failed_steps[@]}"; do
    echo -e "  ${RED}✘${NC} $step"
  done
  echo ""
  log_info "Full log: $LOG_FILE"
}

run_selected_installations() {
  if [[ "$(selected_count)" -eq 0 ]]; then
    log_warning "No options selected. Exiting..."
    return 0
  fi

  exec > >(tee -a "$LOG_FILE") 2>&1

  add_required_steps

  echo -e "\n${BOLD}${CYAN}Starting installation...${NC}\n"

  local i key fn status succeeded=() failed=()
  for i in "${!STEPS[@]}"; do
    [[ "${is_selected[i]}" == true ]] || continue
    key=$(step_field "$i" key)
    fn=$(step_field "$i" fn)

    echo -e "\n${BOLD}==> ${key}${NC}"

    # Subshell with errexit isolates each step; it must not run inside if/||/&&,
    # where bash silently disables errexit for everything it calls
    set +e
    (set -e; "$fn")
    status=$?
    set -e

    if [[ $status -eq 0 ]]; then
      succeeded+=("$key")
    else
      log_error "Step '$key' failed - continuing with the next steps"
      failed+=("$key")
    fi
  done

  print_summary succeeded failed

  if [[ ${#failed[@]} -gt 0 ]]; then
    log_error "${#failed[@]} step(s) failed"
    return 1
  fi
  log_success "All selected installations completed!"
}

usage() {
  cat <<EOF
Usage: sudo $0 [options]

Without options, an interactive menu is shown.

Options:
  --all             Run every step except: ${ALL_EXCLUDED[*]}
  --only <steps>    Run only the given comma-separated steps (e.g. zsh,uv,dotfiles)
  -y, --yes         Answer yes to every prompt (Docker defaults to Engine)
  --list            List available steps
  -h, --help        Show this help
EOF
}

list_steps() {
  local i
  for i in "${!STEPS[@]}"; do
    printf "  %-14s %s\n" "$(step_field "$i" key)" "$(step_field "$i" label)"
  done
}

# Sets RUN_MODE to "menu" or "batch"
parse_args() {
  local mode="menu"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all) select_all; mode="batch" ;;
      --only)
        [[ $# -ge 2 ]] || { log_error "--only requires a value"; exit 1; }
        select_keys "$2"; mode="batch"; shift ;;
      --only=*) select_keys "${1#--only=}"; mode="batch" ;;
      -y | --yes) ASSUME_YES=true ;;
      --list) list_steps; exit 0 ;;
      -h | --help) usage; exit 0 ;;
      *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done
  RUN_MODE="$mode"
}

run_menu() {
  tput civis
  trap 'restore_terminal' EXIT INT TERM

  local exit_code
  while true; do
    draw_menu

    set +e
    handle_input
    exit_code=$?
    set -e

    [[ $exit_code -eq 0 ]] && continue

    restore_terminal
    tput clear

    if [[ $exit_code -eq 2 ]]; then
      log_info "Exiting without running any commands."
      return 0
    fi

    local status
    set +e
    run_selected_installations
    status=$?
    set -e
    echo ""
    echo -e "${YELLOW}Press any key to exit...${NC}"
    read -r -n 1 -s
    return "$status"
  done
}

main() {
  local i
  for i in "${!STEPS[@]}"; do
    is_selected[i]=false
  done

  RUN_MODE="menu"
  parse_args "$@"

  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (sudo)"
    echo -e "Usage: ${CYAN}sudo $0${NC}"
    exit 1
  fi

  if [[ -z "$ACTUAL_HOME" ]]; then
    log_error "Could not resolve the home directory of '$ACTUAL_USER'"
    exit 1
  fi

  if [[ "$RUN_MODE" == "batch" ]]; then
    run_selected_installations
  else
    run_menu
  fi
}

main "$@"
