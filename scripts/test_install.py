#!/usr/bin/env python3
"""Shim: installer tests live in test/test_install.py."""
import runpy
from pathlib import Path

runpy.run_path(str(Path(__file__).resolve().parents[1] / "test" / "test_install.py"), run_name="__main__")
