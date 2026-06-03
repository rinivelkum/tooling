# ============================================================================
#  .zshrc — Git/GitHub Integration & Useful Aliases
# ============================================================================

# ---------------------------------------------------------------------------
#  PATH & Environment
# ---------------------------------------------------------------------------
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"
# $LESS is read by the `less` binary on EVERY invocation (git, man, etc.), so
# these options apply everywhere — not just when you type `less` interactively.
#   -R  pass through color escape codes
#   -F  quit immediately if output fits one screen (git's default behavior)
#   --mouse --wheel-lines=1  smooth one-line-per-notch mouse-wheel scrolling
# Note: git defaults to LESS=FRX; we drop X (--no-init) because it conflicts
# with mouse tracking.
export LESS="-R -F --mouse --wheel-lines=1"
export LANG="en_US.UTF-8"

# ---------------------------------------------------------------------------
#  History
# ---------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS   # no duplicate entries
setopt HIST_REDUCE_BLANKS     # trim superfluous blanks
setopt SHARE_HISTORY          # share history across sessions
setopt APPEND_HISTORY         # append instead of overwrite
setopt INC_APPEND_HISTORY     # write immediately, not on exit

# ---------------------------------------------------------------------------
#  Completion
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive
zstyle ':completion:*' menu select                     # arrow-key menu

# ---------------------------------------------------------------------------
#  Zoxide — `z <partial>` jumps to frecent dirs, `zi` for fuzzy picker
# ---------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ---------------------------------------------------------------------------
#  Prompt — Git-aware, context-rich (lightweight, no plugins needed)
# ---------------------------------------------------------------------------
autoload -Uz vcs_info add-zsh-hook
zmodload zsh/datetime

# vcs_info — branch + staged/unstaged + untracked + ahead/behind
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr   '%F{green}●%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{yellow}✚%f'
zstyle ':vcs_info:git:*' formats       ' %F{cyan}(%b%c%u%m)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}(%b|%a%c%u%m)%f'

+vi-git-untracked() {
  if git rev-parse --is-inside-work-tree &>/dev/null \
     && git status --porcelain 2>/dev/null | grep -q '^??'; then
    hook_com[misc]+='%F{red}…%f'
  fi
}
+vi-git-ahead-behind() {
  local ahead behind
  ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
  behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
  (( ahead  > 0 )) && hook_com[misc]+=" %F{green}↑${ahead}%f"
  (( behind > 0 )) && hook_com[misc]+=" %F{red}↓${behind}%f"
}
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-ahead-behind

# Command duration — exposes $_cmd_duration when last command took ≥2s
_cmd_timer_start() { _cmd_timer=$EPOCHREALTIME }
_cmd_timer_stop() {
  if [[ -n $_cmd_timer ]]; then
    local elapsed=$(( EPOCHREALTIME - _cmd_timer ))
    unset _cmd_timer
    if (( elapsed >= 60 )); then
      _cmd_duration=$(printf '%dm%ds' $(( elapsed / 60 )) $(( elapsed % 60 )))
    elif (( elapsed >= 2 )); then
      _cmd_duration=$(printf '%.1fs' $elapsed)
    else
      _cmd_duration=''
    fi
  else
    _cmd_duration=''
  fi
}
add-zsh-hook preexec _cmd_timer_start
add-zsh-hook precmd  _cmd_timer_stop

