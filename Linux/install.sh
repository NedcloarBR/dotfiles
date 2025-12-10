#!/bin/bash
#
# Linux Dotfiles Installation Script
# ===================================
# Interactive menu to install development tools and configurations
#
# Usage: sudo ./install.sh
#
# Navigation:
#   ↑/↓ or k/j  - Navigate options
#   SPACE       - Toggle selection
#   ENTER       - Confirm and run installations
#   Q           - Quit without running
#

set -euo pipefail

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

# Menu Options
readonly OPT_UPDATE="Update System - (Recommended)"
readonly OPT_REQUIREMENTS="Install Requirements - (Essential)"
readonly OPT_ZSH="Install ZSH + Plugins & Theme as default Shell - (Recommended)"
readonly OPT_DOCKER="Install Docker - (Optional)"
readonly OPT_QEMU="Install QEMU + Virtual Machine Manager - (Optional, Linux only)"
readonly OPT_NODEJS="Install NVM (Node Version Manager) - (Optional)"
readonly OPT_JAVA="Install SDKMan! (Java Version Manager) - (Optional)"
readonly OPT_RUST="Install Rust + Cargo Plugins - (Optional)"
readonly OPT_PYTHON="Install PyEnv (Python Version Manager) - (Optional)"
readonly OPT_GHCLI="Install GitHub CLI - (Optional)"
readonly OPT_DOTFILES="Install ZSH Dotfiles from repository - (Optional)"

# ==============================================================================
# GLOBAL VARIABLES
# ==============================================================================

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

OPTIONS=(
  "$OPT_UPDATE"
  "$OPT_REQUIREMENTS"
  "$OPT_ZSH"
  "$OPT_DOCKER"
  "$OPT_QEMU"
  "$OPT_NODEJS"
  "$OPT_JAVA"
  "$OPT_RUST"
  "$OPT_PYTHON"
  "$OPT_GHCLI"
  "$OPT_DOTFILES"
)

selected=()
current=0
requirements_installed=false

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
  sudo -u "$ACTUAL_USER" "$@"
}

# Detect if running inside WSL
is_wsl() {
  case "$(uname -r)" in
    *microsoft*) return 0 ;; # WSL 2
    *Microsoft*) return 0 ;; # WSL 1
    *) return 1 ;;
  esac
}

# Restore terminal to normal state
restore_terminal() {
  tput cnorm              # Show cursor
  stty sane               # Reset terminal
  read -r -t 0.1 -n 10000 discard 2>/dev/null || true  # Clear input buffer
}

# Ensure requirements are installed before proceeding
ensure_requirements() {
  local tool_name="$1"
  
  if [[ ! " ${selected[*]} " =~ " $OPT_REQUIREMENTS " ]] && [[ "$requirements_installed" == false ]]; then
    log_warning "${tool_name} requires 'Requirements'. Installing requirements first..."
    install_requirements
    requirements_installed=true
  fi
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
  for i in "${!OPTIONS[@]}"; do
    local prefix="   "
    local checkbox="[ ]"
    local color=""
    
    # Highlight current option
    if [[ $i -eq $current ]]; then
      prefix="->"
      color="${CYAN}"
    fi
    
    # Mark selected options
    if [[ " ${selected[*]} " =~ " ${OPTIONS[i]} " ]]; then
      checkbox="[x]"
      color="${GREEN}"
    fi
    
    # Current + selected
    if [[ $i -eq $current ]] && [[ " ${selected[*]} " =~ " ${OPTIONS[i]} " ]]; then
      color="${GREEN}"
    fi
    
    if [[ -n "$color" ]]; then
      echo -e "${color}${prefix} ${checkbox} ${OPTIONS[i]}${NC}"
    else
      echo "${prefix} ${checkbox} ${OPTIONS[i]}"
    fi
  done
  
  # Footer
  echo ""
  echo -e "${YELLOW}Selected: ${#selected[@]} option(s)${NC}"
}

toggle_selection() {
  if [[ " ${selected[*]} " =~ " ${OPTIONS[current]} " ]]; then
    # Remove from selected
    local new_selected=()
    for item in "${selected[@]}"; do
      [[ "$item" != "${OPTIONS[current]}" ]] && new_selected+=("$item")
    done
    selected=("${new_selected[@]}")
  else
    # Add to selected
    selected+=("${OPTIONS[current]}")
  fi
}

navigate_up() {
  if [[ $current -gt 0 ]]; then
    ((current--)) || true
  fi
}

