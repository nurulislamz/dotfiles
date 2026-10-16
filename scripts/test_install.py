#!/usr/bin/env python3
"""Exercise restore in a disposable home, including backups and custom hooks."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts/install.py"


class RestoreTests(unittest.TestCase):
    def run_install(self, home):
        return subprocess.run(
            ["python3", str(INSTALLER)], env={**os.environ, "HOME": str(home)},
            capture_output=True, text=True, check=False,
        )

    def seed_oh_my_tmux(self, home):
        omt = home / ".tmux-omt"
        omt.mkdir()
        (omt / ".tmux.conf").write_text("# dummy oh-my-tmux\n")
        return omt

    def test_restore_preserves_files_hooks_and_is_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            self.seed_oh_my_tmux(home)
            nvim = home / ".config/nvim"
            nvim.mkdir(parents=True)
            (nvim / "init.lua").write_text("original config\n")
            skill = home / ".config/agents/skills/workmux"
            skill.mkdir(parents=True)
            (skill / "local.txt").write_text("local skill\n")
            claude = home / ".claude/settings.json"
            claude.parent.mkdir()
            custom = {"type": "command", "command": "custom-check"}
            claude.write_text(json.dumps({"permissions": {"allow": []}, "hooks": {
                "SessionStart": [{"hooks": [custom, {"command": "workmux register-agent"}]}]
            }}))
            agy = home / ".gemini/config/hooks.json"
            agy.parent.mkdir(parents=True)
            agy.write_text(json.dumps({"custom": {"Stop": []}}))
            result = self.run_install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(nvim.resolve(), ROOT / "nvim")
            self.assertEqual((home / ".config/wezterm").resolve(), ROOT / "wezterm")
            self.assertEqual((home / ".config/foot").resolve(), ROOT / "foot")
            self.assertEqual((home / ".zshrc").resolve(), ROOT / "shell/.zshrc")
            self.assertEqual((home / ".tmux.conf").resolve(), home / ".tmux-omt/.tmux.conf")
            self.assertEqual((home / ".tmux.conf.local").resolve(), ROOT / "tmux/.tmux.conf.local")
            self.assertEqual((home / ".local/bin/sesh-switch").resolve(), ROOT / "tmux/sesh-switch.sh")
            self.assertTrue(os.access(home / ".local/bin/sesh-switch", os.X_OK))
            self.assertEqual(skill.resolve(), ROOT / "agents/skills/workmux")
            self.assertEqual((home / ".codex/skills/workmux").resolve(), skill.resolve())
            self.assertEqual((home / ".local/bin/workmux-agent-hook").resolve(), ROOT / "agents/skills/workmux/scripts/workmux-agent-hook")
            backups = list((home / ".local/state/vsvimsettings/backups").iterdir())
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / ".config/nvim/init.lua").read_text(), "original config\n")
            self.assertEqual((backups[0] / ".config/agents/skills/workmux/local.txt").read_text(), "local skill\n")
            settings = json.loads(claude.read_text())
            self.assertEqual(settings["permissions"], {"allow": []})
            self.assertEqual(settings["hooks"]["SessionStart"][0]["hooks"], [custom])
            self.assertIn("custom", json.loads(agy.read_text()))
            first = claude.read_text()
            result = self.run_install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(claude.read_text(), first)
            self.assertEqual(list(backups[0].parent.iterdir()), backups)

    def test_which_key_config_linked_when_plugin_present(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            self.seed_oh_my_tmux(home)
            plugin = home / ".tmux/plugins/tmux-which-key"
            plugin.mkdir(parents=True)
            (plugin / "config.yaml").write_text("stock\n")
            result = self.run_install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((plugin / "config.yaml").resolve(), ROOT / "tmux/config.yaml")

    def test_zed_directory_already_linked_into_repo(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            self.seed_oh_my_tmux(home)
            (home / ".config").mkdir()
            (home / ".config/zed").symlink_to(ROOT / "zed", target_is_directory=True)
            result = self.run_install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            for name in ("settings.json", "keymap.json", "tasks.json"):
                self.assertFalse((ROOT / "zed" / name).is_symlink())
                self.assertEqual((home / ".config/zed" / name).resolve(), ROOT / "zed" / name)
            self.assertEqual((home / ".claude/AGENTS.md").resolve(), ROOT / "agents/AGENTS.md")

    def test_installed_sesh_switch_connects_selected_session(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            self.seed_oh_my_tmux(home)
            result = self.run_install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            commands = home / ".local/bin"
            for name, body in {
                "sesh": 'if [ "$1" = list ]; then echo "test session"; else printf "%s\\n" "$@"; fi',
                "fzf-tmux": 'cat',
            }.items():
                stub = commands / name
                stub.write_text("#!/bin/sh\n" + body + "\n")
                stub.chmod(0o755)
            result = subprocess.run(
                [str(commands / "sesh-switch")],
                env={**os.environ, "HOME": str(home), "PATH": f"{commands}:{os.environ['PATH']}"},
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), ["connect", "test session"])

    def test_invalid_hooks_abort_before_replacing_config(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            hooks = home / ".codex/hooks.json"
            hooks.parent.mkdir()
            hooks.write_text("invalid JSON")
            result = self.run_install(home)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(hooks.read_text(), "invalid JSON")
            self.assertFalse((home / ".config/nvim").exists())

    def test_tmux_local_has_no_machine_paths(self):
        text = (ROOT / "tmux/.tmux.conf.local").read_text()
        self.assertNotIn("/home/nurul", text)
        self.assertIn("$HOME/.local/bin/sesh-switch", text)
        self.assertIn("$HOME/.tmux/plugins/tmux-smooth-scroll", text)

    def test_zshrc_is_portable(self):
        text = (ROOT / "shell/.zshrc").read_text()
        self.assertNotIn("/home/nurul", text)
        self.assertIn("/opt/homebrew/bin/brew", text)
        self.assertIn("[ -s \"$HOME/.local/bin/env\" ]", text)


if __name__ == "__main__":
    unittest.main()
