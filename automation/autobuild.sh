#!/usr/bin/env bash
#
# phikestrel autobuild — drive the phased build one task per run, PR per task,
# and AUTO-RELAUNCH when Claude Code hits its usage limit.
#
# How it works:
#   * Tasks live in automation/tasks/*.md, executed in filename order.
#   * Each run prepends automation/PREAMBLE.md to one task file and pipes it to a
#     fresh headless `claude -p`. The agent implements the task, runs the green
#     gate, commits, pushes, and opens/updates a PR into main. It never merges.
#   * Completed task ids are recorded in automation/.progress (gitignored) so the
#     next run picks up where the last stopped.
#   * If `claude -p` reports a usage/rate limit, the runner sleeps and RELAUNCHES
#     the same task — so work resumes automatically when your 5-hour window resets.
#
# This wrapper is plain bash; it does NOT itself consume your Claude usage. Only the
# `claude -p` child invocations do. Run it under nohup/tmux/systemd (see README).
#
set -uo pipefail

REPO="${PHIKESTREL_REPO:-/mnt/z/phikestrel}"
TASK_DIR="$REPO/automation/tasks"
PREAMBLE="$REPO/automation/PREAMBLE.md"
PROGRESS="$REPO/automation/.progress"
LOG_DIR="$REPO/automation/logs"
BASE_REF="${PHIKESTREL_BASE:-origin/main}"
BUILD_BRANCH="auto/build"
RETRY_SECONDS="${PHIKESTREL_RETRY_SECONDS:-1800}"   # wait before relaunch after a usage limit
# Unattended runs can't answer permission prompts. Default to skipping them; set
# PHIKESTREL_CLAUDE_FLAGS to override with a narrower policy if you prefer.
read -r -a CLAUDE_FLAGS <<< "${PHIKESTREL_CLAUDE_FLAGS:---dangerously-skip-permissions}"
# Model for the headless build runs. Deliberately NOT Fable 5 — these tasks are small,
# tightly-specified and test-gated, so Sonnet 5 is plenty and far lighter on usage, and it
# steers clear of any Fable/biology-project block. Bump to 'opus' for stronger code, or set
# PHIKESTREL_MODEL to anything the `claude --model` flag accepts.
MODEL="${PHIKESTREL_MODEL:-sonnet}"
CLAUDE_FLAGS+=(--model "$MODEL")

mkdir -p "$LOG_DIR"
touch "$PROGRESS"

log() { printf '%s  %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG_DIR/autobuild.log" ; }

is_done() { grep -qxF "$1" "$PROGRESS" ; }

# Bring auto/build up to date with main, keeping unmerged completed-task commits.
prep_git() {
  git -C "$REPO" fetch -q origin || { log "fetch failed"; return 1; }
  if git -C "$REPO" rev-parse --verify -q "$BUILD_BRANCH" >/dev/null; then
    git -C "$REPO" checkout -q "$BUILD_BRANCH"
    git -C "$REPO" reset -q --hard HEAD          # drop any junk from a crashed run
  else
    git -C "$REPO" checkout -q -B "$BUILD_BRANCH" "$BASE_REF"
  fi
  if ! git -C "$REPO" rebase -q "$BASE_REF"; then
    git -C "$REPO" rebase --abort 2>/dev/null
    log "REBASE CONFLICT onto $BASE_REF — a human should merge the open PR (use a merge"
    log "commit, not squash) so history stays linear; pausing ${RETRY_SECONDS}s then retrying"
    return 3
  fi
  git -C "$REPO" push -q --force-with-lease -u origin "$BUILD_BRANCH" 2>/dev/null \
    || git -C "$REPO" push -q -u origin "$BUILD_BRANCH" 2>/dev/null || true
  return 0
}

# Run one task headless. Return: 0 done, 1 transient error, 2 usage limit, 3 blocked.
run_one() {
  local file="$1" id="$2" stamp logf code
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  logf="$LOG_DIR/${id}.${stamp}.log"
  log "START task=$id  (log: $(basename "$logf"))"
  local prompt
  prompt="$(cat "$PREAMBLE"; printf '\n\n---\n\n'; cat "$file")"
  ( cd "$REPO" && printf '%s' "$prompt" | claude -p "${CLAUDE_FLAGS[@]}" ) >"$logf" 2>&1
  code=$?
  if grep -qiE 'usage limit|rate limit|limit reached|reset[s]? at|please try again later|too many requests' "$logf"; then
    log "LIMIT hit on task=$id (exit=$code) — will relaunch after cooldown"
    return 2
  fi
  if [ -f "$REPO/automation/logs/BLOCKED-${id}.txt" ]; then
    log "BLOCKED task=$id — the agent left a reason in logs/BLOCKED-${id}.txt; pausing for human"
    return 3
  fi
  if [ "$code" -ne 0 ]; then
    log "ERROR task=$id exit=$code — see $(basename "$logf"); retrying next cycle"
    return 1
  fi
  echo "$id" >> "$PROGRESS"
  log "DONE task=$id — a PR should be open into main for your review"
  return 0
}

cooldown() { log "cooldown ${RETRY_SECONDS}s before relaunch"; sleep "$RETRY_SECONDS"; }

main() {
  shopt -s nullglob
  log "autobuild starting: repo=$REPO base=$BASE_REF flags='${CLAUDE_FLAGS[*]}'"
  while true; do
    local next="" id=""
    for f in "$TASK_DIR"/*.md; do
      local fid; fid="$(basename "$f" .md)"
      if ! is_done "$fid"; then next="$f"; id="$fid"; break; fi
    done
    if [ -z "$next" ]; then
      log "ALL TASKS COMPLETE — nothing left to build. Exiting."
      break
    fi

    prep_git; pg=$?
    if [ "$pg" -eq 3 ]; then cooldown; continue; fi
    if [ "$pg" -ne 0 ]; then log "git prep failed; retrying in 60s"; sleep 60; continue; fi

    run_one "$next" "$id"
    case $? in
      0) : ;;                                  # advance to next task
      2) cooldown ;;                           # usage limit -> wait, relaunch same task
      3) cooldown ;;                           # blocked -> wait for human, then re-try
      *) log "transient; retrying in 120s"; sleep 120 ;;
    esac
  done
}

main "$@"
