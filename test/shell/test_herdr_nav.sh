#!/bin/sh
# Checks herdr/nav.sh picks send-keys or focus, using a fake herdr.
set -eu
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cat > "$dir/herdr" <<'FAKE'
#!/bin/sh
case "$1 $2" in
"pane process-info") printf '{"result":{"process_info":{"pane_id":"w1:p1","foreground_processes":[{"name":"%s"}]}}}' "$FG" ;;
"pane current") printf '{"result":{"pane":{"agent":%s}}}' "$AGENT" ;;
*) echo "$*" ;;
esac
FAKE
chmod +x "$dir/herdr"
export HERDR_BIN_PATH="$dir/herdr"
script=$(dirname "$0")/../../herdr/nav.sh

check() { # fg agent direction key expected
    got=$(FG=$1 AGENT=$2 "$script" "$3" "$4")
    [ "$got" = "$5" ] || { echo "FAIL fg=$1 agent=$2 $4: got '$got', want '$5'"; exit 1; }
}
check zsh null left ctrl+h "pane focus --current --direction left"
check nvim null left ctrl+h "pane send-keys w1:p1 ctrl+h"
check vimdiff null up ctrl+k "pane send-keys w1:p1 ctrl+k"
check nvim-helper null right ctrl+l "pane focus --current --direction right"
check zsh null down ctrl+j "pane focus --current --direction down"
check claude '"claude"' down ctrl+j "pane send-keys w1:p1 ctrl+j"
check claude '"claude"' left ctrl+h "pane focus --current --direction left"
echo ok
