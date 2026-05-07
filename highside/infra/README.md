# highside/infra/

Azure Government infrastructure as code for the high-side environment.

## Purpose

Terraform and/or Bicep definitions for Azure Government Secret/Top Secret resources:

- Compute (VM or container for Aptly serving)
- Storage (local disk initially, Azure Blob via blobfuse2 later)
- Networking (VNet, Private Endpoints, NSGs, internal load balancer)
- Identity (Managed Identity, RBAC)
- Key Vault (GPG public keys, TLS certificates)
- DNS (internal zones for repo access)

## Azure Environment

- Cloud: Azure Government Secret (`environment = "usgovernmentsecret"`)
- Endpoints: `*.usgovcloudapi.net`
- All resources use Private Endpoints — no public network access
- Managed Identity for all service-to-service authentication
- Customer-managed keys (CMK) for encryption at rest
- Internal PKI for TLS certificates
