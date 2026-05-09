# High-Side Scripts

High-side (air-gapped) scripts for transfer ingestion, package import, and repository management.

## Scripts

### Package Import

**import-packages.sh** — Import packages from transfer bundle into Aptly repo

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `REPO_NAME` — Aptly repository name (e.g., `highside-noble-main`)
- `PACKAGE_DIR` — Directory containing .deb files
- `MANIFEST_FILE` — Path to verified transfer manifest

Exit codes:
- 0: Packages imported successfully
- 1: Error occurred

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export REPO_NAME=highside-noble-main
export PACKAGE_DIR=/mnt/transfer/packages/main
export MANIFEST_FILE=/mnt/transfer/manifest.json
./import-packages.sh
```

### Package Removal

**remove-packages.sh** — Remove packages based on transfer manifest

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `REPO_NAME` — Aptly repository name
- `MANIFEST_FILE` — Path to verified transfer manifest

Exit codes:
- 0: Packages removed successfully
- 1: Error occurred
- 2: No packages to remove

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export REPO_NAME=highside-noble-main
export MANIFEST_FILE=/mnt/transfer/manifest.json
./remove-packages.sh
```

### Publish Update

**publish-update.sh** — Update published repository endpoint

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `REPO_NAME` — Aptly repository name
- `DISTRIBUTION` — Distribution name (e.g., `noble`)

Exit codes:
- 0: Publish updated successfully
- 1: Error occurred

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export REPO_NAME=highside-noble-main
export DISTRIBUTION=noble
./publish-update.sh
```

### State Reconciliation

**reconcile.sh** — Verify high-side repo state matches expected snapshot

Required environment variables:
- `APTLY_CONFIG` — Path to aptly.conf
- `REPO_NAME` — Aptly repository name
- `MANIFEST_FILE` — Path to verified transfer manifest

Exit codes:
- 0: Repository state matches expected
- 1: Error occurred or state mismatch

Example:
```bash
export APTLY_CONFIG=/etc/aptly/aptly.conf
export REPO_NAME=highside-noble-main
export MANIFEST_FILE=/mnt/transfer/manifest.json
./reconcile.sh
```

### Smoke Testing

**smoke-test.sh** — Test APT repository endpoint availability

Required environment variables:
- `APT_REPO_URL` — APT repository URL (e.g., `http://localhost:8080`)
- `DISTRIBUTION` — Distribution name (e.g., `noble`)
- `COMPONENT` — Component name (e.g., `main`)

Exit codes:
- 0: All smoke tests passed
- 1: One or more tests failed

Example:
```bash
export APT_REPO_URL=http://localhost:8080
export DISTRIBUTION=noble
export COMPONENT=main
./smoke-test.sh
```

Tests performed:
1. Release file accessibility
2. InRelease file accessibility
3. Packages.gz availability
4. Packages.gz format validation (valid gzip)
5. Package entries existence

## Common Library

**lib/common.sh** — Shared functions used by all high-side scripts

Functions:
- `log_info`, `log_error`, `log_warn` — Logging with timestamps
- `require_env` — Validate required environment variables
- `validate_aptly_config` — Check Aptly config exists
- `repo_exists` — Check if repository exists in Aptly
- `verify_gpg_signature` — Verify GPG detached signature
- `verify_sha256` — Verify SHA-256 checksum

## Script Conventions

All scripts follow these conventions:

- **Bash strict mode:** `set -euo pipefail`
- **Exit codes:** 0 = success, 1 = error, 2 = nothing to do (idempotent)
- **Logging:** Structured output with ISO 8601 timestamps to stderr
- **Environment variables:** Required vars documented in script header
- **Air-gap awareness:** No public internet URLs referenced

## Security Requirements

All scripts enforce:

- **GPG signature verification** before any import operations
- **SHA-256 checksum validation** for all .deb files
- **Manifest schema validation** before processing
- **Atomic operations** where feasible (all packages imported or none)

## Typical Workflow

Transfer ingestion cycle:

1. **Verify bundle:**
   ```bash
   # Initial transfer
   ./verify-bundle.sh /mnt/transfer /path/to/keyring.gpg
   
   # Subsequent transfers (with continuity)
   ./verify-bundle.sh /mnt/transfer /path/to/keyring.gpg \
     --expected-previous-snapshot ubuntu-noble-main-20260401
   ```
   
   This single step performs all verification in required order:
   - GPG signature verification
   - Schema and required fields validation
   - Continuity check (snapshot chain integrity)
   - SHA-256 checksums
   - Completeness check

2. **Import packages:**
   ```bash
   ./import-packages.sh
   ```

3. **Remove obsolete packages:**
   ```bash
   ./remove-packages.sh
   ```

4. **Update published repository:**
   ```bash
   ./publish-update.sh
   ```

5. **Reconcile state:**
   ```bash
   ./reconcile.sh
   ```

6. **Run smoke tests:**
   ```bash
   ./smoke-test.sh
   ```

## Air-Gap Constraints

**These scripts must never:**
- Reference public Ubuntu archive URLs
- Reference Azure Commercial endpoints
- Reference any public internet resources
- Make outbound network connections
- Store credentials or secrets

**Azure Government integration must:**
- Use government cloud endpoints (`.usgovcloudapi.net`)
- Use Private Endpoints only
- Authenticate via Managed Identity
- Include required compliance tags

## See Also

- [../aptly/README.md](../aptly/README.md) — Aptly configuration
- [../../docs/architecture.md](../../docs/architecture.md) — System architecture
- [../../docs/manifest-schema.md](../../docs/manifest-schema.md) — Manifest format
- [../../transfer/README.md](../../transfer/README.md) — Transfer verification and decryption
