softwareupdate --install-rosetta --agree-to-license
# defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerSwipeGesture -int 1
defaults write com.apple.AppleMultitouchTrackpad DragLock -bool false
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install fd zoxide fzf kubectl kubectx terraform gh go python@3.11 python@3.12 python@3.13 htop awscli cloc yq docker-machine docker coreutils git-lfs duckdb graphviz httrack git iterm2 neovim raycast azure-cli golangci-lint nvm
brew services start docker-machine
git lfs install
brew install --cask google-chrome || true
brew install --cask cursor slack visual-studio-code microsoft-azure-storage-explorer brave-browser rectangle jetbrains-toolbox whatsapp spotify sublime-text obsidian 
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mkdir ~/projects || true
sudo dscl . append /Groups/_developer GroupMembership $USER
mkdir ~/.nvm || true
cat <<'EOF' >> ~/.zshrc

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
EOF
