# Commercial Scripts

Commercial-side (low-side) scripts for the Aptly mirror, snapshot, diff, and bundle pipeline.

## Scripts

### Mirror Management

**mirror-update.sh** — Update Aptly mirror from upstream Ubuntu archive

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `MIRROR_NAME` — Mirror name (e.g., `ubuntu-noble-main`)

Exit codes:
- 0: Mirror updated successfully
- 1: Error occurred
- 2: Mirror unchanged (idempotent)

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export MIRROR_NAME=ubuntu-noble-main
./mirror-update.sh
```

### Snapshot Management

**snapshot-create.sh** — Create snapshot from mirror

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `MIRROR_NAME` — Source mirror name
- `COMPONENT` — Component (main|security|universe)
- `SNAPSHOT_DATE` — Date in YYYYMMDD format (optional, defaults to today)

Exit codes:
- 0: Snapshot created successfully
- 1: Error occurred
- 2: Snapshot already exists (idempotent)

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export MIRROR_NAME=ubuntu-noble-main
export COMPONENT=main
export SNAPSHOT_DATE=20260501
./snapshot-create.sh
```

### Diff Generation

**diff-generate.sh** — Generate diff between two snapshots

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `PREVIOUS_SNAPSHOT` — Previous snapshot name
- `CURRENT_SNAPSHOT` — Current snapshot name
- `OUTPUT_FILE` — Path to write diff output

Exit codes:
- 0: Diff generated successfully
- 1: Error occurred
- 2: Snapshots are identical (no changes)

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export PREVIOUS_SNAPSHOT=ubuntu-noble-main-20260401
export CURRENT_SNAPSHOT=ubuntu-noble-main-20260501
export OUTPUT_FILE=./diff-20260501.txt
./diff-generate.sh
```

### Manifest Generation

**manifest-generate.sh** — Generate transfer manifest JSON

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `DIFF_FILE` — Path to snapshot diff output
- `PREVIOUS_SNAPSHOT` — Previous snapshot name
- `CURRENT_SNAPSHOT` — Current snapshot name
- `TRANSFER_ID` — Unique transfer ID (e.g., `transfer-20260501-001`)
- `OUTPUT_FILE` — Path to write manifest JSON
- `GPG_KEY_ID` — GPG key ID for signing

Exit codes:
- 0: Manifest generated successfully
- 1: Error occurred

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export DIFF_FILE=./diff-20260501.txt
export PREVIOUS_SNAPSHOT=ubuntu-noble-main-20260401
export CURRENT_SNAPSHOT=ubuntu-noble-main-20260501
export TRANSFER_ID=transfer-20260501-001
export OUTPUT_FILE=./manifest.json
export GPG_KEY_ID=ABCD1234EFGH5678
./manifest-generate.sh
```

### Bundle Packaging

**bundle-package.sh** — Package transfer bundle with .deb files

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `MANIFEST_FILE` — Path to transfer manifest JSON
- `BUNDLE_DIR` — Directory to write transfer bundle
- `APTLY_POOL_DIR` — Path to Aptly pool (default: `/var/lib/aptly/pool`)

Exit codes:
- 0: Bundle packaged successfully
- 1: Error occurred

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export MANIFEST_FILE=./manifest.json
export BUNDLE_DIR=/mnt/transfer/bundle-20260501
export APTLY_POOL_DIR=/var/lib/aptly/pool
./bundle-package.sh
```

## Common Library

**lib/common.sh** — Shared functions used by all commercial scripts

Functions:
- `log_info`, `log_error`, `log_warn` — Logging with timestamps
- `require_env` — Validate required environment variables
- `validate_aptly_config` — Check Aptly config exists
- `snapshot_name` — Generate snapshot name from component and date
- `snapshot_date` — Get current date in snapshot format (YYYYMMDD)
- `snapshot_exists` — Check if snapshot exists in Aptly
- `mirror_exists` — Check if mirror exists in Aptly

## Script Conventions

All scripts follow these conventions:

- **Bash strict mode:** `set -euo pipefail`
- **Exit codes:** 0 = success, 1 = error, 2 = nothing to do (idempotent)
- **Logging:** Structured output with ISO 8601 timestamps to stderr
- **Environment variables:** Required vars documented in script header
- **Idempotency:** Where feasible, scripts check state and exit early if no work needed

## Typical Workflow

Monthly snapshot cycle:

1. **Update mirrors:**
   ```bash
   ./mirror-update.sh  # For each component: main, security, universe
   ```

2. **Create snapshots:**
   ```bash
   ./snapshot-create.sh  # For each component
   ```

3. **Generate diffs:**
   ```bash
   ./diff-generate.sh  # Compare with previous month
   ```

4. **Generate manifest:**
   ```bash
   ./manifest-generate.sh  # Build JSON manifest
   ```

5. **Package bundle:**
   ```bash
   ./bundle-package.sh  # Collect .deb files
   ```

6. **Sign and encrypt** (handled by transfer tooling in `../../transfer/`)

## See Also

- [../aptly/README.md](../aptly/README.md) — Aptly configuration
- [../../docs/architecture.md](../../docs/architecture.md) — System architecture
- [../../docs/manifest-schema.md](../../docs/manifest-schema.md) — Manifest format
