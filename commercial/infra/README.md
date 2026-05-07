# commercial/infra/

Azure Commercial infrastructure as code for the low-side environment.

## Purpose

Terraform and/or Bicep definitions for Azure Commercial resources that support the Aptly mirroring pipeline:

- Compute (VM or container for Aptly)
- Storage (local disk initially, Azure Blob via blobfuse2 later)
- Networking (VNet, Private Endpoints, NSGs)
- Identity (Managed Identity, RBAC)
- Key Vault (GPG key storage, encryption keys)

## Azure Environment

- Cloud: Azure Commercial
- All resources use Private Endpoints
- Managed Identity for all service-to-service authentication
