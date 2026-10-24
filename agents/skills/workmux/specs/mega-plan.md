# Workmux combined execution plan

Historical record. Task-file tracking and its runnable prompts have been removed.

Sources: `../scripts/e2e_spawn_r2_fix.md`, `task-md.md` + `PROMPT.md`,
`sidebar-group-by-session/spec.md` + `sidebar-group-by-session/plan.md`.

## Scope and ownership

Preserve existing checkout changes. No commits, model/config pins, published
binary changes, full spawn-matrix rerun, or real GitHub operations.

| Lane | Owner | Changes and consumers | Verification |
|---|---|---|---|
| R2 fork | R2 subagent | `/tmp/e2e-codex-leftover.py` seed/wait/dialog handling; `e2e_spawn_results.md`; helper only if reproduced failure requires it | Seed→metadata self-check; isolated R2 on named boxes `mohammed` and `nurulz`; AC2.1–2.5; cleanup |
| Task tracking | task-md subagent | Only task-md spec's file plan: helper, AGENTS.md, skill task section, regression harness, paste-ready prompts; inspect existing symlink, hook, binds, ignore | Helper and harness self-checks; prefix+t resolves `task.md`; numbered IDs/status/Notes/monitor rules; no inherited TASK_FILE |
| Sidebar | sidebar subagent | Operator restore to `session`; existing config/runtime state and live panes | Headers per visible session, rows in their group, unchanged compact template and tabs; persistence; capture evidence |
| Integration | primary agent | This plan; sidebar policy in SKILL.md after task lane finishes; review touched files and shared boundaries | Relevant regression checks; reconcile evidence; report unresolved live failures truthfully |

## Execution

1. Read plans, current callers/config/tests, session Tasks and Notes. Record
   baseline dirty paths and available boxes; preserve unrelated work.
2. Run three subagents concurrently with disjoint write ownership. Sidebar
   agent does not edit SKILL.md; primary adds its policy after the task lane.
   Subagents do not rename the shared window or race on the session checklist.
3. R2 seeds a genuine conversation, waits for settled metadata, invokes the
   same-window fork helper, dismisses visible dialogs only, and validates
   lineage, placement, registry and task artifact. Record FAIL if Codex fails.
4. Task lane implements numbered Tasks and Notes instructions, sequential
   monitor protocol and prescribed prompt cases; reuse installed integration
   where already correct. Test helper resolution and the regression harness.
5. Sidebar lane restores existing CLI grouping and captures live evidence;
   no daemon/binary patch or theme changes.
6. Review integrated changes, run necessary checks, record evidence and any
   environment/product blockers. Mark only completed acceptance checks done.

## Progress

- [x] Read sources and baseline integration; both named boxes authenticated.
- [x] R2 implementation, self-check and isolated live results (both named
  boxes PASS with exact artifacts; fixture cleanup verified).
- [x] Task-md implementation and acceptance checks (helper/harness self-checks
  and actual prefix+t popup in fallback and worktree contexts).
- [x] Sidebar restore, capture and skill policy (persisted `session`, two live
  groups, duplicate indexes and a new-window capture; limits below).
- [x] Integration review and final report (remaining live sidebar limitations
  and unrun full task/spawn matrices explicitly reported).

## Risks and constraints

- Live tmux, account sessions and task state need sandbox escalation.
- Incoming TMUX_PANE is stale; helper must not accept empty tmux results as
  valid session/worktree metadata. Session task path may differ across agents.
- Existing AGENTS.md and SKILL.md changes must survive edits.
- Codex 0.162 fork projection/metadata failures must remain recorded failures.
- Sidebar `t` remains an intentional persisted override; no lock is requested.

## Verification evidence

- Existing hook checks: `test_codex_box_hooks_sync.py` (1 test) and
  `test_sidebar_working_status.py` (4 tests) passed.
- Task helper handles stale/empty pane metadata, caller cwd in post_create,
  current-branch workmux detection, detached branch `none`, and prevents tmux
  session inheritance of TASK_FILE. Migration keeps old content and file.
- Prefix+t was executed through an attached disposable tmux PTY client using
  the exact live binding and an editor stub; fallback `task.md` and
  `.worktrees/feat/.workmux/task.md` opened correctly. Prefix+. shares the
  same helper. Existing config hook, symlink and global ignore already fit.
- Six-case task-md E2E prompt added; the full boxed C1–C6 prompt was not run.
  `PROMPT.md`'s stopping condition is helper self-check plus prefix+t.
- Sidebar report: `/tmp/sidebar-verification.md`; grouped captures:
  `/tmp/sidebar-grouped-{94,95,96}.txt`. Only persisted grouping changed;
  config and tab theme preserved. Detached new-window grouping passed.
- Sidebar gap: current window's temporary sidebar stayed `Loading` after one
  restart. Explicit `none`→`--clear`→`session` settings worked, but live flat
  refresh was not observed. Navigation/filter/status-order/server-restart
  checks were not run. No published binary patch, as required by the plan.
- User-requested pane cleanup: captured the three idle planning panes, closed
  `%78`, `%61`, `%74`; kept conversation `%93` in window `@2`. Temporary
  sidebars/new window removed; other windows and sessions preserved.

## Integration review

- Standards: no remaining implementation findings. Changes reuse the existing
  helper/CLI, preserve migration/error handling, add no dependency, and keep
  unrelated dirty files intact. Self-checks cover new metadata/task parsing.
- Spec: task-md file-plan scope preserved; exact monitor protocol and C1–C6
  prompt present. Review corrected C5's missing prompt filename and added
  isolated dispatcher context. Sidebar policy and runtime pin match FR-008;
  live refresh gaps remain explicitly recorded rather than patched upstream.
- Final offline checks: helper, task harness and R2 seed-wait self-checks
  passed; changed Python parsed; shell syntax and diff whitespace passed.
- R2 final fixture `e2e-spawn-2i8T`: mohammed child `%2`, nurulz child `%4`,
  both in `$0 @0`. Each native fork's `forked_from_id` equals its seeded
  parent; exact registered pane, zero new worktrees, exact three-line c2.ok
  (pane tuple, cwd, git root), checked numbered marker. Fork helper unchanged.
- R2 also exposed scrollback-driven dialog keys and a sandbox-denied socket
  query; dismissal now reads visible screen, and the child shell is explicitly
  fixture-scoped. One actual shell approval was reviewed and accepted; this
  was an approval wait, not a model failure. Generic shell approvals are not
  blindly accepted by the driver.
- R2 shutdown hook recreated a fixture log after removal; cleanup now retries
  deletion within a bound and asserts the owned root is absent. Server/root
  and current-task generated trust stanzas were removed, preserving all
  other account/project configuration. No account model/effort changes.
- Persistent R2 results: `../scripts/e2e_spawn_results.md` (seeded-parent
  section). Final driver and full evidence: `../scripts/e2e_spawn_r2_evidence.tar.gz`.
  Final cleanup state: root absent, isolated server absent, no fixture
  leftovers. Historical matrix and R1 Task/Subagent judgement unchanged.
