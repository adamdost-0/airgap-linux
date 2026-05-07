# highside/aptly/

High-side Aptly repository and publish configuration.

## Purpose

Configuration for the air-gapped Aptly instance that serves packages to high-side clients:

- Aptly repo definitions (local repos, not mirrors)
- Publish configuration and GPG signing
- Retention policies for old snapshots
- `aptly serve` or `aptly publish` configuration

## Key Differences from Commercial Side

- **No mirrors** — High side has no upstream to sync from
- **Local repos only** — Packages imported via `aptly repo add`
- **Publish over HTTPS** — Internal PKI certificates, not public CAs
- **Serves to APT clients** — VMs and containers on the high-side network

## Azure Environment

- Cloud: Azure Government Secret / Top Secret
- Endpoints: `*.usgovcloudapi.net`
- All access via Private Endpoints
- Managed Identity authentication
