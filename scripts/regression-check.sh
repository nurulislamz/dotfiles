#!/usr/bin/env bash
# Live WSL host audit (hardcoded /home/nurul and agentusage paths).
# Portable installer checks: scripts/verify
set -euo pipefail

PASS=0
FAIL=0
fail_msgs=()

ok() { PASS=$((PASS + 1)); printf 'PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); fail_msgs+=("$1"); printf 'FAIL  %s\n' "$1"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

echo '======== TMUX ========'
need_cmd tmux
if tmux show -g prefix 2>/dev/null | grep -qx 'prefix C-b'; then
  ok 'tmux prefix is C-b'
else
  fail "tmux prefix is not C-b ($(tmux show -g prefix 2>/dev/null | tr '\n' ' '))"
fi
if ! tmux show -g prefix2 2>/dev/null | grep -qv 'prefix2 None'; then
  ok 'tmux prefix2 unset (Ctrl-A not a prefix)'
else
  fail "tmux prefix2 still set ($(tmux show -g prefix2 2>/dev/null))"
fi
if ! tmux list-keys -T prefix 2>/dev/null | grep -q 'C-a'; then
  ok 'C-a not bound in prefix table'
else
  fail 'C-a still bound in prefix table'
fi
if [[ "$(readlink -f "$HOME/.tmux.conf" 2>/dev/null)" == *tmux-omt* ]]; then
  ok '~/.tmux.conf -> oh-my-tmux'
else
  fail '~/.tmux.conf is not the oh-my-tmux symlink'
fi
if [[ "$(readlink -f "$HOME/.tmux.conf.local" 2>/dev/null)" == *dotfiles/tmux/.tmux.conf.local ]]; then
  ok '~/.tmux.conf.local -> dotfiles'
else
  fail '~/.tmux.conf.local is not the dotfiles symlink'
fi
if tmux show -g @continuum-restore 2>/dev/null | grep -q "on"; then
  ok 'continuum-restore on'
else
  fail "continuum-restore missing ($(tmux show -g @continuum-restore 2>/dev/null | tr '\n' ' '))"
fi
plugin_extra="$(ls "$HOME/.tmux/plugins" 2>/dev/null | grep -Ev '^(tpm|tpm_log.txt|tmux-which-key|tmux-resurrect|tmux-continuum|tmux-fzf|tmux-smooth-scroll|tmux-sessionx|tmux-assistant-resurrect)$' || true)"
if [[ -z "$plugin_extra" ]]; then
  ok 'tmux plugin set is resurrect/continuum/fzf/which-key/smooth-scroll/sessionx/assistant-resurrect'
else
  fail "unexpected tmux plugins: $plugin_extra"
fi
if grep -q 'set -gu prefix2' "$HOME/dotfiles/tmux/.tmux.conf.local" 2>/dev/null \
  || grep -q 'set -gu prefix2' /home/nurul/dotfiles/tmux/.tmux.conf.local; then
  ok 'local config unsets prefix2'
else
  fail 'tmux/.tmux.conf.local missing prefix2 unset'
fi
if tmux list-keys -T prefix 2>/dev/null | grep -q 'swap-window'; then
  ok 'swap-window bound'
else
  fail 'swap-window not bound'
fi
if tmux list-keys -T root 2>/dev/null | grep -q 'bind-key -T root C-h'; then
  ok 'vim-aware C-h pane navigation bound'
else
  fail 'C-h pane navigation missing'
fi
if [[ -L "$HOME/.tmux/plugins/tmux-which-key/config.yaml" ]]; then
  ok 'which-key config.yaml symlinked to repo'
else
  fail 'which-key config.yaml is not a repo symlink'
fi

echo
echo '======== NVIM ========'
need_cmd nvim
if [[ "$(readlink -f "$HOME/.config/nvim" 2>/dev/null)" == *dotfiles/nvim ]]; then
  ok '~/.config/nvim -> dotfiles/nvim'
else
  fail '~/.config/nvim is not the dotfiles symlink'
fi
if nvim --headless -c 'lua print("nvim-boot-ok")' -c qa 2>&1 | grep -q 'nvim-boot-ok'; then
  ok 'nvim headless boots'
else
  fail 'nvim headless boot failed'
fi
lua_bad=0
while IFS= read -r -d '' f; do
  if ! nvim --headless -c "lua assert(loadfile([[$f]]))" -c qa >/dev/null 2>&1; then
    fail "lua parse failed: $f"
    lua_bad=1
  fi
done < <(find /home/nurul/dotfiles/nvim -name '*.lua' -print0)
if [[ "$lua_bad" -eq 0 ]]; then
  ok 'all nvim lua files parse'
fi
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [[ -d "$runtime_dir" && -w "$runtime_dir" ]]; then
  ok "XDG runtime dir writable ($runtime_dir)"
else
  fail "XDG runtime dir not writable ($runtime_dir)"
fi

echo
echo '======== ANTIGRAVITY SKILLS ========'
host_skills="$HOME/.gemini/config/skills"
host_agents="$HOME/.gemini/config/agents"
for s in feature-cycle debug-cycle magi code-quality-cycle security-cycle perf-cycle test-cycle coverage-cycle ui-cycle; do
  if [[ -f "$host_skills/$s/SKILL.md" ]]; then
    ok "host skill $s"
  else
    fail "host skill missing $s"
  fi
done
for a in explorer implementer verifier coordinator; do
  if [[ -f "$host_agents/$a/agent.md" ]]; then
    ok "host agent $a"
  else
    fail "host agent missing $a"
  fi
done
if [[ -f "$HOME/.gemini/config/workflows/feature-cycle.md" ]]; then
  ok 'host workflow feature-cycle.md'
else
  fail 'host workflow feature-cycle.md missing'
fi
broken=0
if [[ -d "$HOME/.agents/skills" ]]; then
  while IFS= read -r p; do
    if [[ -L "$p" && ! -e "$p" ]]; then
      fail "broken skill link $(basename "$p") -> $(readlink "$p")"
      broken=1
    fi
  done < <(find "$HOME/.agents/skills" -mindepth 1 -maxdepth 1)
fi
if [[ "$broken" -eq 0 ]]; then
  ok 'no broken ~/.agents/skills symlinks'
fi

echo
echo '======== AGY-BOX ========'
repo_box=/home/nurul/agentusage/scripts/boxes/agy-box
inst_box="$HOME/.local/bin/agy-box"
if [[ -f "$inst_box" && -f "$repo_box" ]] && cmp -s "$inst_box" "$repo_box"; then
  ok 'installed agy-box matches repo'
else
  fail 'installed agy-box missing or differs from repo'
fi
if grep -q 'XDG_RUNTIME_DIR' "$repo_box"; then
  ok 'repo agy-box binds XDG_RUNTIME_DIR'
else
  fail 'repo agy-box missing XDG_RUNTIME_DIR bind'
fi
if grep -q 'for src in workflows global_workflows skills agents rules' "$repo_box"; then
  ok 'repo agy-box syncs agents/rules'
else
  fail 'repo agy-box does not sync agents/rules'
fi
shopt -s nullglob
for box in "$HOME"/.agy-containers/*; do
  [[ -d "$box" ]] || continue
  name="$(basename "$box")"
  if [[ -f "$box/.gemini/config/skills/feature-cycle/SKILL.md" ]]; then
    ok "box $name has feature-cycle skill"
  else
    fail "box $name missing feature-cycle skill"
  fi
  if [[ -f "$box/.gemini/config/agents/explorer/agent.md" ]]; then
    ok "box $name has explorer agent"
  else
    fail "box $name missing explorer agent"
  fi
  if [[ -f "$box/.gemini/config/workflows/feature-cycle.md" ]]; then
    ok "box $name has feature-cycle workflow"
  else
    fail "box $name missing feature-cycle workflow"
  fi
done
shopt -u nullglob

if grep -q 'XDG_RUNTIME_DIR' /home/nurul/agentusage/scripts/boxes/agent-box \
  && grep -q 'XDG_RUNTIME_DIR' "$HOME/.local/bin/agent-box"; then
  ok 'agent-box binds XDG_RUNTIME_DIR'
else
  fail 'agent-box missing XDG_RUNTIME_DIR bind'
fi
if [[ -x /home/nurul/agentusage/scripts/boxes/agy-box_test.sh ]]; then
  if /home/nurul/agentusage/scripts/boxes/agy-box_test.sh >/dev/null; then
    ok 'agy-box_test.sh passed'
  else
    fail 'agy-box_test.sh failed'
  fi
fi

echo
echo "======== SUMMARY ========"
echo "passed=$PASS failed=$FAIL"
if [[ "$FAIL" -gt 0 ]]; then
  for m in "${fail_msgs[@]}"; do
    printf ' - %s\n' "$m"
  done
  exit 1
fi
exit 0
