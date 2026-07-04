# TASK 60 — First real plugin: phenotype → PHIPO (Phase 6)

**Goal:** the first out-of-process plugin, tying the whole core together: it takes a
phenotype description and returns a PHIPO term, as a subprocess speaking the envelope.

Build in `plugins/` (this plugin MAY use its own deps behind the process boundary, but keep
it light; the **core** stays untouched and stdlib-only):
- A `phenotype-to-phipo` plugin: a manifest (TASK 30) declaring
  `input_type = "phenotype"`, `output_type = "phipo_term"`, and an executable entrypoint
  that uses the TASK 20 plugin-author wrapper.
- Its reasoning goes through the TASK 50 inference interface (use the **mock** backend in
  tests — no real model needed to land this).
- **Never guess:** if the phenotype can't be confidently mapped, return `not_found` or
  `ambiguous` — never a fabricated PHIPO id. Record provenance incl. model identity.
- Golden fixtures (TASK 40): at least one happy-path mapping and one never-guess fixture.

**Acceptance tests (`tests/`):**
- End-to-end through the transport: a phenotype envelope in → a `phipo_term` envelope out,
  provenance populated with model id.
- An unmappable phenotype yields `not_found`/`ambiguous`, **no** invented PHIPO id.
- The plugin passes the conformance harness (validity + never-guess + exit-code).
- Green gate passes; the core still imports only stdlib; tests are network-free.
