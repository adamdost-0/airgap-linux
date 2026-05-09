# Commercial Aptly Configuration

This directory contains Aptly configuration for the commercial-side (low-side) mirror and snapshot pipeline.

## Files

- **aptly.conf** — Aptly configuration for commercial side
  - Root directory: `/var/lib/aptly`
  - Architecture filter: `amd64` only
  - Download concurrency: 4 (mirrors sync from upstream Ubuntu)
  - GPG verification enabled for upstream packages

## Configuration Notes

### Root Directory

The `rootDir` setting (`/var/lib/aptly`) defines where Aptly stores:
- Database
- Pool (package files)
- Public directory (published repositories)

### Download Settings

- **downloadConcurrency:** 4 — Allows parallel downloads when updating mirrors
- **downloadSpeedLimit:** 0 — No rate limiting (adjust if bandwidth is constrained)

### Architecture Filtering

- **architectures:** `["amd64"]` — Only amd64 packages are mirrored
- This must match the target high-side environment

### Dependencies

All dependency following options are disabled to avoid pulling unnecessary packages:
- `dependencyFollowSuggests: false`
- `dependencyFollowRecommends: false`
- `dependencyFollowAllVariants: false`
- `dependencyFollowSource: false`

## Mirror Creation

Mirrors must be created manually before the automation scripts can run:

```bash
# Main repository mirror
aptly mirror create -architectures="amd64" \
  ubuntu-noble-main \
  http://archive.ubuntu.com/ubuntu \
  noble main

# Security repository mirror
aptly mirror create -architectures="amd64" \
  ubuntu-noble-security \
  http://security.ubuntu.com/ubuntu \
  noble-security main

# Universe repository mirror (if needed)
aptly mirror create -architectures="amd64" \
  ubuntu-noble-universe \
  http://archive.ubuntu.com/ubuntu \
  noble universe
```

## Snapshot Naming Convention

Snapshots follow the pattern: `ubuntu-noble-{component}-YYYYMMDD`

Examples:
- `ubuntu-noble-main-20260501`
- `ubuntu-noble-security-20260501`
- `ubuntu-noble-universe-20260501`

## Related Scripts

See `../scripts/README.md` for automation scripts that use this configuration.
