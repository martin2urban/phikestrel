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
| 10 | `tasks/70-document-ingest.md` | 6b | Ingestion plugin: `document → document_text` (paper → normalized, sectioned text) |
| 11 | `tasks/80-phenotype-extract.md` | 6c | Extraction plugin: `document_text → phenotype` (pull candidate phenotypes + source spans) |
| 12 | `tasks/90-pipeline-orchestrator.md` | 6d | Core orchestrator: run a validated chain end-to-end, fan-out, provenance threading, CLI |
| 13 | `tasks/95-curation-record.md` | 6e | Assembly plugin: `phipo_term → curation_record`; full **paper → curated record** integration |
| — | (hands-on) | 7 | ROGER: Apptainer, GPU services, SLURM, the local model — supervised, not automated |

**Paper-in pipeline (Phases 6b–6e).** Tasks 70/80/90/95 turn the host from a single mapping
stage into a runnable **paper → curated output** chain:
`document → [70] → document_text → [80] → phenotype → [60] → phipo_term → [95] → curation_record`,
composed and fanned-out by the [90] orchestrator. New stage types: `document`,
`document_text`, `curation_record` (declared by the plugins, per TASK 11's string-type rule).
Gene / pathogen / host / disease axes are future plugins built the same way (a 80-style
extractor + a 60-style mapper each) — not in this map yet.

**How progress is tracked:** completed task ids go in `automation/.progress` (gitignored).
Delete a line to force that task to re-run; empty the file to start over.

**Each task, when run, must:** pass the green gate (`python3 -m unittest discover -s tests`),
respect the core-is-stdlib-only and never-guess rules, commit, push, and open/update the PR —
never merge. Full standing rules: `automation/PREAMBLE.md`. Review rubric:
`docs/REVIEW-INSTRUCTIONS.md` (once TASK 00 moves it there).
