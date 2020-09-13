#! /bin/bash

sudo dnf install zsh
sudo dnf install neovim
sudo dnf install cmake ninja-build
sudo dnf install ripgrep
sudo dnf install podman
sudo dnf install wget
sudo dnf install util-linux-user

chsh -s $(which zsh)