# Context segments — each prints empty when not relevant
_ssh_segment()  { [[ -n $SSH_CONNECTION || -n $SSH_TTY ]] && echo "%F{red}[ssh]%f " }
_venv_segment() { [[ -n $VIRTUAL_ENV ]] && echo "%F{yellow}(${VIRTUAL_ENV:t})%f " }
_node_segment() {
  local dir=$PWD
  while [[ $dir != / && -n $dir ]]; do
    if [[ -f $dir/package.json ]]; then
      command -v node &>/dev/null && echo "%F{green}⬢ $(node --version 2>/dev/null)%f "
      return
    fi
    dir=${dir:h}
  done
}
_kube_segment() {
  [[ -d k8s || -d kubernetes || -f Chart.yaml || -f skaffold.yaml || -f kustomization.yaml ]] || return
  command -v kubectl &>/dev/null || return
  local ctx
  ctx=$(kubectl config current-context 2>/dev/null) || return
  [[ -n $ctx ]] && echo "%F{magenta}⎈ ${ctx}%f "
}
_aws_segment() {
  emulate -L zsh
  setopt null_glob
  local tfs=(*.tf)
  if (( ${#tfs} > 0 )) || [[ -d .terraform ]]; then
    [[ -n $AWS_PROFILE ]] && echo "%F{208}☁ ${AWS_PROFILE}%f "
  fi
}

# Refresh vcs_info + insert a blank line before each prompt
_prompt_precmd() { vcs_info; print '' }
add-zsh-hook precmd _prompt_precmd

setopt PROMPT_SUBST

# Two-line prompt
#   line 1: [ssh] ✗exit ⚙jobs (venv) ⬢node ⎈kube ☁aws  user:path (git ●✚…↑↓)
#   line 2: ❯
PROMPT='$(_ssh_segment)%(?..%F{red}✗ %?%f )%(1j.%F{yellow}⚙ %j%f .)$(_venv_segment)$(_node_segment)$(_kube_segment)$(_aws_segment)%(!.%F{red}.%F{green})%n%f:%F{blue}%~%f${vcs_info_msg_0_}
%F{magenta}❯%f '

# Right prompt — last command duration + clock
RPROMPT='%F{8}${_cmd_duration:+${_cmd_duration} }[%*]%f'

# ---------------------------------------------------------------------------
#  Git Aliases — everyday shortcuts
# ---------------------------------------------------------------------------
alias g="git"
alias gs="git status -sb"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -m"
alias gca="git commit --amend --no-edit"
alias gcam="git commit --amend"
alias gco="git checkout"
alias gsw="git switch"
alias gsc="git switch -c"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpu="git push -u origin HEAD"
alias gpl="git pull --rebase"
alias gf="git fetch --all --prune"
alias gl="git log --oneline --graph --decorate -20"
alias gla="git log --oneline --graph --decorate --all"
alias glp="git log --pretty=format:'%C(yellow)%h%Creset %C(cyan)%ad%Creset %s %C(green)(%an)%Creset' --date=short"
alias gd="git diff"
alias gds="git diff --staged"
alias gst="git stash"
alias gstp="git stash pop"
alias gstl="git stash list"
alias grb="git rebase"
alias grbi="git rebase -i"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"
alias gm="git merge"
alias gcp="git cherry-pick"
alias gbl="git blame"
alias gt="git tag"
alias grh="git reset HEAD"
alias grhh="git reset --hard HEAD"
alias gclean="git clean -fd"

# ---------------------------------------------------------------------------
#  GitHub CLI (gh) Aliases
# ---------------------------------------------------------------------------
alias ghpr="gh pr create --fill"
alias ghprl="gh pr list"
alias ghprv="gh pr view --web"
alias ghprc="gh pr checkout"
alias ghprm="gh pr merge --squash --delete-branch"
alias ghprs="gh pr status"
alias ghprd="gh pr diff"
alias ghprr="gh pr review"

alias ghi="gh issue create"
alias ghil="gh issue list"
alias ghiv="gh issue view --web"
alias ghis="gh issue status"
alias ghic="gh issue close"

alias ghr="gh repo view --web"
alias ghrc="gh repo clone"
alias ghrf="gh repo fork --clone"
alias ghrn="gh repo create"

alias ghrl="gh release list"
alias ghrelc="gh release create"

alias ghgist="gh gist create"
alias ghgistl="gh gist list"

alias ghw="gh workflow list"
alias ghwr="gh workflow run"
alias ghwv="gh run list"
alias ghwl="gh run view --log"
alias ghwa="gh run watch"

alias ghcs="gh copilot suggest"
alias ghce="gh copilot explain"

# ---------------------------------------------------------------------------
#  Git Functions — compound operations
# ---------------------------------------------------------------------------

# Quick commit: gac "message"
gac() {
  git add --all && git commit -m "$*"
}

# Quick commit & push: gacp "message"
gacp() {
  git add --all && git commit -m "$*" && git push
}

# Create branch, switch, push upstream
gnew() {
  git switch -c "$1" && git push -u origin "$1"
}

# Delete branch locally and remotely
gdel() {
  git branch -d "$1" 2>/dev/null
  git push origin --delete "$1" 2>/dev/null
  echo "Deleted branch: $1"
}

# Interactive rebase last N commits: greb 5
greb() {
  git rebase -i "HEAD~${1:-5}"
}

# Show what changed between current branch and main
gdiff-main() {
  local main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  : "${main_branch:=main}"
  git diff "${main_branch}...HEAD"
}

# Open PR for current branch in browser
ghpro() {
  gh pr view --web 2>/dev/null || gh pr create --fill --web
}

# Clone and cd into repo: ghclone user/repo
ghclone() {
  gh repo clone "$1" && cd "$(basename "$1" .git)"
}

# List recent branches sorted by last commit
gbr() {
  git for-each-ref --sort=-committerdate refs/heads/ \
    --format='%(color:yellow)%(refname:short)%(color:reset) %(color:green)(%(committerdate:relative))%(color:reset) %(subject)' \
    --count="${1:-10}"
}

# Undo last commit but keep changes staged
gundo() {
  git reset --soft HEAD~1
  echo "Last commit undone. Changes are staged."
}

# Sync current branch with main (rebase)
gsync() {
  local main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  : "${main_branch:=main}"
  git fetch origin && git rebase "origin/${main_branch}"
}

# ---------------------------------------------------------------------------
#  General Aliases
# ---------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
# Prefer eza when available (git status, icons, tree), else cross-platform ls
if command -v eza &>/dev/null; then
  alias ll="eza -lah --git --group-directories-first --icons=auto"
  alias la="eza -a --group-directories-first --icons=auto"
  alias l="eza --icons=auto"
  alias lt="eza --tree --level=2 --git-ignore --icons=auto"
elif ls --color=auto / &>/dev/null; then
  alias ll="ls -lAhF --color=auto"
  alias la="ls -A --color=auto"
  alias l="ls -CF --color=auto"
else
  alias ll="ls -lAhFG"
  alias la="ls -AG"
  alias l="ls -CFG"
fi
alias cls="clear"
alias mkdir="mkdir -pv"
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"
alias df="df -h"
alias du="du -sh"
alias grep="grep --color=auto"
# less options (mouse-wheel scroll + color) are set globally via $LESS in the
# PATH & Environment block above, so they apply to git, man, and every pager.
alias ports="lsof -i -P -n | grep LISTEN"
alias myip="curl -s ifconfig.me"
alias weather="curl -s wttr.in/?format=3"
alias path='echo $PATH | tr ":" "\n" | nl'
alias reload="source ~/.zshrc && echo '✓ .zshrc reloaded'"

# ---------------------------------------------------------------------------
#  Directory Bookmarks
# ---------------------------------------------------------------------------
alias projects="cd ~/Projects"
alias repos="cd ~/Repos"
alias desk="cd ~/Desktop"
alias dl="cd ~/Downloads"

# ---------------------------------------------------------------------------
#  Dev Shortcuts
# ---------------------------------------------------------------------------
alias py="python3"
alias pip="pip3"
alias serve="python3 -m http.server 8000"
alias json="python3 -m json.tool"
alias k="kubectl"
alias tf="terraform"
alias nr="npm run"
alias ni="npm install"

# ---------------------------------------------------------------------------
#  Colima & Docker
# ---------------------------------------------------------------------------
# Colima — lightweight container runtime for macOS
alias col="colima"
alias cols="colima start"
alias colst="colima stop"
alias colk="colima stop"
alias colr="colima start --force"
alias colls="colima list"
alias colssh="colima ssh"
alias colds="colima delete"
alias colstat="colima status"

# Docker — container management
alias d="docker"
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias drm="docker rm"
alias drmi="docker rmi"
alias dex="docker exec -it"
alias drun="docker run --rm -it"
alias dlogs="docker logs -f"
alias dstop="docker stop"
alias dstart="docker start"
alias dinsp="docker inspect"
alias dprune="docker system prune -f"
alias dprunea="docker system prune -af"
alias dvol="docker volume ls"
alias dnet="docker network ls"
alias dpull="docker pull"
alias dbuild="docker build -t"

# Docker Compose
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcr="docker compose restart"
alias dcl="docker compose logs -f"
alias dcps="docker compose ps"
alias dcb="docker compose build"
alias dcpull="docker compose pull"
alias dcexec="docker compose exec"

# ---------------------------------------------------------------------------
#  Extraction helper
# ---------------------------------------------------------------------------
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)  tar xjf "$1"   ;;
      *.tar.gz)   tar xzf "$1"   ;;
      *.tar.xz)   tar xJf "$1"   ;;
      *.bz2)      bunzip2 "$1"   ;;
      *.gz)       gunzip "$1"    ;;
      *.tar)      tar xf "$1"    ;;
      *.tbz2)     tar xjf "$1"   ;;
      *.tgz)      tar xzf "$1"   ;;
      *.zip)      unzip "$1"     ;;
      *.7z)       7z x "$1"      ;;
      *.rar)      unrar x "$1"   ;;
      *)          echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ---------------------------------------------------------------------------
