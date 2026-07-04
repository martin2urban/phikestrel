# TASK 80 — Phenotype extraction plugin (`document_text → phenotype`) (Phase 6c)

**Goal:** the reasoning step that reads a paper's text and pulls out the **candidate
phenotype statements** to curate — the bridge between a whole document and the existing
`phenotype → PHIPO` stage (TASK 60).

Build in `plugins/` (own light deps allowed behind the process boundary; **core** untouched
and stdlib-only). Speak the envelope via the TASK 20 wrapper.

- A `phenotype-extract` plugin with a manifest (TASK 30) declaring
  `input_type = "document_text"`, `output_type = "phenotype"`.
- Its reasoning goes through the TASK 50 inference interface (use the **mock** backend in
  tests — no real model needed to land this).
- **Input:** a `document_text` payload (from TASK 70).
- **Output** (`phenotype` payload): the set of candidate phenotype descriptions found, each
  carrying **its supporting passage/section reference** (the span it came from) so a curator
  can trace every claim back to the paper. The payload is a **list** of candidates — this is
  the fan-out point the orchestrator (TASK 90) expands.
- **Never guess:** a document with no phenotype content yields `not_found` (empty is not
  "success with []"); a passage too vague to pin down is flagged `ambiguous`, never
  upgraded into a confident claim. Record the **model identity** in provenance, and
  **preserve the upstream document provenance** (which paper, which hash) when forwarding.

**Acceptance tests (`tests/`):**
- A `document_text` fixture with a clear phenotype → a `phenotype` envelope whose payload
  lists the candidate(s), each with a source span; provenance carries the (mock) model id
  **and** the forwarded document source.
- A document with no phenotype content → `not_found`, not an empty success.
- A deliberately vague passage → `ambiguous`, no fabricated specifics.
- The plugin passes the conformance harness.
- Green gate passes; core stays stdlib-only; tests are network-free (mock backend only).
