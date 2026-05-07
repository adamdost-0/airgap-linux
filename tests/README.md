# tests/

Integration and validation tests for the airgap-linux pipeline.

## Purpose

Tests that validate the pipeline components work correctly:

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

## Running Tests

> 🚧 Test framework TBD. Will use standard shell-based testing (bats) and Python pytest.
