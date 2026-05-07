# McCauley — History

## Core Context

- **Project:** Cross-domain Aptly repository pipeline delivering incremental Linux package snapshots from Azure Commercial to air-gapped high-side enclaves via offline media.
- **Role:** Lead
- **Joined:** 2026-05-07T15:43:28.678Z

## Learnings

<!-- Append learnings below -->
- 2026-05-07: First-phase structure and related transfer/IaC decisions were merged into the squad registry; contract-first build order remains the canonical implementation path.
- 2026-05-07: Infra diagnostics and audit logging boundaries were finalized with a Log Analytics sink, resource diagnostic settings, and documented VM/private endpoint audit TODOs.
- 2026-05-07: Model governance policy now excludes the retired fast model from active guidance. Fast/cheap non-code and mechanical work routes to `gpt-5.4-mini`; premium architecture, reviewer gates, security, and multi-agent coordination route to `gpt-5.5`. Updated `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md`; agent charters remained `Preferred: auto` with no retired-model references. Added `.squad/skills/model-selection-governance/SKILL.md`.
- 2026-05-07: Auto design review for implementation structure set build order around contracts first (`docs/manifest-schema.md`, `transfer/manifest/schema/manifest-v1.0.0.schema.json`, shared fixtures), then domain-owned code lanes: Cheritto owns Aptly/APT scripts/config, Nate owns manifest/encryption/verification security tooling, Shiherlis owns Azure Commercial/Gov IaC, Eady owns docs/diagrams, with Drucker/Ralph review gates. Parallel work should avoid shared README/docs edits unless coordinated.
- 2026-05-07: Structure review APPROVED. The assembled tree matches the intended low-side Aptly mirror → snapshot diff → manifest/bundle → LUKS2 transfer → high-side verify/import/remove/publish → APT client flow. Boundaries are clean: Cheritto owns Aptly/script surfaces, Nate owns transfer manifest/verification/encryption, Shiherlis owns commercial/high-side IaC, and Eady owns structure docs/diagram. First-phase scaffolding is sufficient for next implementation; notable follow-ups are to replace manifest/bundle/import/reconcile stubs with real logic, add shared fixtures/tests, close IaC CMK/diagnostic TODOs, avoid `latest` VM image pinning, and tighten high-side smoke-test/TLS examples.
- 2026-05-07: Infra diagnostics/audit logging boundaries revision COMPLETE. Added Log Analytics workspace resources, diagnostic settings for Key Vault/Storage/NSG, and TODO blocks for VM-level log collection via Azure Monitor Agent to both high-side (air-gapped, Azure Gov endpoints) and commercial infra. High-side defaults remain air-gap safe: no public IPs, no public endpoints, zero internet outbound. Variables added: `enable_log_analytics` (default true), `log_retention_days` (default 90), `enable_vm_diagnostics` (default true). Locals categorize log types per resource (Key Vault audit events, Storage read/write/delete, NSG flow logs). READMEs updated with diagnostics sections and TODO boundary documentation. Terraform fmt validation unavailable (binary not in env); no external modules or public registry calls introduced.
