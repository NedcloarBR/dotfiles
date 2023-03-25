# NedcloarBR's Linux Configuration

These are the settings I use in Linux/WSL for my development environment
<br>
First of all it is necessary to have cURL installed on your system if you do not have run the command below to install it

```zsh
sudo apt-get install curl
```
After installing curl run the following command and the configuration will be done
```zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/NedcloarBR/dotfiles/Master/Linux/install.sh)"
```

#
## This script will install on your system the following items
```
Linux/WSL
├── wsl.conf (etc/)
└── Packages
    ├── build-essential
    ├── dkms
    ├── gcc
    ├── wget
    ├── zip
    ├── unzip
    ├── libssl-dev 
    ├── pkg-config
    ├── git
    ├── curl
    ├── ZSH
    │   ├── Oh My ZSH
    │   │   └─ PowerLevel10K (Theme)
    │   ├── zsh-autosuggestion (Plugin)
    │   ├── zsh-syntax-highlighting (Plugin)
    │   └── zsh-completions (Plugin)
    ├── nvm (Node Version Manager)
    │   ├── Node Gallium # v16.19.0
    │   ├── Node Hydrogen # v18.14.0
    │   └── Node Latest
    ├── SDKMAN! (Java Software Development Kit Manager)
    │   └── Java 19.0.2 Oracle
    └── pyenv (Python Version Management)
        ├── Python 2.7.18
        └── Python 3.11.2
``` 
