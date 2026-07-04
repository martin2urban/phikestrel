---
date: 2026-07-04
type: session
tags: [session]
---

# Session: Opus review instructions + session-log provisioning

**Objective:** Write direct review instructions for Opus (cybersecurity out of
scope), and set up session logs so phikestrel restarts cleanly.
**Context:** phikestrel is a fresh repo — only `phikestrel-SETUP.md` existed
(the phased build plan). Split from PHI-Weaver; plug-in/pipe host for
AI-assisted PHI-base/PHI-Canto biocuration on the ROGER GPU cluster.

## What happened
- Read `phikestrel-SETUP.md` to ground the review checklist in the real
  architecture (stdlib-only core, out-of-process plugins, shared envelope,
  typed stage contract, never-guess, provenance, green-gated).
- Wrote **`phikestrel-REVIEW-INSTRUCTIONS.md`** — an imperative checklist for
  Opus to use when reviewing autonomously-produced PRs. Explicitly declares
  **cybersecurity out of scope** (deferred to a separate security review).
  Covers: orient-first, non-negotiable principles, envelope contract,
  typed stage contract, plugin process boundary, inference-backend
  abstraction, correctness/quality, tests, phase-specific notes, reporting.
- Provisioned session logs: `sessions/` folder + `SessionStart` hook
  (`.claude/hooks/inject-latest-sessions.py`, wired in `.claude/settings.json`).
  Hook activates on the **next** session in this vault.
- Built the **autonomous build harness** under `automation/`: the whole project as
  9 PR-sized task files (`tasks/00-scaffold.md` … `60-phenotype-plugin.md`,
  Phases 0–6; Phase 7 ROGER stays manual), a standing-rules `PREAMBLE.md`, a
  `PLAN.md` step map, and `autobuild.sh` — a bash runner that executes one task per
  run and **auto-relaunches when Claude Code hits its usage limit** (detects the
  limit message, sleeps `PHIKESTREL_RETRY_SECONDS`=1800s, retries the same task).
- Verified plumbing: WSL git commits fine in this repo (only `git config` hits the
  9p chmod gotcha); wired `gh auth setup-git` as git's credential helper; pushed
  `main` to origin so the runner's `auto/build` base carries the task files.
- **Not started yet** — the runner is ready but I left kicking it off to Martin
  (it burns the premium window + uses `--dangerously-skip-permissions`).

## Decisions
| Decision | Rationale |
|----------|-----------|
| Review doc lives at repo root as `phikestrel-REVIEW-INSTRUCTIONS.md` | Matches existing `phikestrel-*.md` naming (SETUP file) pre-scaffold |
| Cybersecurity excluded from Opus review | User instruction; a separate security review owns that surface |
| No CLAUDE.md edit | Vault has no CLAUDE.md yet, so nothing to update |

## Next steps
- [ ] **Start the autobuild runner** and watch the first task (Phase 0 scaffold):
      `cd /mnt/z/phikestrel && nohup bash automation/autobuild.sh >> automation/logs/nohup.out 2>&1 &`
      then `tail -f automation/logs/autobuild.log`
- [ ] Review + merge each `auto/build` → `main` PR by hand (prefer merge commit, not
      squash, so the runner's rebase stays clean); nothing auto-merges
- [ ] Point Opus at `docs/REVIEW-INSTRUCTIONS.md` when reviewing those PRs
- [ ] Keep ROGER bring-up (Phase 7) as the supervised, hands-on phase

## Links
- `phikestrel-SETUP.md` — phased build plan (Phase 0–7)
- `phikestrel-REVIEW-INSTRUCTIONS.md` — Opus review checklist
- [[kestrel-project]] memory
