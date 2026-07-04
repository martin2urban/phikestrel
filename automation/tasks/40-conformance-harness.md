# TASK 40 — Conformance harness (Phase 4)

**Goal:** golden fixtures a plugin must pass before it is incorporated.

Build in `core/` (stdlib only):
- A harness that, given a plugin (via its manifest + the TASK 20 transport) and a directory
  of golden fixtures, runs each fixture and checks the plugin's output.
- A fixture = an input envelope + the expected output (or expected status + constraints on
  the payload). Support at least three fixture kinds:
  1. **validity** — output is a well-formed envelope of the declared `output_type`;
  2. **never-guess** — a fixture whose correct answer is `not_found`/`ambiguous`, asserting
     the plugin returns that status and does **not** fabricate a payload;
  3. **exit-code** — the process exit code matches the envelope status contract from
     TASK 20.
- A clear pass/fail report per fixture; nonzero overall exit if any fixture fails, so CI can
  gate on it.

**Acceptance tests (`tests/`):** use fake plugins (temp scripts):
- A well-behaved plugin passes all three fixture kinds.
- A plugin that fabricates data on a not-found input **fails** the never-guess fixture.
- A plugin that returns the wrong output type **fails** validity.
- The harness exits nonzero when any fixture fails.
- Green gate passes; network-free; core stays stdlib-only.
