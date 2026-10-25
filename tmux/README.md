# tmux config

Based on [oh-my-tmux](https://github.com/gpakosz/.tmux). All personal tweaks live in
`.tmux.conf.local` (theme, plugins, status bar) — the upstream `.tmux.conf` is never edited.

## What's customised

- **Theme**: oh-my-tmux repainted with the Catppuccin Mocha palette (17 colour slots).
- **Tabs**: rounded (Chrome-tab) separators via the semicircle Powerline glyphs.
- **Status right**: stripped to flag indicators only (prefix / mouse / pairing / sync) —
  no battery, clock, date, user, or hostname.
- **Plugins**: which-key (`prefix + Space`), tmux-fzf (`prefix + F`), sessionx,
  smooth-scroll, resurrect + continuum (auto-save 15m, restore on server start),
  assistant-resurrect. nvim buffers come back via persistence.nvim, not Session.vim.

## Install

`scripts/bootstrap` clones oh-my-tmux, links this file, and installs plugins.
Links only:

```sh
python3 ~/dotfiles/scripts/install.py
```

Needs a Nerd/Powerline font for the rounded tab glyphs (JetBrains Mono Nerd works).

## Windows clipboard

WezTerm routes Ctrl+V to tmux when the process, shell marker, or terminal title
identifies tmux. In copy mode, tmux cancels the selection before it pastes from
the Windows clipboard through `tmux/clip.sh`.

The helper ignores empty and whitespace-only copies, so blank mouse selections
cannot replace a copied Chrome URL. PowerShell writes clipboard text without
an added newline and preserves Unicode. A failed read stops before tmux can
paste a stale buffer. The helper requires Windows `clip.exe` and `powershell.exe`.

A Chrome plain-text copy of inline text such as `Roadmap / Frontend Beginner`
can arrive as `Roadmap`, a line containing only `/`, then `Frontend Beginner`,
because the slash is its own element. `paste-buffer` would turn those breaks
into carriage returns and the shell would execute `/`. `clip.sh paste` joins
that separator line back into `Roadmap/Frontend Beginner`. Other multiline
pastes keep their line breaks.

Run the regression on an unlocked Windows desktop with Chrome installed and
WezTerm attached to tmux using the standard tmux window title:

```sh
~/dotfiles/tmux/clip_test.sh
```

The test opens temporary Chrome and tmux windows and briefly takes focus.
It navigates to a test URL, copies Chrome's address with Ctrl+C, and sends Ctrl+V
to WezTerm in normal, vi, and emacs modes. It checks the exact pasted bytes and
that each paste leaves the Windows clipboard sequence number unchanged.
It also checks that a blank selection preserves the copied URL.
The test closes its windows and restores the previous tmux window.
The test URL remains in the clipboard.

`tmux/test_clipboard.py` checks blank selections, Unicode, trailing newlines,
and failed reads without touching the real clipboard. `test/run.sh` runs the
portable tmux check plus `tmux/test_clipboard.py`. On this WSL host it also
runs `test/live/clip_test.sh` (WezTerm keys + Chrome keyboard test).

## Task logging removed

Session task files, the `tmux-tasklog` helper, the tmux session-creation hook,
and the Workmux `post_create` task hook are retired. Prefix+t and Prefix+.
are unbound. The shell no longer exports `TASK_FILE`, and the shared agent
rules no longer require task-file tracking. Existing task notes remain on disk.
Agent hooks are removed. The installer clears host and box hook configs, and
tmux-assistant-resurrect cannot install Claude, Cursor or OpenCode hooks.
Automatic Workmux status updates are disabled. Agents name their tmux window
once at session startup through `agents/AGENTS.md`.
