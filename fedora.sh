#!/bin/bash -e

sudo dnf install -y zsh
sudo dnf install -y neovim
sudo dnf install -y cmake ninja-build
sudo dnf install -y ripgrep exa bat
sudo dnf install -y podman
sudo dnf install -y wget
sudo dnf install -y util-linux-user
sudo dnf install -y python3 python3-pip
sudo dnf install -y fd-find

sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install -y brave-browser brave-keyring

./linux_common.sh
