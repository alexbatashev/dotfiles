#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir -p $HOME/.local/bin

if [ -f /etc/os-release ]; then
  export DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release | sed 's/\"//g')
  echo "Distro is $DISTRO"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Detected macOS. Running macos.sh"
  read -p "Press any key to resume..."
  $DIR/macos.sh
elif [ -f /etc/redhat-release ]; then
  echo "Detected RedHat. Running fedora.sh"
  read -p "Press any key to resume..."
  $DIR/fedora.sh
elif [ -f /etc/arch-release ]; then
  echo "Detected Arch variation. Running arch.sh"
  read -p "Press any key to resume..."
  $DIR/arch.sh
elif [[ "$DISTRO" == "Ubuntu" ]]; then
  echo "Detected Ubuntu. Running ubuntu.sh"
  read -p "Press any key to resume..."
  $DIR/ubuntu.sh
else
  echo "Unsupported distro. Exiting..."
  exit
  # TODO run for SUSE
  $DIR/tumbleweed.sh
fi

stow nvim
stow kitty
stow hyprland
stow waybar 
stow wofi 

echo "source $HOME/dotfiles/zshrc" >> $HOME/.zshrc
echo "source $HOME/dotfiles/fish/config.fish" >> $HOME/.config/fish/config.fish

echo "[include]" >> ~/.gitconfig
echo "  path = ~/dotfiles/gitconfig" >> ~/.gitconfig

echo "Run :PackerSync for full experience"
