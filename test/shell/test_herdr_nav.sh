#!/bin/sh
# Checks herdr/nav.sh picks send-keys, focus or the sidebar, using fake herdr and tmux.
set -eu
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cat > "$dir/herdr" <<'FAKE'
#!/bin/sh
case "$1 $2" in
"pane process-info") printf '{"result":{"process_info":{"pane_id":"w1:p1","foreground_processes":[{"name":"%s"}]}}}' "$FG" ;;
"pane current") printf '{"result":{"pane":{"agent":%s}}}' "$AGENT" ;;
"pane focus") echo "herdr $*" >> "$LOG"; printf '{"result":{"focus":{"changed":%s}}}' "$CHANGED" ;;
*) echo "herdr $*" >> "$LOG" ;;
esac
FAKE
cat > "$dir/tmux" <<'FAKE'
#!/bin/sh
if [ "$1" = list-panes ]; then printf '%b' "$PANES"; else echo "tmux $*" >> "$LOG"; fi
FAKE
chmod +x "$dir/herdr" "$dir/tmux"
export HERDR_BIN_PATH="$dir/herdr" PATH="$dir:$PATH" LOG="$dir/log"
export CHANGED=true PANES='111 herdr %1\n011 herdr %2\n111 zsh %3\n'
script=$(dirname "$0")/../../herdr/nav.sh

check() { # fg agent direction key expected
    : > "$LOG"
    FG=$1 AGENT=$2 "$script" "$3" "$4"
    got=$(cat "$LOG")
    [ "$got" = "$5" ] || { echo "FAIL fg=$1 agent=$2 $4: got '$got', want '$5'"; exit 1; }
}
focus="herdr pane focus --current --direction"
check zsh null left ctrl+h "$focus left"
check nvim null left ctrl+h "herdr pane send-keys w1:p1 ctrl+h"
check vimdiff null up ctrl+k "herdr pane send-keys w1:p1 ctrl+k"
check nvim-helper null right ctrl+l "$focus right"
check zsh null down ctrl+j "$focus down"
check claude '"claude"' down ctrl+j "herdr pane send-keys w1:p1 ctrl+j"
check claude '"claude"' left ctrl+h "$focus left"

CHANGED=false
check zsh null left ctrl+h "$focus left
tmux send-keys -t %1 C-a w"
check zsh null right ctrl+l "$focus right"
PANES='111 herdr %1\n111 herdr %2\n'
check zsh null left ctrl+h "$focus left"
PANES='111 zsh %3\n'
check zsh null left ctrl+h "$focus left"
echo ok
