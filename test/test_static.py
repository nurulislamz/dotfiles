#!/usr/bin/env python3
"""Parse contracts and cross-tool invariants. No GUI, no live HOME."""

from pathlib import Path
import json
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MACHINE = "/home/nurul"


def _read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


def _lua_files():
    files = [ROOT / "nvim/init.lua"]
    files.extend(sorted((ROOT / "nvim/lua").rglob("*.lua")))
    return [f for f in files if " " not in f.name]


class StaticTests(unittest.TestCase):
    def test_csi_u_shift_enter_in_every_tool(self):
        checks = {
            "wezterm/wezterm.lua": 'SendString("\\x1b[13;2u")',
            "tmux/.tmux.conf.local": "S-Enter",
            "nvim/lua/config/keymaps.lua": "<Esc>[13;2u",
            "shell/.zshrc": "bindkey '^[[13;2u'",
            "foot/foot.ini": r"\x1b[13;2u=Shift+Return",
        }
        for rel, needle in checks.items():
            text = _read(rel)
            self.assertIn(needle, text, f"{rel} missing {needle}")
        self.assertIn("send-keys Escape \"[13;2u\"", _read("tmux/.tmux.conf.local"))

    def test_no_machine_home_paths(self):
        for rel in (
            "tmux/.tmux.conf.local",
            "shell/.zshrc",
            "wezterm/wezterm.lua",
        ):
            self.assertNotIn(MACHINE, _read(rel), rel)
        for path in _lua_files():
            self.assertNotIn(MACHINE, path.read_text(encoding="utf-8"), str(path))

    def test_nvim_lua_files_parse(self):
        import subprocess

        nvim = subprocess.run(
            ["nvim", "--clean", "--headless", "+qa"],
            capture_output=True, text=True,
        )
        if nvim.returncode != 0 and not Path("/usr/bin/nvim").exists():
            self.skipTest("nvim missing")
        bad = []
        for path in _lua_files():
            result = subprocess.run(
                [
                    "nvim", "--clean", "--headless",
                    "-c", f"lua assert(loadfile({path.as_posix()!r}))",
                    "+qa",
                ],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                bad.append(str(path.relative_to(ROOT)))
        self.assertEqual(bad, [], f"lua parse failed: {bad}")

    def test_lazy_lock_has_no_leftover_plugins(self):
        lock = json.loads(_read("nvim/lazy-lock.json"))
        specs = []
        for path in (ROOT / "nvim/lua").rglob("*.lua"):
            specs.append(path.read_text(encoding="utf-8"))
        specs.append(_read("nvim/lua/config/lazy.lua"))
        blob = "\n".join(specs)
        leftover = [
            name for name in sorted(lock)
            if name != "lazy.nvim" and name not in blob
        ]
        self.assertEqual(leftover, [], f"lock entries not in plugin specs: {leftover}")

    def test_foot_ini_csi_u_and_fonts(self):
        text = _read("foot/foot.ini")
        self.assertIn(r"\x1b[13;2u=Shift+Return", text)
        self.assertIn(r"\x1b[13;4u=Mod1+Shift+Return", text)
        self.assertIn("Cascadia Code", text)
        self.assertIn("scrollback", text)
        self.assertRegex(text, r"lines\s*=\s*10000")

    def test_workmux_yaml(self):
        try:
            import yaml
        except ImportError:
            yaml = None
        for rel, keys in (
            ("workmux/config.yaml", ("worktree_dir", "mode", "sidebar")),
            ("workmux/review.yaml", ("mode", "windows")),
            ("tmux/config.yaml", ()),
        ):
            text = _read(rel)
            self.assertTrue(text.strip(), rel)
            if yaml is not None:
                data = yaml.safe_load(text)
                self.assertIsInstance(data, dict, rel)
                for key in keys:
                    self.assertIn(key, data, f"{rel} missing {key}")
        if yaml is not None:
            config = yaml.safe_load(_read("workmux/config.yaml"))
            self.assertEqual(config["mode"], "session")
            self.assertEqual(config["worktree_dir"], ".worktrees")
            self.assertEqual(config["sidebar"]["group_by"], "session")
            review = yaml.safe_load(_read("workmux/review.yaml"))
            names = [w.get("name") for w in review.get("windows", [])]
            self.assertEqual(names, ["nvim", "codex"])

    def test_wezterm_static_keys(self):
        text = _read("wezterm/wezterm.lua")
        self.assertIn('SendString("\\x16")', text)
        self.assertIn('EmitEvent("paste-or-send")', text)
        self.assertIn('key = "v", mods = "CTRL|SHIFT"', text)
        self.assertIn('EmitEvent("copy-or-interrupt")', text)
        self.assertIn('SendString("\\x02")', text)
        self.assertIn('leader = { key = "a", mods = "CTRL"', text)
        self.assertIn('enable_csi_u_key_encoding = false', text)
        self.assertIn('enable_kitty_keyboard = false', text)

    def test_wezterm_themes_have_16_colors(self):
        for rel in ("wezterm/cyberdream.lua", "wezterm/cyberdream-light.lua"):
            text = _read(rel)
            ansi = re.search(r"ansi\s*=\s*\{([^}]+)\}", text)
            brights = re.search(r"brights\s*=\s*\{([^}]+)\}", text)
            self.assertIsNotNone(ansi, rel)
            self.assertIsNotNone(brights, rel)
            self.assertEqual(len(re.findall(r"#[0-9a-fA-F]{6}", ansi.group(1))), 8, rel)
            self.assertEqual(len(re.findall(r"#[0-9a-fA-F]{6}", brights.group(1))), 8, rel)


if __name__ == "__main__":
    unittest.main()
