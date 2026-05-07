# Cheritto — History

## Core Context

- **Project:** Cross-domain Aptly repository pipeline delivering incremental Linux package snapshots from Azure Commercial to air-gapped high-side enclaves via offline media.
- **Role:** Packaging Engineer
- **Joined:** 2026-05-07T15:43:28.679Z

## Learnings

### 2026-05-07: Aptly Pipeline Structure

**Established baseline structure:**

- **Aptly configs:** Commercial (download concurrency=4) and high-side (concurrency=0, air-gapped)
- **Snapshot naming:** `ubuntu-noble-{component}-YYYYMMDD` pattern implemented in common.sh
- **Exit code convention:** 0=success, 1=error, 2=nothing-to-do for idempotent operations
- **Bash patterns:** `set -euo pipefail`, shellcheck-aware sourcing with guard comments
- **Logging:** ISO 8601 UTC timestamps to stderr for all log functions

**Key files created:**
- `commercial/aptly/aptly.conf` — Commercial-side Aptly config with upstream mirror support
- `highside/aptly/aptly.conf` — Air-gapped config with downloadConcurrency=0
- `commercial/scripts/lib/common.sh` — Mirror/snapshot helpers, validation functions
- `highside/scripts/lib/common.sh` — GPG/SHA-256 verification, repo helpers
- 5 commercial scripts: mirror-update, snapshot-create, diff-generate, bundle-package, manifest-generate
- 5 high-side scripts: import-packages, remove-packages, publish-update, reconcile, smoke-test

**Air-gap constraints respected:**
- High-side scripts contain zero public URLs
- Commercial scripts may reference Ubuntu archives where documented (mirror configs)
- GPG and SHA-256 verification functions in high-side common.sh
- Smoke tests check APT endpoint availability without external dependencies

**Idempotency patterns:**
- mirror-update: Detects "Mirror is up to date" and exits 2
- snapshot-create: Checks if snapshot exists before creating
- diff-generate: Returns exit 2 if snapshots identical

**Architecture notes:**
- Transfer manifest v1.0.0 schema documented in docs/manifest-schema.md
- Package objects include: name, version, arch, filename, sha256, section, priority
- Validation chain: GPG sig → JSON schema → continuity → checksums → completeness

**Coordination notes:**
- Nate owns transfer/ (manifest schema enforcement, encryption, verification wrappers)
- Shiherlis owns infra/ (Azure IaC)
- Eady owns docs/ and diagrams
- I own Aptly/APT concerns only

### 2026-05-07: Transfer Verification Flow Revision

**Context:** Drucker rejected Nate's transfer verification implementation. Validation order placed continuity after checksums/completeness and used a success-shaped stub. Required order is GPG signature → schema/required fields → continuity → checksums → completeness before import.

**Changes made:**

1. **Moved continuity check into verify-bundle.sh** between schema and checksums (lines 85-137)
   - Extracts `previous_snapshot` from manifest via Python
   - For initial transfers (previous_snapshot: null), automatically passes if no expected state provided
   - For non-initial transfers, requires explicit `--expected-previous-snapshot` or `EXPECTED_PREVIOUS_SNAPSHOT` env var
   - Fails closed: verification stops if expected state unavailable or mismatched

2. **Updated verify-bundle.sh signature:**
   - Added `[--expected-previous-snapshot <snapshot_name>]` optional argument
   - Added `EXPECTED_PREVIOUS_SNAPSHOT` environment variable support
   - Argument parsing handles optional continuity state (lines 166-182)

3. **Updated highside wrapper (highside/scripts/verify-bundle.sh):**
   - Changed to forward all arguments to transfer verifier (not just first two)
   - Updated usage to show optional continuity flag
   - Preserves delegation pattern but passes through continuity state

4. **Updated ingest.sh workflow:**
   - Removed separate `check_continuity()` stub function entirely
   - Ingestion now provides continuity state to verify-bundle via args
   - Argument parsing extracts `--expected-previous-snapshot` and forwards to verifier (lines 110-137)
   - Step 2 now performs all verification atomically: GPG + schema + continuity + checksums + completeness
   - Import cannot proceed until all verification including continuity passes

5. **Updated documentation:**
   - `transfer/verify/README.md`: Documents validation order, continuity check behavior, fail-closed semantics
   - `highside/scripts/README.md`: Updated workflow to show continuity flag usage
   - `transfer/manifest/README.md`: Clarified continuity check is in verify-bundle.sh, not validate-manifest.py

**Validation order now enforced:**
1. GPG signature verification
2. Schema and required fields validation
3. **Continuity check** (previous_snapshot vs expected state)
4. SHA-256 checksums
5. Completeness check
6. Import (only after all checks pass)

**Fail-closed behavior:**
- Non-initial transfers require explicit expected state or verification fails
- Mismatch between manifest previous_snapshot and expected state fails verification
- No stub or success-shaped bypass paths remain

**Air-gap safety maintained:**
- No public URLs referenced
- All validation uses stdlib Python and standard tools (gpg, sha256sum)
- Continuity state provided by operator, not external service

- 2026-05-07: Continuity enforcement now sits inside verify-bundle before checksums/completeness, and the high-side ingest path forwards explicit expected previous snapshot state.
