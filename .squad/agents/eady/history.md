# History — Eady

## Sessions

### Session 1: Created and Revised Copilot Instructions

**Date:** 2026-05-07
**Work:**
- Analyzed airgap-linux codebase and created `.github/copilot-instructions.md` for future Copilot sessions
- Revised for conciseness (121 lines, 5.4 KB)
- Final accuracy pass: clarified endpoint/URL guidance to distinguish high-side (air-gapped) from commercial-side (can reference upstream archives)

**Output:** Repository guidance file covering:
- Build/test/lint status (none currently defined; architecture/planning phase)
- Architecture overview with monthly data flow
- Snapshot diffs pattern and transfer manifest validation chain
- Code conventions (naming, script idempotency, logging)
- Air-gap & Azure Government constraints (endpoints, auth, encryption, tagging)
- Key references to architecture docs, schema, ADRs
- Removed: checklists, generic guidance, team/governance sections
- Removed: exhaustive file listings (kept brief component summary)
- Accuracy: Clarified that commercial-side may reference upstream Ubuntu archives; high-side code must not reference public internet; endpoint suffixes are conditional on side

## Learnings

### Project Architecture

- **airgap-linux** is a cross-domain Aptly repository pipeline for Azure air-gapped environments
- Mirrors Ubuntu 24.04 (noble/amd64) on Azure Commercial, computes monthly snapshot diffs, transfers via encrypted drives to Azure Gov Secret/Top Secret
- Monthly transfer bundles are ~2–10GB (incremental) vs. 150GB+ full mirrors
- Core flow: Ubuntu Archive → Commercial Aptly → Snapshot Diff → Encrypted Drive → High-Side Ingestion → High-Side Aptly → APT Clients

### Key Components

- **commercial/aptly/** — Mirror config, snapshots (YYYYMMDD naming)
- **commercial/scripts/** — Automation (mirror-update, snapshot-create, diff-generate, bundle-package, manifest-generate) — currently placeholders
- **transfer/** — Encryption (LUKS2 Argon2id), manifests (JSON Schema v1.0.0), verification (GPG + SHA-256)
- **highside/scripts/** — Ingestion (decrypt → verify → import), reconciliation, smoke tests — currently placeholders
- **highside/aptly/** — Local repos, publish config (no mirrors on high-side)
- **commercial/infra/, highside/infra/** — Terraform/Bicep for Azure (azure.com vs. usgovcloudapi.net)
- **tests/** — Unit, integration, schema validation (framework TBD: bats + pytest mentioned)

### Air-Gap & Azure Government Constraints

**Non-negotiable requirements:**
- High-side is fully air-gapped (zero outbound internet)
- Azure Government endpoints: `.usgovcloudapi.net` (high-side), `.azure.com` (commercial)
- Private Endpoints only (no public network access)
- Managed Identity for all auth (no hardcoded credentials)
- LUKS2 encryption (Argon2id KDF, 256-bit AES-XTS) for drives
- GPG for manifest signing (detached .sig files)
- SHA-256 checksums for all .deb files
- Internal PKI for TLS (not public CAs)
- Required tags on all Azure resources: Environment, Project, Owner, Classification, Compliance, ManagedBy

### Code Conventions

- **Snapshot naming:** `ubuntu-noble-{component}-YYYYMMDD`
- **Scripts:** kebab-case, idempotent (exit 0/1/2 pattern)
- **Logging:** Human-readable + structured JSON for automation
- **Manifests:** JSON with schema versioning (semver), GPG signature validation, checksum verification

### Documentation

- No actual Python/Shell scripts exist yet — all are placeholders/documented as future work
- `docs/architecture.md` is comprehensive (12.4 KB); explains design, flow, responsibilities
- `docs/manifest-schema.md` defines JSON format (v1.0.0) with field reference, examples
- ADR 001 documents decision to use Aptly with snapshot diffs (rationale vs. apt-mirror, debmirror, rsync)
- All component READMEs are present and describe purpose, conventions

### Key Decisions Made

- Used Aptly (not apt-mirror/debmirror/rsync) because it provides native snapshot diffs and package-awareness
- Monthly physical media transfer cadence (can be triggered manually for critical security updates)
- Split-key encryption for transfer drives (keys never stored on drive)
- Manifest version 1.0.0 uses semver; breaking changes increment major
- Idempotent scripts with clear exit codes for automation and observability
- Atomic ingestion (all packages imported or none) to avoid partial state

### Important Patterns

- **Snapshot diffs:** `aptly snapshot diff snapshot-v1 snapshot-v2` → added/removed/upgraded lists
- **Transfer manifest validation chain:** GPG → schema → continuity → checksums → completeness
- **Idempotency:** Scripts safe to re-run; exit code 2 means "nothing to do"
- **Infrastructure tagging:** All resources tagged for compliance and cost tracking
- **Air-gap philosophy:** Assume zero internet on high-side; never reference public URLs in code

### File Paths of Interest

- `docs/architecture.md` — System design and data flow (12.4 KB, comprehensive)
- `docs/manifest-schema.md` — Transfer manifest JSON format (full schema reference)
- `docs/adr/001-aptly-snapshot-diffs.md` — Decision rationale and alternatives analysis
- `README.md` — Quick start, prerequisites, constraints summary
- `.squad/agents/squad.agent.md` — Squad agent orchestration definition
- `.github/workflows/` — Heartbeat, issue assign, triage, label sync workflows

### No Build/Test/Lint Commands Yet

- No Makefile, package.json, pyproject.toml, setup.py, or pre-commit config exists
- No GitHub Actions workflows for CI/CD exist (workflows are for Squad management only)
- Scripts themselves are documented but not yet implemented
- Test framework TBD (mentioned bats for shell, pytest for Python)

### Documentation Structure

- `docs/project-structure.md` is now the concise canonical map for directory ownership and monthly flow
- `docs/diagrams/airgap-package-flow.svg` is the source-controlled architecture/data-flow diagram for the repo intent
- Root and docs READMEs should stay brief and point to the canonical structure doc instead of duplicating the full map
- Keep high-side documentation free of public internet references; commercial-side upstream Ubuntu references remain allowed only where explicitly documented

### Key File Paths for This Batch

- `README.md` — brief pointer to the project structure doc
- `docs/README.md` — contents index
- `docs/project-structure.md` — directory responsibilities and monthly flow
- `docs/diagrams/airgap-package-flow.svg` — package flow diagram

- 2026-05-07: Canonical project-structure documentation and the package-flow diagram were added, keeping README pointers brief and centralized.
- 2026-05-07: Repository Copilot guidance was documented for future sessions without inventing build/test/lint commands.

### M1 Docs Baseline

- `README.md` and `docs/README.md` now stay intentionally short and point to the canonical docs instead of repeating the full map
- `docs/project-structure.md` is the single source of truth for directory ownership and where validation evidence belongs
- `tests/README.md` now defines what counts as validation evidence and keeps proof close to the relevant test category
- `docs/diagrams/airgap-package-flow.svg` was updated so the visual matches the docs-first baseline and explicitly references docs/tests
- 2026-05-09: M1 burn-down confirmed the docs baseline: `docs/project-structure.md` is the canonical repo map, and `tests/README.md` is the canonical validation-evidence guide.
