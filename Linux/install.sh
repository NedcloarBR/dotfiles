#!/bin/bash

# Update System
sudo apt update  -y && sudo apt upgrade -y

# # Install required modules
sudo apt install build-essential dkms gcc wget make zip unzip git curl zsh -y

# # Set zsh as default bash and install Oh My ZSH
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# # Clone NedcloarBR's config files
git clone https://github.com/NedcloarBR/dotfiles
mv ./dotfiles/Linux/.zshrc ./dotfiles/Linux/.p10k.zsh $HOME
sudo mv ./dotfiles/Linux/wsl.conf ../../etc
rm -rf ./dotfiles

# # Clone Oh My ZSH theme and plugins
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions

# # Install and configure NodeJS with nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install Gallium # v16.19.0
nvm install Hydrogen # v18.14.0
nvm install node # v19.6.0 (latest in 16/02/2023 - 20:00)  DD/MM/YYYY - UTC-3

# Install and configure Docker
curl -o- -fsSL https://get.docker.com | bash

# Install and configure Java with SDKMan
curl -o- -s -fsSL "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 19.0.2-oracle

# Install and configure Rust and Cargo plugins
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"
sudo apt-get install libssl-dev pkg-config -y
cargo install cargo-watch cargo-modules cargo-nextest cargo-make cargo-release cargo-edit cargo-audit cargo-tarpaulin