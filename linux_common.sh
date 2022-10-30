#!/bin/bash -e

chsh -s $(which zsh)

wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/JetBrainsMono.zip 
mkdir /tmp/fonts
unzip -d /tmp/fonts /tmp/JetBrainsMono.zip
sudo mv /tmp/fonts/*.ttf /usr/share/fonts
fc-cache

curl -sfL git.io/antibody | sh -s - -b /usr/local/bin
