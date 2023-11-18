#!/bin/bash

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y vim zsh git openssh-server npm curl daemonize dbus-user-session fontconfig

# Install specific versions or packages from URLs
sudo apt-get install -y fc-cache fonts-powerline fonts-hack-ttf
## Fast Node Manager
curl -fsSL https://fnm.vercel.app/install | bash
## Golang
curl -LO https://dl.google.com/go/go1.20.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz
## ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
sudo dpkg -i ripgrep_13.0.0_amd64.deb

# Download and install Neovim
curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
sudo tar xzvf nvim-linux64.tar.gz -C /opt/
echo 'export PATH=$PATH:/opt/nvim-linux64/bin' >> ~/.profile

## Setup Neovim
rm -rf ~/.local/share/nvim/lazy
rm -rf ~/.config/nvim
git clone https://github.com/Mizaro/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
nvim --headless "+Lazy! sync" +qa

# Clone and install Powerline Fonts
git clone https://github.com/powerline/fonts.git
(cd fonts && ./install.sh)

# FZF installation
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --update-rc)

# Configure PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export PATH=$PATH:/home/giladl/go/bin' >> ~/.profile
echo 'export PATH=$PATH:/home/giladl/.local/bin' >> ~/.profile
source ~/.profile

# Create projects directory
mkdir ~/projects

# Cleanup
sudo apt-get autoremove -y

