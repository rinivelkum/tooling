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

echo "Linking configs from $REPO_ROOT"
echo

echo "nvim:"
link "$REPO_ROOT/nvim" "$HOME/.config/nvim"
echo

echo "terminal:"
link "$REPO_ROOT/terminal/.zshrc" "$HOME/.zshrc"
link "$REPO_ROOT/terminal/ghostty_config" "$HOME/.config/ghostty/config"
echo

echo "Done. Restart your shell and Ghostty to pick up changes."
