#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

link() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
    echo "  [skip]   $target already links here"
    return
  fi

  if [[ -e "$target" ]] || [[ -L "$target" ]]; then
    local backup="${target}.backup.${TIMESTAMP}"
    echo "  [backup] $target -> $backup"
    mv "$target" "$backup"
  fi

  echo "  [link]   $target -> $source"
  ln -s "$source" "$target"
}

brew_install() {
  local pkg="$1"
  if brew list --formula "$pkg" &>/dev/null; then
    echo "  [skip]   $pkg already installed"
  else
    echo "  [brew]   installing $pkg"
    brew install "$pkg"
  fi
}

echo "Linking configs from $REPO_ROOT"
echo

echo "nvim:"
link "$REPO_ROOT/nvim" "$HOME/.config/nvim"
echo

echo "terminal:"
link "$REPO_ROOT/terminal/.zshrc" "$HOME/.zshrc"
link "$REPO_ROOT/terminal/ghostty_config" "$HOME/.config/ghostty/config"
link "$REPO_ROOT/terminal/ripgreprc-dark" "$HOME/.config/ripgrep/ripgreprc-dark"
link "$REPO_ROOT/terminal/ripgreprc-light" "$HOME/.config/ripgrep/ripgreprc-light"
link "$REPO_ROOT/terminal/pgcli_config-dark" "$HOME/.config/pgcli/config-dark"
link "$REPO_ROOT/terminal/pgcli_config-light" "$HOME/.config/pgcli/config-light"
link "$REPO_ROOT/terminal/lazygit_config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
echo

echo "containers:"
link "$REPO_ROOT/colima/default/colima.yaml" "$HOME/.colima/default/colima.yaml"
echo

if command -v brew &>/dev/null; then
  echo "brew packages:"
  # Core tools configured by this repository.
  brew_install neovim
  brew_install ripgrep

  # Colima-backed Docker CLI setup.
  brew_install colima
  brew_install docker
  brew_install docker-buildx
  brew_install docker-compose

  # CLI tools referenced by .zshrc — installing pulls in fzf previews, eza/ls,
  # zoxide jumps, fd-backed fzf, and delta-rendered git diffs.
  brew_install bat
  brew_install eza
  brew_install fd
  brew_install fzf
  brew_install zoxide
  brew_install git-delta
  brew_install lazygit
  brew_install zsh-autosuggestions
  brew_install zsh-syntax-highlighting

  # Extras — not needed by .zshrc, just tools I want on every machine.
  brew_install pgcli
  echo

  echo "git-delta config:"
  git config --global core.pager "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.line-numbers true
  git config --global merge.conflictStyle "zdiff3"
  echo "  [done]   delta wired as git pager"
  echo
else
  echo "brew not found — skipping package installs and git-delta config."
  echo
fi

echo "Done. Restart your shell and Ghostty to pick up changes."
