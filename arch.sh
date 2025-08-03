#!/bin/bash -e

sudo pacman -S yay || echo "Failed to install yay"
sudo pacman -S zsh neovim cmake ninja ripgrep wget perf tmux eza bat fd zoxide fzf github-cli brave-browser btop stow 
sudo pacman -S tre-command || echo "Failed to install tre-command"

sudo pacman -S clang lldb gdb openmp lld libc++
sudo pacman -S nodejs npm

./linux_common.sh
