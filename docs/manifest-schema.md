# Transfer Manifest Schema

## Overview

The transfer manifest is a JSON document that describes the exact contents of a cross-domain transfer bundle. It serves as the source of truth for what packages should be imported on the high side and enables verification without inspecting individual .deb files.

## Schema Version

Current version: `1.0.0`

The manifest version follows semver. Breaking changes (field removals, type changes) increment major. New optional fields increment minor.

## Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `manifest_version` | string | ✅ | Schema version (semver) |
| `transfer_id` | string | ✅ | Unique identifier for this transfer bundle |
| `generated_at` | string (ISO 8601) | ✅ | Timestamp of manifest generation (UTC) |
| `source_snapshot` | object | ✅ | Current snapshot being transferred |
| `source_snapshot.name` | string | ✅ | Aptly snapshot name |
| `source_snapshot.id` | string | ✅ | Aptly internal snapshot UUID |
| `source_snapshot.created_at` | string (ISO 8601) | ✅ | When the snapshot was created |
| `previous_snapshot` | object | ✅ | Previous snapshot (delta base); null for initial transfer |
| `previous_snapshot.name` | string | ✅ | Previous Aptly snapshot name |
| `previous_snapshot.id` | string | ✅ | Previous Aptly snapshot UUID |
| `previous_snapshot.created_at` | string (ISO 8601) | ✅ | When the previous snapshot was created |
| `component` | string | ✅ | Ubuntu component (main, universe, security) |
| `distribution` | string | ✅ | Ubuntu distribution codename (noble) |
| `architecture` | string | ✅ | Target architecture (amd64) |
| `packages_added` | array | ✅ | Packages new in this snapshot |
| `packages_removed` | array | ✅ | Packages dropped from previous snapshot |
| `packages_upgraded` | array | ✅ | Packages with version changes |
| `transfer_size_bytes` | integer | ✅ | Total size of all .deb files in bytes |
| `package_count` | object | ✅ | Summary counts |
| `package_count.added` | integer | ✅ | Number of added packages |
| `package_count.removed` | integer | ✅ | Number of removed packages |
| `package_count.upgraded` | integer | ✅ | Number of upgraded packages |
| `package_count.total_in_snapshot` | integer | ✅ | Total packages in source snapshot |
| `gpg_signature` | object | ✅ | GPG signature metadata |
| `gpg_signature.signer_key_id` | string | ✅ | GPG key ID used to sign |
| `gpg_signature.signature_file` | string | ✅ | Relative path to detached signature |
| `gpg_signature.algorithm` | string | ✅ | Signature algorithm (e.g., "EdDSA") |
| `checksum_algorithm` | string | ✅ | Hash algorithm for file checksums (sha256) |

### Package Object (added)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Package name |
| `version` | string | Package version |
| `arch` | string | Architecture |
| `filename` | string | Relative path to .deb file in bundle |
| `size_bytes` | integer | File size in bytes |
| `sha256` | string | SHA-256 checksum of the .deb file |
| `section` | string | Debian section (libs, net, admin, etc.) |
| `priority` | string | Package priority (required, important, standard, optional) |

### Package Object (removed)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Package name |
| `version` | string | Version being removed |
| `arch` | string | Architecture |
| `reason` | string | Why removed (superseded, dropped-from-archive, security-revoked) |

### Package Object (upgraded)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Package name |
| `old_version` | string | Previous version |
| `new_version` | string | New version |
| `arch` | string | Architecture |
| `filename` | string | Relative path to new .deb file |
| `size_bytes` | integer | File size of new .deb |
| `sha256` | string | SHA-256 of new .deb |
| `is_security_update` | boolean | Whether this is a security fix |

## Example Manifest

