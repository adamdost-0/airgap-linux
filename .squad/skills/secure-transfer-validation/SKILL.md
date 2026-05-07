---
name: "secure-transfer-validation"
description: "Defense-in-depth validation chain for cross-domain air-gap transfers"
domain: "security"
confidence: "high"
source: "implemented"
---

## Context

Use this skill when implementing or reviewing cryptographic validation chains for cross-domain data transfers, especially in air-gapped or high-assurance environments where tampering must be detected before processing untrusted data.

## Pattern: Defense-in-Depth Validation Order

Always validate in this order to minimize attack surface:

1. **Cryptographic signature verification** — Authenticate the manifest before parsing any content
2. **Schema validation** — Verify structure against machine-readable contract (JSON Schema, etc.)
3. **Continuity check** — Ensure the transfer is the expected next item in the sequence
4. **Content checksums** — Verify every payload file against manifest checksums
5. **Completeness check** — Confirm all expected files exist

**Rationale:** Each stage gates the next. Signature validation blocks tampered manifests before any parsing. Schema validation catches malformed data before expensive checksum operations. Never parse untrusted data before cryptographic validation.

## Pattern: Passphrase/Key Handling

- **Never hardcode secrets** in scripts or configuration
- Supply passphrases via **files, environment variables, or operator prompts**
- Use **detached signatures** (`.sig` files) for GPG, not embedded signatures
- Passphrases for LUKS2 should be **split between courier and recipient** (never stored on the drive)
- Public keys can be stored in Azure Key Vault; signing keys stay on secure VMs

## Pattern: LUKS2 Modern Encryption

For encrypted transfer media:

```bash
# Format with modern crypto (not legacy PBKDF2)
cryptsetup luksFormat \
  --type luks2 \
  --cipher aes-xts-plain64 \
  --key-size 512 \
  --hash sha256 \
  --pbkdf argon2id \
  --iter-time 5000 \
  --key-file /path/to/passphrase \
  /dev/device
```

Key parameters:
- **LUKS2** (not LUKS1)
- **Argon2id** (memory-hard KDF, not PBKDF2)
- **AES-XTS-256** (512-bit key = 2×256 for XTS mode)
- **Key file** (not terminal prompt for automation)

## Pattern: Destructive Operations Safety

Scripts that format drives or delete data must:

1. **Require explicit device argument** (no defaults like "first removable drive")
2. **Refuse to operate on system disks** (`/dev/sda`, `/dev/nvme0n1`)
3. **Require confirmation** by typing the exact device name
4. **Display clear warnings** with visual separation (box drawing characters)

Example:

```bash
echo "╔════════════════════════════════════════╗" >&2
echo "║   DESTRUCTIVE OPERATION WARNING        ║" >&2
echo "║   Type device name to confirm:         ║" >&2
echo "╚════════════════════════════════════════╝" >&2
read -r confirmation
[[ "${confirmation}" == "${device}" ]] || exit 2
```

## Pattern: Air-Gap Safe Tooling

Scripts for air-gapped environments must:

- Use **stdlib-only dependencies** (Python standard library, no pip installs)
- **Never reference public URLs** (registries, CDNs, upstream repos) in high-side code
- Use **government cloud endpoints** for Azure resources (`.usgovcloudapi.net`)
- Work **without package manager access** (no apt, yum, pip during execution)

Example Python validator:

```python
# Uses only stdlib: json, re, pathlib, sys
import json
import re
from pathlib import Path
```

## Pattern: Exit Code Convention

```bash
# 0 = success (operation completed)
# 1 = error (validation failed, operation failed)
# 2 = invalid usage (missing args, file not found, confirmation rejected)
```

This distinguishes operational failures (1) from operator mistakes (2).

## Pattern: Idempotent Verification

Verification scripts should be safe to re-run:

```bash
# Check if already mounted before mounting
if mountpoint -q "${mount_point}"; then
    log_info "Already mounted"
    return 0
fi

# Check if volume already open before opening
if cryptsetup status "${mapper_name}" &>/dev/null; then
    log_info "Volume already open"
    return 0
fi
```

## Anti-Patterns

- ❌ Parsing manifest before GPG signature verification
- ❌ Hardcoding passphrases, keys, or connection strings
- ❌ Using PBKDF2 instead of Argon2id for new LUKS volumes
- ❌ Defaulting to "first removable drive" for destructive operations
- ❌ Mixing high-side and commercial-side code in the same script
- ❌ Requiring external Python packages (jsonschema, etc.) for air-gap validators

## Examples

### GPG Signature Verification First

```bash
verify_gpg_signature() {
    local manifest="$1"
    local signature="${manifest}.sig"
    local keyring="$2"
    
    if ! gpg --no-default-keyring --keyring "${keyring}" \
             --verify "${signature}" "${manifest}" 2>&1; then
        log_error "GPG signature verification failed"
        return 1
    fi
    return 0
}

# Always call before parsing manifest
verify_gpg_signature "${manifest}" "${keyring}" || exit 1
```

### Stdlib-Only Schema Validation

```python
def validate_sha256(checksum: str) -> bool:
    """No external dependencies."""
    pattern = r"^[a-f0-9]{64}$"
    return bool(re.match(pattern, checksum))
```

### Explicit Device Confirmation

```bash
if [[ "${device}" == "/dev/sda" ]] || [[ "${device}" == "/dev/nvme0n1" ]]; then
    log_error "Refusing to format primary system disk: ${device}"
    exit 2
fi
```

## References

- `transfer/verify/verify-bundle.sh` — Reference implementation of validation chain
- `transfer/manifest/validate-manifest.py` — Stdlib-only validator
- `transfer/encrypt/format-drive.sh` — LUKS2 with destructive operation safety
- `.github/copilot-instructions.md` — Air-gap constraints and Azure Government requirements
