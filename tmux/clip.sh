#!/usr/bin/env bash
# Windows clipboard is the source of truth for WezTerm-on-WSL.
set -euo pipefail
case "${1:-}" in
  copy)
    # Ignore blank mouse selections without replacing the existing clipboard.
    IFS= read -r -d '' text || true
    [[ "$text" == *[![:space:]]* ]] || exit 0
    printf '%s' "$text" | clip.exe
    ;;
  paste)
    # A one-character separator line is not a command. Chrome's plain-text
    # copy of an inline breadcrumb is "Roadmap\n/\nFrontend Beginner". tmux
    # paste-buffer turns those newlines into carriage returns, and the shell
    # executes "/" by itself. Join that separator back into the phrase.
    # Trailing newlines on real multiline pastes stay; the sentinel keeps
    # command substitution from eating them.
    text=$(powershell.exe -NoProfile -NonInteractive -Command '$ErrorActionPreference = "Stop"; [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false); [Console]::Write((Get-Clipboard -Raw))' | tr -d '\r' && printf x)
    text=${text%x}
    text=${text//$'\n/\n'/\/}
    printf '%s' "$text"
    ;;
  paste-tmux)
    "$0" paste | tmux load-buffer -
    tmux paste-buffer -p
    ;;
  *)
    echo "usage: clip.sh copy|paste|paste-tmux" >&2
    exit 2
    ;;
esac
