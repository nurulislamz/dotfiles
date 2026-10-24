#!/usr/bin/env python3
"""Chrome Ctrl+C -> WezTerm/tmux Ctrl+V, on an unlocked Windows desktop.
Uses temporary windows, briefly takes focus, and restores the prior tmux window.
"""
import base64
from pathlib import Path
import shlex
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
URL = 'https://example.com/clipboard-test?query=chrome&value=a%20b#fragment'
WIN32 = r'''
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class Desktop {
  public delegate bool CB(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetClipboardSequenceNumber();
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
}
"@
function Windows($class, $title) {
  $script:handles = @()
  $cb = [Desktop+CB]{ param($h, $l)
    $s = New-Object System.Text.StringBuilder 256
    [void][Desktop]::GetClassName($h, $s, 256)
    $t = New-Object System.Text.StringBuilder 1024
    [void][Desktop]::GetWindowText($h, $t, 1024)
    if ($s.ToString() -eq $class -and [Desktop]::IsWindowVisible($h) -and $t.ToString().Contains($title)) {
      $script:handles += $h.ToInt64()
    }
    return $true
  }
  [void][Desktop]::EnumWindows($cb, [IntPtr]::Zero)
  $script:handles
}
function Keys($h, $keys) {
  $dummy = [uint32]0
  $current = [Desktop]::GetCurrentThreadId()
  $target = [Desktop]::GetWindowThreadProcessId([IntPtr]$h, [ref]$dummy)
  $foreground = [Desktop]::GetWindowThreadProcessId([Desktop]::GetForegroundWindow(), [ref]$dummy)
  [void][Desktop]::AttachThreadInput($foreground, $target, $true)
  [void][Desktop]::AttachThreadInput($current, $target, $true)
  [void][Desktop]::ShowWindow([IntPtr]$h, 9)
  [void][Desktop]::SetForegroundWindow([IntPtr]$h)
  Start-Sleep -Milliseconds 300
  [void][Desktop]::AttachThreadInput($current, $target, $false)
  [void][Desktop]::AttachThreadInput($foreground, $target, $false)
  if ([Desktop]::GetForegroundWindow().ToInt64() -ne $h) { throw "Cannot focus test window $h, foreground=$([Desktop]::GetForegroundWindow())" }
  [System.Windows.Forms.SendKeys]::SendWait($keys)
  Start-Sleep -Milliseconds 300
}
'''


def ps(script):
    encoded = base64.b64encode((WIN32 + script).encode('utf-16le')).decode()
    return subprocess.check_output(['powershell.exe', '-NoProfile', '-NonInteractive',
                                    '-STA', '-EncodedCommand', encoded],
                                   stdin=subprocess.DEVNULL, text=True, timeout=30).strip()


def tm(*args):
    return subprocess.check_output(['tmux', *args], text=True).strip()


def windows(cls, title=""):
    return set(ps(f"Windows '{cls}' '{title}'").splitlines())


def new_window(cls, before, title=""):
    for _ in range(40):
        added = windows(cls, title) - before
        if added:
            assert len(added) == 1, f'Ambiguous test windows: {added}'
            return int(added.pop())
        time.sleep(.2)
    raise AssertionError(f'No new {cls} window')


def keys(hwnd, text):
    ps(f"Keys {hwnd} '{text}'")


def clipboard():
    return ps("Write-Output ([Desktop]::GetClipboardSequenceNumber()); "
              "$s = [System.Windows.Forms.Clipboard]::GetText(); "
              "Write-Output ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s)))").splitlines()


if __name__ == '__main__':
    chrome_hwnd = pane = None
    session = tm('list-clients', '-F', '#{client_session}').splitlines()[0]
    previous = tm('display-message', '-p', '-t', session, '#{window_id}')
    session_literal = session.replace("'", "''")
    handles = ps("Get-Process wezterm-gui | Where-Object { $_.MainWindowTitle.Contains('❐ "
                 + session_literal + " ●') } | ForEach-Object { $_.MainWindowHandle.ToInt64() }").splitlines()
    assert len(handles) == 1, 'Cannot identify the attached WezTerm window'
    wez_hwnd = int(handles[0])
    with tempfile.TemporaryDirectory(prefix='chrome-clipboard-') as directory:
        out = Path(directory) / 'input'
        receiver = Path(directory) / 'receive.py'
        receiver.write_text('import os,tty\ntty.setraw(0)\nos.write(1,b"\\x1b[?2004hREADY")\n'
                            f'with open({str(out)!r},"ab",buffering=0) as f:\n'
                            ' while True: f.write(os.read(0,4096))\n')
        try:
            pane = tm('new-window', '-t', session, '-n', 'clipboard-regression', '-P', '-F', '#{pane_id}',
                      f'python3 {shlex.quote(str(receiver))}')
            before = windows('Chrome_WidgetWin_1')
            ps("$chrome = Join-Path $env:ProgramFiles 'Google/Chrome/Application/chrome.exe'; "
               "Start-Process $chrome -ArgumentList '--new-window','about:blank'")
            chrome_hwnd = new_window('Chrome_WidgetWin_1', before)
            escaped = ''.join('{' + c + '}' if c in '+^%~(){}' else c for c in URL)
            keys(chrome_hwnd, '^l' + escaped + '{ENTER}')
            time.sleep(2)
            for mode in ('normal', 'vi', 'emacs', 'blank-selection'):
                if mode in ('vi', 'emacs'):
                    tm('set-window-option', '-t', pane, 'mode-keys', mode)
                    tm('copy-mode', '-t', pane)
                    tm('send-keys', '-t', pane, '-X', 'begin-selection')
                    tm('send-keys', '-t', pane, '-X', 'cursor-down')
                keys(chrome_hwnd, '^l^c')
                copied = clipboard()
                assert base64.b64decode(copied[1]).decode() == URL, 'Chrome Ctrl+C failed'
                if mode == 'blank-selection':
                    subprocess.run([str(ROOT / 'tmux/clip.sh'), 'copy'], input=b' \n', check=True)
                    assert clipboard() == copied, 'Blank selection overwrote the Chrome URL/history'
                out.write_bytes(b'')
                keys(wez_hwnd, '^v')
                for _ in range(50):
                    data = out.read_bytes()
                    if data:
                        break
                    time.sleep(.1)
                after = clipboard()
                expected = b'\x1b[200~' + URL.encode() + b'\x1b[201~'
                print(f'{mode}: clipboard sequence {copied[0]} -> {after[0]}; input={data!r}', flush=True)
                assert after == copied, 'Ctrl+V rewrote the Windows clipboard/history'
                assert data == expected, f'Ctrl+V did not deliver exactly one bracketed URL: {data!r}'
                print(f'ok: Chrome Ctrl+C -> Ctrl+V ({mode}); clipboard/history unchanged', flush=True)
        finally:
            if chrome_hwnd:
                ps(f'[void][Desktop]::PostMessage([IntPtr]{chrome_hwnd}, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)')
            if pane:
                tm('kill-window', '-t', pane)
            tm('select-window', '-t', previous)
