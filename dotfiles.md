# Fresh-machine dotfiles install

Instructions for humans and agents restoring this checkout. Repo files are the
source of truth; edit them here, then rerun the installer. Do not copy live
credentials, sessions, caches or task logs into Git.

## 1. Clone

Install Git and Python 3 first. Use HTTPS, or SSH once GitHub SSH access works:

```sh
git clone https://github.com/nurulislamz/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Keep this directory: installed configs and commands are symlinks into it.

## 2. Packages

### Linux / Surface Linux / WSL

Use the distro package manager for Git, Python 3, zsh, tmux, ripgrep, fd, fzf,
zoxide, a C compiler and unzip. For Debian/Ubuntu, the basic packages are:

```sh
sudo apt update
sudo apt install git python3 zsh tmux ripgrep fd-find fzf zoxide build-essential unzip curl
```

Install Neovim, lazygit, sesh and WezTerm separately when the distro does not
provide suitable versions. The shell uses `fzf --zsh`; check that the installed
fzf supports it. Debian/Ubuntu name the fd executable `fdfind`; if `fd` is absent:

```sh
mkdir -p ~/.local/bin
ln -s "$(command -v fdfind)" ~/.local/bin/fd
```

Install Cascadia Code, JetBrainsMono Nerd Font and Noto Color Emoji through the
desktop/font package tools. WezTerm uses those names in `wezterm/wezterm.lua`.
On WSL, install WezTerm/fonts on Windows; its Windows config selects WSL:Ubuntu.
Link/copy the tracked WezTerm directory into the Windows user's WezTerm config
location separately; the Linux installer only sets up the Linux home directory.

This repo has no Surface kernel, touchscreen, pen, firmware or suspend setup.
Restore those as separate machine-specific work. Linux WezTerm currently uses
WebGpu; if graphics fail, diagnose that setting on the target machine.

### macOS

Install Homebrew, then:

```sh
brew bundle --file=~/dotfiles/Brewfile
brew install zsh
```

The Brewfile installs editor/terminal tools and fonts. It includes macOS casks;
on Linux use the Linux package path above rather than assuming the whole
Brewfile is portable.

## 3. Shell theme and plugins

The installer does not install these. On a fresh machine, clone them before
opening the configured zsh shell:

```sh
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

Skip clones whose destinations already exist; inspect existing installs first.
After restoration, run `p10k configure` inside zsh. `~/.p10k.zsh` is local and
not restored by this repo. Optional nvm, Go and OpenClaw setup is also separate.

## 4. Preserve real CLI binaries before linking wrappers

Install native workmux first, then copy its actual executable before the
installer puts this repo's wrapper at `~/.local/bin/workmux`:

```sh
mkdir -p ~/.local/libexec
cp "$(command -v workmux)" ~/.local/libexec/workmux
chmod +x ~/.local/libexec/workmux
```

Only use that copy command before installing the wrapper. On an existing
machine, inspect `command -v workmux` and its symlink target first; never copy
the wrapper over the native binary. The current dashboard config uses the
custom `session` column. The matching native workmux build is not contained in
this repo; obtain that build or explicitly adjust the column list for a stock
binary. Box launchers additionally need bubblewrap on Linux.

If using Antigravity, install its real CLI first and preserve its executable
as `~/.local/bin/agy-real`, or set `AGY_REAL_BIN` to its real path. The installer
replaces `~/.local/bin/agy` with a wrapper. That wrapper and the shell aliases
default to `--dangerously-skip-permissions`; use only with that behavior intended.
Use the agent setup script below to install missing agent CLIs and recreate profiles.
Authentication remains separate.

## Agent tools and saved box inventory

For Linux, Surface Linux and WSL, after installing the package prerequisites:

```sh
sudo apt install curl git python3 tmux bubblewrap
bash ~/dotfiles/scripts/setup-agents.sh
```

The script installs missing Antigravity, Codex, Oh My Pi (`omp`) and Cursor Agent
CLIs, preserves the real AGY executable before linking its wrapper, then runs
`scripts/install.py`. This restores all dotfiles links, including shell
and editor configuration. Existing replacements use the installer's backups.
It also links shared rules at `~/.omp/AGENTS.md` and `~/.config/omp/AGENTS.md`,
and the workmux skill at `~/.omp/agent/skills/workmux`; replaced OMP paths are
backed up under `~/.local/state/vsvimsettings/backups/agents-<timestamp>-<pid>/`.

Profile names captured on 2026-10-17 (including spare/test profiles):

