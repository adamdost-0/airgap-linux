# transfer/manifest/

Manifest generation and validation tooling.

## Purpose

Tools for creating and validating the JSON transfer manifest that accompanies every transfer bundle:

- Manifest generation from Aptly snapshot diffs
- Schema validation (JSON Schema)
- Manifest signing (GPG detached signature)
- Schema migration scripts for version upgrades

## Files

- `manifest.schema.json` — JSON Schema v1.0.0 for machine validation (air-gap compliant: uses URN identifiers, no public internet URLs)
- `example-manifest.json` — Valid manifest example
- `validate-manifest.py` — Python validator (stdlib only, air-gap safe)

## Schema

See [docs/manifest-schema.md](../../docs/manifest-schema.md) for the full schema definition and examples.

## Validation

The manifest validator checks:
1. JSON schema conformance
2. Required fields presence and format
3. Checksum format validity (64-char lowercase hex)
4. Package count consistency
5. Transfer size calculation accuracy

**Note:** The manifest validator (validate-manifest.py) checks structure and internal consistency only. The continuity check (verifying `previous_snapshot` matches expected high-side state) is performed by verify-bundle.sh during ingestion.

## Usage

```bash
# Validate manifest structure
./validate-manifest.py /path/to/manifest.json

# Exit codes:
#   0 = valid
#   1 = validation failed
#   2 = file not found or JSON parse error
```
