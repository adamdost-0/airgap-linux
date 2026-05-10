# P2 Native Aptly HDD Evidence

Milestones: `P2-M2`, `P2-M3`, and `P2-M4` from
`docs/phase-2-milestones.md`.

## Product path

1. Low side uses native Aptly commands to update mirrors, create immutable
   snapshots, diff consecutive snapshots, and collect added/upgraded `.deb`
   packages from the local Aptly pool.
2. Transfer tooling signs `manifest.json`, verifies SHA-256 checksums, and writes
   the bundle to the LUKS2 HDD workflow.
3. High side verifies the HDD bundle in the required order, imports packages into
   local Aptly repos, removes dropped packages, publishes, reconciles, and smoke
   tests clients against the high-side network endpoint.

## Validation commands

Run from the repository root for static checks:

```bash
python3 transfer/manifest/validate-manifest.py transfer/manifest/example-manifest.json
find commercial highside transfer -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
git diff --check HEAD
```

Run in the low-side Phase 2 environment with real Aptly state:

```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export MIRROR_NAME=ubuntu-noble-main
commercial/scripts/mirror-update.sh
export COMPONENT=main
commercial/scripts/snapshot-create.sh
export PREVIOUS_SNAPSHOT=ubuntu-noble-main-20260401
export CURRENT_SNAPSHOT=ubuntu-noble-main-20260501
export OUTPUT_FILE=/var/tmp/diff-20260501.txt
commercial/scripts/diff-generate.sh
```

Run in the high-side Phase 2 environment after HDD mount and verification:

```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export REPO_NAME=highside-noble-main
export PACKAGE_DIR=/mnt/airgap-transfer/packages/main
export MANIFEST_FILE=/mnt/airgap-transfer/manifest.json
highside/scripts/import-packages.sh
highside/scripts/remove-packages.sh
export DISTRIBUTION=noble
highside/scripts/publish-update.sh
highside/scripts/reconcile.sh
export APT_REPO_URL=https://repo.apt.internal.local/ubuntu
export COMPONENT=main
highside/scripts/smoke-test.sh
```

## Current sandbox result

- Manifest fixture validation: passed.
- Shell syntax validation: passed.
- Whitespace validation: passed.
- Live Aptly/HDD hydration evidence: pending a Phase 2 environment with real
  Aptly state and mounted transfer media.
