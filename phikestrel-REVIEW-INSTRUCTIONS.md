# phikestrel — review instructions for Opus

**Audience:** Opus, acting as the reviewer of an autonomously-produced phikestrel PR
(one task from the phased build plan). Read the PR diff, the touched files, and the
tests, then report against the checks below.

**Scope note — cybersecurity is out of scope here.** Do **not** spend review budget on
threat modelling, injection/authn/authz, secret-scanning, supply-chain, sandboxing, or
CVE analysis. A separate security review owns that. Your job is **correctness,
contract-conformance, project-principle adherence, tests, and clarity.** If you happen
to notice a genuinely dangerous mistake, note it in one line and move on — don't pivot
the review into a security audit.

---

## 0. Orient first (don't review blind)

Before judging the diff:

1. Read the PR description and identify **which build-plan phase/task** it claims to
   implement (Phase 0 scaffold … Phase 6 first plugin). The task defines "done."
2. Read `phikestrel-SETUP.md` §1–§2 so you're enforcing the *actual* architecture
   (light stdlib-only core; out-of-process plugins; shared envelope; typed stage
   contract; never-guess; provenance; green-gated).
3. Confirm the PR does **one task**, not several. Scope creep across phases is a
   finding — flag it and ask for a split.

---

## 1. Non-negotiable principles — enforce these on every PR

These are the project's spine. A violation is a blocking finding, not a nit.

- **Core stays stdlib-only.** Anything under `core/` (and `tests/`) must import only the
  Python standard library. A third-party import in the core is a hard reject. Heavy deps
  (models, vision, HTTP clients, vLLM/TGI/Ollama, etc.) live **only** behind the plugin
  process boundary — never imported by the host.
- **Run-from-root, zero-setup.** The core must run with `python3 -m …` from the repo root
  with no install step. `pip install -e .` is optional, never required. Check nothing new
  assumes an installed package or an activated venv.
- **Never guess.** Ambiguity, not-found, and low-confidence are **explicit statuses in the
  envelope** — never invented/defaulted data. Scan new logic for any path that fabricates
  a value, silently substitutes a default for missing input, or "best-guesses" an answer.
  If a stage can't be sure, it must say so in `status`, not make something up.
- **Provenance is preserved.** Every payload carries provenance: source, cache
  (hit/miss), UTC timestamp, and — for reasoning stages — model identity. Check that new
  code populates provenance, uses **UTC**, and never drops/overwrites upstream provenance
  when passing an envelope along.
- **Behaviour-preserving unless the task says otherwise.** A task scoped to add X should
  not quietly change existing behaviour Y.
- **Green-gated.** Tests (and any smoke) must pass before *and* after the change. No PR
  merges red. If CI isn't wired yet (pre-Phase-0), the diff must still pass
  `python3 -m unittest discover -s tests` locally.
- **phiweaver must not grade its own output.** Any benchmarking/scoring code must stay
  independent of the thing it scores. Flag any coupling that lets a component evaluate
  its own results.

---

## 2. The envelope contract — check line by line where touched

The shared envelope is the interface everything crosses. When a PR produces, consumes,
or forwards an envelope, verify:

- **Shape:** `status` + payload + `provenance` present and well-formed. Status is from the
  defined set (success / ambiguous / not-found / error — match whatever the code
  actually defines; flag ad-hoc string statuses invented in one plugin).
- **JSON in / JSON out:** valid JSON on stdin and stdout, one object per item for the
  job-per-item transport. No stray prints to stdout that corrupt the JSON stream — logs
  and diagnostics go to **stderr**, never stdout.
- **Exit codes:** `0` on handled success, `1` on failure — and critically, a *handled*
  "not-found"/"ambiguous" is still an envelope with exit `0`, not a crash. An uncaught
  exception producing a nonzero exit *and* no envelope is a finding.
- **Round-trip:** serialize → deserialize preserves the envelope exactly (types,
  provenance, unicode). If there's no test for this on a changed envelope path, that's a
  test-coverage finding.

---

## 3. The typed stage contract — check compatibility is actually enforced

Each stage declares `input type → output type`; the host uses that to check compatibility
*before* running a plugin. When a PR touches stages/manifests/discovery:

- The declared `input type`/`output type` on the changed stage is present and accurate.
- The host **actually checks** producer-output-type against consumer-input-type and
  refuses/reports an incompatible wiring — it doesn't just run and hope. Verify there's a
  test proving an incompatible pairing is rejected, not silently accepted.
