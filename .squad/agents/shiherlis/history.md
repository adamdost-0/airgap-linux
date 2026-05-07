# Shiherlis — History

## Core Context

- **Project:** Cross-domain Aptly repository pipeline delivering incremental Linux package snapshots from Azure Commercial to air-gapped high-side enclaves via offline media.
- **Role:** Infra Dev
- **Joined:** 2026-05-07T15:43:28.678Z

## Learnings

### 2026-05-07: Initial IaC structure for commercial and high-side environments

**Task:** Set up Terraform project structure for both commercial (low-side) and high-side (air-gapped) environments.

**Key decisions:**
- **Commercial provider:** Targets Azure Commercial (default, no `environment` override). Allows outbound internet for upstream Ubuntu mirror sync.
- **High-side provider:** Configurable via `azure_government_environment` variable (usgovernment/usgovernmentsecret/usgovernmenttopsecret). Explicitly denies all outbound internet via NSG. Uses government cloud endpoint suffixes automatically.
- **Private endpoints only:** All PaaS resources (Key Vault, Blob Storage) default to `public_network_access_enabled = false` with private endpoint + private DNS zone.
- **User-assigned managed identity:** Preferred over system-assigned for RBAC flexibility across resources.
- **Required tags:** All resources include Environment, Project, Owner, Classification, Compliance, ManagedBy tags per project conventions.
- **CMK/encryption:** Structured for customer-managed keys but implementation deferred (marked as TODO). Infrastructure encryption enabled on storage where available.
- **Phase 1 vs Phase 2:** Local managed disk for Aptly pool (Phase 1 default). Blob storage controlled via `enable_blob_storage` variable for Phase 2 migration.

**File paths:**
- Commercial: `commercial/infra/{terraform,variables,locals,main,outputs}.tf`, `commercial/infra/terraform.tfvars.example`, `commercial/infra/README.md`
- High-side: `highside/infra/{terraform,variables,locals,main,outputs}.tf`, `highside/infra/terraform.tfvars.example`, `highside/infra/README.md`

**Patterns:**
- Standard Terraform 5-file layout (terraform.tf, variables.tf, locals.tf, main.tf, outputs.tf)
- snake_case identifiers throughout
- Locals for naming conventions (Azure CAF-aligned prefix patterns)
- Private DNS zones + VNet links for private endpoint resolution
- Internal DNS zone on high side for APT client repo access (`repo.apt.internal.local` default)
- NSG rules: Commercial allows outbound HTTPS for mirrors; high-side explicitly denies Internet outbound
- Backend config via external file (not inline) to support different state storage per environment

**Air-gap compliance:**
- No public IPs on any compute or networking resource
- No hardcoded secrets (SSH key via variable, marked sensitive)
- Provider mirror documentation in READMEs for offline Terraform operations
- Government cloud endpoint suffix mapping in high-side locals for multi-tier support

**Known gaps (documented as TODOs):**
- CMK key resource creation and disk/storage encryption configuration
- Diagnostic settings for audit logs
- Cloud-init automation for Aptly installation
- Bastion/jumpbox for VM access
- Internal PKI/TLS certificate management
- Log Analytics workspace integration

- 2026-05-07: High-side/commercial infra now has explicit diagnostics and audit logging boundaries, including a central audit sink and resource diagnostic settings.
