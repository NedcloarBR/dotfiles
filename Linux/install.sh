#!/bin/sh

# Update System
sudo apt update  -y && sudo apt upgrade -y

# Install required modules
sudo apt install wget make zip unzip git curl zsh -y

# Set zsh as default bash and install Oh My ZSH
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Clone NedcloarBR's config files
git clone https://github.com/NedcloarBR/dotfiles
mv ./dotfiles/Linux/.zshrc ./dotfiles/Linux/.p10k.zsh $HOME
rm -rf ./dotfiles

# Clone Oh My ZSH theme and plugins
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions

# Install and configure NodeJS with nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | zsh
nvm install Gallium # v16.19.0
nvm install Hydrogen # v18.14.0
nvm install node # v19.6.0 (latest in 16/02/2023 - 20:00)  DD/MM/YYYY - UTC-3


# Install anc configure Java with SDKMan
curl -s "https://get.sdkman.io" | zsh
sdk install java 19.0.2-oracle