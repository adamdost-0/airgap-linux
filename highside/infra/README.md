# highside/infra/

Azure Government infrastructure as code for the high-side air-gapped Aptly
environment.

## Purpose

Bicep definitions for Azure Government resources that support native Aptly repo
hydration from transfer HDD contents:

- Linux VM for local Aptly repository import, remove, publish, and serve flows
- Local managed data disk for `/var/lib/aptly`
- VNet, private subnets, NSG, internal DNS, and no public VM IP
- User-assigned Managed Identity for Azure service access
- Key Vault with public network access disabled and a private endpoint

Phase 2 does **not** use Terraform, Azure Blob-backed Aptly pools, or blobfuse2.
The high side remains fully air-gapped: packages arrive only through the LUKS2
HDD transfer workflow, are verified, and then hydrated into local Aptly repos
with native Aptly commands.

## Azure Environment

- **Cloud:** Azure Government, Government Secret, or Government Top Secret
- **Endpoints:** Selected by `azureGovernmentEnvironment`
  - `usgovernment` → `*.usgovcloudapi.net`
  - `usgovernmentsecret` → `*.microsoftazure.us`
  - `usgovernmenttopsecret` → `*.microsoftazure.eaglex.ic.gov`
- **Internet egress:** Denied by NSG
- **Private endpoints:** Required for Azure PaaS resources such as Key Vault
- **Managed Identity:** Required for Azure service-to-service authentication
- **TLS:** TLS 1.2 minimum on Azure services

## File Structure

```
highside/infra/
├── main.bicep                    # Bicep deployment for high-side Aptly VM and support resources
├── main.parameters.example.json  # Example deployment parameters
└── README.md                     # This guide
```

## Deployment

```bash
az cloud set --name AzureUSGovernment
az deployment group create \
  --resource-group <highside-rg> \
  --template-file highside/infra/main.bicep \
  --parameters @highside/infra/main.parameters.example.json
```

Customize `main.parameters.example.json` before use. Do not commit real SSH
keys, credentials, or environment-specific secrets.

## Required Parameters

- `environment` — `dev`, `staging`, or `prod`
- `azureGovernmentEnvironment` — target government cloud tier
- `owner` — required tag value
- `adminSshPublicKey` — SSH public key for VM access

## Optional Parameters

- `location` — Azure Government region
- `aptlyVmSize` — VM SKU, default `Standard_D4s_v5`
- `aptlyDataDiskSizeGb` — local Aptly data disk size, default `1024`
- `internalDnsSuffix` — internal repo DNS zone, default `apt.internal.local`
- `allowedClientSubnets` — client CIDRs allowed to reach HTTPS repo serving
- `vnetAddressPrefix`, `aptlySubnetPrefix`, `privateLinkSubnetPrefix`

## Outputs

- `aptlyVmId`
- `aptlyVmPrivateIp`
- `aptlyRepoFqdn`
- `aptlyIdentityPrincipalId`
- `keyVaultUri`

## Validation

```bash
bicep build highside/infra/main.bicep --stdout >/tmp/highside-main.json
```
