#!/usr/bin/env python3
"""SessionStart hook: inject this vault's startup context.

Injects, as additionalContext at session start:
  1. A SUMMARY of the most recent session logs (sessions/YYYY-MM-DD-*.md, excluding
     README.md) — title + Objective + open Next-steps only, to keep context small.
     The full logs stay on disk as the detailed record.
  2. The latest project note (experiments/<project>/README.md, the one most
     recently modified), in full, so each session starts with current project state.

Outputs nothing if neither is found.

Wired as a SessionStart hook in .claude/settings.json:
    python3 .claude/hooks/inject-latest-sessions.py
"""
import glob
import json
import os
import re

# .claude/hooks/<this> -> .claude -> vault root
VAULT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SESSIONS_DIR = os.path.join(VAULT, "sessions")
EXPERIMENTS_DIR = os.path.join(VAULT, "experiments")
NUM_LOGS = 3  # how many of the most recent session logs to inject


def natural_key(path):
    """Sort key that is numeric-aware, so dated filenames order chronologically."""
    name = os.path.basename(path)
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", name)]


def read_file(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return None


def summarise_log(content):
    """Compact a session log to title + Objective + open Next-steps.

    Falls back gracefully when the log doesn't follow the template: a missing
    section is simply omitted; if nothing matches, returns the first few non-empty
    lines so the log is never silently empty.
    """
    lines = content.splitlines()
    out = []

    # Title: first H1 (e.g. "# Session: ...").
    title = next((ln for ln in lines if ln.startswith("# ")), None)
    if title:
        out.append(title.strip())

    # Objective: the "**Objective:**" line, if present.
    objective = next((ln for ln in lines if "**Objective:**" in ln), None)
    if objective:
        out.append(objective.strip())

    # Next steps: capture the "## Next steps" section up to the next "## ".
    next_steps = []
    in_section = False
    for ln in lines:
        if re.match(r"^##\s+next steps\b", ln.strip(), re.IGNORECASE):
            in_section = True
            continue
        if in_section:
            if ln.startswith("## "):
                break
            if ln.strip():
                next_steps.append(ln.rstrip())
    if next_steps:
        out.append("**Open next steps:**")
        out.extend(next_steps)

    if not out:
        # Fallback: first 8 non-empty lines.
        out = [ln.rstrip() for ln in lines if ln.strip()][:8]
    return "\n".join(out)


def sessions_block():
    candidates = [
        p
        for p in glob.glob(os.path.join(SESSIONS_DIR, "*.md"))
        if os.path.basename(p).lower() != "readme.md"
    ]
    if not candidates:
        return None
    # Most recent NUM_LOGS, ordered oldest -> newest so the latest reads last.
    latest = sorted(candidates, key=natural_key)[-NUM_LOGS:]
    sections = []
    for path in latest:
        content = read_file(path)
        if content is not None:
            sections.append(f"### {os.path.basename(path)}\n\n{summarise_log(content)}")
    if not sections:
        return None
    return (
        f"{len(sections)} most recent session log(s) for this vault — SUMMARY only "
        "(title + objective + open next-steps; full logs are in sessions/). "
        "Oldest first, latest last:\n\n" + "\n\n---\n\n".join(sections)
    )


def project_block():
    # Each project is a folder under experiments/ with a README.md overview.
    readmes = glob.glob(os.path.join(EXPERIMENTS_DIR, "*", "README.md"))
    if not readmes:
        return None
    # "Latest" = most recently modified project note (active project tends to be newest).
    latest = max(readmes, key=lambda p: os.path.getmtime(p))
    content = read_file(latest)
    if not content:
        return None
    rel = os.path.relpath(latest, VAULT)
    return (
        f"Latest / active project note ({rel}) — injected for current project "
        "state (other projects may exist under experiments/):\n\n" + content
    )


def main():
    blocks = [b for b in (sessions_block(), project_block()) if b]
    if not blocks:
        return
    context = "\n\n========================================\n\n".join(blocks)
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": context,
                }
            }
        )
    )


if __name__ == "__main__":
    main()
