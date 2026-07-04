# TASK 90 — Pipeline orchestrator + fan-out (`run a chain end-to-end`) (Phase 6d)

**Goal:** the piece that actually makes "pipe a paper, get curated output" a single command
— run an **ordered chain of plugins** end-to-end, validating the wiring first and handling
the one-to-many fan-out that extraction produces.

Build in `core/` (stdlib only). This is host orchestration, not a plugin.

- A composer that takes an **ordered list of stages** (loaded from manifests, TASK 30) and a
  starting input envelope, then:
  1. **Validates the whole wiring up front** with TASK 11's `check_pipeline` — refuses to
     run a chain whose types don't line up, naming the first bad link. No partial runs on a
     known-broken pipe.
  2. Runs the input through each stage via the TASK 20 transport, in order.
  3. **Fan-out:** when a stage's payload is a *list* of N items (e.g. TASK 80's phenotype
     candidates), dispatch N downstream jobs and gather the results. `not_found` /
     `ambiguous` / `error` items are **carried through and reported, never silently
     dropped**. A single bad item must not sink the whole run.
  4. **Threads and accumulates provenance** across hops, so the final results trace back
     through every stage (paper → text → phenotype → term).
- **Output:** a run report — per-item final envelopes with their status, plus an aggregate
  (how many success / ambiguous / not_found / error).
- A small **run-from-root CLI entry** (`python3 -m ...`) that reads a pipeline definition
  (the ordered list of plugin manifests) and a starting `document`, and prints the report.
  This is the end-to-end `paper → ...` command.
- **Default output = a human-readable summary** (the maintainer is a domain scientist, not a
  developer — plain text they can skim, not raw JSON). For each result item, print:
  the **status** (clearly marked, e.g. `[success]` / `[ambiguous → review]` /
  `[not_found]` / `[error]`), the **phenotype** text, the mapped **PHIPO id** (when present),
  and the **source passage** it came from. End with a one-line **tally**
  (`N success, N for review, N not found, N error`). Keep provenance detail (paper hash,
  model id, timestamps) to a short trailing line per item, not a wall of text.
- Provide a `--json` flag that prints the raw report instead, for anyone who wants to pipe
  it onward — but the **default is the readable summary**.

**Acceptance tests (`tests/`):** use fake plugins (temp scripts), no real model or network:
- A 3-stage chain runs an input end-to-end; the final report reflects each hop's provenance.
- An **incompatible** chain is refused **before** any plugin runs, naming the bad link.
- A stage emitting a list of N items fans out to N downstream results.
- A mix where one fanned-out item is `not_found` and one errors → both are **reported**, the
  successful ones still complete, the run does not crash.
- The **readable summary** is the default: a run prints per-item status + phenotype + PHIPO
  id + source passage and a closing tally; an `ambiguous` item is visibly marked for review.
  `--json` instead prints the raw report. (Assert on the rendered text, not just the data.)
- Green gate passes; core stays stdlib-only; tests are network-free.
