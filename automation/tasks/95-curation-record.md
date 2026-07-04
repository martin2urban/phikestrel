# TASK 95 — Curation-record assembly + full paper→record integration (Phase 6e)

**Goal:** the far end of the pipe — assemble the pipeline's results into a **structured
curation record** shaped like the ones PHI-Weaver consumes, and prove the whole chain works
**paper in → curated record out**.

Build the assembler in `plugins/` (own light deps allowed; **core** untouched and
stdlib-only), speaking the envelope via the TASK 20 wrapper.

- A `curation-record` plugin with a manifest (TASK 30) declaring
  `input_type = "phipo_term"`, `output_type = "curation_record"`.
- **Output** (`curation_record` payload): a structured record carrying the phenotype, its
  mapped **PHIPO id**, the **source passage** it came from, and the **full provenance chain**
  (which paper + hash, which model, timestamps) accumulated across the pipeline. Align the
  field names with PHI-Weaver's curation record so records move between the two projects.
- **Never guess:** only assert what upstream stages delivered with `success`. Items that
  arrived `ambiguous`/`not_found` are recorded **as flagged-for-human-review**, never
  silently completed or dropped. This is a curation *aid*, not an autonomous curator — every
  claim stays traceable and a human makes the final call.
- **Scope, honestly:** this closes the **phenotype → PHIPO** axis end-to-end. A full PHI-base
  record also needs gene / pathogen / host / disease axes — those are **additional
  extraction + mapping plugins built exactly the same way** (a TASK 80-style extractor + a
  TASK 60-style mapper each), chained by TASK 90. List them as the natural next plugins; do
  **not** stub them here.

**Acceptance tests (`tests/`):**
- **End-to-end integration:** a sample paper fixture run through the TASK 90 orchestrator
  across ingest (70) → extract (80) → phenotype→PHIPO (60) → assemble (95) with the **mock**
  backend yields one or more `curation_record`s, each with a PHIPO id, source passage, and a
  complete provenance chain back to the paper.
- An `ambiguous`/`not_found` upstream result appears in the output **flagged for review**,
  not fabricated into a confident record.
- The assembler plugin passes the conformance harness.
- Green gate passes; the core still imports only stdlib; tests are network-free (mock only).
