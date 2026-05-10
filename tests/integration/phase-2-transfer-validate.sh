#!/usr/bin/env bash
# Validate a Phase 2 transfer bundle against a blob-backed Aptly pool.
#
# Required environment variables:
#   APTLY_CONFIG       - Path to aptly.conf
#   APTLY_POOL_MOUNT   - Expected blobfuse2 mount point
#   BUNDLE_ROOT        - Root directory of the transfer bundle
#   GPG_KEYRING        - GPG keyring containing the manifest signer public key
#
# Optional environment variables:
#   EXPECTED_PREVIOUS_SNAPSHOT - Required for non-initial transfers
#   RUN_APTLY_CHECKS           - Set to true for read-only Aptly pool checks
#
# Exit codes:
#   0 - Blob pool and bundle verification passed
#   1 - Validation failed
#   2 - Missing arguments or files

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly BLOB_POOL_VALIDATOR="${SCRIPT_DIR}/phase-2-blob-pool-validate.sh"
readonly BUNDLE_VERIFIER="${REPO_ROOT}/transfer/verify/verify-bundle.sh"

log_info() {
    echo "[INFO] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*" >&2
}

log_error() {
    echo "[ERROR] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*" >&2
}

require_env() {
    local missing=()
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("${var}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing[*]}"
        return 2
    fi
}

main() {
    require_env APTLY_CONFIG APTLY_POOL_MOUNT BUNDLE_ROOT GPG_KEYRING

    if [[ ! -x "${BLOB_POOL_VALIDATOR}" ]]; then
        log_error "Blob pool validator not executable: ${BLOB_POOL_VALIDATOR}"
        return 2
    fi

    if [[ ! -x "${BUNDLE_VERIFIER}" ]]; then
        log_error "Bundle verifier not executable: ${BUNDLE_VERIFIER}"
        return 2
    fi

    log_info "Validating blob-backed Aptly pool"
    "${BLOB_POOL_VALIDATOR}"

    local verifier_args=("${BUNDLE_ROOT}" "${GPG_KEYRING}")
    if [[ -n "${EXPECTED_PREVIOUS_SNAPSHOT:-}" ]]; then
        verifier_args+=("--expected-previous-snapshot" "${EXPECTED_PREVIOUS_SNAPSHOT}")
    fi

    log_info "Validating transfer bundle"
    "${BUNDLE_VERIFIER}" "${verifier_args[@]}"

    log_info "Phase 2 transfer validation passed"
}

main "$@"
