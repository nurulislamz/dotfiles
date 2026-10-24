#!/bin/sh
# Throwaway tmux server: .tmux.conf.local loads and key contracts hold.
# Does not run live clipboard / WezTerm GUI tests.
set -e
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$TEST_DIR/helpers.sh"

SOCK=configcheck
trap 'tmux -L $SOCK kill-server 2>/dev/null || true' EXIT
tmux -L $SOCK kill-server 2>/dev/null || true

tmux -L $SOCK -f /dev/null new-session -d -x 200 -y 50
errs=$(tmux -L $SOCK source-file -v "$HOME/.tmux.conf.local" 2>&1 \
       | grep -viE '^/.*: (set|bind|unbind|setw|if-shell|run-shell|source)' || true)
[ -z "$errs" ] || { echo "FAIL: .tmux.conf.local has errors:"; echo "$errs"; exit 1; }

check() { # label expected actual
  [ "$2" = "$3" ] || { echo "FAIL: $1 expected $2, got $3"; exit 1; }
  echo "ok: $1 ($3)"
}
check "smart Ctrl-hjkl binds" 4 "$(tmux -L $SOCK list-keys -T root | grep -cE 'C-[hjkl] +if-shell' || true)"
check "prefix hjkl binds"     4 "$(tmux -L $SOCK list-keys -T prefix | grep -cE '^bind-key -r +-T prefix +[hjkl] ' || true)"
check "C-\\ pane-last bind"   1 "$(tmux -L $SOCK list-keys -T root | grep -cF 'C-\' || true)"
check "swap-window { }"       2 "$(tmux -L $SOCK list-keys -T prefix | grep -cE 'prefix +.\{|prefix +.\}' || true)"
check "join-pane < >"         2 "$(tmux -L $SOCK list-keys -T prefix | grep -cE 'prefix +[<>] +command-prompt' || true)"
check "mode-keys"           vi "$(tmux -L $SOCK show -gwv mode-keys)"
check "escape-time"          0 "$(tmux -L $SOCK show -sv escape-time)"
check "history-limit"    10000 "$(tmux -L $SOCK show -gv history-limit)"
check "continuum-restore" on "$(tmux -L $SOCK show -gv @continuum-restore)"
check "smooth-scroll-speed" 30 "$(tmux -L $SOCK show -gv @smooth-scroll-speed)"
check "smooth-scroll-mouse" true "$(tmux -L $SOCK show -gv @smooth-scroll-mouse)"
check "C-u not important" 0 "$(grep -c 'copy-mode-vi C-u.*#!important' "$HOME/.tmux.conf.local" || true)"
check "M-k smooth 2-line" 1 "$(tmux -L $SOCK list-keys -T copy-mode-vi | grep -c 'scroll.sh up 2' || true)"
check "no prefix C-a" 0 "$(tmux -L $SOCK list-keys -T prefix | grep -c 'C-a' || true)"
prefix2=$(tmux -L $SOCK show -gv prefix2 2>/dev/null || true)
case "$prefix2" in
  ""|None) echo "ok: prefix2 unset ($prefix2)" ;;
  *) echo "FAIL: prefix2 still set ($prefix2)"; exit 1 ;;
esac

python3 - "$SOCK" <<'PYTEST'
import os, pty, subprocess, sys, time

def tm(*args):
    return subprocess.check_output(["tmux", "-L", sys.argv[1], *args], text=True).strip()

pane = tm("new-window", "-P", "-F", "#{pane_id}", "cat")
master, slave = pty.openpty()
env = {k: v for k, v in os.environ.items() if k not in ("TMUX", "TMUX_PANE")}
env["TERM"] = "xterm-256color"
client = subprocess.Popen(["tmux", "-L", sys.argv[1], "attach-session"],
                          stdin=slave, stdout=slave, stderr=slave, env=env)
try:
    for _ in range(50):
        target = tm("list-clients", "-F", "#{client_tty}")
        if target:
            break
        time.sleep(0.1)
    assert target, "test client did not attach"
    tm("select-pane", "-t", pane)
    tm("set-option", "-p", "-t", pane, "@workmux_role", "sidebar")
    tm("send-keys", "-K", "-c", target, "t")
    time.sleep(0.2)
    assert not tm("capture-pane", "-p", "-t", pane), "sidebar received t"
    tm("set-option", "-pu", "-t", pane, "@workmux_role")
    tm("send-keys", "-K", "-c", target, "t")
    time.sleep(0.2)
    assert tm("capture-pane", "-p", "-t", pane) == "t", "normal typing lost t"
    for key in ("t", "."):
        result = subprocess.run(["tmux", "-L", sys.argv[1], "list-keys", "-T", "prefix", key], capture_output=True)
        assert result.returncode != 0, f"retired task shortcut still bound: {key}"
    assert "tmux-tasklog" not in tm("show-hooks", "-g")
    print("ok: sidebar guard and normal typing preserved; task shortcuts and hooks absent")
finally:
    client.terminate()
    client.wait(timeout=5)
    os.close(slave)
    os.close(master)
PYTEST

local_conf="$HOME/.tmux.conf.local"
if grep -E "^set -g @plugin '.*(copycat|tmux-cpu)" "$local_conf" >/dev/null 2>&1; then
  echo "FAIL: copycat/cpu still in @plugin list"; exit 1
fi
if grep -q '/home/nurul' "$local_conf"; then
  echo "FAIL: hardcoded /home/nurul in .tmux.conf.local"; exit 1
fi
got=$(awk -F"'" '/^set -g @plugin /{n=$2; sub(".*/","",n); print n}' "$local_conf" | paste -sd' ' -)
check "plugin list" "tmux-resurrect tmux-fzf tmux-sessionx tmux-which-key tmux-smooth-scroll tmux-continuum tmux-assistant-resurrect" "$got"
check "sesh-switch bind" 1 "$(tmux -L $SOCK list-keys -T prefix | grep -c sesh-switch || true)"
echo "ok: tmux check (portable)"