navigate_down() {
  if [[ $current -lt $((${#OPTIONS[@]} - 1)) ]]; then
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
  apt update -y && apt upgrade -y
  log_success "System was updated!"
}

install_requirements() {
  log_info "Installing requirements..."
  apt install build-essential dkms gcc wget make zip unzip git curl -y
  log_success "Requirements were installed!"
}

install_zsh() {
  log_info "Installing ZSH and plugins..."
  apt install zsh -y
  
  # Set ZSH as default shell for the actual user
  chsh -s "$(which zsh)" "$ACTUAL_USER"
  
  run_as_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  
  local zsh_custom="${ACTUAL_HOME}/.oh-my-zsh/custom"
  
  # Install plugins and theme in parallel
  run_as_user git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k" &
  run_as_user git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions" &
  run_as_user git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting" &
  run_as_user git clone https://github.com/zsh-users/zsh-completions "$zsh_custom/plugins/zsh-completions" &
  wait
  
  log_success "ZSH + Plugins & Theme were installed!"
  log_info "Please restart your terminal or run 'zsh' to start using ZSH"
}

install_nvm() {
  log_info "Fetching latest NVM version..."
  
  local nvm_version
  nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  
  if [[ -z "$nvm_version" ]]; then
    log_warning "Could not fetch latest version, using fallback v0.40.1"
    nvm_version="v0.40.1"
  fi
  
  log_info "Installing NVM ${nvm_version}..."
  run_as_user bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh | bash"
  
  log_success "NVM ${nvm_version} was installed!"
  log_info "Run 'source ~/.bashrc' or restart terminal, then use 'nvm install --lts'"
}

install_sdkman() {
  log_info "Installing SDKMan! (Java Version Manager) - Latest version..."
  run_as_user bash -c 'curl -s "https://get.sdkman.io?rcupdate=false" | bash'
  
  log_success "SDKMan! was installed!"
  log_info "Run 'source ~/.sdkman/bin/sdkman-init.sh' or restart terminal"
}

install_rust() {
  log_info "Installing Rust and Cargo (Latest stable)..."
  run_as_user bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable'
  
  log_info "Installing Rust dependencies..."
  apt install libssl-dev pkg-config -y
  
  log_info "Installing Cargo plugins (latest versions)..."
  run_as_user bash -c 'source "$HOME/.cargo/env" && cargo install cargo-watch cargo-modules cargo-nextest cargo-make cargo-release cargo-edit cargo-audit cargo-tarpaulin'
  
  log_success "Rust + Cargo Plugins were installed!"
}

install_pyenv() {
  log_info "Installing PyEnv dependencies..."
  apt install libedit-dev zlib1g zlib1g-dev libssl-dev libbz2-dev libsqlite3-dev libreadline-dev libffi-dev -y
  
  log_info "Installing PyEnv (Latest version)..."
  run_as_user bash -c 'curl https://pyenv.run | bash'
  
  log_success "PyEnv was installed!"
  log_info "Add pyenv to your shell config and restart terminal"
}

install_github_cli() {
  if command_exists gh; then
    log_warning "GitHub CLI is already installed"
    return
  fi

  log_info "Installing GitHub CLI (Latest version)..."
  
  # Add GitHub CLI repository
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  
  # Install GitHub CLI
  apt update
  apt install gh -y
  
  log_success "GitHub CLI was installed!"
  log_info "Run 'gh auth login' to authenticate with your GitHub account"
}

install_dotfiles() {
  log_info "Installing ZSH dotfiles from repository..."
  
  local tmp_dir="/tmp/dotfiles-install-$$"
  local repo_url="https://github.com/NedcloarBR/dotfiles.git"
  
  # Clone repository to temp directory
  log_info "Cloning repository..."
  run_as_user git clone --depth=1 "$repo_url" "$tmp_dir"
  
  if [[ ! -d "$tmp_dir/Linux" ]]; then
    log_error "Could not find Linux directory in repository"
    rm -rf "$tmp_dir"
    return 1
  fi
  
  # Copy dotfiles to user's home directory
  log_info "Copying dotfiles to ${ACTUAL_HOME}..."
  
  local dotfiles=(
    ".zshrc"
    ".p10k.zsh"
    ".aliases.zsh"
    ".functions.zsh"
    ".hooks.zsh"
    ".plugins.zsh"
    ".programs.zsh"
  )
  
  for dotfile in "${dotfiles[@]}"; do
    if [[ -f "$tmp_dir/Linux/$dotfile" ]]; then
      # Backup existing file if it exists
      if [[ -f "${ACTUAL_HOME}/$dotfile" ]]; then
        log_warning "Backing up existing $dotfile to ${dotfile}.backup"
        run_as_user mv "${ACTUAL_HOME}/$dotfile" "${ACTUAL_HOME}/${dotfile}.backup"
      fi
      
      # Copy new dotfile
      run_as_user cp "$tmp_dir/Linux/$dotfile" "${ACTUAL_HOME}/$dotfile"
      log_info "Installed $dotfile"
    else
      log_warning "$dotfile not found in repository"
    fi
  done
  
  # Clean up temporary directory
  log_info "Cleaning up temporary files..."
  rm -rf "$tmp_dir"
  
  log_success "Dotfiles were installed!"
  log_info "Backup files were created with .backup extension"
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
  
  apt install qemu-kvm qemu-system qemu-utils libvirt-daemon-system libvirt-clients bridge-utils -y
  apt install virt-manager virt-viewer -y
  apt install ovmf swtpm swtpm-tools -y
  
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

  while true; do
    read -n 1 -p "Continue with Linux Docker installation anyway? [y/n]: " choice
    echo ""
    case "$choice" in
      [Yy]) install_docker_engine; return ;;
      [Nn]) log_info "Docker installation canceled"; return ;;
      *)    log_warning "Please enter 'y' or 'n'" ;;
    esac
  done
}

prompt_docker_type() {
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

  while true; do
    read -n 1 -p "Select option [1/2/3]: " choice
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
  
  curl -fsSL https://get.docker.com | bash
  
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
  log_info "Preparing Docker Desktop installation..."
  
  apt install gnome-terminal -y 2>/dev/null || apt install xterm -y 2>/dev/null || true
  
  local arch
  arch=$(dpkg --print-architecture)
  
  if [[ "$arch" != "amd64" ]]; then
    log_error "Docker Desktop only supports amd64 architecture. Your architecture: $arch"
    log_info "Falling back to Docker Engine..."
    install_docker_engine
    return
  fi
  
  local deb_file="/tmp/docker-desktop.deb"
  
  log_info "Downloading Docker Desktop (this may take a while)..."
  curl -fsSL "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb" -o "$deb_file"
  
  if [[ ! -f "$deb_file" ]]; then
    log_error "Failed to download Docker Desktop"
    log_info "Please download manually from: https://www.docker.com/products/docker-desktop/"
    return
  fi
  
  log_info "Installing Docker Desktop..."
  apt install "$deb_file" -y
  
  rm -f "$deb_file"
  
  log_success "Docker Desktop was installed!"
  log_info "Launch Docker Desktop from your application menu"
  log_info "You may need to log out and log back in for changes to take effect"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

run_selected_installations() {
  if [[ ${#selected[@]} -eq 0 ]]; then
    log_warning "No options selected. Exiting..."
    return
  fi

  echo -e "\n${BOLD}${CYAN}Starting installation...${NC}\n"
  
  for option in "${selected[@]}"; do
    case "$option" in
      "$OPT_UPDATE")
        install_update
        ;;
      "$OPT_REQUIREMENTS")
        if [[ "$requirements_installed" == false ]]; then
          install_requirements
          requirements_installed=true
        fi
        ;;
      "$OPT_ZSH")
        install_zsh
        ;;
      "$OPT_DOCKER")
        ensure_requirements "Docker"
        install_docker
        ;;
      "$OPT_QEMU")
        install_qemu
        ;;
      "$OPT_NODEJS")
        ensure_requirements "NVM"
        install_nvm
        ;;
      "$OPT_JAVA")
        ensure_requirements "SDKMan"
        install_sdkman
        ;;
      "$OPT_RUST")
        ensure_requirements "Rust"
        install_rust
        ;;
      "$OPT_PYTHON")
        ensure_requirements "PyEnv"
        install_pyenv
        ;;
      "$OPT_GHCLI")
        install_github_cli
        ;;
      "$OPT_DOTFILES")
        install_dotfiles
        ;;
    esac
  done
  
  echo ""
  log_success "All selected installations completed!"
}

