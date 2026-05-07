# transfer/verify/

Checksum and GPG signature verification tooling.

## Purpose

Verification tools used on the high side during ingestion to validate transfer bundle integrity:

- GPG signature verification of manifest
- SHA-256 checksum validation of all .deb files
- Manifest schema validation
- Continuity check (previous snapshot reference matches high-side state)

## Verification Order

1. **GPG signature** — Verify `manifest.json.sig` against `manifest.json`
2. **Schema validation** — Ensure manifest conforms to expected schema version
3. **Continuity** — Confirm `previous_snapshot` matches last ingested snapshot
4. **Checksums** — Verify SHA-256 of every .deb file listed in manifest
5. **Completeness** — Ensure all files referenced in manifest exist on drive
