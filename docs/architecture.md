# Architecture: Cross-Domain Aptly Repository Pipeline

## Overview

This system maintains Ubuntu 24.04 (noble/amd64) package repositories across air-gapped Azure environments. Packages are mirrored on Azure Commercial, diffed monthly, and transferred via encrypted hard drives to Azure Government Secret/Top Secret environments.

## High-Level Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AZURE COMMERCIAL (Low Side)                          │
│                                                                             │
│  ┌──────────────┐    ┌──────────────────┐    ┌─────────────────────────┐   │
│  │  Ubuntu       │    │  Aptly Mirror    │    │  Aptly Snapshots        │   │
│  │  Archive      │───▶│  (noble/amd64)   │───▶│  ubuntu-noble-main-     │   │
│  │  (upstream)   │    │                  │    │    YYYYMMDD             │   │
│  └──────────────┘    └──────────────────┘    └────────────┬────────────┘   │
│                                                           │                 │
│                                              ┌────────────▼────────────┐   │
│                                              │  Snapshot Diff          │   │
│                                              │  (added/removed/        │   │
│                                              │   upgraded packages)    │   │
│                                              └────────────┬────────────┘   │
│                                                           │                 │
│                                              ┌────────────▼────────────┐   │
│                                              │  Transfer Bundle        │   │
│                                              │  manifest.json + .debs  │   │
│                                              │  + GPG signatures       │   │
│                                              └────────────┬────────────┘   │
└───────────────────────────────────────────────────────────┼─────────────────┘
                                                            │
                                           ┌────────────────▼──────────────┐
                                           │  Encrypted Transfer Drive     │
                                           │  (LUKS2 + tamper-evident)     │
                                           └────────────────┬──────────────┘
                                                            │
┌───────────────────────────────────────────────────────────┼─────────────────┐
│                    AZURE GOV SECRET / TOP SECRET (High Side)                 │
│                                                           │                 │
│                                              ┌────────────▼────────────┐   │
│                                              │  Transfer Ingestion     │   │
│                                              │  verify + decrypt +     │   │
│                                              │  manifest validation    │   │
│                                              └────────────┬────────────┘   │
│                                                           │                 │
│                                              ┌────────────▼────────────┐   │
│                                              │  Aptly Repo (local)     │   │
│                                              │  Import new .debs       │   │
│                                              │  Remove dropped pkgs    │   │
│                                              └────────────┬────────────┘   │
│                                                           │                 │
│                                              ┌────────────▼────────────┐   │
│                                              │  aptly serve / publish  │   │
│                                              │  Clients consume via    │   │
│                                              │  APT over HTTPS         │   │
│                                              └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### Commercial Side (Low Side)

| Component | Responsibility |
|-----------|---------------|
| **Aptly Mirror** | Sync from upstream Ubuntu archive; filter by component and architecture |
| **Aptly Snapshots** | Point-in-time captures of mirror state; immutable once created |
| **Diff Generator** | Compare consecutive snapshots; produce list of added/removed/upgraded packages |
| **Bundle Packager** | Collect .deb files, generate manifest, sign with GPG, write to transfer drive |
| **Scheduler** | Cron-driven monthly cycle; can be triggered manually for critical security updates |

### Transfer Tooling

| Component | Responsibility |
|-----------|---------------|
| **Encryption** | LUKS2 full-disk encryption of transfer drive; key split between courier and recipient |
| **Manifest** | JSON manifest describing exact contents; SHA-256 checksums for every file |
| **Verification** | GPG signature validation, checksum verification, manifest schema validation |

### High Side

| Component | Responsibility |
|-----------|---------------|
| **Ingestion** | Decrypt drive, validate manifest, verify all checksums and signatures |
| **Aptly Repo** | Local repository; packages imported via `aptly repo add` |
| **Publisher** | `aptly publish` or `aptly serve` exposes repo to high-side clients |
| **Reconciler** | Applies removals and ensures high-side state matches expected snapshot |

## Aptly Concepts Used

### Mirrors

Mirrors sync from upstream Ubuntu archives. We maintain separate mirrors per component:

```bash
aptly mirror create ubuntu-noble-main \
  http://archive.ubuntu.com/ubuntu noble main

aptly mirror create ubuntu-noble-security \
  http://security.ubuntu.com/ubuntu noble-security main

aptly mirror create ubuntu-noble-universe \
  http://archive.ubuntu.com/ubuntu noble universe
```

Mirrors are filtered to `amd64` architecture only:

```bash
aptly mirror create -architectures="amd64" -filter="Priority (required)" \
  ubuntu-noble-main http://archive.ubuntu.com/ubuntu noble main
```

### Snapshots

Snapshots are immutable point-in-time captures of a mirror:

