# phikestrel — setup & development guide

**Repo:** https://github.com/martin2urban/phikestrel

**What it is:** a plug-in, pipe-based pipeline host for AI-assisted PHI-base / PHI-Canto
biocuration — composable, out-of-process modules over a shared envelope, run with a **local AI on
the ROGER GPU cluster**. It is the plug-in / HPC deployment counterpart of
[PHI-Weaver](https://github.com/PHI-base/phi-weaver) (the curation vault, engine, skills,
gold-standard examples, and benchmarking). phikestrel reuses PHI-Weaver's design decisions — see
its `docs/PLUGIN-ARCHITECTURE.md` and `docs/DESIGN-DECISIONS.md`.

> Place this file in the repo as `README.md` (or `docs/SETUP.md`) after cloning.

---

## 1. Architecture (the "pipes")

- **Light, portable core** (Linux / WSL2 / Docker) that *orchestrates* — needs no GPU.
- **Plugins run out-of-process** (subprocess or container) and speak a **shared envelope**:
  `status` + payload + **provenance** (source, cache, UTC timestamp); JSON in / out; exit `0/1`;
  **never guess** (ambiguity / not-found are explicit statuses, never invented data).
- **Typed stage contract** — each stage declares `input type → output type`; that is the socket a
  plugin plugs into, and it lets the host check compatibility before running.
- **Transport** = the envelope over stdin/stdout (job-per-item) or a persistent local service
  (for anything holding a model in GPU memory).
- **Inference-backend abstraction** — reasoning stages call one interface with selectable
  backends: a **local model on ROGER** (vLLM / TGI / Ollama / llama.cpp) for production, cloud
  Claude for dev/comparison. Model identity is recorded in provenance for reproducibility.
- **Conformance harness** — golden fixtures a plugin must pass before it is incorporated.
- **Deployment** — containers with Docker (local) / **Apptainer** (ROGER) parity; the light core
  dispatches heavy GPU work (vision plugins, the local model) to ROGER.

## 2. Principles (carried from PHI-Weaver)

- Core stays **stdlib-only, run-from-root, zero-setup**; heavy dependencies live *only* behind the
  plugin process boundary.
- **Never guess**; preserve provenance; behaviour-preserving changes; **green-gated** (tests +
  smoke pass before and after every change).
- **phiweaver must not grade its own output** — any benchmarking/scoring stays independent.

## 3. Proposed repository layout

```
phikestrel/
  core/            # the host: envelope, typed stage contract, stdin transport,
                   # plugin manifest + discovery, conformance harness, inference backend
  plugins/         # out-of-process modules (e.g. phenotype -> PHIPO; figure -> phenotype)
  deploy/          # ROGER deployment scaffolding: containers, Apptainer defs, SLURM jobs
                   #   (human/IT-run — see the honest split below)
  tests/           # network-free unit tests, one discovery root
  docs/            # architecture, this guide, plugin authoring
  pyproject.toml   # metadata + console entry points (install optional)
  .github/workflows/ci.yml   # run the test suite on every push/PR
  README.md
```

## 4. Development setup

```bash
git clone https://github.com/martin2urban/phikestrel
cd phikestrel
python3 -m unittest discover -s tests     # once tests exist
# heavy plugin deps go in their own venv/container, never in the core
```

- **CI**: a GitHub Actions workflow runs the test suite on every push and PR (add in Phase 0).
- Develop from the repo root (`python3 -m ...`); `pip install -e .` is optional.

## 5. Build plan (phased, test-gated tasks)

Each task is small, independently testable, and lands as its own PR.

| Phase | Task | Autonomous? |
|------|------|-------------|
| 0 | Repo scaffold: layout, `pyproject.toml`, CI, README, this guide | yes |
| 1 | `core` shared **envelope** + **typed stage contract** (+ tests) | yes |
| 2 | **Envelope-over-stdin transport** (subprocess; job-per-item) (+ tests) | yes |
| 3 | **Plugin manifest + discovery** (manifest schema, directory/entry-point scan) (+ tests) | yes |
| 4 | **Conformance harness** (golden fixtures; validity, never-guess, exit codes) (+ tests) | yes |
| 5 | **Inference-backend abstraction** (interface + a mock/local-server client) (+ tests) | yes |
| 6 | First real plugin: **phenotype → PHIPO** as an out-of-process module (+ tests) | yes |
| 7 | **ROGER deployment scaffolding**: container/Apptainer defs, SLURM jobs, persistent model service | **no — human/IT** |

## 6. Autonomous development (within the Fable-5 5-hour windows)

- A **scheduled cloud routine** (or a local loop) executes **one task per run** from the plan.
- Each run: make the change → **run the green gate (tests)** → **open a PR for human review** →
  stop. **No auto-merge to `main`.**
- Progress accrues across your 5-hour windows; you review each PR.
- Note: autonomous runs on a premium model consume the window quickly — one focused task per run
  is deliberate.

## 7. The honest split — what autonomy can and can't do

- **Autonomously buildable** (repo code + tests): the whole **core** (envelope, contract,
  transport, manifest, discovery, conformance, inference interface) and the **plugins**.
- **Hands-on only** (needs the actual cluster): the **ROGER deployment** — Apptainer images, GPU
  services, the local model, SLURM, credentials. Claude can *write* the `deploy/` scaffolding but
  **cannot bring it up or test it** on ROGER. That phase is supervised, with research-computing.

## 8. Relationship to PHI-Weaver

- **PHI-Weaver** (`PHI-base/phi-weaver`) — the curation vault + importable engine (`phiweaver/`),
  the six curation skills, the gold-standard example library, and the benchmarking scorecard.
- **phikestrel** — the plug-in / pipe host that *runs* curation modules with a local AI on ROGER.
  It shares the envelope and never-guess principles and consumes/produces the same structured
  curation records, so modules and examples move between the two.

## 9. Next steps

1. Confirm scope (core + plugins autonomous; `deploy/` scaffolding only), the review gate
   (PR-per-task recommended), and the runner (scheduled cloud routine vs local loop).
2. Scaffold the repo (Phase 0) — layout, `pyproject.toml`, CI, README.
3. Wire the scheduled runner to execute the plan task-by-task via PRs.
4. Keep ROGER bring-up (Phase 7) as the supervised phase.
