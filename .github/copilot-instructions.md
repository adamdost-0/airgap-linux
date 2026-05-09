# Copilot Instructions — airgap-linux

**airgap-linux** is a cross-domain Aptly repository pipeline for Azure air-gapped environments. It mirrors Ubuntu 24.04 (noble/amd64) packages on Azure Commercial, computes monthly snapshot diffs, and transfers incremental bundles via encrypted hard drives to Azure Government Secret/Top Secret environments where they are ingested and served to APT clients.

## Build, Test, and Lint Commands

**No repo-level build, test, or lint commands are currently defined.** The repository is in architecture/planning phase (design complete, implementation in progress). No Makefile, package.json, pyproject.toml, or test runner configuration exists.

## Architecture Overview

**Monthly data flow:**
```
Ubuntu Archive → Commercial Aptly (Azure Commercial) 
→ Snapshot Diffs (added/removed/upgraded)
→ Transfer Bundle (manifest.json + .debs + GPG signature)
→ LUKS2 Encrypted Drive
→ High-Side Ingestion (verify → decrypt → import)
→ High-Side Aptly (usgovcloudapi.net) → APT Clients
```

**Key components:**

- `commercial/aptly/` — Mirror config and snapshots
- `commercial/scripts/` — Planned scripts: mirror-update, snapshot-create, diff-generate, bundle-package, manifest-generate
- `transfer/` — Manifest generation and validation; LUKS2 encryption; GPG signature and checksum verification
- `highside/scripts/` — Planned scripts: ingest, verify-bundle, import-packages, remove-packages, publish-update, reconcile, smoke-test
- `highside/aptly/` — Local repo config (no upstream mirrors on air-gapped side)
- `commercial/infra/`, `highside/infra/` — Infrastructure as code (Terraform/Bicep)
- `docs/` — Architecture design, manifest schema (v1.0.0), ADRs
- `tests/` — Unit, integration, and schema validation tests (framework TBD)

## Snapshot Diffs Pattern

Aptly snapshots are immutable point-in-time captures. Diffs are computed via:

```bash
aptly snapshot diff snapshot-v1 snapshot-v2
```

This produces three lists:
- **packages_added** — New in v2
- **packages_removed** — Dropped from v2
- **packages_upgraded** — Version changed between v1 and v2

The transfer manifest captures these with exact versions, SHA-256 checksums, file paths, and metadata.

## Transfer Manifest & Validation

Manifests are JSON documents (schema v1.0.0) that serve as the source of truth for transfer contents.

**Validation chain (high-side ingestion, in order):**

1. **GPG signature verification** — Detached `.sig` file authenticated
2. **JSON schema validation** — Manifest structure conforms to v1.0.0
3. **Continuity check** — `previous_snapshot` matches last ingested snapshot on high side
4. **Checksum verification** — Every .deb file validated against SHA-256 in manifest
5. **Completeness check** — All files referenced in manifest exist on the drive

See [docs/manifest-schema.md](../docs/manifest-schema.md) for full field reference.

## Code Conventions

### Naming

- **Snapshots:** `ubuntu-noble-{component}-YYYYMMDD` (e.g., `ubuntu-noble-main-20260507`)
- **Transfer bundles:** Encrypted LUKS2 drives; manifests named `manifest.json`
- **Scripts:** kebab-case (e.g., `mirror-update.sh`, `verify-bundle.sh`)

### Script Patterns (Planned Scripts)

Documented scripts follow idempotent conventions:

- **Exit codes:** 0 = success, 1 = error, 2 = nothing to do (idempotent re-run with no changes)
- **Logging:** Human-readable output to stdout; structured JSON for automation
- **Atomicity:** Ingestion is atomic — all packages imported or none

See [commercial/scripts/README.md](../commercial/scripts/README.md), [highside/scripts/README.md](../highside/scripts/README.md) for details.

## Air-Gap & Azure Government Constraints

**Non-negotiable requirements:**

### Network & Endpoints

- **High side is fully air-gapped.** Zero outbound internet. Ever.
- **High-side code must not reference public internet URLs.** All references to internal or government cloud endpoints.
- **Commercial-side code may reference upstream Ubuntu archives** where explicitly documented (e.g., in mirror config).
- **High-side Azure resources:** Use government cloud endpoints like `*.usgovcloudapi.net`.
- **Commercial-side Azure resources:** Target Azure Commercial.
- **Private Endpoints only.** All Azure PaaS must use Private Link; no public network access.

### Authentication & Secrets

- **Managed Identity always.** Use System-assigned or User-assigned MI for Azure service-to-service auth. Never hardcode credentials or connection strings with secrets.
- **GPG keys:** Public keys in Key Vault; signing keys on commercial-side VMs (never in code)
- **LUKS2 keys:** Split between courier and recipient; never stored on the drive

### Encryption & Signing

- **LUKS2 for drives:** Argon2id KDF, minimum 256-bit AES-XTS
- **GPG for manifests:** Detached signatures (`.sig` files)
- **SHA-256 checksums:** Every .deb file; verified before import
- **TLS for APIs:** Internal PKI certificates (not public CAs); TLS 1.2 minimum

### Infrastructure Tags

All Azure resources must include:

```
Environment     = "dev" | "staging" | "prod"
Project         = "airgap-linux"
Owner           = "<team-or-individual>"
Classification  = "CUI"
Compliance      = "IL4" | "IL5" | "IL6"
ManagedBy       = "terraform" | "bicep" | "manual"
```

## Key References

- [docs/architecture.md](../docs/architecture.md) — Detailed system design and component responsibilities
- [docs/manifest-schema.md](../docs/manifest-schema.md) — Transfer manifest JSON schema (v1.0.0) and examples
- [docs/adr/001-aptly-snapshot-diffs.md](../docs/adr/001-aptly-snapshot-diffs.md) — Decision rationale: Aptly with snapshot diffs vs. alternatives
- [README.md](../README.md) — Project overview and prerequisites
