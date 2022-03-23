# Atualizar o sistema

- ```zsh
  sudo apt update -y
  ```
- ```zsh
  sudo apt upgrade -y
  ```

# Instalar pacotes

- ```zsh
  sudo apt install dkms make perl gcc build-essential git curl -y
  ```

# Instalar e Configurar o ZSH

- ```zsh
  sudo apt install zsh -y
  ```

- ```zsh
  chsh -s /bin/zsh
  ```

# Instalar Oh-My-ZSH

- ```zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  ```

# Temas

## Spaceship Prompt

Instalar

- ```zsh
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
  ```
  Definir como tema
  - ```zsh
    ZSH_THEME="spaceship"
    ```

## Powerlevel10k

Instalar

- ```zsh
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  ```

Definir como tema

- ```zsh
  ZSH_THEME="powerlevel10k/powerlevel10k"
  ```

# Plugins

## Zsh Autosuggestions

Instalar

- ```zsh
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  ```

Ativar

- ```zsh
  source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  ```

- ```zsh
  plugins=(zsh-autosuggestions)
  ```

## Zsh Syntax Highlighting

- ```zsh
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  ```

Ativar

- ```zsh
  source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ```

- ```zsh
  plugins=(zsh-syntax-highlighting)
  ```

## Zsh Completions

- ```zsh
      git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
  ```

Ativar

- ```zsh
  source $ZSH_CUSTOM/plugins/zsh-completions/zsh-completions.zsh
  ```

- ```zsh
  plugins=(zsh-completions)
  ```