#  GitHub CLI Completion (if gh is installed)
# ---------------------------------------------------------------------------
if command -v gh &>/dev/null; then
  eval "$(gh completion -s zsh)"
fi

# ---------------------------------------------------------------------------
#  Theme — Gruvbox Material, follows macOS appearance
# ---------------------------------------------------------------------------
# Detected on shell startup; run `theme auto` in an existing shell to re-sync
# after toggling macOS appearance, or `theme dark`/`theme light` to override.

_theme_dark() {
  export FZF_DEFAULT_OPTS="
    --color=bg+:#32302f,bg:#282828,spinner:#a9b665,hl:#7daea3
    --color=fg:#d4be98,header:#7daea3,info:#d8a657,pointer:#ea6962
    --color=marker:#ea6962,fg+:#ddc7a1,prompt:#d8a657,hl+:#7daea3
    --color=border:#45403d
  "
  export BAT_THEME="gruvbox-dark"
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc-dark"
}

_theme_light() {
  export FZF_DEFAULT_OPTS="
    --color=bg+:#ebdbb2,bg:#fbf1c7,spinner:#6c782e,hl:#45707a
    --color=fg:#654735,header:#45707a,info:#b47109,pointer:#c14a4a
    --color=marker:#c14a4a,fg+:#4f3829,prompt:#b47109,hl+:#45707a
    --color=border:#d5c4a1
  "
  export BAT_THEME="gruvbox-light"
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc-light"
}

