# transfer/verify/

Checksum and GPG signature verification tooling.

## Purpose

Verification tools used on the high side during ingestion to validate transfer bundle integrity:

- GPG signature verification of manifest
- JSON schema validation with required fields
- Snapshot continuity verification (previous_snapshot matches expected state)
- SHA-256 checksum validation of all .deb files
- Manifest completeness check (all files exist)

## Files

- `verify-bundle.sh` — Complete bundle verification (GPG + schema + continuity + checksums + completeness)

## Verification Order

The verification chain must execute in this exact order:

1. **GPG signature** — Verify `manifest.json.sig` against `manifest.json`
2. **Schema validation** — Ensure manifest conforms to expected schema version and has all required fields
3. **Continuity check** — Confirm `previous_snapshot` matches operator-provided expected state
4. **Checksums** — Verify SHA-256 of every .deb file listed in manifest
5. **Completeness** — Ensure all files referenced in manifest exist on drive

Verification stops at first failure. Import cannot proceed until all checks pass.

## Continuity Check

The continuity check ensures sequential snapshot consistency. It compares the manifest's `previous_snapshot` field against the operator-provided expected state.

**For non-initial transfers:**
- The operator must provide `--expected-previous-snapshot <snapshot_name>` or set `EXPECTED_PREVIOUS_SNAPSHOT` environment variable
- The check fails if manifest `previous_snapshot` does not match expected state
- This prevents out-of-order ingestion and ensures snapshot chain integrity

**For initial transfers:**
- The manifest has `previous_snapshot: null`
- The operator may omit `--expected-previous-snapshot` or explicitly pass `INITIAL`
- The check passes automatically

**Fail-closed behavior:**
- If expected state is not provided for a non-initial transfer, verification fails
- If manifest previous_snapshot does not match expected state, verification fails
- Ingestion cannot proceed to import until continuity is verified

## Usage

```bash
# Initial transfer (no previous snapshot)
./verify-bundle.sh /mnt/airgap-transfer /path/to/keyring.gpg

# Non-initial transfer (with continuity check)
./verify-bundle.sh /mnt/airgap-transfer /path/to/keyring.gpg \
  --expected-previous-snapshot ubuntu-noble-main-20260401

# Using environment variable
export EXPECTED_PREVIOUS_SNAPSHOT=ubuntu-noble-main-20260401
./verify-bundle.sh /mnt/airgap-transfer /path/to/keyring.gpg

# Exit codes:
#   0 = verification passed (all checks including continuity)
#   1 = verification failed
#   2 = missing arguments or file not found
```

## Environment Variables

- `MANIFEST_VALIDATOR` — Path to validate-manifest.py (default: auto-detect)
- `EXPECTED_PREVIOUS_SNAPSHOT` — Expected previous snapshot name (alternative to --expected-previous-snapshot flag)