```json
{
  "manifest_version": "1.0.0",
  "transfer_id": "transfer-20260501-001",
  "generated_at": "2026-05-01T06:00:00Z",
  "source_snapshot": {
    "name": "ubuntu-noble-main-20260501",
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "created_at": "2026-05-01T04:30:00Z"
  },
  "previous_snapshot": {
    "name": "ubuntu-noble-main-20260401",
    "id": "f0e1d2c3-b4a5-6789-0fed-cba987654321",
    "created_at": "2026-04-01T04:30:00Z"
  },
  "component": "main",
  "distribution": "noble",
  "architecture": "amd64",
  "packages_added": [
    {
      "name": "libexample1",
      "version": "2.4.1-0ubuntu1",
      "arch": "amd64",
      "filename": "packages/main/libexample1_2.4.1-0ubuntu1_amd64.deb",
      "size_bytes": 245760,
      "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "section": "libs",
      "priority": "optional"
    },
    {
      "name": "newutil",
      "version": "1.0.0-1",
      "arch": "amd64",
      "filename": "packages/main/newutil_1.0.0-1_amd64.deb",
      "size_bytes": 51200,
      "sha256": "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a",
      "section": "admin",
      "priority": "optional"
    }
  ],
  "packages_removed": [
    {
      "name": "deprecated-tool",
      "version": "0.9.8-2ubuntu1",
      "arch": "amd64",
      "reason": "dropped-from-archive"
    }
  ],
  "packages_upgraded": [
    {
      "name": "openssl",
      "old_version": "3.0.13-0ubuntu3.1",
      "new_version": "3.0.13-0ubuntu3.2",
      "arch": "amd64",
      "filename": "packages/main/openssl_3.0.13-0ubuntu3.2_amd64.deb",
      "size_bytes": 1843200,
      "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
      "is_security_update": true
    },
    {
      "name": "curl",
      "old_version": "8.5.0-2ubuntu10.1",
      "new_version": "8.5.0-2ubuntu10.2",
      "arch": "amd64",
      "filename": "packages/main/curl_8.5.0-2ubuntu10.2_amd64.deb",
      "size_bytes": 227328,
      "sha256": "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592",
      "is_security_update": true
    }
  ],
  "transfer_size_bytes": 2367488,
  "package_count": {
    "added": 2,
    "removed": 1,
    "upgraded": 2,
    "total_in_snapshot": 4523
  },
  "gpg_signature": {
    "signer_key_id": "ABCD1234EFGH5678",
    "signature_file": "manifest.json.sig",
    "algorithm": "EdDSA"
  },
  "checksum_algorithm": "sha256"
}
```

## Validation Rules

1. **`manifest_version`** must be a valid semver string
2. **`transfer_id`** must match pattern `transfer-\d{8}-\d{3}`
3. **`generated_at`** must be valid ISO 8601 UTC timestamp
4. **`previous_snapshot`** may be `null` only for the initial (full) transfer
5. **All `sha256` values** must be 64-character lowercase hex strings
6. **All `filename` paths** must be relative (no leading `/`) and exist in the bundle
7. **`transfer_size_bytes`** must equal the sum of all `size_bytes` in added + upgraded packages
8. **`package_count`** fields must match the actual array lengths
9. **`is_security_update`** in upgraded packages is determined by the source mirror (security vs main)

## Initial Transfer (Full Sync)

For the first transfer to a new high-side environment, `previous_snapshot` is `null` and all packages appear in `packages_added`. There are no removed or upgraded packages.

```json
{
  "previous_snapshot": null,
  "packages_removed": [],
  "packages_upgraded": []
}
```

## Manifest Signing

The manifest is signed with a detached GPG signature:

```bash
gpg --armor --detach-sign --local-user "${SIGNER_KEY_ID}" manifest.json
```

Verification on the high side:

```bash
gpg --verify manifest.json.sig manifest.json
```

The signing key's public component must be pre-installed on the high side during initial setup.

## Schema Evolution

When adding fields:
- Add as optional with a default that preserves backward compatibility
- Increment minor version
- Update this document and the validation tooling simultaneously

When removing or changing field types:
- Increment major version
- Provide a migration script in `transfer/manifest/migrations/`
- Both sides must be updated before the next transfer cycle
