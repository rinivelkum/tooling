#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Which terminal this machine is set up for. Only decides whether the Ghostty
# config gets linked. .zshrc and nvim pick their palette per shell, so both
# terminals stay usable whichever variant was installed.
VARIANT_FILE="$HOME/.config/tooling/variant"

# An argument switches the machine over, and is the only thing that lets this
# script remove a link an earlier run made. Without one the last recorded choice
# wins, so re-running from the other terminal (or over ssh, where TERM_PROGRAM is
# unset) cannot undo the setup. TERM_PROGRAM only decides the very first run.
if [[ -n "${1:-}" ]]; then
  VARIANT="$1"
  VARIANT_EXPLICIT=1
else
  VARIANT_EXPLICIT=0
  if [[ -r "$VARIANT_FILE" ]]; then
    VARIANT="$(<"$VARIANT_FILE")"
  elif [[ "${TERM_PROGRAM:-}" == ghostty ]]; then
    VARIANT=ghostty
  else
    VARIANT=terminal
  fi
fi
case "$VARIANT" in
  terminal | ghostty) ;;
  *)
    echo "usage: ${0##*/} [terminal|ghostty]" >&2
    exit 2
    ;;
esac

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

# Drops a link this script used to create once its target is gone from the repo.
# Restricted to dangling symlinks, so a real file at that path is never touched.
unlink_stale() {
  local target="$1"

  if [[ -L "$target" ]] && [[ ! -e "$target" ]]; then
    echo "  [rm]     $target -> $(readlink "$target") (gone)"
    rm "$target"
  fi
}

# Drops a link this script created once the chosen variant no longer wants it.
# Only reached on an explicit variant argument, and restricted to links pointing
# into the repo, so neither a bare re-run nor a hand-written config at that path
# loses anything.
unlink_ours() {
  local target="$1"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$REPO_ROOT"/* ]]; then
    echo "  [rm]     $target -> $(readlink "$target")"
    rm "$target"
  fi
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

echo "Linking configs from $REPO_ROOT ($VARIANT variant)"
mkdir -p "$(dirname "$VARIANT_FILE")"
printf '%s\n' "$VARIANT" > "$VARIANT_FILE"
echo

echo "nvim:"
link "$REPO_ROOT/nvim" "$HOME/.config/nvim"
echo

echo "terminal:"
link "$REPO_ROOT/terminal/.zshrc" "$HOME/.zshrc"
if [[ "$VARIANT" == ghostty ]]; then
  link "$REPO_ROOT/terminal/ghostty_config" "$HOME/.config/ghostty/config"
elif (( VARIANT_EXPLICIT )); then
  echo "  [skip]   ghostty config"
  unlink_ours "$HOME/.config/ghostty/config"
else
  echo "  [skip]   ghostty config (run with 'ghostty' to link it)"
fi
link "$REPO_ROOT/terminal/ripgreprc-gruvbox" "$HOME/.config/ripgrep/ripgreprc-gruvbox"
link "$REPO_ROOT/terminal/pgcli_config" "$HOME/.config/pgcli/config"
link "$REPO_ROOT/terminal/pgcli_config-gruvbox" "$HOME/.config/pgcli/config-gruvbox"
link "$REPO_ROOT/terminal/lazygit_config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
# Left behind by earlier runs: dark is gone as a theme, and the -light pair was
# renamed to -gruvbox once ANSI became the other light variant.
unlink_stale "$HOME/.config/ripgrep/ripgreprc-dark"
unlink_stale "$HOME/.config/pgcli/config-dark"
unlink_stale "$HOME/.config/ripgrep/ripgreprc-light"
unlink_stale "$HOME/.config/pgcli/config-light"
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
  brew_install go
  brew_install pgcli
  brew_install rustup
  echo

  echo "rust toolchain:"
  # Without a default toolchain the cargo/rustc shims refuse to run. Test
  # settings.toml rather than `rustup default`, which falls back to reporting
  # stable and exits 0 even when nothing is configured or installed.
  if grep -q '^default_toolchain' "${RUSTUP_HOME:-$HOME/.rustup}/settings.toml" 2>/dev/null; then
    echo "  [skip]   default toolchain already set ($(rustup default))"
  else
    echo "  [rustup] installing stable toolchain"
    rustup default stable
  fi
  echo

  echo "git-delta config:"
  git config --global core.pager "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.line-numbers true
  # delta's own detection queries the terminal, which races with the pager it is
  # attached to. Light is the only supported theme, so state it outright. This
  # still backs everything the ansi-palette feature below leaves alone, blame and
  # merge-conflict styles among them.
  git config --global delta.light true
  # Diff colors on the terminal's own ANSI palette. Only applies when
  # DELTA_FEATURES names this feature, which `theme ansi` in .zshrc does and
  # `theme gruvbox` does not, so Ghostty keeps delta's pale light tints.
  #
  # Syntax highlighting is absent here on purpose: delta takes $BAT_THEME as the
  # default for --syntax-theme, so it already follows whichever palette `theme`
  # selected.
  #
  # `syntax` keeps the highlighted foreground and colors only the background. The
  # ANSI slots are full-strength text colors rather than the pale tints delta
  # picks for a light terminal, so changed lines read as solid red and green
  # bands. That is the cost of letting the profile own them.
  git config --global delta.ansi-palette.minus-style "syntax red"
  git config --global delta.ansi-palette.plus-style "syntax green"
  git config --global delta.ansi-palette.minus-emph-style "syntax brightred"
  git config --global delta.ansi-palette.plus-emph-style "syntax brightgreen"
  # Without these three the line-number columns stay on delta's own 256-cube
  # indices (88, 28) and a fixed #444444, none of which the profile maps.
  git config --global delta.ansi-palette.line-numbers-minus-style "red"
  git config --global delta.ansi-palette.line-numbers-plus-style "green"
  git config --global delta.ansi-palette.line-numbers-zero-style "brightblack"
  git config --global merge.conflictStyle "zdiff3"
  echo "  [done]   delta wired as git pager"
  echo
else
  echo "brew not found — skipping package installs and git-delta config."
  echo
fi

echo "Done. Restart your shell and terminal to pick up changes."
