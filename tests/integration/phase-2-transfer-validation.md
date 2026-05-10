# P2-M3 Transfer Validation Evidence

Milestone: `P2-M3` from `docs/phase-2-milestones.md`.

## Purpose

`phase-2-transfer-validate.sh` is the P2-M3 integration entrypoint. It first
validates that Aptly is using a blobfuse2-mounted pool, then delegates transfer
bundle verification to `transfer/verify/verify-bundle.sh`.

The transfer verifier preserves the required validation order:

1. GPG signature verification.
2. JSON schema validation.
3. Snapshot continuity check.
4. SHA-256 checksum verification.
5. Completeness check.

## Validation commands

Run from the repository root:

```bash
bash -n tests/integration/phase-2-transfer-validate.sh
```

Run in a Phase 2 environment with a mounted pool and transfer bundle:

```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export APTLY_POOL_MOUNT=/mnt/aptly-pool
export BUNDLE_ROOT=/mnt/transfer/transfer-20260501-001
export GPG_KEYRING=/etc/airgap-linux/trusted-signers.gpg
export EXPECTED_PREVIOUS_SNAPSHOT=ubuntu-noble-main-20260401
export RUN_APTLY_CHECKS=true
tests/integration/phase-2-transfer-validate.sh
```

## Current sandbox result

- Shell syntax validation: passed.
- Existing manifest fixture validation: passed.
- Live transfer validation: blocked in this sandbox because no blobfuse2 mount,
  GPG keyring, or signed transfer bundle is available.
