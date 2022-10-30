#!/bin/bash -e

sudo pacman -S yay zsh neovim cmake ninja ripgrep wget perf tmux exa

yay brave

sudo pacman -S clang lldb gdb openmp lld libc++
sudo pacman -S nodejs

sudo mv /tmp/fonts/*.ttf /usr/share/fonts
