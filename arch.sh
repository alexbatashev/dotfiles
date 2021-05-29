#! /bin/bash

sudo pacman -S yay zsh neovim cmake ninja ripgrep wget perf tmux

yay brave

sudo pacman -S clang lldb gdb openmp lld libc++
sudo pacman -S nodejs

chsh -s $(which zsh)
