# Project Structure

This is the canonical repo map for M1. Keep this page, the root `README.md`,
`docs/README.md`, `tests/README.md`, and
`docs/diagrams/airgap-package-flow.svg` aligned.

The architecture overview lives in `docs/architecture.md`; this page maps the
directories to ownership and tells contributors where validation evidence
belongs.

## Milestone focus

1. Commercial side mirrors Ubuntu and prepares monthly deltas.
2. Transfer tooling signs, verifies, and encrypts the bundle.
3. High side ingests, removes, and publishes from local Aptly repos.
4. Tests capture evidence that each completed task still matches the repo
   structure.
5. Phase 2 scope, owner lanes, and PM acceptance gates are tracked in
   `docs/phase-2-milestones.md`.

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
- `commercial/infra/` — Azure Commercial Bicep infrastructure

### Transfer tooling

- `transfer/manifest/` — manifest generation, schema checks, signing
- `transfer/verify/` — GPG, checksum, and continuity verification
- `transfer/encrypt/` — LUKS2 drive preparation and key-handling helpers

### High side

- `highside/scripts/` — ingest, verify, import, remove, publish, reconcile, smoke test
- `highside/aptly/` — local repo and publish configuration
- `highside/infra/` — Azure Government Bicep infrastructure

### Documentation and tests

- `docs/` — architecture, schema, ADRs, milestones, and this structure map
- `docs/diagrams/` — source-controlled SVG diagrams
- `tests/` — schema, integration, and validation tests

## Generated content placement

Generated implementation content must land in the directory that owns the runtime
behavior, not in a new milestone-only area. Use this map before adding files:

| Content type | Canonical location | Notes |
|--------------|--------------------|-------|
| Commercial Aptly config or mirror guidance | `commercial/aptly/` | Keep upstream Ubuntu references on the commercial side only. |
| Commercial workflow scripts | `commercial/scripts/` | Mirror, snapshot, diff, manifest, and bundle logic belongs here. |
| Commercial Azure infrastructure | `commercial/infra/` | Bicep templates, parameter examples, and infra README updates belong here. |
| Transfer manifests, encryption, and verification | `transfer/manifest/`, `transfer/encrypt/`, `transfer/verify/` | Keep validation order and schema references with transfer tooling. |
| High-side Aptly config or publish guidance | `highside/aptly/` | High-side content must not reference public internet resources. |
| High-side ingestion and repo operations | `highside/scripts/` | Verify, import, remove, publish, reconcile, and smoke-test logic belongs here. |
| High-side Azure infrastructure | `highside/infra/` | Bicep templates, parameter examples, and infra README updates belong here. |
| Architecture or milestone decisions | `docs/` | Cross-cutting decisions may link to owned paths but should not duplicate implementation detail. |
| Validation evidence | `tests/` | Add or update category indexes, such as `tests/integration/README.md`, instead of creating isolated milestone evidence files. |

## Notes

- High-side documentation and code must not reference public internet URLs.
- Commercial-side mirror docs may mention upstream Ubuntu archives where needed.
- Keep this page and the diagram in sync when directory ownership changes.
- Keep validation evidence with the test area that matches the change, and use
  `tests/README.md` as the canonical guide for what to record.
