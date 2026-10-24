#!/bin/sh
# Portable contracts always. WSL live checks when HOME is the real host home.
set -eu
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$TEST_DIR/helpers.sh"
status=0

section() { printf '\n======== %s ========\n' "$1"; }

run() {
  if "$@"; then
    return 0
  fi
  status=1
  return 1
}

section "STATIC"
run python3 -m unittest discover -s "$TEST_DIR" -p 'test_*.py' -q || true

if command -v nvim >/dev/null 2>&1; then
  run nvim --clean --headless "+luafile $TEST_DIR/wezterm/test_config.lua" +qa || true
else
  echo "skip: wezterm stub (nvim missing)"
fi

if command -v zsh >/dev/null 2>&1; then
  run "$TEST_DIR/shell/test_zsh.sh" || true
else
  echo "skip: zsh"
fi

section "NVIM"
if command -v nvim >/dev/null 2>&1 && [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy" ]; then
  run nvim --headless "+luafile $TEST_DIR/nvim/contract.lua" || true
  run nvim --headless -i NONE "+luafile $TEST_DIR/nvim/reload.lua" || true
  run nvim --headless "+luafile $TEST_DIR/nvim/clipboard.lua" || true
  run env NVIM_AI_COMPLETION=off nvim --headless "+luafile $TEST_DIR/nvim/ai_off.lua" || true
else
  echo "skip: nvim runtime (nvim or lazy data dir missing)"
fi

section "TMUX"
if command -v tmux >/dev/null 2>&1 && [ -e "$HOME/.tmux.conf.local" ]; then
  run "$TEST_DIR/tmux/check.sh" || true
  run python3 "$ROOT/tmux/test_clipboard.py" -q || true
else
  echo "skip: tmux check (~/.tmux.conf.local missing)"
fi

section "BINS"
for cmd in nvim tmux rg fzf zoxide sesh lazygit; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd"
  else
    echo "warn: missing $cmd"
  fi
done
if command -v wezterm >/dev/null 2>&1 || [ -d /Applications/WezTerm.app ]; then
  ok "wezterm"
else
  echo "warn: missing wezterm"
fi
if command -v foot >/dev/null 2>&1; then
  ok "foot"
else
  echo "warn: missing foot"
fi
if [ -x "$HOME/.local/libexec/workmux" ]; then
  ok "native workmux"
else
  echo "warn: missing ~/.local/libexec/workmux"
fi

if [ -d "$ROOT/agents/skills/workmux/scripts" ]; then
  section "WORKMUX UNITS"
  run python3 -m unittest discover -s "$ROOT/agents/skills/workmux/scripts" -p 'test_*.py' -q || true
fi

if is_wsl_live; then
  section "WSL LIVE"
  run "$TEST_DIR/live/host_links.sh" || true
  run python3 "$TEST_DIR/live/zed_sync.py" || true
  run "$TEST_DIR/live/clip_test.sh" || true
else
  echo "skip: WSL live (not WSL or HOME is not the host home)"
fi

echo
if [ "$status" -ne 0 ]; then
  echo "FAIL: test/run.sh"
  exit 1
fi
echo "PASS: test/run.sh"
exit 0
