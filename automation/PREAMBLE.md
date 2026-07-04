# phikestrel autonomous build — standing rules (read every run)

You are running **headless and unattended**, doing **exactly one task** (below the
`---`). No human is watching this run. When the task is done, **stop** — do not start
the next task.

## Where you are (the runner set this up for you)
- You are in the `phikestrel` repo on branch **`auto/build`**, already rebased on the
  latest `main`. Prior completed tasks are present as commits on this branch.
- Do your work here. Do **not** switch branches, reset, or touch `main`.

## The architecture you must respect (from `phikestrel-SETUP.md`)
- **Core is stdlib-only.** Anything under `core/` and `tests/` imports **only** the Python
  standard library. Heavy deps live only behind the out-of-process plugin boundary.
- **Run-from-root, zero-setup:** everything runs with `python3 -m …` from the repo root.
  No install step required.
- **Never guess.** Ambiguity / not-found / low-confidence are **explicit statuses in the
  envelope** — never invented or defaulted data.
- **Provenance:** every payload carries source, cache state, a **UTC** timestamp, and (for
  reasoning stages) the model identity. Preserve upstream provenance when forwarding.
- **Typed stage contract:** each stage declares `input type → output type`; the host checks
  compatibility before running.
- **Tests are network-free and run from the root** (`python3 -m unittest discover -s tests`).
- Keep it **simple** — the maintainer is a domain scientist, not a software engineer.

## The green gate (non-negotiable)
Before you commit, run the full test suite from the repo root and make it **pass**:
```
python3 -m unittest discover -s tests
```
If it fails, fix it. Do not commit red. If the task is genuinely blocked, commit nothing,
write one line to `automation/logs/BLOCKED-<task-id>.txt` explaining why, and stop.

## Finish procedure (do this, in order, then stop)
1. Make the change + its tests. Run the green gate until green.
2. `git add -A` and commit with a clear message:
   `<task-id>: <what changed>` and end the body with
   `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
3. `git push` (fast-forward onto the remote `auto/build` the runner already aligned).
4. **Ensure a PR exists** from `auto/build` into `main`:
   `gh pr view auto/build >/dev/null 2>&1 || gh pr create --base main --head auto/build
   --title "phikestrel autonomous build" --body "Automated build — review task commits
   individually. See automation/PLAN.md."`
   (If it already exists it auto-updates on push — do nothing more.)
5. **Do NOT merge.** The maintainer reviews and merges every task by hand.
6. Stop.

## Git / commits on this machine
Normal `git`/`gh` work here for commit, push, and PRs. (The `/mnt/z` Windows-git rule only
applies to the separate Obsidian vault housekeeping, not to code commits in this repo.)
