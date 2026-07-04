# TASK 11 — Typed stage contract (Phase 1b)

**Goal:** each stage declares `input type → output type`; the host checks compatibility
**before** running anything.

Build in `core/` (stdlib only):
- A lightweight type/label system for envelope payloads (e.g. named types like
  `"figure"`, `"phenotype"`, `"phipo_term"` — string identifiers are fine; don't
  over-engineer into a full type system).
- A `Stage` descriptor declaring `input_type` and `output_type`.
- A `check_compatibility(producer, consumer)` (and a `check_pipeline([stages])`) that
  returns an explicit result: compatible, or a clear description of the first mismatch
  (which pair, expected vs got). It must **refuse** an incompatible wiring, not run it.

**Acceptance tests (`tests/`):**
- A compatible producer→consumer pair passes the check.
- An incompatible pair is **rejected** with a message naming expected vs actual types.
- A 3-stage pipeline validates end-to-end; a broken link in the middle is pinpointed.
- Green gate passes; core stays stdlib-only.
