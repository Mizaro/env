#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Ubuntu-only guard
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
  zsh curl git vim ripgrep golang-go daemonize \
  fontconfig fonts-hack-ttf ca-certificates build-essential unzip

# GitHub CLI (official repo; optional)
if ! is_cmd gh; then
  (type -p wget >/dev/null || (sudo apt-get update && sudo apt-get install -y wget)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null < "$out" \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt-get update \
    && sudo apt-get install -y gh
fi

# WSL detection (informational)
if grep -qi microsoft /proc/version; then
  IS_WSL=1
else
  IS_WSL=0
fi

# --- Default shell: zsh ---
if is_cmd zsh && [[ "$SHELL" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)" || true
fi

# --- Fast Node Manager (fnm) ---
# Install fnm if missing
if [[ ! -d "${HOME}/.local/share/fnm" ]]; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

# Minimal, clean zsh initialization for fnm
# Keep PATH in zprofile (login), and eval in zshrc (interactive)
append_once "${HOME}/.zprofile" '# fnm (PATH only)'
append_once "${HOME}/.zprofile" 'export FNM_PATH="$HOME/.local/share/fnm"'
append_once "${HOME}/.zprofile" '[ -d "$FNM_PATH" ] && export PATH="$FNM_PATH:$PATH"'

append_once "${HOME}/.zshrc" '# fnm init (interactive)'
append_once "${HOME}/.zshrc" 'export FNM_PATH="$HOME/.local/share/fnm"'
append_once "${HOME}/.zshrc" '[ -d "$FNM_PATH" ] && eval "$(fnm env --use-on-cd)"'

# Make fnm available in current session
export FNM_PATH="$HOME/.local/share/fnm"
[ -d "$FNM_PATH" ] && export PATH="$FNM_PATH:$PATH"
if is_cmd fnm; then
  eval "$(fnm env --use-on-cd)"
  # Install an LTS Node on first run (do not set default to avoid global flips)
  if ! is_cmd node; then
    fnm install --lts || true
  fi
fi

# --- Neovim install (latest stable via tarball) ---
# Remove any older apt neovim to avoid confusion
sudo apt-get remove -y neovim || true

# Fetch latest stable tarball URL and install to /opt
LATEST_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
  | grep browser_download_url \
  | grep nvim-linux-x86_64.tar.gz \
  | cut -d '"' -f 4)
NVIM_TGZ="nvim-linux-x86_64.tar.gz"
curl -fL -o "$NVIM_TGZ" "$LATEST_URL"

sudo rm -rf /opt/nvim-linux-x86_64
sudo tar xzf "$NVIM_TGZ" -C /opt/
rm -f "$NVIM_TGZ"

NVIM_BIN="/opt/nvim-linux-x86_64/bin/nvim"
if [[ ! -x "$NVIM_BIN" ]]; then
  echo "Neovim installation failed." >&2
  exit 1
fi

# Only add PATH once, in zprofile (login). Do NOT also add to zshrc.
append_once "${HOME}/.zprofile" '# Neovim PATH'
append_once "${HOME}/.zprofile" 'export PATH="/opt/nvim-linux-x86_64/bin:$PATH"'

# --- Neovim config (kickstart) ---
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [[ -d "$CFG_DIR" ]]; then
  TS=$(date +%Y%m%d-%H%M%S)
  mv "$CFG_DIR" "${CFG_DIR}.bak-${TS}"
fi

git clone https://github.com/Mizaro/kickstart.nvim.git "$CFG_DIR"

# Headless plugin sync
"$NVIM_BIN" --headless "+Lazy! sync" +qa || true

# --- FZF (idempotent, zsh-only) ---
if [[ -d "${HOME}/.fzf" ]]; then
  (cd "${HOME}/.fzf" && git pull --ff-only)
else
  git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
fi
"${HOME}/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish --no-zsh
append_once "${HOME}/.zshrc" '# fzf (zsh)'
append_once "${HOME}/.zshrc" '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'

# --- Fonts cache refresh ---
fc-cache -fv >/dev/null || true

# --- Projects dir ---
mkdir -p "${HOME}/projects"

# --- Cleanup ---
sudo apt-get -y autoremove
sudo apt-get -y clean

echo "✅ Ubuntu setup complete. (WSL=${IS_WSL})"
