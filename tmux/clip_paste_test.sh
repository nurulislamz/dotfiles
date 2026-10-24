#!/bin/sh
# Uses temporary windows; requires an unlocked Windows desktop with tmux attached.
set -eu
exec python3 "$(dirname -- "$0")/test_chrome_clipboard.py"
