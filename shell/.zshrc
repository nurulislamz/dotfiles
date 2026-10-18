# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

[ -d "$ZSH" ] && source "$ZSH/oh-my-zsh.sh"

# User configuration & PATH
export PATH="$HOME/.local/bin:$PATH"

# Vi-style line editing
bindkey -v
export KEYTIMEOUT=1

# Show insert/command mode in the prompt when p10k is not loaded
if [[ ! -f "$HOME/.p10k.zsh" ]]; then
  function zle-keymap-select {
    if [[ $KEYMAP == vicmd ]]; then
      PROMPT='%F{yellow}(cmd)%f %n@%m:%~%# '
    else
      PROMPT='%F{green}(ins)%f %n@%m:%~%# '
    fi
    zle reset-prompt
  }
  zle -N zle-keymap-select
  PROMPT='%F{green}(ins)%f %n@%m:%~%# '
fi

# History search with Ctrl-r / Ctrl-p / Ctrl-n
bindkey '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward
bindkey -M vicmd '^P' history-beginning-search-backward
bindkey -M vicmd '^N' history-beginning-search-forward

# Word ops on Ctrl
for keymap in emacs viins; do
  bindkey -M $keymap '^H'     backward-kill-word
  bindkey -M $keymap '\e^?'   backward-kill-word
  bindkey -M $keymap '\e^H'   backward-kill-word
  bindkey -M $keymap '^[[3;5~' kill-word
  bindkey -M $keymap '^[[1;5C' forward-word
  bindkey -M $keymap '^[[1;5D' backward-word
  bindkey -M $keymap '^[[1;5A' beginning-of-line
  bindkey -M $keymap '^[[1;5B' end-of-line
done

# Fallback tab completion if oh-my-zsh not present
if ! (( $+functions[compinit] )); then
  autoload -Uz compinit
  compinit
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
  zstyle ':completion:*' menu select
  zstyle ':completion:*' list-colors ''
fi

# Better history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

export nviminit="~/.config/nvim/init.lua"

# Go
if command -v go >/dev/null 2>&1; then
  export PATH="$PATH:$(go env GOPATH)/bin"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Homebrew: Apple Silicon, Intel Mac, Linuxbrew
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done

[ -s "$HOME/.openclaw/completions/openclaw.zsh" ] && . "$HOME/.openclaw/completions/openclaw.zsh"
[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

if [[ -n "$TMUX" && -z "$TASK_FILE" ]]; then
  export TASK_FILE="$(tmux-tasklog path)"
fi

# Antigravity CLI auto-approve permissions
alias agy="agy --dangerously-skip-permissions"
alias agy-box="agy-box --dangerously-skip-permissions"
alias open="$HOME/.local/bin/open"

# Command Code API key (used by opencode's commandcode provider)
[ -f "$HOME/.secrets/commandcode.env" ] && source "$HOME/.secrets/commandcode.env"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# WezTerm semantic zones (wezterm-replay needs OSC 133 command output)
[[ -n "$WEZTERM_PANE" && -f ~/.config/wezterm/wezterm.sh ]] && source ~/.config/wezterm/wezterm.sh

# Shift+Enter newline (matches WezTerm / Windows Terminal CSI-u \x1b[13;2u)
insert-newline() { LBUFFER+=$'\n' }
zle -N insert-newline
bindkey '^[[13;2u' insert-newline
bindkey -M vicmd '^[[13;2u' insert-newline 2>/dev/null || true

# Accept autosuggestion with Ctrl+Space (^  and ^@ for terminal NUL compatibility)
bindkey '^ ' autosuggest-accept
bindkey '^@' autosuggest-accept
bindkey -M viins '^ ' autosuggest-accept
bindkey -M viins '^@' autosuggest-accept

# Prevent accidental shell exit on Ctrl+D
setopt IGNORE_EOF

# Fuzzy finder & directory jumping
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Workmux: official installation recommendations.
alias wm='workmux'
if command -v workmux >/dev/null 2>&1; then
  eval "$(workmux completions zsh)"
fi

# Bare `tmux` attaches the last session; create only when none exist.
tmux() {
  if (( $# )); then
    command tmux "$@"
    return
  fi
  if [[ -n "$TMUX" ]]; then
    command tmux switch-client -l
    return
  fi
  command tmux attach || command tmux new-session
}
