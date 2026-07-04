# TASK 50 — Inference-backend abstraction (Phase 5)

**Goal:** one interface for reasoning stages, with selectable backends; production is a
local model on ROGER, dev/compare is cloud — but this task only needs the **interface + a
mock/local-server client**, no real model.

Build in `core/` (stdlib only):
- An inference interface (e.g. `generate(request) -> response`) that stages call. Stages
  must never reach past this interface to a specific backend.
- A backend selector/config: name a backend and get a client. Include:
  - a **mock** backend (deterministic canned responses) for tests, and
  - a **local-server HTTP client** stub that targets a configurable base URL (vLLM/TGI/
    Ollama-style). Use only `urllib` (stdlib). It's fine for this to be untested against a
    real server — keep the surface small and clearly marked.
- **Every response records the model identity into the envelope provenance.** A reasoning
  result with no `model` in provenance is a bug.

**Acceptance tests (`tests/`):**
- A stage calling the interface with the **mock** backend gets the canned response and the
  result's provenance carries the mock model id.
- Backend selection returns the right client for a given config; an unknown backend name is
  an explicit error.
- No network calls occur in the test suite (mock only).
- Green gate passes; core stays stdlib-only.
