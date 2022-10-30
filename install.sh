#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "$OSTYPE" == "darwin"* ]]; then
  $DIR/macos.sh
elif [ -f /etc/redhat-release ]; then
  $DIR/fedora.sh
elif [ -f /etc/arch-release ]; then
  $DIR/arch.sh
else
  $DIR/tumbleweed.sh
fi

if [[ "$OSTYPE" != "darwin"* ]]; then
  sudo bash -c "curl -sfL git.io/antibody | sh -s - -b /usr/local/bin"
fi

mkdir -p ~/.config/nvim/
echo "set runtimepath^=~/dotfiles/vim" >> ~/.config/nvim/init.vim
echo "source ~/dotfiles/vim/vimrc" >> ~/.config/nvim/init.vim

ln -s ~/dotfiles/kitty ~/.config/kitty

echo "source $HOME/dotfiles/zshrc" >> $HOME/.zshrc

pip install cmake-language-server

echo "[include]" >> ~/.gitconfig
echo "  path = ~/dotfiles/gitconfig" >> ~/.gitconfig

echo "Run :PackerSync for full experience"
