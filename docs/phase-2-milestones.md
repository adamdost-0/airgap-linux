# Phase 2 Milestones

Phase 2 moves the M1 local-filesystem Aptly baseline toward blob-backed
storage and evidence-driven acceptance without widening the product scope.

## PM and design review outcome

- **Review date:** 2026-05-10
- **Reviewed with:** Hanna (Product Manager) acceptance lens and McCauley
  design/architecture lane
- **Review inputs:** `README.md`, `docs/project-structure.md`,
  `docs/architecture.md`, `docs/manifest-schema.md`,
  `docs/adr/001-aptly-snapshot-diffs.md`, `commercial/infra/README.md`,
  `highside/infra/README.md`, `.squad/decisions.md`, `.squad/routing.md`,
  and `tests/README.md`
- **On-track finding:** M1 gives Phase 2 a usable contract baseline: owned
  directories are clear, transfer validation order is documented, and
  `tests/README.md` is the evidence guide.
- **Gap closed here:** Phase 2 now has a single milestone contract that names
  owner lanes, spawn gates, and PM acceptance evidence before implementation
  subagents begin.

## Value

Phase 2 proves that both sides of the pipeline can use Azure Blob-backed Aptly
pool storage through private endpoints while preserving the air-gap, transfer,
verification, and audit controls established in M1.

## Scope

### In scope

1. Blob-backed Aptly pool design for commercial and high-side environments.
2. Terraform work to enable storage, private endpoints, managed identity access,
   CMK-ready encryption, and diagnostics when `enable_blob_storage = true`.
3. blobfuse2 mount and Aptly operation validation for mirror, snapshot, diff,
   repo import, remove, publish, and smoke-test flows.
4. Transfer-cycle evidence showing manifest, checksum, signature, continuity,
   and completeness checks still pass with blob-backed package pools.
5. PM acceptance evidence under `tests/`, tied to the owner lane that produced
   the proof.

### Out of scope

1. High-availability repo serving, VM scale sets, or multi-region replication.
2. Fully automated internal PKI certificate issuance.
3. New package ecosystems beyond Ubuntu 24.04 noble/amd64.
4. Internet connectivity from the high side.
5. Performance tuning beyond a documented baseline for blob-backed Aptly
   operations.

## Milestone sequence

| ID | Milestone | Primary owner | Spawn gate | Acceptance evidence |
|----|-----------|---------------|------------|---------------------|
| P2-M0 | Scope lock and architecture handoff | McCauley + Hanna | This document is linked from the canonical docs and decisions | PM confirms each lane has owner, input, output, and evidence |
| P2-M1 | Blob storage IaC | Shiherlis | P2-M0 complete | Terraform format/validation or captured unavailable-tool evidence for commercial and high-side infra |
| P2-M2 | blobfuse2 Aptly pool validation | Cheritto | P2-M1 resource outputs documented | Aptly mirror/snapshot/diff or repo import/remove/publish commands run against mounted pool paths |
| P2-M3 | Transfer validation with blob-backed pools | Nate + Cheritto | P2-M2 operation evidence | Manifest validation, GPG signature, continuity, checksum, and completeness evidence |
| P2-M4 | Security and audit review | Drucker + Nate | P2-M1 diagnostics and P2-M3 transfer evidence | CMK posture, managed identity permissions, private endpoint posture, and audit evidence review |
| P2-M5 | PM acceptance signoff | Hanna | P2-M1 through P2-M4 complete | `tests/` evidence index links all lane outputs and unresolved risks |

## Subagent spawn contracts

Each Phase 2 spawn must include:

- the milestone ID from the table above;
- the owning path from `docs/project-structure.md`;
- explicit in-scope and out-of-scope bullets from this document;
- the expected evidence path under `tests/`; and
- the reviewer or PM acceptance gate.

No subagent should claim a Phase 2 item complete with narrative status only.
Completion requires repo-backed evidence or a documented blocker.

## Design and architecture checkpoints

- Keep commercial-side references limited to Azure Commercial and approved
  upstream Ubuntu mirroring context.
- Keep high-side implementation and documentation free of public internet
  dependencies; use government or internal endpoints only.
- Preserve the M1 validation order: GPG signature, JSON schema, continuity,
  checksums, then completeness.
- Keep `docs/project-structure.md` as the repo map and `tests/README.md` as the
  validation-evidence guide.
- Update the architecture diagram only when the implemented data flow changes,
  not for planning text alone.