| Launcher | Profiles | Local storage |
| --- | --- | --- |
| `agy-box` | `chaos`, `missing`, `mohammed`, `nurulz`, `physics`, `worker1` | `~/.agy-containers/` |
| `codex-box` | `dev`, `mohammed`, `nurulz` | `~/.codex-containers/` |
| `agent-box` / `cursor-box` | `box-a`, `box-alpha`, `nurulz`, `physics` | `~/.agent-containers/` |
| `omp` | One host configuration; no box launcher | `~/.omp/` |

The names live in the script arrays. Update those arrays when adding profiles.
Rerunning skips installed CLIs and existing box directories. Each created box
gets a small directory-existence check. No existing profiles are deleted, and
no login is performed. A partial failed run can be rerun after fixing its error.

Authenticate each account on the target machine:

```sh
agy-box nurulz
codex-box nurulz login
agent-box nurulz login
omp
```

Repeat for the other boxes you use; complete OMP's provider login inside OMP.
Keep `~/.local/bin` on PATH. If using a custom `AGY_REAL_BIN`, export that same
path in future shells too. The standard preserved path is `~/.local/bin/agy-real`.

Tracked: launcher code, named-profile inventory, shared instructions, workmux
skill and workmux configuration. Not transferred: credentials,
API keys, sessions/history, machine trust, private MCP configuration, extra
locally installed skills/extensions, or per-account model/provider settings.
OMP's local databases and `~/.omp/agent/config.yml` stay outside Git.
The script uses the existing AGY permission bypass and Cursor trust/auto-review/
MCP-approval defaults; these boxes share the host home directory and are account
separation, not isolation from your files. Native workmux (including the custom
Session-column build) is still a separate prerequisite for dashboard use.

Install sources: [Antigravity](https://github.com/google-antigravity/antigravity-cli),
[Codex](https://github.com/openai/codex),
[OMP](https://github.com/can1357/oh-my-pi), and
[Cursor Agent](https://cursor.com/docs/cli/installation).
Only missing CLIs are downloaded; installed versions are retained.

## 5. Restore links and plugins

```sh
~/dotfiles/scripts/bootstrap
```

Bootstrap runs Brewfile installation when `brew` exists, restores links,
restores Neovim's locked plugins, and attempts tmux plugin installation.
On Linux with Homebrew installed, avoid its macOS casks: run these steps manually:

```sh
python3 ~/dotfiles/scripts/install.py
nvim --headless '+Lazy! restore' +qa
```

Then open tmux and install TPM plugins with prefix + I. Rerun the installer
after tmux plugins exist so the tracked tmux-which-key config is linked too:

```sh
python3 ~/dotfiles/scripts/install.py
```

The installer clones oh-my-tmux if missing. Network access is needed for that,
Neovim plugins, tmux plugins and WezTerm plugins. WezTerm loads resurrect,
modal, replay and cmdpicker on startup; `wezterm/wezterm.sh` supplies shell
semantic zones for replay.

Links cover Neovim, WezTerm, zsh, tmux, workmux, Zed, shared agent rules,
the workmux skill and helper commands. Agent hooks are removed from host and
box configs while other settings are preserved. Replaced configs are backed up under
`~/.local/state/vsvimsettings/backups/<timestamp>/`. Rerunning preserves
correct links and settings. Ghostty and IdeaVim configs remain stored
only; the installer does not apply them.

Make `~/.local/bin` available on PATH. Start zsh and, if desired, set it as the
login shell with `chsh -s "$(command -v zsh)"` where the OS permits it.
Install language servers/toolchains needed by your projects through Mason and
the relevant language tools. Restore secrets through local secure storage;
the optional Command Code file is `~/.secrets/commandcode.env`.

The shell's `open` alias expects `~/.local/bin/open`, which this repo does not
provide. Restore that local helper or explicitly adjust the alias on the new
machine. Authentication and machine trust are not transferred. Agent hooks stay
disabled. Agents name their tmux window once at session startup through `AGENTS.md`.

## 6. Verify on the target machine

Run only when requested by the user; this command executes test checks:

```sh
~/dotfiles/test/run.sh
```

Manually open zsh, Neovim, tmux and WezTerm. Check fonts, clipboard, language
servers, workmux dashboard and shell suggestions. WezTerm and tmux both use
Ctrl+A as a prefix/leader; check nested key handling on the target machine.
`scripts/sandbox-linux.sh` is an optional empty-home smoke check;
`scripts/regression-check.sh` targets the original WSL host, not a fresh machine.

For later sync, inspect local changes, pull without overwriting them, then run
`python3 ~/dotfiles/scripts/install.py` again. Read `README.md` and installer
source if this guide and checkout differ; do not silently replace machine-local
settings or credentials.
