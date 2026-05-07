# transfer/manifest/

Manifest generation and validation tooling.

## Purpose

Tools for creating and validating the JSON transfer manifest that accompanies every transfer bundle:

- Manifest generation from Aptly snapshot diffs
- Schema validation (JSON Schema)
- Manifest signing (GPG detached signature)
- Schema migration scripts for version upgrades

## Schema

See [docs/manifest-schema.md](../../docs/manifest-schema.md) for the full schema definition and examples.

## Validation

The manifest validator checks:
1. JSON schema conformance
2. Checksum format validity (64-char lowercase hex)
3. File path existence within the bundle
4. Package count consistency
5. Transfer size calculation accuracy
