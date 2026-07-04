# TASK 10 — Shared envelope (Phase 1a)

**Goal:** the data structure everything crosses — `status` + payload + `provenance`.

Build in `core/` (stdlib only):
- An envelope type (dataclass) with: `status` (an enum/allowed set — at minimum
  `success`, `ambiguous`, `not_found`, `error`), a `payload` (arbitrary JSON-serialisable
  object, may be `None`), and a `provenance` record.
- `provenance` carries: `source`, `cache` (hit/miss/none), `timestamp` (**UTC**, ISO-8601),
  and an optional `model` identity (for reasoning stages). Provide a helper that stamps a
  fresh UTC timestamp so callers never hand-roll one.
- `to_json` / `from_json` (and dict forms) that round-trip exactly, including unicode and
  nested payloads. Unknown/extra fields on input must raise a clear error, not be silently
  dropped or guessed.
- A constructor per status so callers can't forget provenance (e.g. `not_found(...)` still
  requires a source).

**Acceptance tests (`tests/`):**
- Round-trip: `from_json(to_json(e)) == e` for each status, incl. non-ASCII payload.
- A `not_found`/`ambiguous` envelope is representable and serialises with its status intact
  (proves never-guess has a home).
- Malformed JSON and missing required fields raise explicit errors.
- Provenance timestamp parses as UTC ISO-8601.
- Green gate passes; no third-party imports.
