# TASK 31 — Plugin discovery (Phase 3b)

**Goal:** find installed plugins by scanning, using TASK 30's manifests.

Build in `core/` (stdlib only):
- Directory scan: given a plugins root, find each plugin dir, load + validate its manifest,
  and return the set of available plugins keyed by name.
- Entry-point scan: also discover plugins registered via `pyproject.toml` console/entry
  points (use `importlib.metadata` — stdlib). Keep it optional/graceful if none exist.
- **Determinism:** results are sorted/stable, not filesystem-order-dependent.
- **Resilience:** one broken plugin (bad/missing manifest) is reported with a clear message
  but must **not** take down discovery of the good ones.
- A registry object the host can query: list plugins, get one by name, find plugins whose
  `input_type` matches a given type.

**Acceptance tests (`tests/`):** build a temp plugins dir with a couple of valid plugins and
one broken one:
- Both valid plugins are discovered; order is deterministic.
- The broken plugin is reported as an error but the valid ones still load.
- Query-by-input-type returns the right plugin(s).
- Green gate passes; network-free; core stays stdlib-only.
