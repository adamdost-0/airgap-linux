# Squad Decisions

## Active Decisions

### Phase 2 milestone contract

- **By:** McCauley + Hanna
- **Date:** 2026-05-10T02:34:52Z
- **Status:** Active
- **Decision:** Phase 2 starts from `docs/phase-2-milestones.md`, which defines the Bicep and native Aptly/HDD scope, subagent owner lanes, spawn gates, and PM acceptance evidence before implementation work continues.
- **Scope:** `docs/phase-2-milestones.md`, `docs/project-structure.md`, `tests/README.md`, `.squad/routing.md`

### Model selection governance

- **By:** McCauley
- **Date:** 2026-05-07T16:14:10Z
- **Status:** Active
- **Decision:** Active squad model governance uses `gpt-5.5` with reasoning profile `xhigh` for all normal spawned squad tasks. Cost-saving or specialist models are opt-in only by explicit user request or required capability fallback.
- **Scope:** `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, `.squad/skills/model-selection-governance/SKILL.md`, and active agent charter review.
- **Consolidated from:** `.squad/decisions/inbox/mccauley-model-selection.md`, `.squad/decisions/inbox/copilot-directive-2026-05-07T16-14-10Z.md`

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction


## Merged Inbox Decisions

### Transfer Verification Flow: Continuity Check Integration
- **File:** .squad/decisions/inbox/cheritto-transfer-revision.md
- **Date:** 2026-05-07
- **Author:** Cheritto
- **Status:** Implemented
- **Task:** Revise transfer verification flow to gate continuity before checksums and completeness
- **Key points:**
  - Continuity moved into verify-bundle.sh as step 3.
  - Non-initial transfers now require explicit expected previous snapshot state and fail closed on mismatch.
  - High-side ingest forwards continuity state into the shared verifier.

### Drucker Revision Review
- **File:** .squad/decisions/inbox/drucker-revision-review.md
- **Date:** 2026-05-07
- **Author:** Drucker
- **Status:** Approved
- **Task:** Re-review revised transfer continuity and infra diagnostics boundaries
- **Key points:**
  - Verification order now enforces GPG -> schema/required fields -> continuity -> checksums -> completeness.
  - High-side infra now includes explicit audit sink and diagnostic settings boundaries.
  - No new security blockers were found.

### Drucker Security Review — Initial Project Structure
- **File:** .squad/decisions/inbox/drucker-security-review.md
- **Date:** 2026-05-07
- **Author:** Drucker
- **Status:** Rejected
- **Task:** Initial security review of the first project-structure pass
- **Key points:**
  - Transfer validation order was non-compliant and continuity was only a stub.
  - High-side Terraform lacked explicit diagnostics/audit logging boundaries.
  - Revision lockout was required for the remediation pass.

### Created `.github/copilot-instructions.md`
- **File:** .squad/decisions/inbox/eady-copilot-instructions.md
- **Date:** 2026-05-07
- **Author:** Eady
- **Status:** Proposed
- **Task:** Create repository-specific Copilot guidance for future sessions
- **Key points:**
  - Documented repo architecture, constraints, conventions, and reference docs.
  - Kept build/test/lint status honest: none currently defined.

### Repository structure docs
- **File:** .squad/decisions/inbox/eady-structure-docs.md
- **Date:** 2026-05-07
- **Author:** Eady
- **Status:** Proposed
- **Task:** Publish canonical structure docs and diagram pointers
- **Key points:**
  - Canonical mapping now lives in docs/project-structure.md.
  - README files remain brief pointers.
  - Diagram updates stay coupled to ownership or flow changes.

### Decision: Infrastructure Diagnostics and Audit Logging Boundaries
- **File:** .squad/decisions/inbox/mccauley-infra-revision.md
- **Date:** 2026-05-07
- **Author:** McCauley
- **Status:** Proposed
- **Task:** Revise infra to add diagnostics and audit logging boundaries
- **Key points:**
  - Added Log Analytics sink, diagnostic settings for Key Vault, Storage, and NSG.
  - Documented VM/system log, private endpoint, and private link TODO boundaries.
  - Retained air-gap-safe defaults and government endpoint constraints.

### Decision: Transfer Manifest Format & Naming Conventions
- **File:** .squad/decisions/inbox/mccauley-manifest-format-naming.md
- **Date:** 2026-05-07
- **Author:** McCauley
- **Status:** Proposed
- **Task:** Define manifest format and naming conventions for transfer artifacts
- **Key points:**
  - Established manifest v1.0.0 as JSON with source/previous snapshot tracking.
  - Standardized snapshot and transfer bundle naming.
  - Locked checksum and GPG signing conventions.

### Decision: Implementation Structure Build Order
- **File:** .squad/decisions/inbox/mccauley-project-structure.md
- **Date:** 2026-05-07
- **Author:** McCauley
- **Status:** Proposed
- **Task:** Set the contract-first build order for initial implementation
- **Key points:**
  - Stabilize schema and fixtures before parallel lane implementation.
  - Keep ownership aligned by subtree and avoid shared README churn.
  - Defer repo-level tooling until the first executable lane proves the stack.

### Structure Review Decision
- **File:** .squad/decisions/inbox/mccauley-structure-review.md
- **Date:** 2026-05-07
- **Author:** McCauley
- **Status:** Approved
- **Task:** Review and approve the assembled first-phase project structure
- **Key points:**
  - Structure matches the intended commercial -> transfer -> high-side flow.
  - Parallel ownership boundaries are coherent.
  - Follow-ups remain in stubs, shared fixtures, and IaC hardening.

### Decision: Transfer Security Structure and Validation Chain
- **File:** .squad/decisions/inbox/nate-transfer-structure.md
- **Date:** 2026-05-07
- **Author:** Nate
- **Status:** Active
- **Task:** Create the transfer security skeleton and validation chain
- **Key points:**
  - Validation chain was defined contract-first with GPG, schema, continuity, checksums, and completeness.
  - Continuity remained stubbed in the original pass and required revision under reviewer lockout.
  - Stdlib-only validator and LUKS2 helpers were established.

### Decision: Remove Public URLs from Manifest Schema Metadata
- **File:** .squad/decisions/inbox/nate-schema-url-fix.md
- **Date:** 2026-05-07
- **Author:** Nate
- **Status:** Implemented
- **Task:** Replace public URI metadata in the transfer manifest schema with offline-safe identifiers
- **Key points:**
  - Replaced `$schema` and `$id` public URLs with URN-style identifiers.
  - Offline JSON Schema validation remains functional with the existing stdlib validator.
  - Schema metadata no longer references public internet resources.

### M1 docs baseline update
- **File:** .squad/decisions/inbox/eady-m1-docs-update.md
- **Date:** 2026-05-09
- **Author:** Eady
- **Status:** Merged
- **Task:** Keep the repo map and validation guidance canonical for M1
- **Key points:**
  - `docs/project-structure.md` remains the canonical repo map.
  - `tests/README.md` is the canonical validation-evidence guide.
  - Root and docs READMEs stay brief pointers instead of duplicating structure.

### M1 evidence path
- **File:** .squad/decisions/inbox/hanna-m1-evidence-path.md
- **Date:** 2026-05-09
- **Author:** Hanna
- **Status:** Resolved
- **Task:** Define one explicit home for M1 validation evidence
- **Key points:**
  - M1 evidence now lives under `tests/README.md`.
  - Validation proof should stay close to the relevant test category.
  - The evidence path is no longer blocked by missing location guidance.

### M1 scope contract
- **File:** .squad/decisions/inbox/mccauley-m1-scope-contract.md
- **Date:** 2026-05-09
- **Author:** McCauley
- **Status:** Provisional
- **Task:** Define the M1 burn-down scope and acceptance bar
- **Key points:**
  - M1 is a repo baseline with contract clarity and evidence-backed validation, not a finished product.
  - Canonical evidence now lives in `tests/README.md`, aligned with the docs baseline.
  - `docs/project-structure.md` remains the canonical map for ownership and monthly flow.
