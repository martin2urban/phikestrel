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

## Decisions
| Decision | Rationale |
|----------|-----------|
| Review doc lives at repo root as `phikestrel-REVIEW-INSTRUCTIONS.md` | Matches existing `phikestrel-*.md` naming (SETUP file) pre-scaffold |
| Cybersecurity excluded from Opus review | User instruction; a separate security review owns that surface |
| No CLAUDE.md edit | Vault has no CLAUDE.md yet, so nothing to update |

## Next steps
- [ ] Scaffold the repo (Phase 0: layout, `pyproject.toml`, CI, README) — still pending
- [ ] Decide runner: scheduled cloud routine vs. local loop for one-task-per-run PRs
- [ ] Consider folding review instructions into a scheduled review routine's prompt
- [ ] Keep ROGER bring-up (Phase 7) as the supervised, hands-on phase

## Links
- `phikestrel-SETUP.md` — phased build plan (Phase 0–7)
- `phikestrel-REVIEW-INSTRUCTIONS.md` — Opus review checklist
- [[kestrel-project]] memory
