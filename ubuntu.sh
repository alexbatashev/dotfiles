#!/bin/bash -e

sudo apt update
sudo apt install -yqq curl fish zsh neovim build-essential \
                      cmake ninja-build wget linux-tools-generic \
                      tmux exa bat fd-find clang lldb gdb nodejs \
            		      tre-command git-extras python3 python-is-python3 \
                      python3-pip fzf python3-venv gettext ripgrep zoxide

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo apt update

sudo apt install -yqq brave-browser

ln -s $(which fdfind) ~/.local/bin/fd
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

./linux_common.sh
