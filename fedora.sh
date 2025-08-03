#!/bin/bash -e

sudo dnf install -y zsh fish
sudo dnf install -y neovim
sudo dnf install -y cmake ninja-build
sudo dnf install -y ripgrep eza bat zoxide
sudo dnf install -y podman
sudo dnf install -y wget
sudo dnf install -y util-linux-user
sudo dnf install -y python3 python3-pip
sudo dnf install -y fd-find
sudo dnf install -y fzf
sudo dnf install -y clang lldb gdb
sudo dnf install -y tmux
sudo dnf install -y stow

sudo dnf install dnf-plugins-core

sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo dnf install -y brave-browser brave-keyring

./linux_common.sh
