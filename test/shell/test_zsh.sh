#!/bin/sh
set -eu
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$TEST_DIR/helpers.sh"

ZSHRC="$ROOT/shell/.zshrc"
zsh -n "$ZSHRC"
ok "zsh -n"

HOME=$(mktemp -d)
export HOME
trap 'rm -rf "$HOME"' EXIT
mkdir -p "$HOME/.local/bin"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$HOME/.local/bin/workmux"
chmod +x "$HOME/.local/bin/workmux"
printf '%s\n' "# dummy p10k" > "$HOME/.p10k.zsh"
export PATH="$HOME/.local/bin:/usr/bin:/bin"

zsh -f -c "
  setopt NO_GLOBAL_RCS
  source '$ZSHRC'
  [[ \":\$PATH:\" == *\":\$HOME/.local/bin:\"* ]] || { echo 'FAIL: PATH missing ~/.local/bin'; exit 1; }
  [[ \"\$KEYTIMEOUT\" == 1 ]] || { echo 'FAIL: KEYTIMEOUT'; exit 1; }
  alias agy | grep -q dangerously-skip-permissions || { echo 'FAIL: agy alias'; exit 1; }
  alias wm | grep -q workmux || { echo 'FAIL: wm alias'; exit 1; }
  bindkey | grep -F -q '13;2u' || { echo 'FAIL: CSI-u bindkey'; exit 1; }
  echo ok: zsh isolated source
"
