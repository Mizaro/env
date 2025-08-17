softwareupdate --install-rosetta --agree-to-license
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install fzf kubectl kubectx terraform gh go python@3.11 python@3.12 python@3.13 htop awscli session-manager-plugin cloc yq docker-machine docker coreutils aws-iam-authenticator git-lfs duckdb graphviz httrack git gh iterm2 neovim raycast

brew services start docker-machine
git lfs install
brew install --cask google-chrome || true
brew install --cask cursor slack visual-studio-code
brew install --cask rectangle jetbrains-toolbox whatsapp spotify sublime-text obsidian warp stremio 
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mkdir ~/projects || true
