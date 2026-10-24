#!/bin/sh
# Shim: portable tmux check lives in test/tmux/check.sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$ROOT/test/tmux/check.sh"
