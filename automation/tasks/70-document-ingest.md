# TASK 70 — Document ingestion plugin (`document → document_text`) (Phase 6b)

**Goal:** the front door — take a *paper* and turn it into normalized, structured text the
rest of the pipeline can reason over. This is what makes "pipe a paper in" possible.

Build in `plugins/` (this plugin MAY use its own light deps behind the process boundary —
e.g. a stdlib-friendly PDF text extractor — but the **core** stays untouched and
stdlib-only). Speak the envelope via the TASK 20 plugin-author wrapper.

- A `document-ingest` plugin with a manifest (TASK 30) declaring
  `input_type = "document"`, `output_type = "document_text"`.
- **Input** (`document` payload): a reference to a paper — a file path plus a declared
  kind. **Accept plain `.txt`/`.json` as well as PDF**, so the test suite can run
  network-free and dependency-light on a tiny committed sample; PDF support is the
  production path but must not be required to run the tests.
- **Output** (`document_text` payload): a normalized structure — any available metadata
  (title, identifiers such as PMID/DOI **only if present in the source**, never guessed),
  an **ordered list of sections/paragraphs**, and **figure & table captions kept separate**
  from body text (so a future `figure → phenotype` stage can consume them).
- **Deterministic — no inference.** Provenance `source` = the file path + a content hash;
  `cache = none`; UTC timestamp via the TASK 10 helper. (No `model` — this is not a
  reasoning stage.)
- **Never guess:** an empty file, or an image-only/scanned PDF with no extractable text,
  yields `not_found` (or `ambiguous` if partial) — **never** fabricated text or a made-up
  identifier.

**Acceptance tests (`tests/`):** use a tiny committed sample document (plain text is fine):
- Happy path: a sample paper in → a `document_text` envelope out with ordered sections and
  at least one caption separated from body text.
- An identifier absent from the source is **absent** from the output (not invented).
- An empty / unextractable input yields `not_found`/`ambiguous`, no fabricated text.
- The plugin passes the conformance harness (validity + never-guess + exit-code).
- Green gate passes; the core still imports only stdlib; tests are network-free.
