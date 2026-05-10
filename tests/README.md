# tests/

Validation evidence and test coverage for M1.

## Purpose

Use this directory to prove that repo changes still match the documented
structure and contract. Keep evidence close to the test category it supports.

## What counts as validation evidence

- command output for shell, Python, or JSON checks
- fixture paths and expected results for schema or integration tests
- artifact names or bundle paths for end-to-end verification
- short notes that tie the proof back to the directory being changed

## Test coverage

- Manifest generation produces valid JSON conforming to schema
- Checksum verification catches corrupted files
- GPG signature validation works end-to-end
- Snapshot diff parsing handles edge cases
- Bundle packaging includes all referenced files
- High-side ingestion correctly imports and removes packages

## Test Categories

- `unit/` — Individual function/script tests (fast, no Aptly required)
- `integration/` — End-to-end tests using Aptly with test repos
- `schema/` — JSON Schema validation tests for manifest format

Current Phase 2 evidence:

- `integration/phase-2-blob-storage.md` — P2-M1 blob storage IaC evidence
- `integration/phase-2-blob-pool-validation.md` — P2-M2 blob pool mount readiness evidence
- `integration/phase-2-transfer-validation.md` — P2-M3 transfer validation evidence

## Evidence guidance

- Put evidence in the nearest matching test area rather than creating a new
  top-level location.
- If a suite does not yet have executable tooling, record the exact command and
  output in the matching test README or fixture note.
- Prefer concise, reviewable proof over duplicated narrative.
- For Phase 2 work, include the milestone ID from
  `docs/phase-2-milestones.md` in the evidence note so PM acceptance can trace
  the proof back to the subagent spawn contract.

## Running Tests

> 🚧 Test framework TBD. Use standard shell-based testing (bats) and Python
> pytest once the implementation stack exists.
