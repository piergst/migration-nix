#!/bin/bash
set -e

# This script will be executed on the first startup of each new container with the "my-resources" feature enabled.
# Arbitrary code can be added in this file, in order to customize Exegol (dependency installation, configuration file copy, etc).
# It is strongly advised **not** to overwrite the configuration files provided by exegol (e.g. /root/.zshrc, /opt/.exegol_aliases, ...), official updates will not be applied otherwise.

# Exegol also features a set of supported customization a user can make.
# The /opt/supported_setups.md file lists the supported configurations that can be made easily.

# Completion and prompt
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Ignore apt errors (unsigned repo won't block the rest)
sudo apt update || true
sudo apt install -y zoxide ripgrep xclip || true

# eza (pb with apt install retry later)
/opt/my-resources/setup/install-eza.sh

# Keybindings
install -D /opt/my-resources/setup/zsh/keybindings.zsh /root/.oh-my-zsh/custom/keybindings.zsh
cp /opt/my-resources/setup/zsh/aliases /root/.oh-my-zsh/custom/aliases.zsh
#cp /opt/my-resources/setup/zsh/p10k.zsh /root/.p10k.zsh

# Init nvim config
nvim --headless '+Lazy! sync' +qa || true
