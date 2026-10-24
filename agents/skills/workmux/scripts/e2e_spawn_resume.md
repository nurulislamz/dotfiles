# Workmux spawn E2E — complete

Historical record. Task-file tracking and its runnable prompts have been removed.

Continuation finished 2026-10-11. Selected matrix is closed: **29 PASS, 9 FAIL, 0 pending**.

Leftover Codex retest the same day (not a full 38 rerun): mohammed R3–R5 PASS after `hooks.json` `-ef` skip. nurulz default is now `gpt-6-luna`; R4+R5 PASS, R3 FAIL (marker unchecked, not 400). R2 both FAIL (fork session-id lookup). R1 AC1.1 still open.

## Start here (historical)

- Requirements: [e2e_spawn_plan.md](e2e_spawn_plan.md)
- Procedure: `e2e_spawn_prompt.md` (removed)
- Full table: [e2e_spawn_results.md](e2e_spawn_results.md)
- First-segment archive: [e2e_spawn_checkpoint.tar.gz](e2e_spawn_checkpoint.tar.gz)
- Continuation evidence: [e2e_spawn_r5_evidence.tar.gz](e2e_spawn_r5_evidence.tar.gz)
- Leftover Codex retest: [e2e_spawn_leftover_evidence.tar.gz](e2e_spawn_leftover_evidence.tar.gz)
- Luna retest: [e2e_spawn_luna_evidence.tar.gz](e2e_spawn_luna_evidence.tar.gz)
- Codex R2 fork fix plan: [e2e_spawn_r2_fix.md](e2e_spawn_r2_fix.md)

## Continuation fixture (deleted)

- Root: `/home/nurul/.cache/e2e-spawn-UO7x`
- Seed: `e19b86f064705860306a309c02da6a831ff6d88d`
- Isolated dispatcher: `$0 @0 %0` on `$ROOT/socket` (`-f /dev/null`)
- Marker nonce: `1079473`

`workmux add` from a process that only exported `TMUX` created the worktree with MUX `-`. Adds that produced sessions were run inside isolated pane `%0`.

## Remaining-eight verdicts

| Profile | Result |
|---|---|
| Cursor / physics | PASS — one native `Task`, `generalPurpose` / `composer-2.5-fast`, fixer `ed4b4fdd-3552-4426-b80e-0e2b332cebaa` |
| Codex / mohammed | FAIL — startup; hooks.json same-file class |
| Codex / nurulz | FAIL — startup; `gpt-6.1-sol` ChatGPT 400 class |
| AGY / chaos, mohammed, nurulz, physics | PASS — one boxed fixer pane each |
| OMP / default | PASS — one `FixerAppPy` after a rejected `task` call missing `context` |

Automatic first-pass FAIL on Cursor/physics and OMP was a dispatcher auditor bug: reply/report text mentioning `app.py` / `gh` was treated as a parent write. Re-judged from stored tool traces; parent targets were fixture/task files only.

## Leftover Codex retest (deleted fixture `e2e-spawn-1GUz`)

Sol-era nurulz R3–R5 FAIL (ChatGPT 400). Then default set to `gpt-6-luna`.

## Luna retest (deleted fixture `e2e-spawn-2v61`, seed `368d5fed…`)

| Profile | Result |
|---|---|
| Codex / mohammed R3 R4 R5 | PASS |
| Codex / nurulz R4 R5 | PASS — luna; R5 fixer `app_fixer`, pytest 2 passed |
| Codex / nurulz R3 | FAIL — tracked; marker unchecked (not 400) |
| Codex R2 both | FAIL — `fork_codex_pane.py` never got parent session id |

`codex-box` skips `hooks.json` `cp` when src `-ef` dest. nurulz default `gpt-6-luna`. Mohammed still `gpt-6.1-sol`. No workmux config.yaml pin. R1 AC1.1 still open.

## Failures retained

Original 9 still on the closed 38-row table. Codex mohammed same-file class is fixed for `workmux add`. Codex nurulz Sol-400 class is fixed by luna for R4/R5.

## Cleanup verified

Isolated `kill-server`; `list-sessions` fails; fixture root gone; `~/.cache/e2e-spawn-*` empty. User tmux (`config`, jobby worktrees) was not used as the mux target.