main() {
  # Check root privileges
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (sudo)"
    echo -e "Usage: ${CYAN}sudo $0${NC}"
    exit 1
  fi

  # Check system architecture
  local arch
  arch=$(uname -m)
  
  case "$arch" in
    x86_64|amd64)
      # Supported architectures
      ;;
    aarch64|arm64|armv7l|armv8*)
      log_error "This script does not support ARM/AARCH64 architecture"
      log_error "Your architecture: $arch"
      log_info "Please install tools manually or use architecture-specific installation methods"
      exit 1
      ;;
    *)
      log_warning "Unsupported or unknown architecture: $arch"
      log_warning "This script is designed for x86_64/amd64 systems"
      echo ""
      read -n 1 -p "Continue anyway? [y/N]: " choice
      echo ""
      case "$choice" in
        [Yy]) log_info "Continuing installation at your own risk..." ;;
        *) log_info "Installation canceled"; exit 1 ;;
      esac
      ;;
  esac

  # Setup terminal
  tput civis
  trap 'restore_terminal' EXIT INT TERM
  
  # Main loop - temporarily disable errexit for handle_input
  set +e
  while true; do
    draw_menu
    
    handle_input
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
      set -e
      restore_terminal
      tput clear
      
      if [[ $exit_code -eq 1 ]]; then
        # Enter pressed - run installations
        run_selected_installations
        echo ""
        echo -e "${YELLOW}Press any key to exit...${NC}"
        read -n 1 -s -r
      else
        # Q pressed - quit
        log_info "Exiting without running any commands."
      fi
      
      exit 0
    fi
  done
}

# Run the script
main
