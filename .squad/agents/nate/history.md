# Nate — History

## Core Context

- **Project:** Cross-domain Aptly repository pipeline delivering incremental Linux package snapshots from Azure Commercial to air-gapped high-side enclaves via offline media.
- **Role:** Security Engineer
- **Joined:** 2026-05-07T15:43:28.680Z

## Learnings

### 2026-05-07: Transfer Security Infrastructure

Created contract-first security skeleton for cross-domain transfer pipeline:

**Files created:**
- `transfer/manifest/manifest.schema.json` — JSON Schema v1.0.0 for machine validation
- `transfer/manifest/example-manifest.json` — Valid manifest example with all required fields
- `transfer/manifest/validate-manifest.py` — Python stdlib-only validator (air-gap safe)
- `transfer/verify/verify-bundle.sh` — Complete verification chain (GPG → schema → checksums → completeness)
- `transfer/encrypt/format-drive.sh` — LUKS2 drive formatter (Argon2id, AES-XTS-256)
- `transfer/encrypt/open-drive.sh` — LUKS2 drive opener and mounter
- `highside/scripts/ingest.sh` — Main ingestion workflow with stubs for Cheritto's Aptly scripts
- `highside/scripts/verify-bundle.sh` — High-side verification wrapper

**Security patterns enforced:**
- Validation order: GPG signature → JSON schema → continuity → SHA-256 checksums → completeness
- No hardcoded secrets or key material; all supplied via environment/files/operator prompts
- LUKS2 with Argon2id KDF and 256-bit AES-XTS encryption
- Explicit device arguments with confirmation for destructive operations
- High-side code contains no public internet URLs
- Python validator uses stdlib only (no jsonschema dependency)

**Key architectural decisions:**
- JSON Schema is the machine-readable contract; docs/manifest-schema.md remains human reference
- Validation is idempotent and can be run standalone or as part of ingestion
- High-side ingestion delegates Aptly operations to Cheritto's import/publish scripts
- Continuity check is stubbed in ingest.sh (needs Aptly state query implementation)
- All scripts follow exit code convention: 0=success, 1=error, 2=invalid args

**File paths for future reference:**
- Manifest validator: `transfer/manifest/validate-manifest.py`
- Bundle verifier: `transfer/verify/verify-bundle.sh`
- Ingestion workflow: `highside/scripts/ingest.sh`
- LUKS2 helpers: `transfer/encrypt/{format,open}-drive.sh`

- 2026-05-07: Transfer validation structure was established, but the continuity gate required a reviewer-driven revision to become fail-closed and operator-controlled.

### 2026-05-07: Schema Air-Gap Hygiene Fix

Removed public internet URL references from transfer manifest schema metadata:

**Changed:**
- `$schema`: `http://json-schema.org/draft-07/schema#` → `urn:json-schema:draft-07`
- `$id`: `https://github.com/adamdost/airgap-linux/...` → `urn:airgap-linux:transfer:manifest:v1.0.0`

**Validation confirmed:**
- Python stdlib validator still works correctly with URN identifiers
- Schema validation remains functional offline
- No external dependencies or network calls required

**Rationale:**
- Schema metadata fields (`$schema`, `$id`) are descriptive and not fetched at validation time
- URN-style identifiers preserve semantic meaning without internet references
- Air-gap hygiene: no public URLs in any high-side or transfer tooling

- 2026-05-07: Decision merged into `.squad/decisions.md` and the inbox entry was cleared after final validation.
