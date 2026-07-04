# TASK 00 — Repo scaffold (Phase 0)

**Goal:** stand up the empty skeleton so every later task has a home.

Build:
- Directory layout from `phikestrel-SETUP.md` §3, each with a short `README.md`:
  `core/`, `plugins/`, `deploy/`, `tests/`, `docs/`.
- `pyproject.toml` — project metadata (name `phikestrel`, Python ≥3.10, no runtime deps),
  and a `[project.scripts]` console entry point placeholder (e.g. `phikestrel`) that can be
  wired later. Keep it minimal; `pip install -e .` stays optional.
- `README.md` at the repo root: copy the intro/architecture from `phikestrel-SETUP.md`, and
  move the full setup guide to `docs/SETUP.md`. Move `phikestrel-REVIEW-INSTRUCTIONS.md`
  content to `docs/REVIEW-INSTRUCTIONS.md`. Leave the `automation/` folder as-is.
- `.github/workflows/ci.yml` — GitHub Actions running
  `python3 -m unittest discover -s tests` on every push and PR (Python 3.10, 3.11, 3.12).
- A trivial placeholder test in `tests/test_scaffold.py` (e.g. asserts the package imports)
  so CI and the green gate are green from day one.

**Acceptance:** `python3 -m unittest discover -s tests` passes; the layout matches SETUP §3;
the core dir contains no third-party imports. Don't over-build — scaffold only.
