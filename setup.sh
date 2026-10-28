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
link "$REPO_ROOT/terminal/pgcli_config" "$HOME/.config/pgcli/config"
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

  # Python runtime (includes pip and venv), plus uv for project dependencies
  # and isolated CLI tools via `uv tool install` / `uvx`.
  brew_install python
  brew_install uv

  # Extras — not needed by .zshrc, just tools I want on every machine.
  brew_install go
  brew_install pgcli
  brew_install rustup
  echo

  echo "python:"
  echo "  [done]   Python, pip, venv, and uv installed"
  echo "  [usage]  Create a project environment: python3 -m venv .venv"
  echo "  [usage]  Activate it: source .venv/bin/activate"
  echo "  [usage]  Install dependencies: python -m pip install <package>"
  echo "  [usage]  Run an isolated CLI: uvx <tool>"
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
  # attached to. Light is the only supported theme, so state it outright. It
  # picks every diff color from here: pale red and green backgrounds, which read
  # better than the full-strength ANSI slots a profile maps. Syntax highlighting
  # inside a diff still follows the profile, since delta takes $BAT_THEME as its
  # --syntax-theme default and .zshrc exports it as ansi.
  git config --global delta.light true
  git config --global merge.conflictStyle "zdiff3"
  echo "  [done]   delta wired as git pager"
  echo
else
  echo "brew not found — skipping package installs and git-delta config."
  echo
fi

echo "node / nvm:"
(
  # Match .zshrc's lazy loader, even when XDG_CONFIG_HOME is set.
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    echo "  [skip]   nvm already installed"
  else
    # Resolve the latest published release without requiring a JSON parser.
    nvm_release_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/nvm-sh/nvm/releases/latest)"
    nvm_version="${nvm_release_url##*/}"
    if [[ ! "$nvm_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "  [error]  could not determine the latest nvm release" >&2
      exit 1
    fi
    echo "  [nvm]    installing nvm $nvm_version"
    mkdir -p "$NVM_DIR"
    # .zshrc is managed here; prevent the installer from appending eager loading.
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh" | PROFILE=/dev/null NVM_INSTALL_VERSION="$nvm_version" bash
  fi

  # nvm is not compatible with strict shell options. Relax them only in this
  # subshell and explicitly propagate failures back to the setup script.
  set +eu
  . "$NVM_DIR/nvm.sh" --no-use || exit 1

  if default_version="$(nvm version default)" && [[ "$default_version" != "N/A" ]]; then
    echo "  [skip]   default Node.js version already installed ($default_version)"
  else
    echo "  [nvm]    installing Node.js LTS"
    nvm install --lts || exit 1
    # Pin the resolved version so .zshrc can find it without loading nvm.
    nvm alias default "$(nvm current)" || exit 1
  fi
)
echo

echo "Done. Restart your shell and terminal to pick up changes."
