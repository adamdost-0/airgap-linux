# Squad Decisions

## Active Decisions

### Model selection governance

- **By:** McCauley
- **Date:** 2026-05-07T16:14:10Z
- **Status:** Active
- **Decision:** Active squad model governance no longer selects or lists the retired fast model. Fast/cheap non-code and mechanical tasks use `gpt-5.4-mini`; premium architecture, reviewer gates, security, and multi-agent coordination use `gpt-5.5`.
- **Scope:** `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, and active agent charter review.
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
