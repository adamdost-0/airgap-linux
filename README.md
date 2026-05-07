# airgap-linux

Cross-domain Aptly repository pipeline for Azure air-gapped environments. Mirrors Ubuntu 24.04 (noble/amd64) packages on Azure Commercial, produces incremental snapshot diffs, and ships them via encrypted hard drives to Azure Government Secret/Top Secret Aptly instances.

## Architecture

```
Ubuntu Archive → Commercial Aptly → Snapshot Diff → Encrypted Drive → High-Side Aptly → apt clients
```

Monthly transfers carry only the delta between snapshots — typically 2-10GB instead of 150GB+ full mirrors.

## Repository Structure

```
docs/                   Architecture docs, ADRs, and schema definitions
commercial/aptly/       Aptly mirror and snapshot configuration (low side)
commercial/infra/       Azure Commercial infrastructure (Terraform/Bicep)
commercial/scripts/     Automation scripts for mirror, snapshot, bundle
transfer/encrypt/       LUKS2 encryption tooling for transfer drives
transfer/manifest/      Manifest generation and validation
transfer/verify/        Checksum and GPG signature verification
highside/aptly/         High-side Aptly repo and publish configuration
highside/infra/         Azure Government infrastructure (Terraform/Bicep)
highside/scripts/       Ingestion and reconciliation automation
tests/                  Integration and validation tests
```

## Key Documents

- [Architecture](docs/architecture.md) — System design, data flow, and monthly cycle
- [Manifest Schema](docs/manifest-schema.md) — Transfer manifest JSON format
- [ADR 001: Aptly Snapshot Diffs](docs/adr/001-aptly-snapshot-diffs.md) — Why Aptly, why diffs

## Constraints

- **Air-gap first** — No internet access on the high side. Ever.
- **Azure Government endpoints** — All Azure services use `.usgovcloudapi.net`
- **Private endpoints only** — No public network access on any Azure PaaS
- **Managed Identity** — No hardcoded credentials anywhere
- **Monthly cadence** — Physical media transfer once per month (emergency updates as needed)

## Target Environment

| Parameter | Value |
|-----------|-------|
| OS | Ubuntu 24.04 LTS (noble) |
| Architecture | amd64 |
| Azure (Commercial) | Azure Commercial |
| Azure (High Side) | Azure Government Secret / Top Secret |
| Transfer Medium | LUKS2-encrypted hard drive |
| Aptly Version | Latest stable |

## Getting Started

> 🚧 Implementation in progress. See `docs/architecture.md` for the full design.

### Prerequisites

- Aptly installed on both commercial and high-side systems
- GPG keypair for manifest signing (public key pre-installed on high side)
- LUKS2 tools (`cryptsetup`) for drive encryption
- Azure CLI configured for Government cloud (`az cloud set --name AzureUSGovernment`)

## License

Internal use only.