- Manifest schema: required fields validated; a malformed or missing manifest is a clear,
  explicit error (never a silent skip that makes a plugin vanish from discovery with no
  message).
- Discovery (directory scan / entry-point scan): deterministic, and a broken plugin
  directory doesn't take down discovery of the good ones.

---

## 4. Plugin process boundary

- Plugins run **out-of-process** (subprocess or container). Confirm the host talks to them
  only over the envelope/stdio (or the persistent local service for model-holding
  stages) — never by importing plugin code into the host.
- Subprocess handling: check for the boring-but-real bugs — timeouts on a hung plugin,
  capturing stderr for diagnostics, not deadlocking on large stdout, and surfacing a
  plugin crash as a proper `error` envelope rather than a host traceback.
- The conformance/golden-fixture harness (Phase 4): a plugin must pass validity,
  never-guess, and exit-code fixtures **before** it's incorporated. Check new fixtures
  actually exercise the never-guess path (i.e. there's a not-found/ambiguous fixture, not
  only happy-path).

---

## 5. Inference-backend abstraction (Phase 5+)

- Reasoning stages call **one interface** with selectable backends (local ROGER model for
  prod; cloud for dev/compare). Check no stage hard-codes a single backend or reaches past
  the interface.
- **Model identity is recorded in provenance** for every inference call — reproducibility
  depends on it. A reasoning result with no model id in provenance is a finding.
- Tests must run **network-free**: inference is exercised via a mock/fake client, never a
  live model or a real HTTP call. Any test that would hit the network or a GPU is a
  finding — it breaks the "one discovery root, network-free unit tests" rule.

---

## 6. Correctness & general code quality

- **Logic:** trace the changed code paths for off-by-one, wrong-branch, mishandled
  empty/None, and error paths that swallow exceptions silently.
- **Edge cases specific to this domain:** empty input item, malformed input JSON, a
  plugin that returns nothing, a plugin that returns extra fields, duplicate items,
  non-ASCII biological identifiers/text.
- **No dead scope creep:** unused args, half-wired abstractions "for later," speculative
  config. This project values simple over clever (the maintainer is a domain scientist,
  not a software engineer) — call out anything more complicated than the task needs and
  suggest the simpler form.
- **Readability:** names, and comments that state constraints rather than narrate. Flag
  comments that just restate the code.
- **Determinism:** dict/set ordering leaking into output, timestamps in tests that aren't
  frozen, filesystem-order dependence in discovery.

---

## 7. Tests — presence and quality, not just count

- **Every behavioural change has a test.** New envelope path, new status, new stage type,
  new plugin → new tests. Missing = test-coverage finding.
- Tests are **network-free and run-from-root** (`python3 -m unittest discover -s tests`),
  single discovery root, no hidden fixtures outside it.
- Tests assert the **contract**, not the implementation: they check the envelope shape,
  the status, exit codes, provenance presence — not internal helper internals that will
  churn.
- **Never-guess is tested explicitly:** at least one test proves the code emits an
  ambiguous/not-found status instead of fabricating data. This is the single most
  important test to look for on any curation-logic PR.
- Negative/error tests exist: malformed JSON in, plugin crash, incompatible stage types.

---

## 8. Phase-specific reminders

- **Phase 0 (scaffold):** layout matches SETUP §3; `pyproject.toml` metadata + entry points
  sane; CI workflow runs the test suite on push/PR; README present. Nothing heavy pulled
  into the core. Don't over-build — scaffold only.
- **Phase 7 (ROGER deploy):** Claude may *write* `deploy/` scaffolding (Apptainer defs,
  SLURM jobs, container files) but **cannot bring it up or test it** on the cluster. Review
  the scaffolding for obvious correctness and Docker/Apptainer parity, but do **not** treat
  "untested on ROGER" as a blocker — that phase is supervised with research-computing. Flag
  anything that hard-codes cluster-specific paths/credentials into portable code.

---

## 9. How to report

- Lead with a **verdict**: approve / approve-with-nits / request-changes.
- Rank findings **most-severe first.** Separate **blocking** (principle violation, broken
  contract, red tests, never-guess violation) from **nits** (style, naming, minor
  simplification).
- For each finding: the file:line, one sentence on the defect, and a concrete failure
  scenario (input → wrong behaviour). No vague "consider improving."
- If the PR is clean, say so plainly and don't manufacture findings.
- Keep it short. The maintainer reviews every PR by hand — give them the signal, not a
  wall of text.
