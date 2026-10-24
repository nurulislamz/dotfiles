# Plan: remaining workmux live verification

Historical record. Task-file tracking and its runnable prompts have been removed.

Status: executed 2026-10-11; C1–C6 success paths and isolated sidebar checks PASS. Overall acceptance BLOCKED: historical Loading cannot be reproduced, C6 live failure paths untested, originating pane absent at final inventory. Results: [live-verification-results.md](live-verification-results.md).

Sources: `task-md.md` (removed),
six-case prompt (removed),
[completed mega plan](mega-plan.md),
[sidebar specification](sidebar-group-by-session/spec.md).

## Outcome

Prove the six task.md cases with real children, especially unattended monitor
ordering and mid-run additions. Diagnose the current-window sidebar `Loading`
failure, then verify the sidebar interactions left unchecked.

Previous R2 passes and offline checks remain valid. Do not repeat the full
38-case matrix or rewrite the historical report.

## Scope and gates

- Box gate fulfilled by the user-selected launcher account `mohammed`; available boxes listed and launcher identity verified. Do not repeat selection. Configured model/effort/service defaults preserved.
- Use the existing six-case prompt and native agent capabilities. Cursor
  children retain its specified generalPurpose/model restrictions.
- Disposable fixtures under `~/.cache`, isolated tmux socket, isolated state,
  and worktrees under the fixture's `.worktrees/`. No real repo changes.
- Only the initial disposable fixture commit is needed. No push, merge,
  real GitHub operation, new runner, dependency, or published binary patch.
- Keep this conversation pane and other real sessions intact. Resolve fresh
  pane IDs rather than reusing historical `%93`, `@2`, or stale environment.
- Record baseline config/settings/theme/focus before sidebar tests. Prefer
  isolated reproduction; restore settings through the CLI, not live JSON edits.

## Phase 1 — live C1–C6, sequential

One dispatcher executes `e2e_workmux_prompt.md`; it delegates the child work
and audits actual tool targets. Cases do not overlap. C6 has one monitor and
one worker on a fresh task.md; the monitor never performs the worker's work.

| Case | Required evidence |
|---|---|
| C1 | Native in-process child; same fixture cwd/git root; no new pane; completed numbered task and generated test fact in parent Notes |
| C2 | Same session/window fork or allowed split; exact registered child pane; no worktree; child reads C1 fact from Notes and reproduces it exactly |
| C3 | New session/worktree; own resolved task.md; parent file byte-identical; path/list/status/capture identify the child |
| C4 | Review overlay placement; both defects in REVIEW.md and Notes; reviewer does not edit app.py |
| C5 | Exactly one fixer; actual tool writes prove only fixer changed app.py; both fixture comments answered; pytest passes; both agents use numbered Tasks/Notes |
| C6 | Monitor assigns T1→T2→T3; T4 appended while T1 is working and runs last; IDs/titles preserved; T2 reads T1 Notes; no worker self-selection |

For C6, capture the exact assignment messages and observed status transitions.
Check future tasks/output files before each assignment. Verify the monitor
never treats `[!]` or a stalled `[>]` as completion; keep those observations
under C6, not new numbered cases. Do not claim failure-path coverage unless
observed. A full live monitor PASS is required before unattended use.

All children resolve `TASK_FILE=$(tmux-tasklog path)` themselves, read Tasks
and Notes, and do not inherit a preset TASK_FILE. Wrong file or placement is
FAIL even when the child produces the requested output.

Allow up to 120 seconds for startup and seven minutes per child turn or
assigned C6 ID; allow 15 minutes for C5's orchestrator/fixer case. Share
progress at least once per minute. On timeout preserve captures/status and
report BLOCKED, never mark the task done. Review a pending shell command
before approving it; never blindly accept a visible approval dialog.

If C1 is unavailable, report BLOCKED; C2's Notes handoff cannot pass without
the C1 fact. Missing Codex conversation ID also blocks C2; no fresh split
substitution. Continue independent later cases as the existing prompt allows.

## Phase 2 — sidebar Loading diagnosis

