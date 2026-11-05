# Personal dotfiles

`dotfiles` is the source of truth for Neovim, Foot, WezTerm, zsh, tmux
customizations, shared agent instructions
and box launchers. Installed paths point here; edit and commit files in this
repo.

## Restore

Clone this repo to `~/dotfiles`. On a Mac with Homebrew, run:

```sh
git clone git@github.com:nurulislamz/dotfiles.git ~/dotfiles
~/dotfiles/scripts/bootstrap
```

`bootstrap` runs `brew bundle` from `Brewfile`, then `scripts/install.py`, then
restores Neovim plugins from `lazy-lock.json` and installs tmux plugins.
Packages already present? Links only:

```sh
python3 ~/dotfiles/scripts/install.py
```

The installer links Neovim, Foot, WezTerm, `.zshrc`, tmux's local config, oh-my-tmux
(`~/.tmux-omt` cloned if missing), shared rules, skills and
helper commands. It removes agent hooks from host and box configs while
preserving other settings. Replaced files and directories are preserved in
`~/.local/state/vsvimsettings/backups/<timestamp>/`, with their original paths.
Running it again leaves correct links and settings alone.

Keep `~/.local/bin` on PATH. Authenticate agent CLIs separately. Agent hooks
are disabled. This repo does not copy credentials or machine trust.

Box launchers need bubblewrap and are Linux only. Existing Codex and AGY boxes sync host rules on
their next launch.

The installer also links Zed's `settings.json`, `keymap.json` and `tasks.json`.
Ghostty and IdeaVim stay stored; the installer does not apply them.

## Agent setup (Linux/WSL)

Install `curl`, `git`, `python3`, `tmux` and distro `bubblewrap`, then:

```sh
bash ~/dotfiles/scripts/setup-agents.sh
```

Installs missing AGY/Codex/OMP/Cursor CLIs, restores dotfiles, and recreates the
saved box names. Existing accounts remain; sign in separately on new machines.
See [agent inventory and setup details](dotfiles.md#agent-tools-and-saved-box-inventory).

## Neovim

All configuration lives under `nvim/`, including `lazy-lock.json` and Tree-sitter
queries. The installer restores `~/.config/nvim` as a link. `scripts/bootstrap`
runs `:Lazy restore`. Mason installs configured language servers. Install language
tools for the projects you edit.

Plugins, Mason downloads, sessions, caches and machine-specific authentication
are regenerated or kept locally, rather than committed. Older copies of the
config are available in Git; restore the complete directory from one commit:

```sh
git restore --source=<commit> -- nvim
git add nvim
git commit -m 'Restore Neovim configuration'
```

## Check

```sh
~/dotfiles/test/run.sh
```

Empty-HOME Linux smoke (links + tmux load, no plugin downloads):

```sh
~/dotfiles/scripts/sandbox-linux.sh
```

`scripts/regression-check.sh` is a live WSL host audit, not the portable installer test.
