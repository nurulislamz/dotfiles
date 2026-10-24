#!/usr/bin/env python3
"""WSL host: repo Zed files match Windows roaming and ~/.config/zed links."""

from pathlib import Path
import json
import os
import sys

ROOT = Path(__file__).resolve().parents[2]
ZED = ROOT / "zed"
WIN_ROAMING = Path("/mnt/c/Users") / os.environ.get("USER", "nurul") / "AppData/Roaming/Zed"
WSL_CONFIG = Path.home() / ".config/zed"
FILES = ("settings.json", "keymap.json", "tasks.json")
# Machine-local Zed keys. Repo is the source of truth for everything else.
LOCAL_KEYS = {"wsl_connections"}


def _load(path):
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".json":
        return json.loads(text)
    return text


def _normalize(value):
    if isinstance(value, dict):
        return {k: _normalize(v) for k, v in value.items() if k not in LOCAL_KEYS}
    if isinstance(value, list):
        return [_normalize(v) for v in value]
    return value


def main():
    failed = 0
    roaming = WIN_ROAMING
    if not roaming.is_dir():
        roaming = Path("/mnt/c/Users/nurul/AppData/Roaming/Zed")
    for name in FILES:
        source = ZED / name
        target = roaming / name
        if not target.exists():
            print(f"FAIL: missing Windows Zed {target}")
            failed += 1
            continue
        if _normalize(_load(source)) != _normalize(_load(target)):
            print(f"FAIL: Windows Zed {name} differs from repo")
            failed += 1
        else:
            print(f"ok: Windows Zed {name} matches repo")
        link = WSL_CONFIG / name
        if not link.is_symlink():
            print(f"FAIL: {link} is not a symlink")
            failed += 1
        elif not link.exists():
            print(f"FAIL: {link} is a broken symlink")
            failed += 1
        else:
            print(f"ok: {link} -> repo")
    return failed


if __name__ == "__main__":
    sys.exit(1 if main() else 0)
