---
date: 2026-07-04
type: session
tags: [session]
---

# Session: Autobuild harness + bypass-permissions

**Objective:** Turn the phikestrel build plan into automatic one-task-per-run steps
with usage-limit auto-relaunch, and set the project to bypass permission prompts.
**Context:** Picked up from `2026-07-04-review-instructions-and-session-logs` — repo
had `phikestrel-SETUP.md` (phased plan) + Opus review instructions + session logs.

## What happened
- Built the **autonomous build harness** under `automation/`:
  - 9 PR-sized task files (`tasks/00-scaffold.md` … `60-phenotype-plugin.md`),
    covering Phases 0–6; Phase 7 (ROGER) stays hands-on and is not automated.
  - `PREAMBLE.md` — standing rules prepended to every run (stdlib-only core,
    never-guess, provenance, green gate, finish-with-a-PR-then-stop).
  - `PLAN.md` — human-readable step map. `README.md` — ops guide.
  - `autobuild.sh` — bash runner: picks first unfinished task, pipes
    `PREAMBLE + task` to a fresh `claude -p`, tracks progress in `.progress`
    (gitignored), and **auto-relaunches on usage limit** (greps the limit message,
    sleeps `PHIKESTREL_RETRY_SECONDS`=1800s, retries the same task). The wrapper is
    plain bash and consumes no Claude usage itself.
- **Fixed a real bug before it bit:** the runner bases `auto/build` on `origin/main`;
  `automation/` was only on local main, so a checkout would have deleted the task
  files mid-run. Resolved by pushing main to origin.
- **Verified plumbing:** WSL git commits fine in this repo (only `git config` hits the
  9p chmod gotcha, per [[wsl-git-config-chmod]]); wired `gh auth setup-git` as git's
  credential helper so unattended `git push` / `gh pr create` work; pushed `main`.
- **Set project permission mode to `bypassPermissions`** in `.claude/settings.json`
  (merged in, SessionStart hook preserved). Committed + pushed.
- Runner is **ready but not started** — left to Martin (burns the premium window,
  runs with `--dangerously-skip-permissions`).

## Decisions
| Decision | Rationale |
|----------|-----------|
| One accumulating PR (`auto/build`→`main`), one commit per task | Stacked per-task PRs are fragile to drive unattended; still reviewed per-task, no auto-merge |
| Runner defaults to `--dangerously-skip-permissions` | Headless runs can't answer permission prompts; only acts in this repo, never merges |
| `bypassPermissions` in committed project settings (not local) | User asked project-wide; can move to `settings.local.json` if they want it machine-only |
| Prefer merge commits over squash when merging PRs | Keeps the runner's rebase of `auto/build` onto new `main` clean |
| ROGER (Phase 7) excluded from automation | Needs the real cluster; stays supervised |

## Next steps
- [ ] **Start the runner** + watch the first task (Phase 0 scaffold):
      `cd /mnt/z/phikestrel && nohup bash automation/autobuild.sh >> automation/logs/nohup.out 2>&1 &`
      then `tail -f automation/logs/autobuild.log`
- [ ] Accept the one-time bypass-permissions dialog on the next session in this project
      (takes effect next startup, not retroactively)
- [ ] Review + merge each `auto/build` → `main` PR by hand (merge commit, not squash)
- [ ] Point Opus at `docs/REVIEW-INSTRUCTIONS.md` when reviewing (moved there by task 00)

## Links
- `automation/PLAN.md` — the step map; `automation/README.md` — ops guide
- `phikestrel-SETUP.md` — phased build plan (Phases 0–7)
- `phikestrel-REVIEW-INSTRUCTIONS.md` → becomes `docs/REVIEW-INSTRUCTIONS.md`
- [[kestrel-project]], [[user-is-domain-scientist]]
