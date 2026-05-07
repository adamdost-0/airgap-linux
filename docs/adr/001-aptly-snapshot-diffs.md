# ADR 001: Aptly with Snapshot Diffs for Cross-Domain Package Transfer

## Status

Accepted

## Date

2026-05-07

## Context

We need to maintain Ubuntu 24.04 (noble/amd64) package repositories in Azure Government Secret and Top Secret environments that have no network connectivity to the internet. Packages must be transferred monthly via encrypted physical media.

Key constraints:
- Air-gapped environments with zero internet access
- Monthly transfer cadence (physical media)
- Transfer drive capacity is limited (~2TB practical maximum)
- Must support incremental updates (full mirror is ~150GB+ and growing)
- Must provide cryptographic verification end-to-end
- Must track exactly what changed between transfers for audit purposes

We evaluated four approaches:
1. **apt-mirror** — simple mirroring tool
2. **debmirror** — more configurable mirroring
3. **rsync** — raw file-level synchronization
4. **Aptly** — full repository management with snapshots and diffs

## Decision

We will use **Aptly** as our repository management tool on both commercial and high sides, leveraging its native **snapshot diff** capability to produce incremental transfer bundles.

## Rationale

### Why Aptly over apt-mirror

| Criteria | apt-mirror | Aptly |
|----------|-----------|-------|
| Snapshot management | ❌ None | ✅ Native, immutable snapshots |
| Diff between states | ❌ Manual file comparison | ✅ `aptly snapshot diff` |
| Package-level metadata | ❌ File-level only | ✅ Full .deb metadata awareness |
| Filtering | ❌ Limited | ✅ Rich query language |
| Multi-component merge | ❌ No | ✅ Snapshot merge/pull |
| Publishing | ❌ Static files | ✅ Full publish with signing |
| Active maintenance | ⚠️ Minimal | ✅ Active development |

apt-mirror gives us no way to compute what changed between syncs. We'd need to build our own diffing layer on top.

### Why Aptly over debmirror

debmirror supports GPG verification and architecture filtering, but:
- No concept of snapshots — only "current state"
- No native diff mechanism
- Would require rsync-based diffing (see below)
- Less flexible filtering and publishing

### Why Aptly over rsync

rsync operates at the file level and could technically produce delta transfers, but:
- **No package awareness** — rsync doesn't know .deb metadata, versions, or dependencies
- **No atomic snapshots** — state is "whatever files exist right now"
- **Brittle diffs** — file renames, directory restructuring break delta computation
- **No manifest generation** — we'd build all metadata tooling from scratch
- **No publish capability** — high side still needs a repo tool

rsync would save bandwidth but shifts all intelligence into custom tooling we'd have to maintain.

### Why snapshot diffs over full clones

| Approach | Monthly Transfer Size | Verification | Rollback |
|----------|----------------------|--------------|----------|
| Full clone | ~150GB+ | All or nothing | Replace entirely |
| Snapshot diff | ~2-10GB typical | Per-package checksums | Revert to previous snapshot |

Full clones:
- ❌ Exceed practical transfer media capacity as repos grow
- ❌ Waste time transferring unchanged packages
- ❌ No audit trail of what changed
- ❌ Harder to verify (must re-checksum everything)

Snapshot diffs:
- ✅ Transfer only what changed — typically 2-10GB/month
- ✅ Explicit manifest of added/removed/upgraded packages
- ✅ Per-file verification with SHA-256 checksums
- ✅ Clear audit trail for compliance (what entered the environment and when)
- ✅ Smaller transfers = faster ingestion = reduced operational risk window

## Trade-offs

### Accepted trade-offs

1. **Aptly is another tool to manage** — Both sides need Aptly installed and configured. Mitigated by its single-binary deployment and established maturity.

2. **Snapshot accumulation** — Snapshots are immutable and accumulate. We'll implement a retention policy (keep last 6 months) to manage disk usage.

3. **Initial transfer is still large** — The first sync is a full transfer (~150GB). Subsequent months are incremental. The initial transfer may require multiple drives or a larger-capacity medium.

4. **Ordering dependency** — Monthly diffs must be applied in sequence. If a transfer is lost, we must regenerate from the last known-good state. Mitigated by keeping recent snapshots available on the commercial side.

### Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Aptly project abandonment | Would need to fork or migrate | Aptly is Go, easy to maintain; evaluate annually |
| Snapshot diff misses edge cases | Packages could be missing on high side | Periodic full reconciliation (quarterly) |
| Drive lost in transit | One month's updates delayed | Re-generate from same snapshots; notify stakeholders |
| Aptly DB corruption | Loss of snapshot history | Regular Aptly DB backups; DB is small (~100MB) |
| Transfer ordering violated | High side out of sync | Manifest references previous snapshot; ingestion validates continuity |

## Consequences

- All team members must understand Aptly concepts (mirrors, snapshots, repos, publish)
- Transfer tooling depends on Aptly's diff output format
- High-side automation must handle both full (initial) and incremental transfers
- We commit to a specific manifest schema (see `docs/manifest-schema.md`)
- Quarterly full reconciliation process needed as a safety net

## References

- [Aptly documentation](https://www.aptly.info/doc/overview/)
- [Aptly snapshot diff](https://www.aptly.info/doc/aptly/snapshot/diff/)
- Ubuntu 24.04 LTS release: April 2024, supported until June 2029
