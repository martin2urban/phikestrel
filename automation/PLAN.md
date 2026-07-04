# phikestrel build plan — the automated step map

The whole project, broken into small independently-testable steps. The runner
(`autobuild.sh`) executes them **in order, one per run**, each landing as a commit on
`auto/build` with a PR into `main` for you to review. Phase 7 (ROGER) is **not** here —
it needs the real cluster and stays hands-on.

| # | Task file | Phase | What it builds |
|---|-----------|-------|----------------|
| 1 | `tasks/00-scaffold.md` | 0 | Repo layout, `pyproject.toml`, CI, README, docs; a green placeholder test |
| 2 | `tasks/10-envelope.md` | 1a | Shared envelope: `status` + payload + provenance; JSON round-trip |
| 3 | `tasks/11-stage-contract.md` | 1b | Typed stage contract + pre-run compatibility check |
| 4 | `tasks/20-stdin-transport.md` | 2 | Envelope-over-stdin subprocess transport; timeouts; exit-code contract |
| 5 | `tasks/30-manifest-schema.md` | 3a | Plugin manifest format + validator |
| 6 | `tasks/31-discovery.md` | 3b | Directory + entry-point discovery; deterministic, resilient |
| 7 | `tasks/40-conformance-harness.md` | 4 | Golden fixtures: validity, never-guess, exit codes |
| 8 | `tasks/50-inference-backend.md` | 5 | Inference interface + mock/local-server client; model id in provenance |
| 9 | `tasks/60-phenotype-plugin.md` | 6 | First real plugin: phenotype → PHIPO, out-of-process, end-to-end |
| — | (hands-on) | 7 | ROGER: Apptainer, GPU services, SLURM, the local model — supervised, not automated |

**How progress is tracked:** completed task ids go in `automation/.progress` (gitignored).
Delete a line to force that task to re-run; empty the file to start over.

**Each task, when run, must:** pass the green gate (`python3 -m unittest discover -s tests`),
respect the core-is-stdlib-only and never-guess rules, commit, push, and open/update the PR —
never merge. Full standing rules: `automation/PREAMBLE.md`. Review rubric:
`docs/REVIEW-INSTRUCTIONS.md` (once TASK 00 moves it there).
