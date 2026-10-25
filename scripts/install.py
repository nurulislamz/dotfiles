#!/usr/bin/env python3
"""Restore dotfiles links and remove agent hooks; preserve replaced files."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
OMT_REPO = "https://github.com/gpakosz/.tmux.git"


def link(source, destination, backup):
    # Also covers a destination inside a directory already linked into the repo.
    if destination.resolve() == source.resolve():
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    if os.path.lexists(destination):
        saved = backup / destination.relative_to(Path.home())
        saved.parent.mkdir(parents=True, exist_ok=True)
        destination.rename(saved)
        print(f"Backed up {destination} -> {saved}")
    destination.symlink_to(source, target_is_directory=source.is_dir())


def ensure_oh_my_tmux(home):
    dest = home / ".tmux-omt"
    if (dest / ".tmux.conf").exists():
        return dest
    if dest.exists():
        try:
            dest.rmdir()
        except OSError:
            print(f"Skipped oh-my-tmux: {dest} exists without .tmux.conf")
            return None
    try:
        subprocess.run(
            ["git", "clone", "--depth", "1", OMT_REPO, str(dest)],
            check=True, capture_output=True, text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "stderr", None) or exc
        print(f"Skipped oh-my-tmux clone: {detail}")
        return None
    return dest


def install():
    home = Path.home()
    # Validate every config before replacing any installed files.
    updates = []
    for pattern in (
        ".codex/hooks.json", ".claude/settings*.json", ".cursor/hooks.json",
        ".gemini/config/hooks.json", ".codex-containers/*/.codex/hooks.json",
        ".agy-containers/*/.gemini/config/hooks.json",
        ".agent-containers/*/.cursor/hooks.json",
    ):
        for destination in sorted(home.glob(pattern)):
            current = json.loads(destination.read_text())
            if not isinstance(current, dict):
                raise ValueError(f"Expected a JSON object in {destination}")
            cleaned = {} if ".gemini" in destination.parts else {
                key: value for key, value in current.items() if key != "hooks"
            }
            updates.append((destination, current, cleaned))

    for name in ("tmux-tasklog", "workmux-agent-hook", "codex-box-rename-bridge"):
        retired = home / ".local/bin" / name
        if retired.is_symlink() and retired.resolve() == ROOT / "agents/skills/workmux/scripts" / name:
            retired.unlink()

    backup = home / ".local/state/vsvimsettings/backups" / str(time.time_ns())
    for name in ("workmux-status.ts", "session-tracker.js"):
        plugin = home / ".config/opencode/plugins" / name
        if os.path.lexists(plugin):
            saved = backup / plugin.relative_to(home)
            saved.parent.mkdir(parents=True, exist_ok=True)
            plugin.rename(saved)
    paths = {
        ".config/nvim": "nvim",
        ".config/wezterm": "wezterm",
        ".config/foot": "foot",
        ".zshrc": "shell/.zshrc",
        ".tmux.conf.local": "tmux/.tmux.conf.local",
        ".config/agents/AGENTS.md": "agents/AGENTS.md",
        ".config/agents/skills/workmux": "agents/skills/workmux",
        ".config/workmux/config.yaml": "workmux/config.yaml",
        ".config/workmux/review.yaml": "workmux/review.yaml",
        ".config/zed/settings.json": "zed/settings.json",
        ".config/zed/keymap.json": "zed/keymap.json",
        ".config/zed/tasks.json": "zed/tasks.json",
    }
    for target in (
        ".codex/AGENTS.md", ".claude/CLAUDE.md", ".config/opencode/AGENTS.md",
        ".cursor/rules/session-tasks.md", ".gemini/config/rules/session-tasks.md",
    ):
        paths[target] = "agents/AGENTS.md"
    paths[".cursor/rules/fastapi-string-ids.mdc"] = "cursor/rules/fastapi-string-ids.mdc"
    for directory in (
        ".agents/skills", ".codex/skills", ".claude/skills", ".cursor/skills",
        ".config/opencode/skills", ".gemini/config/skills",
    ):
        paths[f"{directory}/workmux"] = "agents/skills/workmux"
    for source in sorted((ROOT / "agents/bin").iterdir()):
        paths[f".local/bin/{source.name}"] = str(source.relative_to(ROOT))
    paths[".local/bin/cursor-box"] = "agents/bin/agent-box"
    paths[".local/bin/sesh-switch"] = "tmux/sesh-switch.sh"
    omt = ensure_oh_my_tmux(home)
    if omt is not None:
        link(omt / ".tmux.conf", home / ".tmux.conf", backup)
    for target, source in paths.items():
        link(ROOT / source, home / target, backup)

    which_key = home / ".tmux/plugins/tmux-which-key"
    if which_key.is_dir():
        link(ROOT / "tmux/config.yaml", which_key / "config.yaml", backup)

    for destination, current, merged in updates:
        if destination.exists() and current == merged:
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists():
            saved = backup / destination.relative_to(home)
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(destination, saved)
        # Replace atomically so an interrupted write cannot corrupt settings.
        with tempfile.NamedTemporaryFile(mode="w", dir=destination.parent, delete=False) as stream:
            json.dump(merged, stream, indent=2)
            stream.write("\n")
        try:
            os.replace(stream.name, destination)
        finally:
            Path(stream.name).unlink(missing_ok=True)
    print(f"Restored links and removed agent hooks from {ROOT}")


if __name__ == "__main__":
    install()
