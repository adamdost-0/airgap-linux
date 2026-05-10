# P2-M2 Blob Pool Validation Evidence

Milestone: `P2-M2` from `docs/phase-2-milestones.md`.

## Purpose

`phase-2-blob-pool-validate.sh` gives the Cheritto lane a repeatable readiness
check for a blobfuse2-mounted Aptly pool before running mirror, snapshot, diff,
repo import, remove, publish, or smoke-test flows.

The validator checks:

1. `APTLY_CONFIG` exists and has a non-empty `rootDir`.
2. `rootDir` is on the expected `APTLY_POOL_MOUNT`.
3. `APTLY_POOL_MOUNT` is an active mount point.
4. The Aptly root supports write, read-after-write, and delete operations.
5. Optional read-only Aptly checks use `-config="${APTLY_CONFIG}"`.

## Validation commands

Run from the repository root:

```bash
bash -n tests/integration/phase-2-blob-pool-validate.sh
```

Run in a Phase 2 environment with blobfuse2 mounted:

```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export APTLY_POOL_MOUNT=/mnt/aptly-pool
export RUN_APTLY_CHECKS=true
tests/integration/phase-2-blob-pool-validate.sh
```

## Current sandbox result

- Shell syntax validation: passed.
- Live mount validation: blocked in this sandbox because no blobfuse2 mount is
  available.
