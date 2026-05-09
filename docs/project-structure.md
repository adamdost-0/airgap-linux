# Project Structure

This repo is organized around a contract-first monthly package pipeline. The
canonical overview lives in `docs/architecture.md`; this page maps directories
to ownership, and `docs/diagrams/airgap-package-flow.svg` shows the same flow
visually.

## Monthly flow

1. Commercial side mirrors Ubuntu and creates date-stamped Aptly snapshots.
2. Commercial scripts diff snapshots, package the delta, and sign `manifest.json`.
3. Transfer tooling validates, encrypts, and seals the bundle onto removable media.
4. High-side scripts verify, decrypt, import, remove, and publish packages.
5. High-side Aptly serves clients from local repos only.

## Directory responsibilities

### Commercial side

- `commercial/aptly/` — mirror definitions, snapshot naming, commercial Aptly config
- `commercial/scripts/` — mirror update, snapshot creation, diffing, bundle packaging
- `commercial/infra/` — Azure Commercial infrastructure

### Transfer tooling

- `transfer/manifest/` — manifest generation, schema checks, signing
- `transfer/verify/` — GPG, checksum, and continuity verification
- `transfer/encrypt/` — LUKS2 drive preparation and key-handling helpers

### High side

- `highside/scripts/` — ingest, verify, import, remove, publish, reconcile, smoke test
- `highside/aptly/` — local repo and publish configuration
- `highside/infra/` — Azure Government infrastructure

### Documentation and tests

- `docs/` — architecture, schema, ADRs, and this structure map
- `docs/diagrams/` — source-controlled SVG diagrams
- `tests/` — schema, integration, and validation tests

## Notes

- High-side documentation and code must not reference public internet URLs.
- Commercial-side mirror docs may mention upstream Ubuntu archives where needed.
- Keep this page and the diagram in sync when directory ownership changes.
