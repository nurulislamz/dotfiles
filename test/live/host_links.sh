#!/bin/sh
set -eu
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$TEST_DIR/helpers.sh"

check_link() {
  dest=$1
  expect=$2
  got=$(readlink -f "$dest" 2>/dev/null || true)
  expect_abs=$(readlink -f "$expect")
  if [ "$got" = "$expect_abs" ]; then
    ok "$dest -> repo"
    return 0
  fi
  fail "$dest is $got (want $expect_abs)"
  return 1
}

status=0
check_link "$HOME/.config/nvim" "$ROOT/nvim" || status=1
check_link "$HOME/.config/wezterm" "$ROOT/wezterm" || status=1
check_link "$HOME/.config/foot" "$ROOT/foot" || status=1
check_link "$HOME/.zshrc" "$ROOT/shell/.zshrc" || status=1
check_link "$HOME/.tmux.conf.local" "$ROOT/tmux/.tmux.conf.local" || status=1
exit "$status"
