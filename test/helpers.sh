# Shared by test/run.sh and the shell checks. Source only.
# Callers set TEST_DIR to this directory first; $0 is the caller when sourced.
if [ -z "${TEST_DIR:-}" ] || [ ! -f "$TEST_DIR/helpers.sh" ]; then
  _here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  case "$_here" in
    */test) TEST_DIR=$_here ;;
    */test/*) TEST_DIR=$(CDPATH= cd -- "$_here/.." && pwd) ;;
    *) TEST_DIR=$_here ;;
  esac
fi
ROOT=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
export ROOT TEST_DIR DOTFILES_ROOT="$ROOT"

ok() { printf 'ok: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; }

real_home() {
  getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# Live host checks only when HOME is this machine's real home.
# Empty-HOME sandbox on WSL must not run WezTerm/Zed/clipboard GUI tests.
is_wsl_live() {
  is_wsl || return 1
  [ "${DOTFILES_TEST_PORTABLE:-}" = "" ] || return 1
  [ "$HOME" = "$(real_home)" ]
}
