# highside/infra/

Azure Government infrastructure as code for the high-side air-gapped environment.

## Purpose

Terraform definitions for Azure Government resources that support the Aptly repository serving pipeline:

- Compute (Linux VM for Aptly serving)
- Storage (local disk initially, Azure Blob via blobfuse2 later)
- Networking (VNet, Private Endpoints, NSGs, internal load balancer)
- Identity (User-assigned Managed Identity, RBAC)
- Key Vault (GPG public keys, TLS certificates, encryption keys)
- DNS (internal private zones for repo access)
- Diagnostics & Audit Logging (Log Analytics workspace, diagnostic settings per PaaS resource)

## Azure Environment

- **Cloud:** Azure Government (IL4/IL5), Government Secret (IL6), or Government Top Secret (TS/SCI)
- **Endpoints:** Automatically adjust based on `azure_government_environment` variable:
  - `usgovernment` → `*.usgovcloudapi.net`
  - `usgovernmentsecret` → `*.microsoftazure.us` (air-gapped)
  - `usgovernmenttopsecret` → `*.microsoftazure.eaglex.ic.gov` (air-gapped)
- **Fully air-gapped** — Zero outbound internet access; NSG denies all outbound to Internet
- **Private Endpoints only** — All PaaS services disable public network access
- **Managed Identity** for all service-to-service authentication
- **Customer-managed keys (CMK)** for encryption at rest
- **Internal PKI** for TLS certificates (not represented in IaC yet)
- **TLS 1.2 minimum** on all services

## File Structure

```
highside/infra/
├── terraform.tf            # Provider config, backend, required versions
├── variables.tf            # Input variables with validation
├── locals.tf               # Local values, naming conventions, tags
├── main.tf                 # Resource definitions
├── outputs.tf              # Output values
└── terraform.tfvars.example # Example variable values
```

## Prerequisites

### Air-Gap Considerations

This environment is **fully air-gapped** with:
- **Zero outbound internet access** — NSG explicitly denies outbound to Internet
- **No upstream package mirrors** — All packages arrive via encrypted transfer drives
- **No public endpoints** — All Azure PaaS accessed via Private Link only

For deployment, you **must**:
1. Pre-download Terraform providers using `terraform providers mirror` on a connected system
2. Transfer the provider mirror to the air-gapped environment via approved media
3. Configure local provider mirror in `.terraformrc` or via `TF_CLI_CONFIG_FILE`
4. Use offline backend (local or Azure Storage within the air-gapped environment)

### Required Tools

- Terraform >= 1.6.0
- Azure CLI (`az`) configured for Azure Government:
  ```bash
  az cloud set --name AzureUSGovernment
  az login
  ```

For Government Secret/Top Secret, use the appropriate cloud name and authentication method per your security procedures.

## Deployment

### 1. Configure Backend

Create a backend configuration file `backend.tfvars`:

```hcl
environment          = "usgovernment"  # or usgovernmentsecret / usgovernmenttopsecret
storage_account_name = "your-tfstate-storage"
container_name       = "tfstate"
key                  = "highside.tfstate"
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

**Critical variables:**
- `azure_government_environment` — Must match your target cloud tier
- `allowed_client_subnets` — CIDR blocks of APT clients that need repo access

### 4. Plan and Apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Required Variables

- `environment` — dev, staging, or prod
- `owner` — Owner tag value
- `admin_ssh_public_key` — SSH public key for VM access
- `azure_government_environment` — Target Azure Government cloud tier

## Optional Variables

- `location` — Azure Government region (default: `usgovvirginia`)
- `aptly_vm_size` — VM SKU (default: `Standard_D4s_v5`)
- `internal_dns_suffix` — Internal DNS zone (default: `apt.internal.local`)
- `enable_blob_storage` — Enable Phase 2 blob storage (default: `false`)
- `enable_customer_managed_keys` — Enable CMK encryption (default: `true`)
- `enable_internal_load_balancer` — Enable HA with ILB (default: `false`)
- `allowed_client_subnets` — Client CIDRs allowed to access repo (default: `[]`)
- `enable_log_analytics` — Enable Log Analytics workspace (default: `true`)
- `log_retention_days` — Log retention period in days, 30-730 (default: `90`)
- `enable_vm_diagnostics` — Enable VM system log collection (default: `true`)

See `variables.tf` for full list.

## Outputs

- `aptly_vm_private_ip` — Private IP of Aptly VM
- `aptly_repo_fqdn` — Internal FQDN for APT clients (e.g., `repo.apt.internal.local`)
- `key_vault_uri` — Key Vault URI for secrets/keys access
- `internal_load_balancer_ip` — ILB IP (if HA enabled)
- `log_analytics_workspace_id` — Log Analytics workspace resource ID (if enabled)
- `log_analytics_workspace_workspace_id` — Log Analytics workspace ID for queries (if enabled)

APT clients should configure `/etc/apt/sources.list.d/local.list`:
```
deb [trusted=yes] https://repo.apt.internal.local/ubuntu noble main
```

## Security Baseline

- ✅ **Zero internet access** — NSG explicitly denies all outbound to Internet
- ✅ No public IP addresses on any resource
- ✅ Private endpoints for Key Vault and Blob Storage (when enabled)
- ✅ User-assigned Managed Identity with RBAC
- ✅ NSG denies all inbound by default; allows HTTPS only from allowed client subnets
- ✅ TLS 1.2 minimum enforced
- ✅ Premium Key Vault with purge protection and soft delete
- ✅ Infrastructure encryption on storage
- ✅ Required compliance tags on all resources
- ✅ Internal DNS for repo resolution (no external DNS dependencies)
- ✅ Log Analytics workspace for diagnostics and audit logs (enabled by default)
- ✅ Diagnostic settings on Key Vault, Storage, NSG with audit event capture
- ✅ TODO boundaries for VM-level system log collection via Azure Monitor Agent

## Diagnostics & Audit Logging

Enabled by default via `enable_log_analytics = true`:

**Log Analytics Workspace:**
- Retention: 90 days (configurable via `log_retention_days`)
- SKU: PerGB2018
- Air-gap note: No public ingestion or query endpoints; private link support pending gov cloud availability

**Diagnostic Settings per Resource:**
- **Key Vault** — Audit events, policy evaluations
- **Storage Account** — Transaction metrics, blob service logs (read/write/delete)
- **NSG** — Flow logs, security group events and rule counters
- **Private Endpoints** — TODO: Add when supported in gov cloud

**VM-Level System Logs:**
- **TODO:** Install Azure Monitor Agent extension when `enable_vm_diagnostics = true`
- Target logs: `/var/log/syslog`, `/var/log/auth.log`, `/var/log/apt/history.log`, nginx access/error logs
- Data Collection Rules (DCR) must route to Log Analytics workspace
- Optional: VM Insights for performance metrics and dependency mapping

## TODO

- [ ] Add customer-managed key (CMK) implementation when `enable_customer_managed_keys = true`
- [ ] Install Azure Monitor Agent extension for VM system log collection (syslog, auth, apt, nginx)
- [ ] Add cloud-init or custom_data for Aptly installation automation
- [ ] Add Azure Bastion or jumpbox for secure VM access (or document existing access pattern)
- [ ] Implement TLS certificate management (internal PKI integration)
- [ ] Add Private Link for Log Analytics workspace when available in gov environment
- [ ] Add availability set or VMSS for multi-VM HA when ILB is enabled
- [ ] Document ingestion workflow integration points

## Validation

```bash
terraform fmt -check
terraform validate
```

No linting tools (tflint, checkov) configured yet — add when available in the air-gapped environment.
