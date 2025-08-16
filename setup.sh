#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [[ ! -f /etc/os-release ]]; then
  echo "This script supports Ubuntu only."; exit 1
fi
. /etc/os-release
if [[ "${NAME:-}" != "Ubuntu" ]]; then
  echo "Detected ${NAME:-unknown}. This script supports Ubuntu only."; exit 1
fi

# --- Helpers ---
is_cmd() { command -v "$1" >/dev/null 2>&1; }
append_once() { # append_once <file> <line>
  local file="$1" line="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fqx "$line" "$file" || echo "$line" >> "$file"
}

export DEBIAN_FRONTEND=noninteractive

# --- Update & base packages ---
sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get install -y \
  curl git vim zsh ripgrep golang-go daemonize dbus-user-session \
  fontconfig fonts-hack-ttf ca-certificates build-essential unzip

# (Optional) GitHub CLI (from official repo; safer than universe on some images)
if ! is_cmd gh; then
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
fi

# WSL detection (informational)
if grep -qi microsoft /proc/version; then
  IS_WSL=1
else
  IS_WSL=0
fi

# --- Fast Node Manager (fnm) ---
if [[ ! -d "${HOME}/.local/share/fnm" ]]; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

# zsh init for fnm (use-on-cd = auto switch per project)
append_once "${HOME}/.zshrc"    'FNM_PATH="$HOME/.local/share/fnm"; [ -d "$FNM_PATH" ] && export PATH="$FNM_PATH:$PATH" && eval "$(fnm env --use-on-cd)"'
append_once "${HOME}/.zprofile" 'FNM_PATH="$HOME/.local/share/fnm"; [ -d "$FNM_PATH" ] && export PATH="$FNM_PATH:$PATH"'

# Ensure fnm is on PATH for this session
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$FNM_PATH:$PATH"
if [ -d "$FNM_PATH" ]; then
  eval "$(fnm env --use-on-cd)"
fi

# Install a Node LTS (if none installed)
if is_cmd fnm && ! is_cmd node; then
  fnm install --lts
fi

# --- Neovim install (latest stable via tarball) ---
# Remove any older Neovim package first
sudo apt-get remove -y neovim || true

# Download latest stable tarball from GitHub
LATEST_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep browser_download_url | grep nvim-linux-x86_64.tar.gz | cut -d '"' -f 4)
NVIM_TGZ="nvim-linux-x86_64.tar.gz"
curl -fL -o "$NVIM_TGZ" "$LATEST_URL"

# Extract to /opt
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar xzf "$NVIM_TGZ" -C /opt/
rm -f "$NVIM_TGZ"

NVIM_BIN="/opt/nvim-linux-x86_64/bin/nvim"
if [[ ! -x "$NVIM_BIN" ]]; then
  echo "Neovim installation failed." >&2
  exit 1
fi

# Put Neovim on PATH for zsh
append_once "${HOME}/.zprofile" 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"'
append_once "${HOME}/.zshrc"    'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"'

# --- Neovim config (kickstart) ---
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [[ -d "$CFG_DIR" ]]; then
  # Backup existing config once
  TS=$(date +%Y%m%d-%H%M%S)
  mv "$CFG_DIR" "${CFG_DIR}.bak-${TS}"
fi
git clone https://github.com/Mizaro/kickstart.nvim.git "$CFG_DIR"

# Lazy sync headless (using absolute path)
"$NVIM_BIN" --headless "+Lazy! sync" +qa || true

# --- FZF (idempotent install) ---
if [[ -d "${HOME}/.fzf" ]]; then
  (cd "${HOME}/.fzf" && git pull --ff-only)
else
  git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
fi
# Use installer but avoid repeated RC edits; we add our own lines
"${HOME}/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish --no-zsh
# Add sourcing lines once (fzf provides these files)
append_once "${HOME}/.bashrc"  '[ -f ~/.fzf.bash ] && source ~/.fzf.bash'
append_once "${HOME}/.zshrc"   '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'

# --- Fonts cache refresh (since we installed fonts) ---
fc-cache -fv >/dev/null || true

# --- Projects dir ---
mkdir -p "${HOME}/projects"

# --- Optional: make zsh default shell (comment out if undesired) ---
if command -v zsh >/dev/null 2>&1 && [[ "$SHELL" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)" || true
fi

# --- Cleanup ---
sudo apt-get -y autoremove
sudo apt-get -y clean

echo "✅ Ubuntu setup complete. (WSL=${IS_WSL})"
