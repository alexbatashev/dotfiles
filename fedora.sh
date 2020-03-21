#!/bin/sh

sudo dnf install fish tmux neovim ack
sudo pip3 install neovim

chsh -s $(which fish)
echo "[include]" > ~/.gitconfig
echo "  path = ~/.dotfiles/.gitconfig" >> ~/.gitconfig

# Install VS Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install code
ln -s ~/.dotfiles/Code ~/.config/Code

curl -L https://get.oh-my.fish > /tmp/omf-install
fish /tmp/omf-install --path=~/.local/share/omf --config=~/.dotfiles/omf
echo "export OMF_PATH=$HOME/.local/share/omf" >> ~/.config/fish/config.fish
echo "export OMF_CONFIG=$HOME/.dotfiles/omf" >> ~/.config/fish/config.fish
echo "source ~/.local/share/omf/init.fish" >> ~/.config/fish/config.fish
echo "source ~/.dotfiles/fish/config.fish" >> ~/.config/fish/config.fish
