#!/usr/bin/env bash
# Restore this machine's agent tools and named profiles; authenticate separately.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export PATH="$HOME/.local/bin:$PATH"

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  echo "Usage: bash scripts/setup-agents.sh"
  echo "Linux/WSL: install missing CLIs, restore dotfiles, create named boxes."
  echo "Requires curl, git, python3, tmux and distro bubblewrap. Login stays manual."
  exit 0
fi
if [[ $# != 0 || $(uname -s) != Linux ]]; then
  echo "Usage: bash scripts/setup-agents.sh (Linux/WSL only)" >&2
  exit 1
fi
for tool in curl git python3 tmux bwrap; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing $tool. Install prerequisites from dotfiles.md first." >&2
    exit 1
  fi
done

TEMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEMP_DIR"' EXIT
install_cli() {
  curl -fsSL "$1" -o "$TEMP_DIR/install.sh"
  "$2" "$TEMP_DIR/install.sh"
  hash -r
}

# Preserve the native CLI before install.py links the AGY wrapper.
REAL_AGY=${AGY_REAL_BIN:-$HOME/.local/bin/agy-real}
if [[ ! -x $REAL_AGY ]]; then
  AGY_PATH=$(command -v agy || true)
  if [[ -n $AGY_PATH && $AGY_PATH -ef "$ROOT/agents/bin/agy" ]]; then
    echo "AGY wrapper exists without its real binary. Set AGY_REAL_BIN first." >&2
    exit 1
  fi
  if [[ -z $AGY_PATH ]]; then
    install_cli https://antigravity.google/cli/install.sh bash
    AGY_PATH=$(command -v agy)
  fi
  mkdir -p -- "$(dirname -- "$REAL_AGY")"
  cp -- "$AGY_PATH" "$REAL_AGY"
  chmod +x "$REAL_AGY"
fi
if [[ $REAL_AGY -ef "$ROOT/agents/bin/agy" ]]; then
  echo "AGY_REAL_BIN must point to the native CLI, not the dotfiles wrapper." >&2
  exit 1
fi
export AGY_REAL_BIN="$REAL_AGY"

if ! command -v codex >/dev/null 2>&1; then
  install_cli https://chatgpt.com/codex/install.sh sh
fi
if ! command -v omp >/dev/null 2>&1; then
  install_cli https://omp.sh/install sh
fi
if ! command -v agent >/dev/null 2>&1; then
  install_cli https://cursor.com/install bash
fi
for tool in codex omp agent; do
  command -v "$tool" >/dev/null
done

python3 "$ROOT/scripts/install.py"

# OMP's existing tmux instructions are included in the shared rules.
BACKUP_DIR="$HOME/.local/state/vsvimsettings/backups/agents-$(date +%Y%m%d-%H%M%S)-$$"
link_omp() {
  local source=$1 destination="$HOME/$2"
  if [[ $source -ef $destination ]]; then
    return
  fi
  mkdir -p -- "$(dirname -- "$destination")"
  if [[ -e $destination || -L $destination ]]; then
    mkdir -p -- "$BACKUP_DIR/$(dirname -- "$2")"
    mv -- "$destination" "$BACKUP_DIR/$2"
    echo "Backed up $destination -> $BACKUP_DIR/$2"
  fi
  ln -s -- "$source" "$destination"
}
link_omp "$ROOT/agents/AGENTS.md" .omp/AGENTS.md
link_omp "$ROOT/agents/AGENTS.md" .config/omp/AGENTS.md
link_omp "$ROOT/agents/skills/workmux" .omp/agent/skills/workmux

# Inventory from the source machine, including spare/test profiles.
AGY_BOXES=(chaos missing mohammed nurulz physics worker1)
CODEX_BOXES=(dev mohammed nurulz)
AGENT_BOXES=(box-a box-alpha nurulz physics)
for name in "${AGY_BOXES[@]}"; do
  bash "$ROOT/agents/bin/agy-box" add "$name"
  [[ -d $HOME/.agy-containers/$name/.gemini ]]
done
for name in "${CODEX_BOXES[@]}"; do
  bash "$ROOT/agents/bin/codex-box" add "$name"
  [[ -d $HOME/.codex-containers/$name/.codex ]]
done
for name in "${AGENT_BOXES[@]}"; do
  bash "$ROOT/agents/bin/agent-box" add "$name"
  [[ -d $HOME/.agent-containers/$name/.cursor ]]
done

echo "Agent setup complete. Existing profiles and CLI versions retained."
echo "Login per box: agy-box <name>, codex-box <name> login, agent-box <name> login."
echo "Start omp, then /login. Keep ~/.local/bin on PATH."
echo "AGY skips permission prompts; Cursor enables trust/auto-review/MCP approval."
echo "Native workmux and its custom Session build remain separate; see dotfiles.md."
