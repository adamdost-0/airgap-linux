# commercial/infra/

Azure Commercial infrastructure as code for the low-side Aptly environment.

## Purpose

Bicep definitions for Azure Commercial resources that support native Aptly
mirroring and snapshot export from local filesystem storage:

- Linux VM for Aptly mirror, snapshot, diff, and bundle generation
- Local managed data disk for `/var/lib/aptly`
- VNet, private subnets, NSG, and no public VM IP
- User-assigned Managed Identity for Azure service access
- Key Vault with public network access disabled and a private endpoint

Phase 2 does **not** use Terraform, Azure Blob-backed Aptly pools, or blobfuse2.
Aptly reads and writes its local pool, and transfer bundles are written to the
LUKS2 HDD workflow under `transfer/`.

## Azure Environment

- **Cloud:** Azure Commercial
- **Outbound access:** Allowed only for approved Ubuntu archive mirroring and
  Azure Commercial control-plane access
- **Private endpoints:** Required for Azure PaaS resources such as Key Vault
- **Managed Identity:** Required for Azure service-to-service authentication
- **TLS:** TLS 1.2 minimum on Azure services

## File Structure

```
commercial/infra/
├── main.bicep                    # Bicep deployment for low-side Aptly VM and support resources
├── main.parameters.example.json  # Example deployment parameters
└── README.md                     # This guide
```

## Deployment

```bash
az deployment group create \
  --resource-group <commercial-rg> \
  --template-file commercial/infra/main.bicep \
  --parameters @commercial/infra/main.parameters.example.json
```

Customize `main.parameters.example.json` before use. Do not commit real SSH
keys, credentials, or environment-specific secrets.

## Required Parameters

- `environment` — `dev`, `staging`, or `prod`
- `owner` — required tag value
- `adminSshPublicKey` — SSH public key for VM access

## Optional Parameters

- `location` — Azure region
- `aptlyVmSize` — VM SKU, default `Standard_D4s_v5`
- `aptlyDataDiskSizeGb` — local Aptly data disk size, default `512`
- `vnetAddressPrefix`, `aptlySubnetPrefix`, `privateLinkSubnetPrefix`

## Outputs

- `aptlyVmId`
- `aptlyVmPrivateIp`
- `aptlyIdentityPrincipalId`
- `keyVaultUri`

## Validation

```bash
bicep build commercial/infra/main.bicep --stdout >/tmp/commercial-main.json
```
