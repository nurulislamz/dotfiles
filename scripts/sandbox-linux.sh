#!/bin/sh
# Empty HOME: links, portable tmux load, unittest. No brew. No plugin downloads.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOME=$(mktemp -d)
export HOME
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
trap 'rm -rf "$HOME"' EXIT

mkdir -p "$HOME/.tmux-omt"
printf '%s\n' "# dummy oh-my-tmux" > "$HOME/.tmux-omt/.tmux.conf"

python3 "$ROOT/scripts/install.py"

python3 - "$HOME" "$ROOT" <<'PY'
from pathlib import Path
import sys

home, root = Path(sys.argv[1]), Path(sys.argv[2])
assert (home / ".config/nvim").resolve() == root / "nvim"
assert (home / ".config/wezterm").resolve() == root / "wezterm"
assert (home / ".config/foot").resolve() == root / "foot"
assert (home / ".zshrc").resolve() == root / "shell/.zshrc"
assert (home / ".tmux.conf.local").resolve() == root / "tmux/.tmux.conf.local"
assert (home / ".tmux.conf").resolve() == (home / ".tmux-omt/.tmux.conf")
assert (home / ".local/bin/sesh-switch").resolve() == root / "tmux/sesh-switch.sh"
print("ok: sandbox links")
PY

python3 -m unittest discover -s "$ROOT/scripts" -p 'test_*.py'

if command -v tmux >/dev/null 2>&1; then
  "$ROOT/tmux/check.sh"
else
  echo "skip: tmux not installed"
fi

echo "sandbox-linux passed"