# `defaults` returns "Dark" when dark mode is active; the key is unset (and the
# command exits non-zero) under light mode, so absence == light.
_theme_macos_is_dark() {
  [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]
}

theme() {
  case "${1:-auto}" in
    dark)  _theme_dark ;;
    light) _theme_light ;;
    auto)  _theme_macos_is_dark && _theme_dark || _theme_light ;;
    *)     echo "usage: theme [dark|light|auto]" >&2; return 1 ;;
  esac
}

theme auto

# ---------------------------------------------------------------------------
#  FZF Integration (if installed) — supercharges git workflows
# ---------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
  # Ctrl-R history, Ctrl-T file picker, Alt-C dir jump, plus completion
  eval "$(fzf --zsh)"

  # Use fd for file/dir listing if available — respects .gitignore, faster than find
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # Fuzzy checkout branch
  fbr() {
    local branch
    branch=$(git branch --all --sort=-committerdate | fzf --height 40% --reverse | sed 's/^[* ]*//' | sed 's|remotes/origin/||')
    [ -n "$branch" ] && git checkout "$branch"
  }

  # Fuzzy git log browser
  flog() {
    git log --oneline --graph --color=always | fzf --ansi --reverse --preview 'git show --color=always {2}'
  }

  # Fuzzy file add
  fadd() {
    local files
    files=$(git status -s | fzf -m --height 40% --reverse | awk '{print $2}')
    [ -n "$files" ] && echo "$files" | xargs git add && git status -sb
  }
fi

# ---------------------------------------------------------------------------
#  Ripgrep — search text & find files
# ---------------------------------------------------------------------------
if command -v rg &>/dev/null; then
  # --- Text search ---
  alias rg="rg --smart-case"            # case-insensitive unless uppercase used
  alias rgi="rg --ignore-case"           # always case-insensitive
  alias rgc="rg --case-sensitive"        # always case-sensitive
  alias rgh="rg --hidden"                # include hidden files/dirs
  alias rgu="rg --no-ignore"             # include gitignored files
  alias rga="rg --hidden --no-ignore"    # search everything
  alias rgw="rg --word-regexp"           # match whole words only
  alias rgf="rg --fixed-strings"         # literal string (no regex)
  alias rgl="rg -l"                      # list matching filenames only
  alias rgc0="rg -c"                     # show match count per file
  alias rgt="rg -t"                      # filter by type: rgt py "pattern"

  # --- Find files by name ---
  alias rgfind="rg --files | rg"         # find files by name
  alias rgfh="rg --files --hidden | rg"  # find files by name, incl hidden
  alias rgfa="rg --files --hidden --no-ignore | rg"  # find all files by name

  # --- Functions ---
  # Search in a specific file type: rgin py "pattern"
  rgin() {
    rg --smart-case -t "$1" -- "${@:2}"
  }

  # Search and replace (preview): rgsub "pattern" "replacement" [path]
  rgsub() {
    rg --smart-case -l "$1" ${3:-.} | xargs sed -n "s/$1/$2/gp"
  }

  # Search with context: rgctx 3 "pattern" (shows N lines around matches)
  rgctx() {
    rg --smart-case -C "$1" -- "${@:2}"
  }

  # FZF-powered interactive ripgrep (if fzf available)
  if command -v fzf &>/dev/null; then
    # Live grep: type and results update in real time
    rgfzf() {
      rg --smart-case --color=always --line-number -- '' "${1:-.}" |
        fzf --ansi --delimiter : \
            --preview 'bat --color=always --highlight-line {2} {1} 2>/dev/null || head -n $((${2:-1}+20)) {1}' \
            --preview-window 'up,60%,+{2}-10'
    }

    # Live file finder with preview
    rgff() {
      rg --files "${1:-.}" |
        fzf --preview 'bat --color=always {} 2>/dev/null || head -60 {}'
    }
  fi
fi

# ---------------------------------------------------------------------------
#  Zsh plugins — autosuggestions then syntax highlighting (highlighting MUST be last)
# ---------------------------------------------------------------------------
if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ---------------------------------------------------------------------------
#  End of .zshrc
# ---------------------------------------------------------------------------

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.local/bin:$PATH"
