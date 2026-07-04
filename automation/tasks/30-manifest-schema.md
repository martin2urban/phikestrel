# TASK 30 — Plugin manifest + schema (Phase 3a)

**Goal:** a declarative manifest that describes a plugin so the host can wire it without
importing it.

Build in `core/` (stdlib only):
- A manifest format (JSON or TOML — pick one, stdlib-parseable) with required fields:
  `name`, `version`, `stage` (`input_type` / `output_type`, reusing TASK 11's types),
  `entrypoint` (how to launch the subprocess — e.g. a command/argv), and optional
  `description`.
- A validator that returns an explicit result: valid, or a clear list of what's
  missing/malformed. A bad manifest is an **explicit error**, never a silent skip.
- Load a manifest from a file path into a typed object.

**Acceptance tests (`tests/`):**
- A well-formed manifest validates and loads with all fields.
- Each missing required field produces a specific, named error.
- A malformed manifest file (bad syntax) errors clearly.
- The manifest's declared stage types are usable by TASK 11's compatibility check.
- Green gate passes; core stays stdlib-only.
