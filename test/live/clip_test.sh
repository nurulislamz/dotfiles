#!/bin/sh
# WSL live: WezTerm resolved keys + Chrome/WezTerm clipboard regression.
set -eu
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$TEST_DIR/helpers.sh"

WEZ="$ROOT/wezterm/wezterm.lua"
CONF="$ROOT/tmux/.tmux.conf.local"
CLIP="$ROOT/tmux/clip.sh"
WEZTERM="/mnt/c/Program Files/WezTerm/wezterm.exe"

check() {
  [ "$2" = "$3" ] || { echo "FAIL: $1 expected $2, got $3"; exit 1; }
  echo "ok: $1 ($3)"
}

[ -x "$CLIP" ] || { echo "FAIL: clip.sh not executable"; exit 1; }
command -v clip.exe >/dev/null 2>&1 || { echo "FAIL: clip.exe missing"; exit 1; }
[ -x "$WEZTERM" ] || { echo "FAIL: wezterm.exe missing at $WEZTERM"; exit 1; }

check "wezterm tmux C-v send" 1 "$(grep -c 'SendString("\\x16")' "$WEZ" || true)"
check "wezterm paste-or-send" 2 "$(grep -c 'EmitEvent("paste-or-send")' "$WEZ" || true)"
check "wezterm keeps Ctrl+Shift+V" 1 "$(grep -c 'key = "v", mods = "CTRL|SHIFT"' "$WEZ" || true)"
check "wezterm smart Ctrl+C" 1 "$(grep -c 'EmitEvent("copy-or-interrupt")' "$WEZ" || true)"
resolved_paste=$("$WEZTERM" show-keys 2>/dev/null | grep -c 'CTRL[[:space:]]*V[[:space:]]*->[[:space:]]*PasteFrom' || true)
check "wezterm resolved no Ctrl+V PasteFrom" 0 "$resolved_paste"

check "tmux root C-v" 1 "$(grep -c 'bind -n C-v.*clip.sh paste-tmux' "$CONF" || true)"
check "tmux copy-mode C-c" 1 "$(grep -c 'copy-mode-vi C-c.*clip.sh copy' "$CONF" || true)"
check "tmux C-v not rectangle" 0 "$(grep -c 'copy-mode-vi C-v.*rectangle-toggle' "$CONF" || true)"
check "tmux mouse copy keeps mode" 2 "$(grep -c 'MouseDragEnd1Pane send-keys -X copy-pipe "' "$CONF" || true)"
check "tmux mouse not cancel" 0 "$(grep -c 'MouseDragEnd1Pane.*copy-pipe-and-cancel' "$CONF" || true)"
check "tmux paste not wl-paste" 0 "$(grep -cE '^bind.*wl-paste' "$CONF" || true)"

win_wez="/mnt/c/Users/nurul/.config/wezterm/wezterm.lua"
if [ -f "$win_wez" ]; then
  if cmp -s "$WEZ" "$win_wez"; then
    ok "Windows wezterm.lua matches repo"
  else
    echo "FAIL: Windows wezterm.lua differs from repo"
    exit 1
  fi
else
  echo "FAIL: missing $win_wez"
  exit 1
fi

# Needs an unlocked Windows desktop with WezTerm focused. Config contracts
# above already ran. Focus failures are environmental, not config drift.
set +e
"$ROOT/tmux/clip_paste_test.sh"
chrome=$?
set -e
if [ "$chrome" -eq 0 ]; then
  ok "chrome clipboard GUI"
else
  echo "warn: chrome clipboard GUI failed (needs unlocked focused WezTerm)"
fi
