#! /bin/bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew update
brew tap homebrew/cask

brew install --cask visual-studio-code
brew install --cask iterm2
brew install --cask docker
brew install nvim
brew install zsh
brew install ripgrep exa bat
brew install nodejs
brew install wget
brew install cmake ninja
brew install antibody

wget -O /tmp/jetbrainsmono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/JetBrainsMono.zip
unzip -d /tmp /tmp/jetbrainsmono.zip
sudo mv /tmp/*.ttf /Library/Fonts
