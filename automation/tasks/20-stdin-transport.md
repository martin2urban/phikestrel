# TASK 20 — Envelope-over-stdin transport (Phase 2)

**Goal:** run a plugin as a subprocess, one job per item, speaking the envelope over
stdin/stdout.

Build in `core/` (stdlib only, e.g. `subprocess`, `json`):
- A runner that launches a plugin as a subprocess, writes an input envelope as JSON to its
  stdin, reads one JSON envelope back from stdout, and returns it parsed.
- **stdout carries only the envelope JSON; logs/diagnostics go to stderr.** Capture stderr
  for diagnostics but never mix it into the parsed result.
- Exit-code contract: `0` = handled (including a `not_found`/`ambiguous` envelope);
  nonzero or no/garbled envelope = turn it into an `error` envelope with the captured
  stderr in provenance/payload — never let the host crash on a bad plugin.
- A **timeout** so a hung plugin can't block forever; on timeout return an `error`
  envelope.
- A tiny helper for plugin authors: a `read stdin envelope → your fn → write stdout
  envelope` wrapper, so plugins don't re-implement the protocol.

**Acceptance tests (`tests/`):** use small inline Python scripts as fake plugins (written to
a temp dir) — no external processes beyond `python3`:
- Happy path: input envelope in → expected envelope out, exit 0.
- A plugin that emits a `not_found` envelope is handled as success (exit 0), status intact.
- A plugin that crashes / prints garbage → host returns an `error` envelope, doesn't raise.
- A plugin that hangs → timeout produces an `error` envelope.
- Stray stdout logging by a plugin is detected/handled (does not corrupt the parse).
- Green gate passes; network-free; core stays stdlib-only.
