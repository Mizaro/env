#!/bin/bash
set -e

# Detect the OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

# Update and install necessary packages
if [ "$OS" = "Ubuntu" ]; then
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y vim zsh git openssh-server npm curl daemonize dbus-user-session fontconfig golang-go fonts-powerline ripgrep gh
    sudo apt-get install -y fc-cache fonts-hack-ttf
elif [[ "$OS" == "Fedora Linux" ]]; then
    sudo dnf update -y
    sudo dnf install -y vim zsh git openssh-server npm curl daemonize fontconfig golang-go powerline-fonts ripgrep gh neovim python3-neovim
fi

# Setup commands that are common across both distributions

## Fast Node Manager
curl -fsSL https://fnm.vercel.app/install | bash

## Download and install Neovim
if [ "$OS" = "Ubuntu" ]; then
    curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
    sudo tar xzvf nvim-linux64.tar.gz -C /opt/
    echo 'export PATH=$PATH:/opt/nvim-linux64/bin' >> ~/.profile
elif [[ "$OS" == "Fedora Linux" ]]; then
    # Already Done in dnf install
fi

## Setup Neovim
rm -rf ~/.local/share/nvim/lazy
rm -rf ~/.config/nvim
git clone https://github.com/Mizaro/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
nvim --headless "+Lazy! sync" +qa

## Clone and install Powerline Fonts
git clone https://github.com/powerline/fonts.git
(cd fonts && ./install.sh)

## FZF installation
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --update-rc

# Configure PATH and environment settings remains largely the same
# Make sure to adjust paths and environment variables as necessary for your setup

# Create projects directory
mkdir -p ~/projects

# Cleanup
if [ "$OS" = "Ubuntu" ]; then
    sudo apt-get autoremove -y
elif [[ "$OS" == "Fedora Linux" ]]; then
    sudo dnf autoremove -y
fi