```bash
aptly mirror update ubuntu-noble-main
aptly snapshot create ubuntu-noble-main-20260501 from mirror ubuntu-noble-main
```

### Snapshot Diffs

Aptly natively supports computing diffs between snapshots:

```bash
aptly snapshot diff ubuntu-noble-main-20260401 ubuntu-noble-main-20260501
```

This outputs added, removed, and version-changed packages — the basis for our transfer manifest.

### Published Repos (High Side)

On the high side, we publish from a local repo:

```bash
aptly repo create -distribution=noble -component=main highside-noble-main
aptly repo add highside-noble-main /transfer/incoming/*.deb
aptly publish repo -architectures="amd64" highside-noble-main
```

## Naming Conventions

### Snapshot Names

Format: `ubuntu-noble-{component}-{YYYYMMDD}`

Examples:
- `ubuntu-noble-main-20260501`
- `ubuntu-noble-security-20260501`
- `ubuntu-noble-universe-20260501`

### Transfer Bundle Names

Format: `transfer-{YYYYMMDD}-{sequence}`

Examples:
- `transfer-20260501-001` (monthly scheduled)
- `transfer-20260515-001` (emergency security update)

### Manifest Files

Format: `manifest-{source_snapshot}-{YYYYMMDD}.json`

Example: `manifest-ubuntu-noble-main-20260501-20260501.json`

## Directory Layout on Transfer Drive

```
/transfer-20260501-001/
├── manifest.json                    # Transfer manifest (see manifest-schema.md)
├── manifest.json.sig               # Detached GPG signature of manifest
├── metadata/
│   ├── source-snapshot.txt         # Source snapshot name for reference
│   ├── prev-snapshot.txt           # Previous snapshot name (delta base)
│   └── generation-info.json        # Build environment metadata
├── packages/
│   ├── main/
│   │   ├── package1_1.2.3_amd64.deb
│   │   ├── package2_4.5.6_amd64.deb
│   │   └── ...
│   ├── security/
│   │   └── ...
│   └── universe/
│       └── ...
└── checksums/
    └── SHA256SUMS                  # sha256sum output for all .deb files
```

## Monthly Cycle: End-to-End

### Week 1: Mirror Update (Commercial Side)

1. **Update mirrors** — Pull latest packages from Ubuntu archive
2. **Create snapshots** — Capture current mirror state with date-stamped names
3. **Compute diffs** — Compare new snapshot against previous month's snapshot
4. **Generate manifest** — Build JSON manifest with package details and checksums

### Week 2: Bundle & Encrypt (Commercial Side)

5. **Collect .deb files** — Copy only the added/upgraded packages to staging directory
6. **Verify integrity** — SHA-256 checksum every file; validate manifest completeness
7. **Sign manifest** — GPG-sign the manifest with the team signing key
8. **Encrypt drive** — Write bundle to LUKS2-encrypted transfer drive
9. **Tamper-evident seal** — Physical security measures on the drive

### Week 3: Physical Transfer

10. **Chain of custody** — Drive transported per organizational security procedures
11. **Courier log** — Documented handoff with timestamps

### Week 4: Ingestion (High Side)

12. **Decrypt drive** — Unlock LUKS2 volume
13. **Validate manifest** — Verify GPG signature, validate JSON schema
14. **Verify checksums** — SHA-256 check every .deb against manifest
15. **Import packages** — `aptly repo add` for new/upgraded packages
16. **Remove packages** — `aptly repo remove` for dropped packages
17. **Publish** — Update published repository
18. **Smoke test** — Verify clients can `apt update && apt install` successfully

## Storage Strategy

### Phase 1: Local Filesystem

Both commercial and high-side Aptly instances store packages on local disk:
- Commercial: `/opt/aptly/` (standard Aptly root)
- High-side: `/opt/aptly/` with separate pool directories per component

### Phase 2: Native Aptly local storage

Aptly pool storage remains on local managed disks on both sides. The low side
creates snapshots and extracts the added/upgraded package binaries into the
transfer bundle; the high side verifies the HDD contents and hydrates local Aptly
repos with native Aptly commands.

Bicep provisions the Azure VM, local disk, private networking, managed identity,
and Key Vault support resources. Phase 2 scope, implementation lanes, and PM
acceptance evidence are tracked in `docs/phase-2-milestones.md`.

## Security Considerations

- All .deb packages retain their upstream GPG signatures (apt-secure)
- Transfer manifest is independently GPG-signed by the pipeline
- LUKS2 encryption with Argon2id KDF for transfer drives
- No network connectivity between low and high sides — physical media only
- High-side Aptly serves over HTTPS with internal PKI certificates
- All scripts run under least-privilege service accounts with Managed Identity
