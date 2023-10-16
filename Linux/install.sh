#!/bin/bash

# TODO: Remove sudo Requirement => Create a new User with the required perms in system to execute the commands then exclude this ScriptUser
# TODO: Improved Menu => Better Descriptions for each Option, Menu likes VIM/Nano
# TODO: More Options

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root(sudo)"
  exit 1
fi

update="Update System - (Recommended)"
requirements="Install Requirements - (Essential)"
zsh="Install ZSH + Plugins & Theme as default Shell - (Recommended)"
docker="Install Docker - (Optional)"
nodejs="Install NVM (Node Version Manager) - (Optional)"
java="Install SDKMan! (Java Version Manager) - (Optional)"
rust="Install Rust + Cargo Plugins - (Optional)"
python="Install PyEnv (Python Version Manager) - (Optional)"
options=("$update" "$requirements" "$zsh" "$docker" "$nodejs" "$java" "$rust" "$python")
selected=()
current=0

createMenu() {
  tput clear
  echo "Select the options you want:"

  for i in "${!options[@]}"; do
    if [[ $i -eq $current ]]; then
      if [[ " ${selected[@]} " =~ " ${options[i]} " ]]; then
        echo "-> [x] ${options[i]}"
      else
        echo "-> [ ] ${options[i]}"
      fi
    else
      if [[ " ${selected[@]} " =~ " ${options[i]} " ]]; then
        echo "   [x] ${options[i]}"
      else
        echo "   [ ] ${options[i]}"
      fi
    fi
  done
}

runCommands() {
  for option in "${selected[@]}"; do
    case "$option" in
    "$update")
      Iupdate
      ;;
    "$zsh")
      Izsh
      ;;
    "$docker" | "$nodejs" | "$java" | "$rust" | "$python")
      if [[ ! " ${selected[@]} " =~ " $requirements " ]]; then
        echo "Esta Opção só roda com requirements"
      else
        Irequirements
        case "$option" in
        "$docker")
          Idocker
          ;;
        "$nodejs")
          Invm
          ;;
        "$java")
          Ijava
          ;;
        "$rust")
          Irust
          ;;
        esac
      fi
      ;;
    esac
  done
}

main() {
  while true; do
    createMenu
    read -r -sn1 key

    if [[ "$key" == "q" && $current -eq 0 ]]; then
      continue
    fi

    case "$key" in
    "p")
      if [[ " ${selected[@]} " =~ " ${options[current]} " ]]; then
        selected=("${selected[@]/${options[current]}/}")
      else
        selected+=("${options[current]}")
      fi
      ;;
    'q')
      tput clear
      runCommands
      echo "Pressione qualquer tecla para sair..."
      read -n 1 -s -r
      exit 0
      ;;
    'A')
      if [[ $current -gt 0 ]]; then
        ((current--))
      fi
      ;;
    'B')
      if [[ $current -lt $((${#options[@]} - 1)) ]]; then
        ((current++))
      fi
      ;;
    esac

    show_menu
  done
}

Iupdate() {
  sudo apt update -y && sudo apt upgrade -y &&
    echo -e "System was Updated!"

}

Irequirements() {
  sudo apt install build-essential dkms gcc wget make zip unzip git curl -y &&
    echo -e "\n\nRequirements was Installed!"

}

Izsh() {
  sudo apt install zsh -y
  chsh -s /bin/zsh -y
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &&
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ &
  ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom/themes/powerlevel10k &
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions &
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting &
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions &&
    echo -e "\n\n ZSH + Plugins & Theme was Installed!"
}

Invm() {
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash &&
    echo -e "NVM was Installed!"
}

Ijava() {
  curl -o- -s -fsSL "https://get.sdkman.io" | bash &&
    echo -e "\n\nSDKMan! was Installed!"
}

Irust() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  . "$HOME/.cargo/env" &&
    sudo apt-get install libssl-dev pkg-config -y &&
    cargo install cargo-watch cargo-modules cargo-nextest cargo-make cargo-release cargo-edit cargo-audit cargo-tarpaulin &&
    echo -e "Rust + Cargo Plugins was Installed!"
}

Ipython() {
  sudo apt install libedit-dev zlib1g zlib1g-dev libssl-dev libbz2-dev libsqlite3-dev -y &&
    curl https://pyenv.run | bash &&
    echo -e "\n\nPyEnv was Installed!"
}

Idocker() {
  if command -v docker &>/dev/null; then
    echo "Docker is already installed"
  else
    if isWSL; then
      echo
      echo "WSL DETECTED: We recommend using Docker Desktop for Windows."
      echo "Please get Docker Desktop from https://www.docker.com/products/docker-desktop/"
      echo

      local choice

      while true; do
        tput cup 5 0
        read -n 1 -p "Continue? [y/n]: " choice
        case "$choice" in
        [Nn])
          echo -e "\n\nDocker Installation Canceled"
          break
          ;;
        [Yy])
          continueDocker
          break
          ;;
        *)
          tput cup 5 0
          echo "Continue? [y/n]:  "
          ;;
        esac
      done
    fi
    echo "Docker"
  fi
}

continueDocker() {
  curl -o- -fsSL https://get.docker.com | bash &
  sudo groupadd docker &
  sudo usermod -aG docker $USER &
  newgrp docker &
  sudo chown "$USER":"$USER" /home/"$USER"/.docker -R &
  sudo chmod g+rwx "$HOME/.docker" -R &
  sudo systemctl enable docker.service &
  sudo systemctl enable containerd.service &&
    echo -e "\n\nDocker wa Installed!"
}

isWSL() {
  case "$(uname -r)" in
  *microsoft*) true ;; # WSL 2
  *Microsoft*) true ;; # WSL 1
  *) false ;;
  esac
}

main
