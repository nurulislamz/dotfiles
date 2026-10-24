#!/usr/bin/env python3
"""Clipboard boundary checks; no desktop focus or real clipboard changes."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

CLIP = Path(__file__).with_name('clip.sh')


class ClipboardTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.clipboard = self.root / 'clipboard'
        self.clipboard.write_bytes(b'https://example.com/?query=chrome')
        self.calls = self.root / 'tmux-calls'
        for name, body in {
            'clip.exe': 'cat > "$TEST_CLIPBOARD"',
            'powershell.exe': 'test "${FAIL_READ:-0}" = 0 || exit 1; cat "$TEST_CLIPBOARD"',
            'tmux': 'echo "$*" >> "$TEST_CALLS"; if [ "$1" = load-buffer ]; then cat >/dev/null; fi',
        }.items():
            path = self.root / name
            path.write_text('#!/bin/sh\nset -e\n' + body + '\n')
            path.chmod(0o755)
        self.env = {**os.environ, 'PATH': str(self.root) + ':' + os.environ['PATH'],
                    'TEST_CLIPBOARD': str(self.clipboard), 'TEST_CALLS': str(self.calls)}

    def run_clip(self, command, data=b''):
        return subprocess.run([str(CLIP), command], input=data, env=self.env, capture_output=True)

    def test_blank_selection_preserves_chrome_url(self):
        before = self.clipboard.read_bytes()
        for blank in (b'', b'\n', b' \t\r\n'):
            self.assertEqual(self.run_clip('copy', blank).returncode, 0)
            self.assertEqual(self.clipboard.read_bytes(), before)

    def test_copy_preserves_unicode_and_trailing_newlines(self):
        text = 'https://example.com/日本語?q=a%20b\n\n'.encode()
        self.assertEqual(self.run_clip('copy', text).returncode, 0)
        self.assertEqual(self.clipboard.read_bytes(), text)

    def test_paste_reads_without_writing_clipboard(self):
        before = self.clipboard.read_bytes()
        self.assertEqual(self.run_clip('paste').stdout, before)
        self.assertEqual(self.clipboard.read_bytes(), before)

    def test_failed_read_does_not_paste_stale_tmux_buffer(self):
        self.env['FAIL_READ'] = '1'
        self.assertNotEqual(self.run_clip('paste-tmux').returncode, 0)
        self.assertNotIn('paste-buffer', self.calls.read_text())


if __name__ == '__main__':
    unittest.main()
