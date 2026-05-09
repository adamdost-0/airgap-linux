# High-Side Aptly Configuration

This directory contains Aptly configuration for the high-side (air-gapped) local repository.

## Files

- **aptly.conf** — Aptly configuration for high-side
  - Root directory: `/var/lib/aptly`
  - Architecture filter: `amd64` only
  - **Download concurrency: 0** (no upstream mirrors, local repo only)
  - GPG verification enabled for imported packages

## Configuration Notes

### Air-Gap Environment

**Critical:** This configuration is for a fully air-gapped environment with zero internet access.

- **downloadConcurrency:** 0 — No upstream downloads occur on high side
- Mirrors are NOT created on high side
- All packages arrive via offline transfer bundles

### Root Directory

The `rootDir` setting (`/var/lib/aptly`) defines where Aptly stores:
- Database
- Pool (package files)
- Public directory (published repositories)

### Architecture Filtering

- **architectures:** `["amd64"]` — Must match commercial-side configuration
- Only amd64 packages are accepted for import

## Repository Creation

Local repositories must be created manually:

```bash
# Create local repository for main component
aptly repo create -distribution=noble -component=main highside-noble-main

# Create for security component
aptly repo create -distribution=noble -component=security highside-noble-security

# Create for universe component (if needed)
aptly repo create -distribution=noble -component=universe highside-noble-universe
```

## Publishing

After importing packages, publish the repository:

```bash
# Publish repository
aptly publish repo -architectures="amd64" highside-noble-main

# Or serve via HTTP (for APT clients)
aptly serve -listen=:8080
```

## GPG Key Management

The high side must have the commercial-side signing key's public component pre-installed:

```bash
# Import public key (via secure transfer mechanism)
gpg --import /path/to/commercial-signing-key.pub

# Verify key fingerprint matches documented value
gpg --fingerprint
```

## Security Constraints

**This configuration must never:**
- Reference public Ubuntu archive URLs
- Reference Azure Commercial endpoints
- Reference any public internet resources
- Store credentials or secrets in configuration files

**Azure Government resources must:**
- Use government cloud endpoints (`.usgovcloudapi.net`)
- Use Private Endpoints only
- Authenticate via Managed Identity
- Include required compliance tags

## Related Scripts

See `../scripts/README.md` for ingestion and repository management scripts.
