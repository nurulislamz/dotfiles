---
name: workmux
description: >-
  Manages git worktrees paired with tmux sessions via the workmux CLI,
  including same-window Codex conversation forks.
  Use when the user mentions workmux, wm, worktrees, parallel agents,
  isolated branches, workmux add/merge/list/remove/rename, dispatching
  boxed agents into worktrees, or forking the current chat into a sibling pane.
---

# workmux

Shared by Cursor, Codex, Claude, OpenCode, and Antigravity. Source: `<repo>/agents/skills/workmux` in the dotfiles repo (`dirname "$(readlink ~/.config/nvim)"`). Installed skill dirs and `~/.config/agents/skills/workmux` link here; edit the dotfiles source. Restore links, helpers, rules and hooks with `python3 <repo>/scripts/install.py`.

Binary: `~/.local/bin/workmux` (`workmux 0.1.271`).
Global config: `~/.config/workmux/config.yaml`.
Docs: https://workmux.raine.dev/guide/skills/

Each worktree is an isolated workspace: own branch, directory, tmux session, and agent.

## This machine

```yaml
worktree_dir: .worktrees   # inside the repo, not sibling __worktrees
mode: session              # one tmux session per worktree
status_format: false
```

Sidebar MUST stay `group_by: session` (worktree ≡ session). Tmux blocks `t`
in sidebar panes. Do not run `workmux sidebar group` unless the user asks. Restore with
`workmux sidebar group session`; its persisted preference overrides config.

**Boxed agents.** Reuse the box already authorized for this task. If none was named, list boxes and ask which one; never invent a box or default to bare `codex` / `agy` / `agent`.

```bash
codex-box list      # ~/.codex-containers  (dev, mohammed, nurulz, …)
agy-box list        # ~/.agy-containers    (Antigravity)
cursor-box list     # ~/.agent-containers  (same as agent-box)
opencode-box list
```

Launch is `<tool> <box> [args]`, e.g. `codex-box mohammed`. Bare `codex` is the unboxed ChatGPT login; `gpt-6.1-sol` and `gpt-6-sol` 400 there. `codex-box nurulz` is that ChatGPT account — default `gpt-6-luna`. Sol (`gpt-6.1-sol`) is `codex-box mohammed`.

Model, effort, and `fast` are optional spawn parameters. Do not pin them in `~/.config/workmux/config.yaml`. If the user omits them, do not invent values. If they ask what they can set: model slug, effort (`low|medium|high|xhigh`), `service_tier=fast`.

```bash
# after the user names the box (and optional model/effort/fast)
# skip Codex update/NUX prompts — there is no workmux hook for those
codex-box <box> -m <model> -c model_reasoning_effort="<effort>" -c service_tier="fast" -c check_for_update_on_startup=false
```

Workmux hooks (`post_create`, `pre_merge`, `pre_remove`, `workmux setup --hooks`) do not dismiss agent TUI questions. `post_create` runs before the pane exists; setup hooks only set working/waiting/done. Always pass `-c check_for_update_on_startup=false` on Codex/codex-box pane commands so the update prompt does not block.

After `workmux add`, create/open the Codex window via workmux (do not type the launch command into a leftover shell). Then `workmux capture` / `tmux capture-pane`. If a TUI dialog is up, answer it with `tmux send-keys` — prefer skip/decline upgrades (`n`, highlight Skip/No + Enter, Esc). `F2` opens the warning tray; Esc dismisses it. `-P` with a custom overlay `command:` writes `.workmux/PROMPT-*.md` but does not inject into Codex; once the composer shows `Ask Codex to do anything`, `workmux send <handle> "$(cat …/PROMPT-*.md)"`. Do not expect-script a general wizard.

`workmux add -a` only takes an agent name, not `-m` or a box. Put the full boxed command in the pane (one-off `--config`). `-l` cannot combine with `-a`. Named layouts cannot set `windows`.

Review overlay (window 1 `nvim`, window 2 agent): copy `~/.config/workmux/review.yaml` to a temporary overlay and replace its `codex` pane command with the authorized boxed command, including `-c check_for_update_on_startup=false`. The stored file is a template, not a ready-to-launch account selection.

```bash
workmux add <handle> --config <boxed-review-overlay> -b -P "$tmpfile"
```

Put a worktree **in the current tmux session**: `--mode window --parent-session "$(tmux display-message -p '#{session_name}')"`. Default config is still session-per-worktree.

Existing tree, dead/wrong pane: `workmux close <handle>` then `add -o` with the boxed command. `status`/`capture` stay empty until `workmux setup --hooks`; confirm via the pane command.

`workmux rename <old> <new> [-b]` renames worktree/session; `-b` also renames the branch.

- Handle = slugified branch/directory name. Use it in every command.
- Path = `<repo>/.worktrees/<handle>`
- Worktree commands target a tmux session. Same-context forks stay in the current window.
- Prefer `workmux` for worktrees; use the helper below for interactive same-window forks.

## Dispatcher vs implementer

If the user asks to create worktrees or dispatch tasks (`workmux add`, "spin this off", "run this in a worktree"):

1. You are a **dispatcher**. Do not explore, grep, or implement first.
2. Write prompt files from context you already have. Ask if that is not enough.
3. Run `workmux add`. The worktree agent does the work.
4. Stop once worktrees exist. Do not implement in the current tree.

