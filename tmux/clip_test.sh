#!/bin/sh
# Boundary checks and the real Chrome Ctrl+C -> WezTerm/tmux Ctrl+V regression.
set -eu
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
python3 "$DIR/test_clipboard.py"
"$DIR/clip_paste_test.sh"
