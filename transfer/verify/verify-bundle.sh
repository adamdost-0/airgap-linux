#!/usr/bin/env bash
#
# Verify transfer bundle integrity: GPG signature, schema, continuity, checksums, completeness.
#
# Usage: verify-bundle.sh <bundle_root> <gpg_keyring> [--expected-previous-snapshot <snapshot_name>]
#
# Validation order:
#   1. GPG signature verification (manifest.json.sig)
#   2. JSON schema validation
#   3. Continuity check (previous_snapshot matches expected state)
#   4. SHA-256 checksum verification of all .deb files
#   5. Completeness check (all files in manifest exist)
#
# Exit codes:
#   0 = verification passed
#   1 = verification failed
#   2 = missing arguments or file not found
#
# Environment variables:
#   MANIFEST_VALIDATOR       - Path to validate-manifest.py (default: auto-detect)
#   EXPECTED_PREVIOUS_SNAPSHOT - Expected previous snapshot name (overrides --expected-previous-snapshot)

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MANIFEST_VALIDATOR="${MANIFEST_VALIDATOR:-${SCRIPT_DIR}/../manifest/validate-manifest.py}"

usage() {
    echo "Usage: $0 <bundle_root> <gpg_keyring> [--expected-previous-snapshot <snapshot_name>]" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  bundle_root  - Root directory of the transfer bundle" >&2
    echo "  gpg_keyring  - Path to GPG keyring containing signer's public key" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --expected-previous-snapshot <name>  - Expected previous snapshot (required for non-initial transfers)" >&2
    echo "" >&2
    echo "Environment variables:" >&2
    echo "  EXPECTED_PREVIOUS_SNAPSHOT  - Alternative to --expected-previous-snapshot flag" >&2
    exit 2
}

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

verify_gpg_signature() {
    local bundle_root="$1"
    local gpg_keyring="$2"
    local manifest="${bundle_root}/manifest.json"
    local signature="${bundle_root}/manifest.json.sig"

    log_info "Verifying GPG signature..."

    if [[ ! -f "${signature}" ]]; then
        log_error "Signature file not found: ${signature}"
        return 1
    fi

    if ! gpg --no-default-keyring --keyring "${gpg_keyring}" --verify "${signature}" "${manifest}" 2>&1; then
        log_error "GPG signature verification failed"
        return 1
    fi

    log_info "✓ GPG signature valid"
    return 0
}

verify_schema() {
    local bundle_root="$1"
    local manifest="${bundle_root}/manifest.json"

    log_info "Validating manifest schema..."

    if [[ ! -f "${MANIFEST_VALIDATOR}" ]]; then
        log_error "Manifest validator not found: ${MANIFEST_VALIDATOR}"
        return 1
    fi

    if ! python3 "${MANIFEST_VALIDATOR}" "${manifest}"; then
        log_error "Manifest schema validation failed"
        return 1
    fi

    log_info "✓ Manifest schema valid"
    return 0
}

verify_continuity() {
    local bundle_root="$1"
    local expected_previous="$2"
    local manifest="${bundle_root}/manifest.json"

    log_info "Verifying snapshot continuity..."

    # Extract previous_snapshot from manifest
    local prev_snapshot
    prev_snapshot="$(python3 -c "
import json, sys
try:
    with open('${manifest}') as f:
        m = json.load(f)
    prev = m.get('previous_snapshot')
    if prev is None:
        print('INITIAL')
    else:
        print(prev['name'])
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
")" || {
        log_error "Failed to extract previous_snapshot from manifest"
        return 1
    }

    if [[ "${prev_snapshot}" == "INITIAL" ]]; then
        log_info "Initial transfer detected (previous_snapshot: null)"
        
        # For initial transfers, expected_previous must be empty or "INITIAL"
        if [[ -n "${expected_previous}" && "${expected_previous}" != "INITIAL" ]]; then
            log_error "Continuity check failed: manifest indicates initial transfer but expected '${expected_previous}'"
            return 1
        fi
        
        log_info "✓ Continuity valid: initial transfer"
        return 0
    fi

    # Non-initial transfer: require explicit expected_previous
    if [[ -z "${expected_previous}" ]]; then
        log_error "Continuity check failed: expected_previous is required for non-initial transfers"
        log_error "Manifest previous_snapshot: ${prev_snapshot}"
        log_error "Provide --expected-previous-snapshot or set EXPECTED_PREVIOUS_SNAPSHOT"
        return 1
    fi

    # Verify continuity: manifest previous must match expected
    if [[ "${prev_snapshot}" != "${expected_previous}" ]]; then
        log_error "Continuity check failed: snapshot mismatch"
        log_error "  Manifest previous_snapshot: ${prev_snapshot}"
        log_error "  Expected previous_snapshot:  ${expected_previous}"
        return 1
    fi

    log_info "✓ Continuity valid: ${prev_snapshot} → manifest"
    return 0
}

