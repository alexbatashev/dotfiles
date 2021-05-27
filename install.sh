#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "$OSTYPE" == "darwin"* ]]; then
  $DIR/macos.sh
elif [ -f /etc/redhat-release ]; then
  $DIR/fedora.sh
else
  $DIR/tumbleweed.sh
fi

mkdir -p ~/.config/nvim/
echo "set runtimepath^=~/dotfiles/vim" >> ~/.config/nvim/init.vim
echo "source ~/dotfiles/vim/vimrc" >> ~/.config/nvim/init.vim

echo "source $HOME/dotfiles/zshrc" >> $HOME/.zshrc
