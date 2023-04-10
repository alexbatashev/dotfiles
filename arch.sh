#!/bin/bash -e

sudo pacman -S yay zsh neovim cmake ninja ripgrep wget perf tmux exa bat fd tre-command

yay brave

sudo pacman -S clang lldb gdb openmp lld libc++
sudo pacman -S nodejs

./linux_common.sh