verify_checksums() {
    local bundle_root="$1"
    local manifest="${bundle_root}/manifest.json"

    log_info "Verifying package checksums..."

    local failed=0
    local total=0

    # Extract filenames and checksums from manifest (added + upgraded)
    while IFS=$'\t' read -r filename expected_sha256; do
        ((total++))
        local file_path="${bundle_root}/${filename}"

        if [[ ! -f "${file_path}" ]]; then
            log_error "File missing: ${filename}"
            ((failed++))
            continue
        fi

        local actual_sha256
        actual_sha256="$(sha256sum "${file_path}" | awk '{print $1}')"

        if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
            log_error "Checksum mismatch: ${filename}"
            log_error "  Expected: ${expected_sha256}"
            log_error "  Actual:   ${actual_sha256}"
            ((failed++))
        fi
    done < <(python3 -c "
import json, sys
with open('${manifest}') as f:
    m = json.load(f)
for pkg in m['packages_added']:
    print(f\"{pkg['filename']}\t{pkg['sha256']}\")
for pkg in m['packages_upgraded']:
    print(f\"{pkg['filename']}\t{pkg['sha256']}\")
")

    if [[ ${failed} -gt 0 ]]; then
        log_error "Checksum verification failed: ${failed}/${total} files"
        return 1
    fi

    log_info "✓ All checksums valid (${total} files)"
    return 0
}

verify_completeness() {
    local bundle_root="$1"
    local manifest="${bundle_root}/manifest.json"

    log_info "Verifying bundle completeness..."

    local missing=0

    while read -r filename; do
        local file_path="${bundle_root}/${filename}"
        if [[ ! -f "${file_path}" ]]; then
            log_error "Missing file: ${filename}"
            ((missing++))
        fi
    done < <(python3 -c "
import json
with open('${manifest}') as f:
    m = json.load(f)
for pkg in m['packages_added']:
    print(pkg['filename'])
for pkg in m['packages_upgraded']:
    print(pkg['filename'])
")

    if [[ ${missing} -gt 0 ]]; then
        log_error "Completeness check failed: ${missing} files missing"
        return 1
    fi

    log_info "✓ Bundle complete"
    return 0
}

main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local bundle_root="$1"
    local gpg_keyring="$2"
    shift 2

    # Parse optional arguments
    local expected_previous="${EXPECTED_PREVIOUS_SNAPSHOT:-}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --expected-previous-snapshot)
                if [[ $# -lt 2 ]]; then
                    log_error "Missing value for --expected-previous-snapshot"
                    usage
                fi
                expected_previous="$2"
                shift 2
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                ;;
        esac
    done

    local manifest="${bundle_root}/manifest.json"

    if [[ ! -d "${bundle_root}" ]]; then
        log_error "Bundle root not found: ${bundle_root}"
        exit 2
    fi

    if [[ ! -f "${manifest}" ]]; then
        log_error "Manifest not found: ${manifest}"
        exit 2
    fi

    if [[ ! -f "${gpg_keyring}" ]]; then
        log_error "GPG keyring not found: ${gpg_keyring}"
        exit 2
    fi

    log_info "Starting bundle verification: ${bundle_root}"

    # Execute verification chain in required order
    verify_gpg_signature "${bundle_root}" "${gpg_keyring}" || exit 1
    verify_schema "${bundle_root}" || exit 1
    verify_continuity "${bundle_root}" "${expected_previous}" || exit 1
    verify_checksums "${bundle_root}" || exit 1
    verify_completeness "${bundle_root}" || exit 1

    log_info "✓ Bundle verification complete: all checks passed"
    exit 0
}

main "$@"
