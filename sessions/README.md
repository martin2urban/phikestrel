# sessions

Session logs for **this vault's** work — analysis, development, decisions made
during Claude Code sessions. Domain-specific; these stay in this vault and do
**not** live in the OBS-BotVault orchestrator. Only genuinely cross-vault
coordination belongs in `[[OBS-BotVault::Session-Index]]`.

## Auto-load at session start
A `SessionStart` hook (`.claude/hooks/inject-latest-sessions.py`, wired in
`.claude/settings.json`) injects, when Claude Code starts in this vault:
- a **summary** of the **3 most recent session logs** here (title + Objective +
  open Next-steps only — kept small by default; the full logs stay on disk), and
- the **latest/active project note** (`experiments/<project>/README.md`, by
  modification time), in full.

Keep this folder current and the next session picks up where the last left off.
To make the summary useful, give each log a clear `# Session:` title, an
`**Objective:**` line, and a `## Next steps` checklist.

## Naming
`YYYY-MM-DD-short-title.md`. One file per working session.

## Lightweight template
```markdown
---
date: YYYY-MM-DD
type: session
tags: [session]
---

# Session: <title>

**Objective:** what this session set out to do
**Context:** where we picked up from

## What happened
- bullet points of the actual work / decisions

## Decisions
| Decision | Rationale |
|----------|-----------|

## Next steps
- [ ] open items / follow-ups

## Links
- related experiments / notes / pipelines
```

## Index
| Date | Session | Outcome |
|------|---------|---------|
| | | |
