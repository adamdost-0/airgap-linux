# Phase 2 Milestones

Phase 2 moves the M1 planning baseline into native Aptly operations backed by
Bicep-provisioned Azure VMs and local filesystem storage. The low side creates
Aptly snapshots and export bundles; the high side verifies HDD contents and
hydrates local Aptly repos each transfer cycle.

## PM and design review outcome

- **Review date:** 2026-05-10
- **Reviewed with:** Hanna (Product Manager) acceptance lens and McCauley
  design/architecture lane
- **Review inputs:** `README.md`, `docs/project-structure.md`,
  `docs/architecture.md`, `docs/manifest-schema.md`,
  `docs/adr/001-aptly-snapshot-diffs.md`, `commercial/infra/README.md`,
  `highside/infra/README.md`, `.squad/decisions.md`, `.squad/routing.md`,
  and `tests/README.md`
- **Direction update:** Terraform, Azure Blob-backed Aptly pools, and blobfuse2
  are out. Bicep is the infrastructure language, and native Aptly local
  filesystem workflows are the product path.
- **Gap closed here:** Phase 2 has a single milestone contract that names owner
  lanes, spawn gates, and PM acceptance evidence before implementation subagents
  continue.

## Value

Phase 2 proves the full monthly path using only native Aptly repository tools:
low-side mirror snapshots, signed HDD bundles, high-side verification, and
high-side local repo hydration without any package-pool dependency outside the
local filesystem on each side.

## Scope

### In scope

1. Bicep infrastructure for commercial and high-side Aptly VMs, local data disks,
   private networking, managed identity, Key Vault, and required tags.
2. Low-side native Aptly snapshot creation, snapshot diffing, package extraction,
   manifest generation, and signing from local filesystem storage.
3. HDD transfer bundle evidence for manifest, checksum, signature, continuity,
   and completeness checks.
4. High-side native Aptly repo hydration: verify HDD contents, import added and
   upgraded packages, remove dropped packages, publish, reconcile, and smoke test.
5. PM acceptance evidence under `tests/`, tied to the owner lane that produced
   the proof.

### Out of scope

1. Terraform.
2. Azure Blob-backed Aptly pools or blobfuse2 mounts.
3. High-availability repo serving, VM scale sets, or multi-region replication.
4. Fully automated internal PKI certificate issuance.
5. New package ecosystems beyond Ubuntu 24.04 noble/amd64.
6. Internet connectivity from the high side.

## Milestone sequence

| ID | Milestone | Primary owner | Spawn gate | Acceptance evidence |
|----|-----------|---------------|------------|---------------------|
| P2-M0 | Scope lock and architecture handoff | McCauley + Hanna | This document is linked from canonical docs and decisions | PM confirms each lane has owner, input, output, and evidence |
| P2-M1 | Bicep infrastructure baseline | Shiherlis | P2-M0 complete | `bicep build` evidence for commercial and high-side templates |
| P2-M2 | Low-side Aptly snapshot export | Cheritto | P2-M1 local disk paths documented | Mirror update, snapshot create, snapshot diff, and bundle package evidence using `-config="${APTLY_CONFIG}"` |
| P2-M3 | HDD transfer verification | Nate + Drucker | P2-M2 bundle exists | GPG signature, schema, continuity, checksum, and completeness evidence |
| P2-M4 | High-side Aptly repo hydration | Cheritto + Nate | P2-M3 verification passes | Import, remove, publish, reconcile, and smoke-test evidence against local high-side repos |
| P2-M5 | PM acceptance signoff | Hanna | P2-M1 through P2-M4 complete | `tests/integration/README.md` links all lane outputs and unresolved risks |

## Subagent spawn contracts

Each Phase 2 spawn must include:

- the milestone ID from the table above;
- the owning path from `docs/project-structure.md`;
- explicit in-scope and out-of-scope bullets from this document;
- the expected evidence section under the existing `tests/` category index; and
- the reviewer or PM acceptance gate.

No subagent should claim a Phase 2 item complete with narrative status only.
Completion requires repo-backed evidence in the owning implementation path plus
a `tests/` category index entry or a documented blocker.

## Design and architecture checkpoints

- Keep commercial-side references limited to Azure Commercial and approved
  upstream Ubuntu mirroring context.
- Keep high-side implementation and documentation free of public internet
  dependencies; use government or internal endpoints only.
- Preserve the M1 validation order: GPG signature, JSON schema, continuity,
  checksums, then completeness.
- Use local Aptly filesystem paths on both sides; package bits move by encrypted
  HDD, not by shared object storage.
- Keep `docs/project-structure.md` as the repo map and `tests/README.md` plus
  category indexes such as `tests/integration/README.md` as validation-evidence
  guides.
- Update the architecture diagram only when the implemented data flow changes,
  not for planning text alone.
