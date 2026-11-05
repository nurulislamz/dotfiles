#!/bin/sh
# Smart ctrl+hjkl for herdr, same rule as tmux/.tmux.conf.local: Neovim gets the key, else move panes.
# Usage: herdr-nav <left|down|up|right> <key>
# shortcut: at a Neovim edge the key stays in Neovim, use prefix+hjkl there; upgrade needs a Neovim plugin that knows herdr.
direction=$1 key=$2
herdr=${HERDR_BIN_PATH:-herdr}

info=$("$herdr" pane process-info --current) || exit 1
pane=$(printf '%s' "$info" | jq -r .result.process_info.pane_id)

pass=
printf '%s' "$info" | jq -r '.result.process_info.foreground_processes[].name' |
    grep -qE '^g?(view|n?vim?x?)(diff)?$' && pass=1
# ctrl+j is newline in agent prompts.
[ "$key" = ctrl+j ] && "$herdr" pane current | jq -e '.result.pane.agent' >/dev/null && pass=1

if [ -n "$pass" ]; then
    "$herdr" pane send-keys "$pane" "$key"
else
    "$herdr" pane focus --current --direction "$direction"
fi
