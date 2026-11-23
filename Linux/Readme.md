# NedcloarBR's Linux Configuration

These are the settings I use in Linux/WSL for my development environment
<br>
The script needs `bash`, `curl` and root privileges. Download it and run it with `sudo`:

```zsh
curl -fsSL https://raw.githubusercontent.com/NedcloarBR/dotfiles/Master/Linux/install.sh -o install.sh
sudo bash install.sh
```

When run from a clone of this repository, the dotfiles are copied from the local checkout; otherwise the repository is cloned.

### Options

```
sudo bash install.sh                        # interactive menu
sudo bash install.sh --all                  # every step except remove-snap
sudo bash install.sh --only zsh,uv,dotfiles # only the given steps
sudo bash install.sh --only docker --yes    # answer yes to every prompt
bash install.sh --list                      # list step names
```

Failed steps don't stop the others; a summary is shown at the end and the full log is saved to `/var/log/dotfiles-install-<timestamp>.log`.
Existing dotfiles are backed up as `<file>.backup-<timestamp>`.

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
    │   └── Node LTS
    ├── SDKMAN! (Java Software Development Kit Manager)
    ├── Rust + Cargo (via rustup)
    │   └── cargo-watch, cargo-modules, cargo-nextest, cargo-make,
    │       cargo-release, cargo-edit, cargo-audit, cargo-tarpaulin (via cargo-binstall)
    ├── uv (Python Version & Package Manager)
    │   └── Python Latest
    └── GitHub CLI
``` 
