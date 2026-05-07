# highside/scripts/

Ingestion and reconciliation automation for the high side.

## Purpose

Shell and Python scripts for processing transfer bundles on the air-gapped high side:

- `ingest.sh` — Main ingestion workflow (decrypt → verify → import → publish)
- `verify-bundle.sh` — GPG and checksum verification
- `import-packages.sh` — Add new/upgraded .debs to Aptly repo
- `remove-packages.sh` — Remove dropped packages from Aptly repo
- `publish-update.sh` — Update published repository
- `reconcile.sh` — Quarterly full reconciliation against expected state
- `smoke-test.sh` — Verify APT clients can install packages

## Conventions

- All scripts are idempotent — safe to re-run if interrupted
- Exit codes: 0 = success, 1 = error, 2 = nothing to do
- Ingestion is atomic — either all packages are imported or none are
- Detailed logging for audit trail