1. Reproduce in the actual conversation window with temporary sidebar panes;
   compare with a fresh detached window and an isolated server. Capture pane
   output, daemon/client logs, process state, socket context and settings.
2. Allow up to 30 seconds for refresh, rather than the previous one-second
   observation. Distinguish delayed refresh, stale client registration,
   socket/context mismatch, and configuration before choosing a fix.
3. Use existing CLI recovery first. Inspect local CLI help/source before
   suggesting flags or daemon controls. Never restart the real tmux server.
4. If a local helper/config defect is proven, inspect all callers and fix it
   once with a small regression check. Limit edits to the implicated existing
   workmux helper/config and test; leave themes, grouping policy and account
   settings alone.
5. If the published binary is the cause, stop at an evidence-backed report
   and tested reversible workaround if available. Do not upgrade or patch it
   under this plan. Loading unresolved means affected interaction checks stay
   BLOCKED, even if a fresh window renders correctly.

## Phase 3 — sidebar interactions after rendering works

Use two fixture sessions from the same project, with colliding window indexes
and tracked agents. Inspect existing CLI help for the supported operations.

- Group `session`: one header per visible session, correct row ownership.
- Group `none`, then `--clear`: capture actual flat→grouped refresh; restore
  the final explicit `session` preference.
- Filter to the current session, then restore: its header/rows only.
- Change fixture agent statuses: sorting stays within each session group.
- Exercise next/prev/jump: navigation follows grouped order and skips headers.
- Create a new fixture window and restart only the disposable tmux server:
  grouping persists. The real server and conversation remain running.

Fixture success and actual-window recovery are separate results. An isolated
restart does not prove that restarting the user's live server would work.

## Evidence and cleanup

Write `specs/live-verification-results.md`: six C1–C6 PASS/FAIL/BLOCKED rows,
sidebar checks, exact acceptance evidence, observed failure causes, and cleanup.
Archive final captures, assignment/status history, artifact snapshots and
reviewed tool-target evidence beside the existing workmux evidence archives.
Do not include credentials or entire account configurations.

Always clean in finally: remove only this run's worktrees/panes/server/root;
verify absence after late shutdown hooks. Remove only trust stanzas generated
for this run's exact fixture paths, preserving unrelated config bytes. Restore
sidebar settings, focus and pane layout; keep only the conversation pane in
its window. Preserve all unrelated user changes.

## Completion checklist

- [x] Box selected and isolated fixture/dispatcher established (initial dispatcher XDG fallback deviation reverted; see results).
- [x] C1–C6 live success results recorded; C6 ordering/mid-run append proven.
- [ ] C6 live blocked/stalled-worker failure paths: NOT RUN; unattended failure recovery unverified.
- [ ] Actual-window Loading root cause: BLOCKED, symptom absent in existing, temporary and fresh-window clients after >30 seconds; no causal fix claimed.
- [x] Isolated sidebar grouping/clear/filter/status/navigation/new-window/server-persistence checks PASS; historical diagnosis separately BLOCKED.
- [x] Evidence saved; owned fixtures/worktrees/servers/trust tables removed; real settings/theme/config layout preserved.
- [ ] Originating pane preservation: FAIL / cause unconfirmed; %93/@2 disappeared during run, user clarification unanswered. Config executor remains open.

Not included: full 38-case matrix, separate R1 Task/Subagent rejudgement,
standalone R3–R5 reruns, real gh/PR operations, binary upgrade/patch, or a real
tmux-server restart. C3–C5 here check the new task.md contract rather than
reopening the historical spawn matrix.

## Observed execution limits

Only the initial disposable seed was committed. No code/binary/account-default changes, real-server restart, gh/PR, push, or full historical matrix. All temporary root resources were cleaned. Existing fallback tasklog edit was reverted after explicit XDG isolation. C6 success PASS does not cover live failure/stall handling. Historical Loading is not reproducible now, so diagnosis remains blocked. Final origin-pane absence prevents claiming complete real-pane preservation. See results and archived evidence for actual tool-target and cleanup assertions.
