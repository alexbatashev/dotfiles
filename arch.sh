#!/bin/bash -e

sudo pacman -S yay || echo "Failed to install yay"
sudo pacman -S zsh neovim cmake ninja ripgrep wget perf tmux exa bat fd zoxide fzf github-cli brave-browser btop 
sudo pacman -S tre-command || echo "Failed to install tre-command"

sudo pacman -S clang lldb gdb openmp lld libc++
sudo pacman -S nodejs

./linux_common.sh
