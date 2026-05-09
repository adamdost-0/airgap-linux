#!/usr/bin/env bash
#
# High-side ingestion workflow: verify, decrypt, import, publish.
#
# Usage: ingest.sh <device> <passphrase_file> <gpg_keyring> [--expected-previous-snapshot <snapshot_name>]
#
# Workflow:
#   1. Open LUKS2 encrypted drive
#   2. Verify bundle integrity (GPG + schema + continuity + checksums + completeness)
#   3. Import packages via Aptly (delegates to import-packages.sh)
#   4. Publish updated repository
#   5. Cleanup and close drive
#
# Continuity state:
#   For non-initial transfers, provide --expected-previous-snapshot or set
#   EXPECTED_PREVIOUS_SNAPSHOT environment variable. Verification fails if
#   manifest previous_snapshot does not match expected state.
#
# Exit codes:
#   0 = success
#   1 = verification or import failed
#   2 = missing arguments or prerequisites

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MOUNT_POINT="/mnt/airgap-transfer"
readonly VERIFY_BUNDLE="${SCRIPT_DIR}/verify-bundle.sh"
readonly OPEN_DRIVE="${SCRIPT_DIR}/../../transfer/encrypt/open-drive.sh"

usage() {
    echo "Usage: $0 <device> <passphrase_file> <gpg_keyring> [--expected-previous-snapshot <snapshot_name>]" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  device          - Block device containing transfer bundle" >&2
    echo "  passphrase_file - File containing LUKS passphrase" >&2
    echo "  gpg_keyring     - GPG keyring with signer's public key" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --expected-previous-snapshot <name>  - Expected previous snapshot (required for non-initial)" >&2
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

cleanup() {
    log_info "Cleaning up..."
    if mountpoint -q "${MOUNT_POINT}" 2>/dev/null; then
        umount "${MOUNT_POINT}" || true
    fi
    if cryptsetup status airgap_transfer &>/dev/null; then
        cryptsetup close airgap_transfer || true
    fi
}

trap cleanup EXIT

import_packages() {
    local bundle_root="$1"

    log_info "Importing packages to Aptly..."

    # TODO: Call import-packages.sh script
    # This delegates package repository operations to the Aptly specialist
    log_info "⚠ Import stub: would call highside/scripts/import-packages.sh here"

    return 0
}

publish_repository() {
    log_info "Publishing repository updates..."

    # TODO: Call Cheritto's publish-update.sh script
    log_info "⚠ Publish stub: would call highside/scripts/publish-update.sh here"

    return 0
}

main() {
    if [[ $# -lt 3 ]]; then
        usage
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 2
    fi

    local device="$1"
    local passphrase_file="$2"
    local gpg_keyring="$3"
    shift 3

    # Parse optional arguments for continuity state
    local verify_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --expected-previous-snapshot)
                if [[ $# -lt 2 ]]; then
                    log_error "Missing value for --expected-previous-snapshot"
                    usage
                fi
                verify_args+=("$1" "$2")
                shift 2
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                ;;
        esac
    done

    if [[ ! -x "${OPEN_DRIVE}" ]]; then
        log_error "Drive opener not found or not executable: ${OPEN_DRIVE}"
        exit 2
    fi

    if [[ ! -x "${VERIFY_BUNDLE}" ]]; then
        log_error "Bundle verifier not found or not executable: ${VERIFY_BUNDLE}"
        exit 2
    fi

    log_info "Starting high-side ingestion"

    # 1. Open encrypted drive
    log_info "Step 1: Opening encrypted drive..."
    if ! "${OPEN_DRIVE}" "${device}" "${passphrase_file}" "${MOUNT_POINT}"; then
        log_error "Failed to open drive"
        exit 1
    fi

    # 2. Verify bundle integrity (includes continuity check)
    log_info "Step 2: Verifying bundle integrity (GPG + schema + continuity + checksums + completeness)..."
    if ! "${VERIFY_BUNDLE}" "${MOUNT_POINT}" "${gpg_keyring}" "${verify_args[@]}"; then
        log_error "Bundle verification failed"
        exit 1
    fi

    # 3. Import packages (atomic)
    log_info "Step 3: Importing packages..."
    if ! import_packages "${MOUNT_POINT}"; then
        log_error "Package import failed"
        exit 1
    fi

    # 4. Publish repository
    log_info "Step 4: Publishing repository..."
    if ! publish_repository; then
        log_error "Publish failed"
        exit 1
    fi

    log_info "✓ Ingestion complete"
    exit 0
}

main "$@"