If the user asks you to **do the work in the current checkout**, implement here. Do not spawn worktrees unless asked.

## Same-context Codex pane

For "fork this chat below" or "open a sibling pane with the same context", keep the current directory, branch, tmux session, and window. Do not `workmux add` — that creates a new workspace.

```bash
python3 ~/.config/agents/skills/workmux/scripts/fork_codex_pane.py --direction below
# --direction right for a pane beside this chat
# --dry-run to preview
```

Reads the current conversation ID from the environment. If missing, pass `--session-id <exact-id>`; do not use `--last`.

On this machine it launches `codex-box <current-account> fork --no-daemon <exact-id>` (or `codex fork` outside a box). `--no-daemon` avoids the missing app-server socket. `workmux run` disconnects stdin and is unsuitable.

Clears inherited parent session/relay/status IDs, verifies `forked_from_id`, and registers the pane if the startup hook did not. Success = live pane in the requested location and an entry in `workmux status --all --json`. Forked chats start idle unless the user gives a task.

If startup fails, inspect the named pane. Do not create another pane blindly. Leave the shared window/session name unchanged.

## Commands

```bash
workmux add <branch>                 # create worktree + tmux session
workmux add <branch> -b              # background (do not switch)
workmux add <branch> -b -P <file>    # background + prompt file for agent pane
workmux add <branch> -p "prompt"     # inline prompt
workmux add <branch> --headless --json   # no multiplexer (testing)
workmux add <branch> --dry-run       # print plan, no changes
workmux add --pr <n|url>             # checkout a PR (needs gh)
workmux list
workmux open <handle>
workmux close <handle>               # close session, keep worktree
workmux path <handle>
workmux merge [handle]               # merge into main + cleanup
workmux remove <handle>              # cleanup without merging
workmux rename <old> <new> [-b]      # rename worktree/session; -b also renames branch
workmux status
workmux wait <handle>...
workmux capture <handle> [-n 50]
workmux send <handle> "instruction"
workmux run <handle> -- <cmd>
workmux dashboard
```

Useful `add` flags: `--base <ref>`, `--name <handle>`, `-o` (open if exists), `-a <agent>`, `-w` (move uncommitted changes), `-H`/`-F`/`-C` (skip hooks / file ops / pane cmds).

`send` / `capture` / `status` / `wait` / `run` accept `project:handle` when names collide.

## Dispatch workflow

Write **all** prompt files first, then run **all** `workmux add` commands.

```bash
tmpfile=$(mktemp).md
cat > "$tmpfile" << 'EOF'
<self-contained task>
Use relative paths. Inspect any absolute attachment paths given by the user.
EOF

# only after the user named the box (and any model/effort)
workmux add <kebab-handle> -b -P "$tmpfile" --config <overlay-with-boxed-pane>
```

Prompt rules:

- Self-contained. The worktree agent cannot see this conversation.
- Relative paths inside the repo. Preserve absolute paths to attachments.
- If the user named a skill (`/merge`, `/auto`), tell the worktree agent to use it. Do not expand the skill into steps.

Run `workmux add` from the **current directory** for same-repo tasks. Do not `cd` to main. New worktrees branch from the current HEAD unless `--base` is set.

`workmux add` must run **inside** the target tmux pane. A host process that only exports `TMUX=` creates the worktree with MUX `-`.

Do not send `n`/`3` into Cursor, or into a Codex composer that is already on the prompt. Skip/Esc (Codex update) or AGY folder-trust Enter only while that dialog is on screen.

OMP native `task` needs `context`. When auditing whether a parent edited `app.py` or invoked `gh`, inspect tool targets — not reply text.

Cross-project: set the command cwd to that repo. Pass `--parent-session <repo-basename>` when window placement matters.

## Finish work

**Local merge** (current worktree): commit, rebase onto the local base branch (never `git fetch` / `origin/*` unless asked), then:

```bash
workmux merge --rebase --notification
```

Base branch:

```bash
git config --local --get "branch.$(git branch --show-current).workmux-base"
```

Default `main` if unset.

**PR workflow:** commit, push, open PR. After remote merge: `workmux rm --gone`.

**Coordinator loop** (only when asked to manage agents through completion):

1. `workmux wait <handles> --status working --timeout 120`
2. `workmux wait <handles> --any --timeout 7200`
3. `workmux status` + `workmux capture <done> -n 50`
4. Review, then `workmux send <done> "/merge"` one at a time
5. Repeat until every handle is merged or removed

## Config

Two levels: `~/.config/workmux/config.yaml` (global) and `.workmux.yaml` (project). Project wins.

```bash
workmux init              # example .workmux.yaml
workmux config reference  # full option list
workmux setup --skills    # install bundled skills to Claude/OpenCode/Pi/OMP
```

`<agent>` in pane commands resolves to the configured agent.

## Related bundled skills

Installed by `workmux setup --skills` for Claude/OpenCode/Pi/OMP:

- `/worktree` — fire-and-forget dispatch
- `/coordinator` — spawn, wait, review, merge
- `/merge` — commit + rebase + `workmux merge`
- `/rebase` — rebase with conflict handling
- `/open-pr` — PR description from conversation context
