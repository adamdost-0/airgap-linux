# airgap-linux

Cross-domain Aptly repository pipeline for Azure air-gapped environments.

## M1 baseline

- Canonical repo map: `docs/project-structure.md`
- System flow: `docs/architecture.md`
- Transfer contract: `docs/manifest-schema.md`
- Validation evidence: `tests/README.md`

## Constraints

- Air-gap first
- High side uses `*.usgovcloudapi.net`
- Private endpoints only
- Managed Identity only
- Monthly transfer cadence
