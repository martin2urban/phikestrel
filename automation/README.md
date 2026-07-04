# automation/ — autonomous build runner

Drives the phikestrel build **one task per run, a PR per task**, and **auto-relaunches
when Claude Code hits its usage limit** so progress accrues across your 5-hour windows
without you babysitting it.

## What's here
- `PLAN.md` — the whole project as an ordered step map.
- `tasks/*.md` — one file per step (executed in filename order). Each file is the exact
  brief handed to the agent for that run.
- `PREAMBLE.md` — standing rules prepended to every task (green gate, stdlib-only core,
  never-guess, provenance, finish-with-a-PR-then-stop).
- `autobuild.sh` — the runner.
- `.progress` — completed task ids (gitignored, local). `logs/` — per-run transcripts.

## Prerequisites (one-time)
1. **Claude Code CLI** on PATH and logged in (`claude` runs).
2. **`gh` authenticated** with push rights to `martin2urban/phikestrel`
   (`gh auth status`), and the repo has an `origin` remote.
3. You're OK with unattended edits: the runner defaults to
   `--dangerously-skip-permissions` because a headless run can't answer permission
   prompts. It only ever acts inside this repo and opens PRs — it **never merges to
   `main`**. To narrow this, set `PHIKESTREL_CLAUDE_FLAGS` to your own policy.

## Start it
Run it detached so it survives closing the terminal:
```bash
cd /mnt/z/phikestrel
nohup bash automation/autobuild.sh >> automation/logs/nohup.out 2>&1 &
echo $! > automation/logs/autobuild.pid
```
or in a `tmux`/`screen` session, or as a systemd user service.

Watch it:
```bash
tail -f /mnt/z/phikestrel/automation/logs/autobuild.log
```

Stop it:
```bash
kill "$(cat /mnt/z/phikestrel/automation/logs/autobuild.pid)"
```

## The usage-limit relaunch
When a `claude -p` run reports a usage/rate limit, the runner logs it, **sleeps**
(`PHIKESTREL_RETRY_SECONDS`, default 1800s = 30 min), then **relaunches the same task**.
Once your window has reset the next attempt goes through. The wrapper itself is plain bash
and consumes no Claude usage — only the task runs do. (Best-effort: it matches the CLI's
limit message; if Anthropic changes that wording, adjust the `grep` in `run_one`.)

## Your side of the loop
- Each completed task opens/updates **one PR** (`auto/build` → `main`) with the task as its
  own commit. **You review and merge** at your pace — nothing auto-merges.
- Prefer a **merge commit** (not squash) when merging, so the runner's rebase of `auto/build`
  onto the new `main` stays clean. On a rebase conflict the runner pauses and asks for a hand.
- The runner accumulates unmerged tasks on `auto/build`, so later tasks build on earlier
  ones even before you've merged them.

## Knobs (env vars)
| Var | Default | Meaning |
|-----|---------|---------|
| `PHIKESTREL_REPO` | `/mnt/z/phikestrel` | repo path |
| `PHIKESTREL_BASE` | `origin/main` | branch tasks build on top of |
| `PHIKESTREL_RETRY_SECONDS` | `1800` | cooldown before relaunch after a limit |
| `PHIKESTREL_CLAUDE_FLAGS` | `--dangerously-skip-permissions` | flags passed to `claude -p` |

## Re-running / resetting a task
Task selection = first `tasks/*.md` whose id isn't in `.progress`. Remove its line to
re-run one task; empty `.progress` to rebuild everything from scratch.
