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

# --- Zsh as default (idempotent) ---
if is_cmd zsh; then
  ZSH_PATH="$(command -v zsh)"
  if [[ "${SHELL:-}" != "$ZSH_PATH" ]]; then
    chsh -s "$ZSH_PATH" "$USER" || true
  fi
fi

# --- Oh My Zsh (idempotent) ---
[ -f "${HOME}/.zshrc" ] || rm -f "${HOME}/.zshrc"
# We should check ~/.oh-my-zsh instead.
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=no \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Ensure .zshrc exists (kept if present; we do NOT overwrite it)
[ -f "${HOME}/.zshrc" ] || touch "${HOME}/.zshrc"


# --- Fast Node Manager (fnm) ---
if [[ ! -d "${HOME}/.local/share/fnm" ]]; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

append_once "${HOME}/.zprofile" '# fnm (PATH only)'
append_once "${HOME}/.zprofile" 'export FNM_PATH="$HOME/.local/share/fnm"'
append_once "${HOME}/.zprofile" '[ -d "$FNM_PATH" ] && export PATH="$FNM_PATH:$PATH"'

append_once "${HOME}/.zshrc" '# fnm init (interactive)'
append_once "${HOME}/.zshrc" 'export FNM_PATH="$HOME/.local/share/fnm"'
append_once "${HOME}/.zshrc" '[ -d "$FNM_PATH" ] && eval "$(fnm env --use-on-cd)"'

export FNM_PATH="$HOME/.local/share/fnm"
[ -d "$FNM_PATH" ] && export PATH="$FNM_PATH:$PATH"
if is_cmd fnm; then
  eval "$(fnm env --use-on-cd)"
  if ! is_cmd node; then
    fnm install --lts || true
  fi
fi

# --- Neovim install (latest stable via snap for now) ---
sudo apt-get remove -y neovim || true
sudo snap install nvim --classic || true

append_once "${HOME}/.zprofile" '# Neovim PATH'
append_once "${HOME}/.zprofile" 'export PATH="/snap/bin:$PATH"'

# --- Neovim config (kickstart) ---
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [[ -d "$CFG_DIR" ]]; then
  TS=$(date +%Y%m%d-%H%M%S)
  mv "$CFG_DIR" "${CFG_DIR}.bak-${TS}"
fi

git clone https://github.com/Mizaro/kickstart.nvim.git "$CFG_DIR"

# Headless plugin sync
nvim --headless "+Lazy! sync" +qa || true

# --- FZF (idempotent, zsh-only) ---
if [[ -d "${HOME}/.fzf" ]]; then
  (cd "${HOME}/.fzf" && git pull --ff-only)
else
  git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
fi
"${HOME}/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish --no-zsh
append_once "${HOME}/.zshrc" '# fzf (zsh)'
append_once "${HOME}/.zshrc" '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
append_once "${HOME}/.zshrc" '# Set up fzf key bindings and fuzzy completion'
append_once "${HOME}/.zshrc" 'source <(fzf --zsh)'

# --- Fonts cache refresh ---
fc-cache -fv >/dev/null || true

# --- Projects dir ---
mkdir -p "${HOME}/projects"

# --- Cleanup ---
sudo apt-get -y autoremove
sudo apt-get -y clean

echo "✅ Ubuntu setup complete. (WSL=${IS_WSL})"
