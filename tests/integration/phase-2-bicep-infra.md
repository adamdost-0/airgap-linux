# P2-M1 Bicep Infrastructure Evidence

Milestone: `P2-M1` from `docs/phase-2-milestones.md`.

## Repo-backed changes

- Commercial and high-side infrastructure are Bicep templates, not Terraform.
- Both templates provision an Aptly VM with a local managed data disk for native
  Aptly filesystem storage.
- Both templates include managed identity, private Key Vault access, private DNS,
  NSG rules, and required tags.
- No Azure Blob-backed Aptly pool or blobfuse2 mount is defined.

## Validation commands

Run from the repository root:

```bash
bicep build commercial/infra/main.bicep --stdout >/tmp/commercial-main.json
bicep build highside/infra/main.bicep --stdout >/tmp/highside-main.json
```

## Current sandbox result

- Commercial Bicep build: passed.
- High-side Bicep build: passed.
