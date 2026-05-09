# commercial/infra/

Azure Commercial infrastructure as code for the low-side environment.

## Purpose

Terraform definitions for Azure Commercial resources that support the Aptly mirroring pipeline:

- Compute (Linux VM for Aptly)
- Storage (local disk initially, Azure Blob via blobfuse2 later)
- Networking (VNet, Private Endpoints, NSGs)
- Identity (User-assigned Managed Identity, RBAC)
- Key Vault (GPG key storage, encryption keys)
- Diagnostics & Audit Logging (Log Analytics workspace, diagnostic settings per PaaS resource)

## Azure Environment

- **Cloud:** Azure Commercial (default provider, no `environment` override needed)
- **Endpoints:** Standard Azure endpoints (`.windows.net`, `.azure.com`)
- **Private Endpoints only** — All PaaS services disable public network access
- **Managed Identity** for all service-to-service authentication
- **TLS 1.2 minimum** on all services

## File Structure

```
commercial/infra/
├── terraform.tf            # Provider config, backend, required versions
├── variables.tf            # Input variables with validation
├── locals.tf               # Local values, naming conventions, tags
├── main.tf                 # Resource definitions
├── outputs.tf              # Output values
└── terraform.tfvars.example # Example variable values
```

## Prerequisites

### Air-Gap Considerations

This environment requires **outbound internet access** for:
- Ubuntu archive mirroring (`archive.ubuntu.com`, `security.ubuntu.com`)
- Azure Commercial API endpoints

For **fully air-gapped deployment**, you must:
1. Pre-download Terraform providers using `terraform providers mirror`
2. Configure local provider mirror in `.terraformrc` or via `TF_CLI_CONFIG_FILE`
3. Use filesystem or HTTP mirror for provider registry

### Required Tools

- Terraform >= 1.6.0
- Azure CLI (`az`) configured for Azure Commercial
- SSH key pair for VM access

## Deployment

### 1. Configure Backend

Create a backend configuration file `backend.tfvars`:

```hcl
storage_account_name = "your-tfstate-storage"
container_name       = "tfstate"
key                  = "commercial.tfstate"
```

### 2. Initialize

```bash
terraform init -backend-config=backend.tfvars
```

### 3. Configure Variables

Copy the example and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 4. Plan and Apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Required Variables

- `environment` — dev, staging, or prod
- `owner` — Owner tag value
- `admin_ssh_public_key` — SSH public key for VM access

## Optional Variables

- `location` — Azure region (default: `eastus`)
- `aptly_vm_size` — VM SKU (default: `Standard_D4s_v5`)
- `enable_blob_storage` — Enable Phase 2 blob storage (default: `false`)
- `enable_customer_managed_keys` — Enable CMK encryption (default: `true`)
- `enable_log_analytics` — Enable Log Analytics workspace (default: `true`)
- `log_retention_days` — Log retention period in days, 30-730 (default: `90`)
- `enable_vm_diagnostics` — Enable VM system log collection (default: `true`)

See `variables.tf` for full list.

## Outputs

- `aptly_vm_private_ip` — Private IP of Aptly VM
- `key_vault_uri` — Key Vault URI for secrets access
- `storage_account_primary_blob_endpoint` — Blob endpoint (if enabled)
- `log_analytics_workspace_id` — Log Analytics workspace resource ID (if enabled)
- `log_analytics_workspace_workspace_id` — Log Analytics workspace ID for queries (if enabled)

## Security Baseline

- ✅ No public IP addresses on any resource
- ✅ Private endpoints for Key Vault and Blob Storage
- ✅ User-assigned Managed Identity with RBAC
- ✅ NSG denies all inbound by default
- ✅ TLS 1.2 minimum enforced
- ✅ Soft delete and purge protection on Key Vault
- ✅ Infrastructure encryption on storage
- ✅ Required compliance tags on all resources
- ✅ Log Analytics workspace for diagnostics and audit logs (enabled by default)
- ✅ Diagnostic settings on Key Vault, Storage, NSG with audit event capture
- ✅ TODO boundaries for VM-level system log collection via Azure Monitor Agent

## Diagnostics & Audit Logging

Enabled by default via `enable_log_analytics = true`:

**Log Analytics Workspace:**
- Retention: 90 days (configurable via `log_retention_days`)
- SKU: PerGB2018

**Diagnostic Settings per Resource:**
- **Key Vault** — Audit events, policy evaluations
- **Storage Account** — Transaction metrics, blob service logs (read/write/delete)
- **NSG** — Flow logs, security group events and rule counters

**VM-Level System Logs:**
- **TODO:** Install Azure Monitor Agent extension when `enable_vm_diagnostics = true`
- Target logs: `/var/log/syslog`, `/var/log/auth.log`, `/var/log/apt/history.log`
- Data Collection Rules (DCR) must route to Log Analytics workspace
- Optional: VM Insights for performance metrics

## TODO

- [ ] Add customer-managed key (CMK) implementation when `enable_customer_managed_keys = true`
- [ ] Install Azure Monitor Agent extension for VM system log collection (syslog, auth, apt)
- [ ] Add cloud-init or custom_data for Aptly installation automation
- [ ] Add Azure Bastion or jumpbox for secure VM access
- [ ] Implement Azure Firewall for egress filtering (if required)

## Validation

```bash
terraform fmt -check
terraform validate
```

No linting tools (tflint, checkov) configured yet — add when needed.
